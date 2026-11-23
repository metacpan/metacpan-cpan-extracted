package Google::gRPC::Framing;

use strict;
use warnings;
use Carp qw(croak);
use Google::gRPC::Status;

sub pack_frame {
    my ($payload, %opts) = @_;
    $payload = '' unless defined $payload;
    my $compressed = $opts{compressed} ? 1 : 0;
    return pack('C N', $compressed, length($payload)) . $payload;
}

sub unpack_frame {
    my ($data_ref) = @_;
    return unless defined $$data_ref;

    my @frames;
    while (length($$data_ref) >= 5) {
        my ($compressed, $len) = unpack('C N', substr($$data_ref, 0, 5));
        if (length($$data_ref) < 5 + $len) {
            last;
        }
        substr($$data_ref, 0, 5, '');
        my $payload = substr($$data_ref, 0, $len, '');
        push @frames, {
            compressed => $compressed,
            payload    => $payload,
        };
    }
    return @frames;
}

sub parse_trailers {
    my ($headers) = @_;
    my %res = (
        status     => 0,
        has_status => 0,
        message    => '',
    );

    my $details_bin;

    if (ref($headers) eq 'HASH') {
        if (exists $headers->{'grpc-status'} && defined $headers->{'grpc-status'} && $headers->{'grpc-status'} =~ /\A-?\d+\z/) {
            $res{status}     = int($headers->{'grpc-status'});
            $res{has_status} = 1;
        }
        if (exists $headers->{'grpc-message'}) {
            $res{message} = $headers->{'grpc-message'};
        }
        if (exists $headers->{'grpc-status-details-bin'}) {
            $details_bin = $headers->{'grpc-status-details-bin'};
        }
    }
    elsif (ref($headers) eq 'ARRAY') {
        for (my $i = 0; $i < @$headers; $i += 2) {
            my $k = lc($headers->[$i]);
            my $v = $headers->[$i + 1];
            if ($k eq 'grpc-status' && defined $v && $v =~ /\A-?\d+\z/) {
                $res{status}     = int($v);
                $res{has_status} = 1;
            }
            elsif ($k eq 'grpc-message') {
                $res{message} = $v;
            }
            elsif ($k eq 'grpc-status-details-bin') {
                $details_bin = $v;
            }
        }
    }

    if (defined $details_bin) {
        my $status_obj = Google::gRPC::Status->from_trailer($details_bin);
        if ($status_obj) {
            $res{status_details} = $status_obj;
        }
    }

    return \%res;
}


=encoding UTF-8

=head1 NAME

Google::gRPC::Framing - gRPC 5-byte length-prefixed wire framing and trailer parsing

=head1 SYNOPSIS

    use Google::gRPC::Framing;

    # Pack a serialized Protobuf payload into a gRPC frame
    my $frame = Google::gRPC::Framing::pack_frame($proto_bytes);

    # Unpack complete frames from a streaming byte buffer (mutates $buf)
    my @frames = Google::gRPC::Framing::unpack_frame(\$buf);
    for my $f (@frames) {
        my $payload = $f->{payload};
    }

    # Parse gRPC HTTP/2 trailers
    my $trailers = Google::gRPC::Framing::parse_trailers(\%response_headers);
    if ($trailers->{has_status} && $trailers->{status} != 0) {
        die "gRPC error $trailers->{status}: $trailers->{message}";
    }

=head1 DESCRIPTION

C<Google::gRPC::Framing> implements the gRPC-over-HTTP/2 wire framing format
(1-byte compression flag + 4-byte big-endian message length + payload) and
parses C<grpc-status>, C<grpc-message>, and C<grpc-status-details-bin>
trailers.

=head1 FUNCTIONS

=head2 pack_frame( $payload, %opts )

Packs C<$payload> with a 5-byte gRPC header (C<compressed => 1> optional).

=head2 unpack_frame( \$buffer )

Consumes all complete gRPC frames from C<$$buffer> in place and returns a list
of C<{ compressed => $flag, payload => $bytes }> HashRefs. Partial trailing
bytes remain in C<$$buffer>.

=head2 parse_trailers( $headers )

Accepts either a HashRef or flat key/value ArrayRef of HTTP/2 headers/trailers
and returns C<{ status => $int, has_status => $bool, message => $str, status_details => $obj }>.

=head1 SEE ALSO

L<Google::gRPC>, L<Google::gRPC::Status>, L<Google::gRPC::Client>,
L<Google::gRPC::Stream>

=head1 AUTHOR

C.J. Collier E<lt>cjac@google.comE<gt>

=head1 LICENSE

Apache License 2.0

=cut

1;
