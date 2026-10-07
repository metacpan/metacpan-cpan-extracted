use strict;
use warnings;

use Test::More;
use Test::TCP qw(empty_port);
use File::Temp qw(tempdir);
use IO::Socket::INET;
use IO::Socket::UNIX;

use EV;
use EV::Redis;

# failures raised inside the connect call itself, before any loop iteration
my $missing_sock = '/nonexistent/ev-redis-test.sock';

sub run_loop {
    my $guard = EV::timer 5, 0, sub { EV::break };
    EV::run;
}

my @cases = (
    [ 'missing unix socket', 0, sub { $_[0]->connect_unix($missing_sock) } ],
    # 192.0.2.1 (TEST-NET-1) is normally not a local address
    [ 'unbindable source address', 1, sub {
        $_[0]->source_addr('192.0.2.1');
        $_[0]->connect('127.0.0.1', empty_port());
    } ],
);

for my $case (@cases) {
    my ($name, $may_bind, $connect) = @$case;
    my @errors;
    my $r = EV::Redis->new(
        on_error => sub {
            push @errors, $_[0];
            EV::break if $_[0] =~ /max attempts reached/;
            $_[0] = 'changed by on_error';    # must not reach the queued commands
        },
        reconnect              => 1,
        reconnect_delay        => 10,
        max_reconnect_attempts => 2,
    );

    $connect->($r);
    SKIP: {
        skip "$name: 192.0.2.1 is bindable here", 7
            if $may_bind && $r->is_connected;

        is scalar(@errors), 1, "$name: error reported by the connect call";
        like $errors[0], qr/^connect error: /, "$name: connect error prefix";

        my @cb_err;
        ok eval {
            $r->command(get => 'x', sub { $cb_err[0] = $_[1] });
            $r->command(get => 'y', sub { $cb_err[1] = $_[1] });
            1;
        }, "$name: commands queued while the reconnect is pending"
            or diag $@;

        run_loop();

        is scalar(grep { /^reconnect error: / } @errors), 3,
            "$name: two retries, then gave up"
            or diag explain \@errors;
        like $cb_err[0], qr/^reconnect error: (?!max attempts)/,
            "$name: queued command failed with the retry";
        is $cb_err[1], $cb_err[0], "$name: every queued command got the error";
        is $r->is_connected, 0, "$name: not connected";
    }
}

{
    my ($cb_err, @errors);
    my $r = EV::Redis->new(
        on_error => sub {
            push @errors, $_[0];
            EV::break if $_[0] =~ /max attempts reached/;
        },
        reconnect                   => 1,
        reconnect_delay             => 10,
        max_reconnect_attempts      => 2,
        resume_waiting_on_reconnect => 1,
    );
    $r->connect_unix($missing_sock);
    $r->command(get => 'x', sub { $cb_err = $_[1] });
    run_loop();
    like $cb_err, qr/max attempts reached/,
        'resume_waiting_on_reconnect: queued command outlives the failed retries';
}

{
    my $r;
    $r = EV::Redis->new(
        on_error        => sub { undef $r },
        reconnect       => 1,
        reconnect_delay => 10,
    );
    $r->connect_unix($missing_sock);
    ok !defined $r, 'on_error may drop the last reference inside connect_unix';
}

{
    my $path = tempdir(CLEANUP => 1) . '/s';
    my $srv = IO::Socket::UNIX->new(Local => $path, Listen => 1)
        or die "listen on $path: $!";
    my (@errors, $connected);
    my $r = EV::Redis->new(
        tcp_user_timeout => 1000,
        on_error   => sub { push @errors, $_[0]; EV::break },
        on_connect => sub { $connected = 1; EV::break },
    );
    $r->connect_unix($path);
    run_loop();

    ok $connected, 'tcp_user_timeout: unix socket connects'
        or diag explain \@errors;
    is scalar(@errors), 0, 'tcp_user_timeout: no error on a unix socket';
    $r->disconnect;
}

# Linux has TCP_USER_TIMEOUT; elsewhere connect may fail inside the call
{
    my $srv = IO::Socket::INET->new(
        Listen => 1, LocalAddr => '127.0.0.1', LocalPort => 0,
    ) or die "listen: $!";
    my (@errors, $connected);
    my $r = EV::Redis->new(
        tcp_user_timeout => 1000,
        on_error   => sub { push @errors, $_[0]; EV::break },
        on_connect => sub { $connected = 1; EV::break },
    );
    $r->connect('127.0.0.1', $srv->sockport);
    if (@errors && $^O ne 'linux') {
        like $errors[0], qr/^connect error: .*TCP_USER_TIMEOUT/,
            'tcp_user_timeout: unsupported option reported';
        is $r->is_connected, 0, 'tcp_user_timeout: no context left behind';
    }
    else {
        run_loop();
        ok $connected, 'tcp_user_timeout: TCP connects' or diag explain \@errors;
        is scalar(@errors), 0, 'tcp_user_timeout: no error on TCP';
        $r->disconnect;
    }
}

# a failing connect() from on_error must not use up the retry
{
    my ($r, @errors, $nested);
    $r = EV::Redis->new(
        on_error => sub {
            push @errors, $_[0];
            $r->connect_unix($missing_sock) unless $nested++;
            EV::break if $_[0] =~ /max attempts reached/;
        },
        reconnect              => 1,
        reconnect_delay        => 10,
        max_reconnect_attempts => 1,
    );
    $r->connect('127.0.0.1', empty_port());
    run_loop();

    is scalar(grep { /^reconnect error: / && !/max attempts/ } @errors), 1,
        'nested failing connect: the one retry still ran'
        or diag explain \@errors;
    like $errors[-1], qr/max attempts reached/, 'nested failing connect: then gave up';
    undef $r;
}

# a failed connect's pending callback starts a sync-failing connect, then drops $r
SKIP: {
    my $r = EV::Redis->new(on_error => sub {});
    $r->connect('127.0.0.1', empty_port());
    skip 'loopback connect refused synchronously', 1 unless $r->is_connected;

    my $fired;
    $r->command(get => 'x', sub {
        $r->connect_unix($missing_sock);
        undef $r;
        $fired = 1;
        EV::break;
    });
    run_loop();
    ok $fired, 'failed connect: pending callback survived connect + DESTROY';
}

done_testing;
