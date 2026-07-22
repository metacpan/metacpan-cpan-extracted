package Google::gRPC::Engine::NGHTTP2;

use strict;
use warnings;
use Carp qw(croak);
use XSLoader;

our $VERSION = '0.03';

eval {
    XSLoader::load('Google::gRPC', $VERSION);
    1;
} or eval {
    XSLoader::load('Google::gRPC::Engine::NGHTTP2', $VERSION);
    1;
};

sub new {
    my ($class, %args) = @_;
    croak 'C/XS engine (nghttp2) is not available on this system' unless defined &_xs_new;
    my $self = _xs_new($class);

    my $on_headers = $args{on_headers};
    my $on_data    = $args{on_data};
    my $on_trailers = $args{on_trailers};
    my $on_close   = $args{on_stream_close};

    _xs_set_callbacks($self, $on_headers, $on_data, $on_trailers, $on_close);
    return $self;
}

sub set_callbacks {
    my ($self, %args) = @_;
    _xs_set_callbacks($self, $args{on_headers}, $args{on_data}, $args{on_trailers}, $args{on_stream_close});
}

sub send_ping {
    my ($self, $cb) = @_;
    if ($self->can('_xs_send_ping')) {
        $self->_xs_send_ping();
    }
    elsif ($cb) {
        $cb->();
    }
}

sub submit_request {
    my ($self, $args) = @_;
    my $headers    = $args->{headers} or croak 'headers is required';
    my $data       = $args->{data};
    my $end_stream = $args->{end_stream} ? 1 : 0;

    return _xs_submit_request($self, $headers, $data, $end_stream);
}


=head1 NAME

Google::gRPC::Engine::NGHTTP2 - gRPC C/XS nghttp2 Transport Engine

=head1 SYNOPSIS

    use Google::gRPC::Engine::NGHTTP2;

=head1 DESCRIPTION

This module provides grpc c/xs nghttp2 transport engine functionality for the Google gRPC Perl client SDK.

=head1 AUTHOR

C.J. Collier E<lt>cjac@google.comE<gt>

=head1 LICENSE

Apache License 2.0

=cut

1;
