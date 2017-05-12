package Util;
# ABSTRACT: Utility subroutines for testing HTTP::AnyUA

=head1 SYNOPSIS

    use Util qw(:server :test :ua);

=cut

use warnings;
use strict;

use Exporter qw(import);
use Future;
use Test2::API qw(context release);
use Test::More;

our @EXPORT_OK = qw(
    recv_env
    send_env
    start_server
    use_server

    is_response_content
    is_response_header
    is_response_reason
    is_response_status
    is_response_success
    is_response_url
    response_protocol_ok

    test_all_user_agents
    test_user_agent
    user_agents
);
our %EXPORT_TAGS = (
    server  => [qw(
        recv_env
        send_env
        start_server
        use_server
    )],
    test    => [qw(
        is_response_content
        is_response_header
        is_response_reason
        is_response_status
        is_response_success
        is_response_url
        response_protocol_ok
    )],
    ua      => [qw(
        test_all_user_agents
        test_user_agent
        user_agents
    )],
);

our @USER_AGENTS = qw(
    AnyEvent::HTTP
    Furl
    HTTP::Tiny
    LWP::UserAgent
    Mojo::UserAgent
    Net::Curl::Easy
);
our %USER_AGENT_TEST_WRAPPER;

sub _croak { require Carp; Carp::croak(@_) }
sub _carp  { require Carp; Carp::carp(@_)  }


=func use_server

    use_server;

Try to use the test server package. If it fails, the test plan is set to C<skip_all>.

=cut

sub use_server {
    eval 'use Server';
    if (my $err = $@) {
        diag $err;
        plan skip_all => 'Could not compile test server runner.';
    }
}

=func start_server

    $server = start_server('app.psgi');

Start a test server.

=cut

sub start_server {
    use_server;
    my $server = eval { Server->new(@_) };
    if (my $err = $@) {
        diag $err;
        plan skip_all => 'Could not start test server.';
    }
    return $server;
}

=func send_env

    send_env(\%env);

Encode and send a L<PSGI> environment over C<STDOUT>, to be received by L</recv_env>.

=cut

sub send_env {
    my $env = shift || {};
    my $fh  = shift || *STDOUT;

    my %data = map { !/^psgi/ ? ($_ => $env->{$_}) : () } keys %$env;

    # read in the request body
    my $buffer;
    my $body = '';
    $env->{'psgix.input.buffered'} or die 'Expected buffered input';
    while (1) {
        my $bytes = $env->{'psgi.input'}->read($buffer, 32768);
        defined $bytes or die 'Error while reading input stream';
        last if !$bytes;
        $body .= $buffer;
    }
    $data{content} = $body;

    require JSON;
    print $fh JSON::encode_json(\%data), "\n";
}

=func recv_env

    my $env = recv_env($fh);

Receive and decode a L<PSGI> environment over a filehandle, sent by L</send_env>.

=cut

sub recv_env {
    my $fh = shift;

    my $data = <$fh>;

    require JSON;
    return JSON::decode_json($data);
}


=func is_response_content, is_response_reason, is_response_status, is_response_success, is_response_url, is_response_header

    is_response_content($resp, $body, $test_name);
    is_response_content($resp, $body);
    # etc.

Test a response for various fields.

=cut

sub is_response_content { my $ctx = context; release $ctx, _test_response_field($_[0], 'content', @_[1,2]) }
sub is_response_reason  { my $ctx = context; release $ctx, _test_response_field($_[0], 'reason',  @_[1,2]) }
sub is_response_status  { my $ctx = context; release $ctx, _test_response_field($_[0], 'status',  @_[1,2]) }
sub is_response_success { my $ctx = context; release $ctx, _test_response_field($_[0], 'success', @_[1,2], 'bool') }
sub is_response_url     { my $ctx = context; release $ctx, _test_response_field($_[0], 'url',     @_[1,2]) }
sub is_response_header  { my $ctx = context; release $ctx, _test_response_header(@_) }

=func response_protocol_ok

    response_protocol_ok($resp);

Test that a response protocol is well-formed.

=cut

