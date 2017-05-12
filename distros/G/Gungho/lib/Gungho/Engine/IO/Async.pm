# $Id: /mirror/gungho/lib/Gungho/Engine/IO/Async.pm 9352 2007-11-21T02:13:31.513580Z lestrrat  $
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package Gungho::Engine::IO::Async;
use strict;
use warnings;
use base qw(Gungho::Engine);
use HTTP::Parser;
use IO::Async::Buffer;
use IO::Async::Notifier;
use IO::Socket::INET;
use Net::DNS;

__PACKAGE__->mk_classdata($_) for qw(impl_class);
__PACKAGE__->mk_accessors($_) for qw(context impl loop_delay resolver);

# probe for available impl_class
use constant HAVE_IO_POLL => (eval { use IO::Poll } && !$@);

sub setup
{
    my ($self, $c) = @_;

    $self->context($c);
    $self->setup_impl_class($c);

    $self->loop_delay( $self->config->{loop_delay} ) if $self->config->{loop_delay};
    if (! $self->config->{dns}{disable}) {
        $self->resolver(Net::DNS::Resolver->new);
    }
}

sub setup_impl_class
{
    my ($self, $c) = @_;

    my $loop = $self->config->{loop};
    if (! $loop) {
        $loop = HAVE_IO_POLL ?
            'IO_Poll' :
            'Select'
        ;
    }
    my $pkg = $c->load_gungho_module($loop, 'Engine::IO::Async::Impl');
    $self->impl_class($pkg);

    my $obj = $pkg->new();
    $obj->setup($c);
    $self->impl( $obj );
}

sub run
{
    my ($self, $c) = @_;
    $self->impl->run($c);
}

sub send_request
{
    my ($self, $c, $request) = @_;

    if ($self->resolver && $request->requires_name_lookup) {
        $self->lookup_host($c, $request);
    } else {
        $request->uri->host( $request->notes('resolved_ip') )
            if $request->notes('resolved_ip');
        if ( ! $c->request_is_allowed($request)) {
            return;
        }
        $self->start_request($c, $request);
    }
    return 1;
}

sub handle_response
{
    my ($self, $c, $req, $res) = @_;
    if (my $host = $req->notes('original_host')) {
        # Put it back
        $req->uri->host($host);
    }
    $c->handle_response($req, $c->prepare_response($res) );
}

sub lookup_host
{
    my ($self, $c, $request) = @_;

    my $resolver = $self->resolver;
    my $bgsock   = $resolver->bgsend($request->uri->host);
    my $notifier = IO::Async::Notifier->new(
        handle => $bgsock,
        on_read_ready => sub {
            $self->impl->remove($_[0]);
            $self->handle_dns_response(
                $c,
                $request,
                $resolver->bgread($bgsock), 
            );
        }
    );
    $self->impl->add($notifier);
}

sub start_request
{
    my ($self, $c, $req) = @_;
    my $uri  = $req->uri;
    my $socket = IO::Socket::INET->new(
        PeerAddr => $uri->host,
        PeerPort => $uri->port || $uri->default_port,
        Blocking => 0,
    );
    if ($@) {
        $self->handle_response(
            $c,
            $req,
            $c->_http_error(500, "Failed to connect to " . $uri->host . ": $@
", $req)
        );
        return;
    }

    my $buffer = IO::Async::Buffer->new(
        handle => $socket,
        on_incoming_data => sub {
            my ($notifier, $buffref, $closed) = @_;

            my $parser = $notifier->{parser};
            my $st = $parser->add($$buffref);
            $$buffref = '';

            if ($st == 0) {
                my $res = $parser->object;
                $c->notify('engine.handle_response', { request => $req, response => $res });
                $self->handle_response($c, $notifier->{request}, $res);
                $notifier->handle_closed();
                $self->impl->remove($notifier);
            }
        },
        on_read_error => sub {
            my $notifier = shift;
            my $res = $c->_http_error(400, "incomplete response", $notifier->{request});
            $c->handle_response($c, $notifier->{request}, $res);
        },
        on_write_error => sub {
            my $notifier = shift;
            my $res = $c->_http_error(500, "Could not write to socket ", $notifier->{request});
            $c->notify('engine.handle_response', { request => $req, response => $res });
            $self->handle_response($c, $notifier->{request}, $res);
        }
    );

    # Not a good thing, I know...
    $buffer->{parser}  = HTTP::Parser->new(response => 1);
    $buffer->{request} = $req;

    $c->notify('engine.send_request', { request => $req });
    $buffer->send($req->format);
    $self->impl->add($buffer);
}

package Gungho::Engine::IO::Async::Impl::Select;
use strict;
use warnings;
use base qw(IO::Async::Set::Select Class::Accessor::Fast);

__PACKAGE__->mk_accessors($_) for qw(context);

sub setup
{
}

sub run
{
    my ($self, $c) = @_;
    $self->context($c);

    my $engine = $c->engine;
    my ($rvec, $wvec, $evec);
    my $timeout;
    while ($c->is_running || keys %{$self->{notifiers}}) {
        $c->dispatch_requests();

        $timeout = $engine->loop_delay;
        if (! defined $timeout || $timeout <= 0) {
            $timeout = 5;
        }
        ($rvec, $wvec, $evec) = ('' x 3);

        $self->pre_select(\$rvec, \$wvec, \$evec, \$timeout);
        select($rvec, $wvec, $evec, $timeout);
        $self->post_select($rvec, $wvec, $evec);
    }
}

1;

__END__

=head1 NAME

Gungho::Engine::IO::Async - IO::Async Engine

=head1 SYNOPSIS

  engine:
    module: IO::Async
    config:
        loop_delay: 0.01
        dns:
            disable: 1 # Only if you don't want Gungho to resolve DNS


=head1 DESCRIPTION

This class uses IO::Async to dispatch requests.

WARNING: This engine is still experimental. Patches welcome!
In particular, this class definitely should cache connections.

=head1 METHODS

=head2 run

=head2 setup

=head2 setup_impl_class

=head2 send_request

=head2 handle_response

=head2 start_request

=head2 lookup_host

=cut
