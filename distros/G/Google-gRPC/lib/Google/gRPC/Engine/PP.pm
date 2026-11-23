package Google::gRPC::Engine::PP;

use strict;
use warnings;
use Moo;
use Protocol::HTTP2::Client;
use Carp qw(croak);

has on_headers      => ( is => 'rw' );
has on_data         => ( is => 'rw' );
has on_trailers     => ( is => 'rw' );
has on_stream_close => ( is => 'rw' );

has client => ( is => 'ro', lazy => 1, builder => '_build_client' );

sub _build_client {
    my ($self) = @_;
    return Protocol::HTTP2::Client->new(
        on_error => sub {
            my ($err) = @_;
        },
    );
}

sub is_xs {
    return 0;
}

sub send_ping {
    my ($self, $cb) = @_;
    if ($self->client->can('ping')) {
        $self->client->ping($cb);
    }
}

sub submit_request {
    my ($self, $args) = @_;
    my $headers_arr = $args->{headers} or croak 'headers is required';
    my $data        = $args->{data};
    my $end_stream  = $args->{end_stream};

    my %pseudo;
    my @normal_headers;

    for (my $i = 0; $i < @$headers_arr; $i += 2) {
        my $k = $headers_arr->[$i];
        my $v = $headers_arr->[$i + 1];
        if ($k =~ /^:(.*)$/) {
            $pseudo{':' . $1} = $v;
        }
        else {
            push @normal_headers, lc($k), $v;
        }
    }

    my $on_headers_cb  = $self->on_headers;
    my $on_data_cb     = $self->on_data;
    my $on_trailers_cb = $self->on_trailers;
    my $on_close_cb    = $self->on_stream_close;

    my $req_id;
    $req_id = $self->client->request(
        ':method'    => $pseudo{':method'} || 'POST',
        ':path'      => $pseudo{':path'} || '/',
        ':scheme'    => $pseudo{':scheme'} || 'https',
        ':authority' => $pseudo{':authority'} || 'localhost',
        headers      => \@normal_headers,
        defined($data) ? ( data => $data ) : (),
        on_headers => sub {
            my ($headers_ref) = @_;
            if ($on_headers_cb && defined $req_id) {
                $on_headers_cb->($req_id, $headers_ref);
            }
        },
        on_data => sub {
            my ($chunk) = @_;
            if ($on_data_cb && defined $req_id) {
                $on_data_cb->($req_id, $chunk);
            }
        },
        on_done => sub {
            my ($headers_ref, $body) = @_;
            if ($on_trailers_cb && $headers_ref && defined $req_id) {
                $on_trailers_cb->($req_id, $headers_ref);
            }
            if ($on_close_cb && defined $req_id) {
                $on_close_cb->($req_id, 0);
            }
        },
    );

    return $req_id;
}

sub feed_input {
    my ($self, $bytes) = @_;
    return unless defined $bytes && length($bytes);
    $self->client->feed($bytes);
}

sub get_output {
    my ($self) = @_;
    my $out = '';
    while (defined(my $frame = $self->client->next_frame)) {
        $out .= $frame;
    }
    return $out;
}


=head1 NAME

Google::gRPC::Engine::PP - Pure-Perl HTTP/2 transport engine for Google::gRPC

=head1 SYNOPSIS

    use Google::gRPC::Engine::PP;

    my $engine = Google::gRPC::Engine::PP->new(
        on_headers      => sub { my ($stream_id, $headers)  = @_; ... },
        on_data         => sub { my ($stream_id, $chunk)    = @_; ... },
        on_trailers     => sub { my ($stream_id, $trailers) = @_; ... },
        on_stream_close => sub { my ($stream_id, $code)     = @_; ... },
    );

    my $stream_id = $engine->submit_request({
        headers    => [ ':method' => 'POST', ':path' => '/pkg.Svc/Call', ... ],
        data       => $framed_bytes,
        end_stream => 1,
    });

    my $wire_out = $engine->get_output();
    $engine->feed_input($wire_in);

=head1 DESCRIPTION

C<Google::gRPC::Engine::PP> is the pure-Perl HTTP/2 transport engine for
L<Google::gRPC>, built on L<Protocol::HTTP2::Client>. It is used automatically
by L<Google::gRPC::Engine> when C<libnghttp2> C/XS bindings are unavailable
or when C<engine_type =E<gt> 'pureperl'> is requested explicitly.

=head1 ATTRIBUTES

=over 4

=item C<on_headers> / C<on_data> / C<on_trailers> / C<on_stream_close>

Optional coderef callbacks invoked for incoming HTTP/2 headers, DATA frames,
trailing headers, and stream completion events.

=item C<client> (read-only, lazy)

Underlying L<Protocol::HTTP2::Client> session instance.

=back

=head1 METHODS

=head2 is_xs()

Returns C<0>, indicating this is the pure-Perl engine.

=head2 submit_request(\%args)

    my $stream_id = $engine->submit_request({
        headers    => \@headers,
        data       => $bytes,
        end_stream => 1,
    });

Submits an HTTP/2 request using the provided flat C<headers> arrayref
(separating pseudo-headers such as C<:method>, C<:path>, C<:scheme>, and
C<:authority> from regular headers) and optional C<data> payload. Returns the
assigned stream ID.

=head2 feed_input($bytes)

    $engine->feed_input($raw_bytes);

Feeds raw bytes read from the TLS/TCP socket into the HTTP/2 state machine,
triggering registered callbacks as frames are decoded.

=head2 get_output()

    my $bytes = $engine->get_output();

Drains and returns all pending outbound HTTP/2 frames ready to be written to
the socket.

=head2 send_ping($cb)

    $engine->send_ping(sub { ... });

Queues an HTTP/2 C<PING> frame if supported by the underlying
L<Protocol::HTTP2::Client>.

=head1 SEE ALSO

L<Google::gRPC>, L<Google::gRPC::Engine>, L<Google::gRPC::Engine::NGHTTP2>

=head1 AUTHOR

C.J. Collier E<lt>cjac@google.comE<gt>

=head1 LICENSE

Apache License 2.0

=cut

1;