sub response_protocol_ok {
    my ($resp) = @_;
    my $ctx = context;
    my $test;
    if (ref($resp) ne 'HASH') {
        $test = isa_ok($resp, 'HASH', 'response');
    }
    else {
        my $proto = $resp->{protocol};
        $test = ok(!$proto || $proto =~ m!^HTTP/!, 'response protocol matches or is missing');
    }
    release $ctx, $test;
}

sub _test_response_field {
    my ($resp, $key, $val, $name, $type) = @_;
    if (ref($resp) ne 'HASH') {
        return isa_ok($resp, 'HASH', 'response');
    }
    elsif (defined $val) {
        $type ||= '';
        if ($type eq 'bool') {
            my $disp = $val ? 'true' : 'false';
            return is(!!$resp->{$key}, !!$val, $name || "response $key matches \"$disp\"");
        }
        else {
            my $disp = $val;
            $disp =~ s/(.{40}).{4,}/$1.../;
            return is($resp->{$key}, $val, $name || "response $key matches \"$disp\"");
        }
    }
    else {
        return ok(exists $resp->{$key}, $name || "response $key exists");
    }
}

sub _test_response_header {
    my ($resp, $key, $val, $name) = @_;
    if (ref($resp) ne 'HASH') {
        return isa_ok($resp, 'HASH', 'response');
    }
    elsif (ref($resp->{headers}) ne 'HASH') {
        return isa_ok($resp, 'HASH', 'response headers');
    }
    elsif (defined $val) {
        my $disp = $val;
        $disp =~ s/(.{40}).{4,}/$1.../;
        return is($resp->{headers}{$key}, $val, $name || "response header \"$key\" matches \"$disp\"");
    }
    else {
        return ok(exists $resp->{headers}{$key}, $name || "response header $key exists");
    }
}


=func user_agents

    @user_agents = user_agents;

Get a list of user agents available for testing. Shortcut for C<@Util::USER_AGENTS>.

=cut

sub user_agents { @USER_AGENTS }

=func test_user_agent

    test_user_agent($ua_type, \&test);

Run a subtest against one user agent.

=cut

sub test_user_agent {
    my $name = shift;
    my $code = shift;

    my $wrapper = $USER_AGENT_TEST_WRAPPER{$name} || sub {
        my $name = shift;
        my $code = shift;

        if (!eval "require $name") {
            diag $@;
            return;
        }

        my $ua = $name->new;
        $code->($ua);

        return 1;
    };

    # this is quite gross, but we don't want any active event loops from preventing us from
    # committing suicide if things are looking deadlocked
    local $SIG{ALRM} = sub { $@ = 'Deadlock or test is slow'; _carp $@; exit 1 };
    alarm 5;
    my $ret = $wrapper->($name, $code);
    alarm 0;

    plan skip_all => "Cannot create user agent ${name}" if !$ret;
}

=func test_all_user_agents

    test_all_user_agents { ... };

Run the same subtest against all user agents returned by L</user_agents>.

=cut

sub test_all_user_agents(&) {
    my $code = shift;

    for my $name (user_agents) {
        subtest $name => sub {
            test_user_agent($name, $code);
        };
    }
}


$USER_AGENT_TEST_WRAPPER{'AnyEvent::HTTP'} = sub {
    my $name = shift;
    my $code = shift;

    if (!eval "require $name") {
        diag $@;
        return;
    }

    require AnyEvent;
    my $cv = AnyEvent->condvar;

    my $ua = 'AnyEvent::HTTP';
    my @futures = $code->($ua);
    my $waiting = Future->wait_all(@futures)->on_ready(sub { $cv->send });

    $cv->recv;

    return 1;
};

$USER_AGENT_TEST_WRAPPER{'Mojo::UserAgent'} = sub {
    my $name = shift;
    my $code = shift;

    if (!eval "require $name") {
        diag $@;
        return;
    }

    require Mojo::IOLoop;
    my $loop = Mojo::IOLoop->singleton;

    my $ua = Mojo::UserAgent->new;
    my @futures = $code->($ua);
    my $waiting = Future->wait_all(@futures)->on_ready(sub { $loop->reset });

    $loop->start;

    return 1;
};

1;
