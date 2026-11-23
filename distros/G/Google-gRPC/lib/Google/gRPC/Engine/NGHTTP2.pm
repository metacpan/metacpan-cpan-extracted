package Google::gRPC::Engine::NGHTTP2;

use strict;
use warnings;
use Carp qw(croak);
use XSLoader;

our $VERSION = '0.09';

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

Google::gRPC::Engine::NGHTTP2 - C/XS nghttp2 HTTP/2 transport engine for Google::gRPC

=head1 SYNOPSIS

    use Google::gRPC::Engine::NGHTTP2;

    my $engine = Google::gRPC::Engine::NGHTTP2->new(
        on_headers      => sub { my ($stream_id, $headers) = @_; ... },
        on_data         => sub { my ($stream_id, $chunk)   = @_; ... },
        on_trailers     => sub { my ($stream_id, $trailers) = @_; ... },
        on_stream_close => sub { my ($stream_id, $code)    = @_; ... },
    );

    my $stream_id = $engine->submit_request({
        headers    => [ ':method' => 'POST', ':path' => '/pkg.Svc/Call', ... ],
        data       => $framed_bytes,
        end_stream => 1,
    });

=head1 DESCRIPTION

C<Google::gRPC::Engine::NGHTTP2> is the high-performance C/XS HTTP/2 framing
engine for L<Google::gRPC>, backed by C<libnghttp2>. It is selected
automatically by L<Google::gRPC::Engine> when compiled XS bindings are
available on the host system, falling back to L<Google::gRPC::Engine::PP>
otherwise.

=head1 METHODS

=head2 new(%callbacks)

    my $engine = Google::gRPC::Engine::NGHTTP2->new(
        on_headers      => \&on_headers,
        on_data         => \&on_data,
        on_trailers     => \&on_trailers,
        on_stream_close => \&on_stream_close,
    );

Creates a new C<nghttp2> client session and registers the HTTP/2 frame
callbacks. Croaks if the C/XS C<nghttp2> bindings were not compiled.

=head2 set_callbacks(%callbacks)

    $engine->set_callbacks(
        on_headers      => \&on_headers,
        on_data         => \&on_data,
        on_trailers     => \&on_trailers,
        on_stream_close => \&on_stream_close,
    );

Replaces the registered HTTP/2 event callbacks on an existing session.

=head2 submit_request(\%args)

    my $stream_id = $engine->submit_request({
        headers    => \@headers,
        data       => $bytes,
        end_stream => 1,
    });

Submits an HTTP/2 request with the given flat header arrayref (required),
optional framed request body C<data>, and boolean C<end_stream> flag. Returns
the assigned HTTP/2 stream ID.

=head2 send_ping($cb)

    $engine->send_ping(sub { ... });

Queues an HTTP/2 C<PING> frame on the connection for keepalive probing.

=head1 SEE ALSO

L<Google::gRPC>, L<Google::gRPC::Engine>, L<Google::gRPC::Engine::PP>

=head1 AUTHOR

C.J. Collier E<lt>cjac@google.comE<gt>

=head1 LICENSE

Apache License 2.0

=cut

1;
