package JSON::RPC2::AnyEvent::Server::Handle;
use 5.010;
use strict;
use warnings;

our $VERSION = "0.02";

use AnyEvent::Handle;
use Carp qw(croak);
use Errno ();
use JSON;
use Scalar::Util qw(blessed reftype openhandle);

use JSON::RPC2::AnyEvent::Server;
use JSON::RPC2::AnyEvent::Constants qw(ERR_PARSE_ERROR);


sub new {
    my ($class, $srv, $hdl) = @_;
    
    croak "Not an JSON::RPC2::AnyEvent::Server object: $srv"  unless blessed $srv && $srv->isa('JSON::RPC2::AnyEvent::Server');
    
    unless ( blessed $hdl && $hdl->isa('AnyEvent::Handle') ) {
        $hdl = openhandle $hdl  or croak "Neither AnyEvent::Handle nor open filehandle: $hdl";
        $hdl = AnyEvent::Handle->new(fh => $hdl);
    }
    
    my $self = bless {
        hdl => $hdl,
        srv => $srv,
    }, $class;
    
    $hdl->on_read(sub{
        shift->push_read(json => sub{
            my ($h, $json) = @_;
            $self->{srv}->dispatch($json)->cb(sub{
                my $res = shift->recv;
                $h->push_write(json => $res)  if defined $res;
            });
        });
    });
    
    $hdl->on_eof(sub{
        my $on_end = $self->{on_end};
        $self->destroy;
        $on_end->($self)  if $on_end;
    });
    
    $hdl->on_error(sub{
        my ($h, $fatal, $msg) = @_;
        if ( $! == Errno::EBADMSG ) {  # JSON Parse error
            my $res = JSON::RPC2::AnyEvent::_make_error_response(undef, ERR_PARSE_ERROR, 'Parse error');
            $h->push_write(json => $res);
        } elsif ( $self->{on_error} ){
            $self->{on_error}->($self, $fatal, $msg);
            $self->destroy if $fatal;
        } else {
            $self->destroy if $fatal;
            croak "JSON::RPC2::AnyEvent::Handle uncaught error: $msg";
        }
    });
    
    $self;
}


sub JSON::RPC2::AnyEvent::Server::dispatch_fh{
    my ($self, $fh) = @_;
    __PACKAGE__->new($self, $fh);
}


# Create on_xxx methods
for my $name ( qw/ on_end on_error / ) {
    no strict 'refs';
    *$name = sub {
        my ($self, $code) = @_;
        reftype $code eq 'CODE'  or croak "coderef must be specified";
        $self->{$name} = $code;
    };
}


# This DESTROY-pattern originates from AnyEvent::Handle code.
sub DESTROY {
    my ($self) = @_;
    $self->{hdl}->destroy;
}

sub destroy {
    my ($self) = @_;
    $self->DESTROY;
    %$self = ();
    bless $self, "JSON::RPC2::AnyEvent::Server::Handle::destroyed";
}

sub JSON::RPC2::AnyEvent::Server::Handle::destroyed::AUTOLOAD {
   #nop
}


1;
__END__

=encoding utf-8

=head1 NAME

JSON::RPC2::AnyEvent::Server::Handle - dispatch JSON-RPC requests comming from file-handle to JSON::RPC2::AnyEvent::Server

=head1 SYNOPSIS

    use AnyEvent::Socket;
    use JSON::RPC2::AnyEvent::Server::Handle;  # Add `dispatch_fh' method in JSON::RPC2::AnyEvent::Server
    
    my $srv = JSON::RPC2::AnyEvent::Server->(
        echo => sub{
            my ($cv, $args) = @_;
            $cv->send($args);
        }
    );
    
    my $w = tcp_server undef, 8080, sub {
        my ($fh, $host, $port) = @_;
        my $hdl = $srv->dispatch_fh($fh);  # equivalent to JSON::RPC2::AnyEvent::Server::Handle->new($srv, $fh)
        $hdl->on_end(sub{
            my $h = shift;  # JSON::RPC2::AnyEvent::Server::Handle
            # underlying fh is already closed here
            $h->destroy;
            undef $hdl;
        });
        $hdl->on_error(sub{
            my ($h, $fatal, $message) = @_;
            warn $message;
            $h->destroy  if $fatal;
            undef $hdl;
        });
    };

=head1 DESCRIPTION

JSON::RPC2::AnyEvent::Server::Handle is AnyEvent::Handle adapter for JSON::RPC2::AnyEvent::Server.


=head1 INTERFACE

=head2 C<CLASS-E<gt>new($srv, $fh)> -> C<$handle>

=head2 C<$srv-E<gt>dispatch_fh($fh)> -> C<$handle>

Connect C<$fh> to C<$srv> and returns a JSON::RPC2::AnyEvent::Handle object.
The object dispatches coming requests to C<$srv> and sends back returned response to C<$fh>.

This module adds C<dispatch_fh> method in JSON::RPC2::AnyEvent::Server, which can be used as a shortcut of C<new>.

=over

=item C<$srv>: JSON::RPC2::AnyEvent::Server

JSON::RPC2::AnyEvent::Server object to connect.

=item C<$fh>: AnyEvent::Handle or file-handle

File handle to be connected.

=item C<$handle>: JSON::RPC2::AnyEvent::Server::Handle

New JSON::RPC2::AnyEvent::Server::Handle object.

=back

=head2 C<$self-E<gt>on_end(sub{ my($self) = @_; ... })>

Registers callback called when the underlying file handle successfully reaches EOF.

=head2 C<$self-E<gt>on_error(sub{ my($self, $fatal, $message) = @_; ... })>

Registers callback called when an error occurs during comminication.

=head2 C<$self-E<gt>destroy>

Manually destroys this object.


=head1 LICENSE

Copyright (C) Daisuke (yet another) Maki.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Daisuke (yet another) Maki E<lt>maki.daisuke@gmail.comE<gt>

=cut
