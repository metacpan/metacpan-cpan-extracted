# $Id: /mirror/gungho/lib/Gungho/Engine/POE.pm 39017 2008-01-16T16:05:45.674472Z lestrrat  $
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package Gungho::Engine::POE;
use strict;
use warnings;
use base qw(Gungho::Engine);
use POE;
use POE::Component::Client::Keepalive;
use POE::Component::Client::HTTP;

__PACKAGE__->mk_accessors($_) for qw(alias loop_alarm loop_delay resolver clients);

use constant DEBUG => 0;
use constant UserAgentAlias => 'Gungho_Engine_POE_UserAgent_Alias';
use constant DnsResolverAlias => 'Gungho_Engine_POE_DnsResolver_Alias';
use constant SKIP_DECODE_CONTENT  =>
    exists $ENV{GUNGHO_ENGINE_POE_SKIP_DECODE_CONTENT} ?  $ENV{GUNGHO_ENGINE_POE_SKIP_DECODE_CONTENT} : 1;
use constant FORCE_ENCODE_CONTENT => 
    $ENV{GUNGHO_ENGINE_POE_FORCE_ENCODE_CONTENT} && ! SKIP_DECODE_CONTENT;

BEGIN
{
    if (SKIP_DECODE_CONTENT) {
        # PoCo::Client::HTTP workaround for blindly decoding content for us
        # when encountering Contentn-Encoding
        eval sprintf(<<'        EOCODE', 'HTTP::Response');
            no warnings 'redefine';
            package %s;
            sub HTTP::Response::decoded_content {
                my ($self, %%opt) = @_;
                my $caller = (caller(2))[3];

                if ($caller eq 'POE::Component::Client::HTTP::Request::return_response') {
                    $opt{charset} = 'none';
                }
                $self->SUPER::decoded_content(%%opt);
            }
        EOCODE
    }
}

sub setup
{
    my $self = shift;
    $self->alias('MainComp');
    $self->loop_delay( $self->config->{loop_delay} ) if $self->config->{loop_delay};
    $self->next::method(@_);
}

sub run
{
    my ($self, $c) = @_;

    my %config = %{ $self->config || {} };

    my $keepalive_config = delete $config{keepalive} || {};

    {
        my %defaults = (
            keep_alive   => 10,
            max_open     => 200,
            max_per_host => 5,
            timeout      => 10
        );
        while (my($key, $value) = each %defaults) {
            if (! defined $keepalive_config->{$key}) {
                $keepalive_config->{$key} = $value;
            }
        }
    }

    my $keepalive = POE::Component::Client::Keepalive->new(%$keepalive_config);

    my $client_config = delete $config{client} || {};
    foreach my $key (keys %$client_config) {
        if ($key =~ /^[a-z]/) { # ah, need to make this CamelCase
            my $camel = ucfirst($key);
            $camel =~ s/_(\w)/uc($1)/ge;
            $client_config->{$camel} = delete $client_config->{$key};
        }
    }

    # Starting from 0.09002, we accept that there are environments where
    # DNS resolution is NOT necessary. This turns out to be a problem when
    # going through, for example, a misconfigured proxy.
    #
    # Here, we detect if one of the following is true:
    #   1) The user has explicitly disable DNS resolution via dns.disable = 1
    #   2) The user has requested the use of a proxy via engine.client.proxy
    #   3) The user has implicitly requested the use of a proxy via
    #      $ENV{HTTP_PROXY}
    my $dns_config = delete $config{dns} || {};
    unless ($dns_config->{disable} || $client_config->{Proxy} || $client_config->{proxy} || $ENV{HTTP_PROXY}) {
        foreach my $key (keys %$dns_config) {
            if ($key =~ /^[a-z]/) { # ah, need to make this CamelCase
                my $camel = ucfirst($key);
                $camel =~ s/_(\w)/uc($1)/ge;
                $dns_config->{$camel} = delete $dns_config->{$key};
            }
        }
        my $resolver = POE::Component::Client::DNS->spawn(
            %$dns_config,
            Alias => &DnsResolverAlias,
        );
        $self->resolver($resolver);
    }

    # Oh, guess what. We will create as many clients as we were requested,
    # just so that PoCo::Client::HTTP doesn't stall on us (as of 
    # PoCo::Client::HTTP 0.82, PoCo::Client::HTTP tended to get filled up
    # pretty quickcly)
    $self->clients( [] );
    my $spawn = delete $client_config->{Spawn} || 2;
    if ($spawn < 1) { $spawn = 2 }
    for my $i ( 1 .. $spawn ) {
        my $alias = join('-', &UserAgentAlias, $i);
        push @{ $self->clients }, $alias;
        POE::Component::Client::HTTP->spawn(
            FollowRedirects   => 1,
            Agent             => $c->user_agent,
            Timeout           => 60,
            %$client_config,
            Alias             => $alias,
            ConnectionManager => $keepalive,
        );
    }

    POE::Session->create(
        heap => { CONTEXT => $c },
        object_states => [
            $self => {
                _start => '_poe_session_start',
                _stop  => '_poe_session_stop',
                map { ($_ => "_poe_$_") }
                    qw(session_loop start_request handle_response got_dns_response shutdown)
            }
        ]
    );

    POE::Kernel->run() if
        ! exists $config{ kernel_start } || $config{ kernel_start };
}

