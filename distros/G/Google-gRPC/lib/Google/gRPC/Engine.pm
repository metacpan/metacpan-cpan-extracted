package Google::gRPC::Engine;

use strict;
use warnings;
use Carp qw(croak);

sub create {
    my ($class, %args) = @_;
    my $preferred = delete $args{engine};

    if (defined $preferred) {
        if ($preferred eq 'NGHTTP2') {
            require Google::gRPC::Engine::NGHTTP2;
            return Google::gRPC::Engine::NGHTTP2->new(%args);
        }
        elsif ($preferred eq 'PP') {
            require Google::gRPC::Engine::PP;
            return Google::gRPC::Engine::PP->new(%args);
        }
    }

    my $eng = eval {
        require Google::gRPC::Engine::NGHTTP2;
        Google::gRPC::Engine::NGHTTP2->new(%args);
    };
    return $eng if $eng;

    require Google::gRPC::Engine::PP;
    return Google::gRPC::Engine::PP->new(%args);
}


=encoding UTF-8

=head1 NAME

Google::gRPC::Engine - HTTP/2 transport engine factory for Google::gRPC (NGHTTP2 XS with Pure-Perl fallback)

=head1 SYNOPSIS

    use Google::gRPC::Engine;

    # Auto-select NGHTTP2 (C/XS) with automatic fallback to PP (Pure-Perl)
    my $engine = Google::gRPC::Engine->create(
        on_headers      => sub { my ($sid, $headers) = @_; ... },
        on_data         => sub { my ($sid, $chunk)   = @_; ... },
        on_trailers     => sub { my ($sid, $trailers)= @_; ... },
        on_stream_close => sub { my ($sid, $code)    = @_; ... },
    );

    # Explicitly select a specific engine
    my $pp_engine = Google::gRPC::Engine->create(engine => 'PP');

=head1 DESCRIPTION

C<Google::gRPC::Engine> is the factory class used by L<Google::gRPC::Channel>
to instantiate an HTTP/2 framing/session engine. By default it attempts to load
the C/XS L<Google::gRPC::Engine::NGHTTP2> engine (backed by C<libnghttp2>) and
automatically falls back to the Pure-Perl L<Google::gRPC::Engine::PP> engine
(backed by L<Protocol::HTTP2>) if C<libnghttp2> is unavailable.

=head1 METHODS

=head2 create( %args )

    my $engine = Google::gRPC::Engine->create(
        engine          => 'NGHTTP2', # optional: 'NGHTTP2' or 'PP'
        on_headers      => \&on_headers_cb,
        on_data         => \&on_data_cb,
        on_trailers     => \&on_trailers_cb,
        on_stream_close => \&on_stream_close_cb,
    );

Instantiates and returns a transport engine object. If C<engine> is omitted,
tries C<NGHTTP2> first and falls back to C<PP>.

=head1 SEE ALSO

L<Google::gRPC>, L<Google::gRPC::Channel>, L<Google::gRPC::Engine::NGHTTP2>,
L<Google::gRPC::Engine::PP>

=head1 AUTHOR

C.J. Collier E<lt>cjac@google.comE<gt>

=head1 LICENSE

Apache License 2.0

=cut

1;
