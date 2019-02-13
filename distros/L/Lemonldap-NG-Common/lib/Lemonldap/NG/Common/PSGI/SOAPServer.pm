# Extend SOAP::Transport::HTTP::Server to be able to handle PSGI requests

package Lemonldap::NG::Common::PSGI::SOAPServer;

use bytes;
use strict;
use SOAP::Transport::HTTP;

our @ISA = ('SOAP::Transport::HTTP::Server');

our $VERSION = '2.0.0';

# Call SOAP::Trace::objects().
sub DESTROY { SOAP::Trace::objects('()') }

sub new {
    my $self = shift;
    return $self if ref $self;

    my $class = ref($self) || $self;
    $self = $class->SUPER::new(@_);
    SOAP::Trace::objects('()');

    return $self;
}

# Build SOAP request using $req->content and call
# SOAP::Transport::HTTP::Server::handle(), then return the result to the client.
sub handle {
    my $self = shift->new;
    my $req  = shift;

    unless ( $req->content_length ) {
        return [ 411, [], [] ];
    }
    $self->request(
        HTTP::Request->new(
            $req->method, $req->uri, $req->headers,
            do { $req->content }
        )
    );
    $self->SUPER::handle();
    my @headers;
    $self->response->headers->scan( sub { push @headers, @_ } );
    return [ $self->response->code, \@headers, [ $self->response->content ] ];
}

1;