sub stop
{
    my ($self, $c) = @_;
    POE::Kernel->post($self->alias, 'shutdown');
}

sub _poe_shutdown
{
    my ($self, $kernel, $heap) = @_[OBJECT, KERNEL, HEAP];
    my $clients = $self->clients;
    foreach my $client (@$clients) {
        $kernel->post($client, 'shutdown');
    }
    my $c = $heap->{CONTEXT};
    $c->is_running(0);
}

sub _poe_session_start
{
    $_[KERNEL]->alias_set( $_[OBJECT]->alias );
    $_[KERNEL]->yield('session_loop');
}

sub _poe_session_stop
{
    $_[KERNEL]->alias_remove( $_[OBJECT]->alias );
    eval {
        $_[KERNEL]->post($_, 'shutdown') for @{ $_[OBJECT]->clients }
    };
}

sub _poe_session_loop
{
    my ($self, $kernel, $heap) = @_[OBJECT, KERNEL, HEAP];

    my $c = $heap->{CONTEXT};

    if (! $c->is_running) {
        $c->log->debug("is_running = 0, waiting for other queued states to finish...\n");
        return;
    }

    $c->dispatch_requests();

    my $alarm_id = $self->loop_alarm;
    if ($alarm_id) {
        $kernel->alarm_remove( $alarm_id );
    }
    my $delay = $self->loop_delay;
    if (! defined $delay || $delay <= 0) {
        $delay = 1;
        $self->loop_delay($delay);
    }
    $self->loop_alarm($kernel->alarm_set('session_loop', time() + $delay));

    $c->notify('engine.end_loop');
}

sub send_request
{
    my ($self, $c, $request) = @_;
    POE::Kernel->post($self->alias, 'start_request', $request);
    return 1;
}

sub _poe_start_request
{
    my ($kernel, $self, $heap, $request) = @_[KERNEL, OBJECT, HEAP, ARG0];
    my $c = $heap->{CONTEXT};

    # check if this request requires a DNS resolution
    if ($c->engine->resolver && $request->requires_name_lookup()) {
        my $dns_response = $c->engine->resolver->resolve(
            event => "got_dns_response",
            host  => $request->uri->host,
            context => { request => $request }
        );
        # PoCo::Client::DNS may resolve DNS immediately
        if ($dns_response) {
            $kernel->yield('got_dns_response', $dns_response);
        }
        return;
    }

    $request->uri->host($request->notes('resolved_ip'))
        if $request->notes('resolved_ip');

    if (! $c->request_is_allowed($request)) {
        # For whatever reason, the request was not allowed
        return;
    }

    $c->notify('engine.send_request', { request => $request });

    if (DEBUG) {
        my $uri = $request->uri->clone;
        $uri->host( $request->notes('original_host') ) if $request->notes('original_host');
        $c->log->info("Going to fetch $uri");
    }

    # Choose a random client
    my @clients = @{ $self->clients };
    my $client  = $clients[ rand @clients ];
    POE::Kernel->post($client, 'request', 'handle_response', $request);
}

sub _poe_got_dns_response
{
    my ($kernel, $response) = @_[KERNEL, ARG0];

    $_[OBJECT]->handle_dns_response(
        $_[HEAP]->{CONTEXT}, 
        $response->{context}->{request}, # original request
        $response->{response}, # DNS response
    );
}

sub _poe_handle_response
{
    my ($kernel, $heap, $req_packet, $res_packet) = @_[ KERNEL, HEAP, ARG0, ARG1 ];

    my $c = $heap->{CONTEXT};

    my $req = $req_packet->[0];
    my $res = $res_packet->[0];

    if (my $host = $req->notes('original_host')) {
        # Put it back
        $req->uri->host($host);
    }
    if (DEBUG) {
        $c->log->info("Received " . $req->uri);
    }

    # Work around POE doing too much for us. 
    if (FORCE_ENCODE_CONTENT && $POE::Component::Client::HTTP::VERSION # Hide from CPAN
        >= 0.80)
    {
        if ($res->content_encoding) {
            my @ct = $res->content_type;
            if ((shift @ct) =~ /^text\//) {
                foreach my $ct (@ct) {
                    next unless $ct =~ /charset=((?!utf-?8).+)$/;
                    my $enc = $1;
                    require Encode;
                    $res->content( Encode::encode($enc, $res->content) );
                    last;
                }
            }
        }
    }

    $c->notify('engine.handle_response', { request => $req, response => $res });

    # Do we support auth challenge ?
    my $code = $c->can('check_authentication_challenge');
    if ( $code ) {
        # return if auth has taken care of the response
        return if $code->($c, $req, $res);
    }

    $c->handle_response($req, $c->prepare_response($res) );

    $kernel->yield('session_loop');
}

