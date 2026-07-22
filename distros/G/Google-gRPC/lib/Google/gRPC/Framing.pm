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
        status  => 0,
        message => '',
    );

    my $details_bin;

    if (ref($headers) eq 'HASH') {
        if (exists $headers->{'grpc-status'}) {
            $res{status} = int($headers->{'grpc-status'});
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
            if ($k eq 'grpc-status') {
                $res{status} = int($v);
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


=head1 NAME

Google::gRPC::Framing - gRPC Wire Framing Utilities

=head1 SYNOPSIS

    use Google::gRPC::Framing;

=head1 DESCRIPTION

This module provides grpc wire framing utilities functionality for the Google gRPC Perl client SDK.

=head1 AUTHOR

C.J. Collier E<lt>cjac@google.comE<gt>

=head1 LICENSE

Apache License 2.0

=cut

1;