1;

__END__

=head1 NAME

Gungho::Engine::POE - POE Engine For Gungho

=head1 SYNOPSIS

  engine:
    module: POE
    config:
      loop_delay: 5 
      client:
        spawn: 2
        agent:
          - AgentName1
          - AgentName2
        max_size: 16384
        follow_redirect: 2
        proxy: http://localhost:8080
      keepalive:
        keep_alive: 10
        max_open: 200
        max_per_host: 20
        timeout: 10
      dns:
        # disable: 1 If you want to disable DNS resolution by Gungho


=head1 DESCRIPTION

Gunghog::Engine::POE gives you the full power of POE to Gungho.

=head1 CONFIGURATION PARAMETERS

You can configure the POE engine in many ways. For convenience, all second 
level parameter names below are written as 'parent.child'. For example,
'client.agent' will actually mean

  engine:
    module: POE
    config:
      client:
        agent: XXXXX

Or in perl,

  engine => {
    module => 'POE',
    config => {
      client => {
        agent => "XXXX"
      }
    }
  }

=head2 kernel_start

If you're embedding Gungho into another POE application, you probably don't
want Gungho to call POE::Kernel->run(). This option can control that behavior.

If you don't want to start the kernel, then specify 0 for this option.
The default is 1.

=head2 client.loop_delay

C<loop_delay> specifies the number of seconds to wait until calling C<dispatch>
again. If you feel like Gungho is running slow, try setting this parameter to
a smaller amount. 

Settings this too low will cause your crawler to be constantly looking up for
URLs to dispatch instead of fetching the URLs. Alays try to time the requests
before going to extremes with this setting.

=head2 client.spawn

C<spawn> specifies the number of POE::Component::Client::HTTP sessions to start.
This will greatly affect your fetching speed, as PoCo::Client::HTTP tends to
start jamming up after a certain number of requests have been pushed onto
its queue.

If you feel like all of your other settings are correct but the actual
HTTP fetch is taking too long, try setting this number to something higher.

By default this is set to 2. 

=head2 keepalive.keep_alive

Specifies the number of seconds to keep a connection in the Keepalive
connection manager. 

This is an important option to tweak if you're using proxies. Even though
you might be accessing thousands of different URLs, POE will think that
you are in fact trying to connect to the same host because you're
accessing the same proxy.

Turn this to 0 if you are using a proxy.

=head1 POE::Component::Client::HTTP AND DECODED CONTENTS

Since version 0.80, POE::Component::Client::HTTP silently decodes the content 
of an HTTP response. This means that, even when the HTTP header states

  Content-Type: text/html; charset=euc-jp

Your content grabbed via $response->content() will be in decode Perl unicode.
This is a side-effect from POE::Component::Client::HTTP trying to handle
Content-Encoding for us, and HTTP::Request also trying to be clever.

We have devised workarounds for this. You can either set the following
variables in your environment (before Gunghoe::Engine::POE is loaded)
to enable the workarounds:

  GUNGHO_ENGINE_POE_SKIP_DECODE_CONTENT = 1
  # or
  GUNGHO_ENGINE_POE_FORCE_ENCODE_CONTENT = 1

See L<ENVIRONMENT VARIABLES|ENVIRONMENT VARIABLES> for details

=head1 USING KEEPALIVE

Gungho::Engine::POE uses PoCo::Client::Keepalive to control the connections.
For the most part this has no visible effect on the user, but the "timeout"
parameter dictate exactly how long the component waits for a new connection
which means that, after finishing to fetch all the requests the engine
waits for that amount of time before terminating. This is NORMAL.

=head1 ENVIRONMENT VARIABLES

=head2 GUNGHO_ENGINE_POE_SKIP_DECODE_CONTENT

When set to a non-null value, this will install a new subroutine in
HTTP::Response's namespace, and will circumvent HTTP::Response to decode
its content by explicitly passing charset = 'none' to HTTP::Response's
decoded_content().

This workaround is ENABLED by default.

=head2 GUNGHO_ENGINE_POE_FORCE_ENCODE_CONTENT

When set to a non-null value, this will re-encode the content back to
what the Content-Type header specified the charset to be.

By default this option is disabled.

=head1 METHODS

=head2 setup

sets up the engine.

=head2 run

Instantiates a PoCo::Client::HTTP session and a main session that handles the
main control.

=head2 stop

Shutsdown the engine

=head2 send_request($request)

Sends a request to the http client

=head1 CAVEATS

The POE engine supports multiple values in the user-agent header, but this
is an exception that other engines don't support. Please use define your
agent strings in the top level config:

  user_agent: my_user_agent
  engine:
    module: POE
    ...

If you don't do this, components such as RobotRules won't work properly

=head1 TODO

Xango, Gungho's predecessor, tried really hard to overcome one of my pet-peeves
with PoCo::Client::HTTP -- which is that, while it can handle hundreds and
thousands of requests, all the requests are unnecessarily stored on
memory. Xango tried to solve this, but it ended up bloating the software.
We may try to tackle this later.

=cut
