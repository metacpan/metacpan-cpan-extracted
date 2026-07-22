package Google::gRPC::Status;

use strict;
use warnings;
use Moo;
use MIME::Base64 qw(decode_base64);

has code    => ( is => 'ro', default => sub { 0 } );
has message => ( is => 'ro', default => sub { '' } );
has details => ( is => 'ro', default => sub { [] } );

sub parse_status_details {
    my ($class_or_self, $raw) = @_;
    return undef unless defined $raw && length($raw);

    my $bytes = $raw;
    if ($raw =~ /^[A-Za-z0-9+\/=\s_-]+$/ && $raw !~ /^[\x00-\x08\x0b-\x1f]/) {
        my $decoded = eval { decode_base64($raw) };
        $bytes = $decoded if defined $decoded && length($decoded);
    }

    # Manual binary wire decoder for google.rpc.Status (tag 1: code, tag 2: message, tag 3: details)
    my $pos = 0;
    my $len = length($bytes);
    my $code = 0;
    my $message = '';
    my @details;

    eval {
        while ($pos < $len) {
            my $tag = ord(substr($bytes, $pos++, 1));
            my $field_number = $tag >> 3;
            my $wire_type    = $tag & 0x07;

            if ($field_number == 1 && $wire_type == 0) { # varint code
                my $val = 0;
                my $shift = 0;
                while ($pos < $len) {
                    my $b = ord(substr($bytes, $pos++, 1));
                    $val |= ($b & 0x7f) << $shift;
                    last unless $b & 0x80;
                    $shift += 7;
                }
                $code = $val;
            }
            elsif ($field_number == 2 && $wire_type == 2) { # string message
                my $vlen = 0;
                my $shift = 0;
                while ($pos < $len) {
                    my $b = ord(substr($bytes, $pos++, 1));
                    $vlen |= ($b & 0x7f) << $shift;
                    last unless $b & 0x80;
                    $shift += 7;
                }
                $message = substr($bytes, $pos, $vlen);
                $pos += $vlen;
            }
            elsif ($field_number == 3 && $wire_type == 2) { # Any details
                my $vlen = 0;
                my $shift = 0;
                while ($pos < $len) {
                    my $b = ord(substr($bytes, $pos++, 1));
                    $vlen |= ($b & 0x7f) << $shift;
                    last unless $b & 0x80;
                    $shift += 7;
                }
                my $any_bytes = substr($bytes, $pos, $vlen);
                $pos += $vlen;

                # Parse Any submessage (tag 1: type_url, tag 2: value)
                my $apos = 0;
                my $alen = length($any_bytes);
                my $type_url = '';
                my $value = '';
                while ($apos < $alen) {
                    my $atag = ord(substr($any_bytes, $apos++, 1));
                    my $afnum = $atag >> 3;
                    my $awire = $atag & 0x07;
                    if ($afnum == 1 && $awire == 2) {
                        my $l = ord(substr($any_bytes, $apos++, 1));
                        $type_url = substr($any_bytes, $apos, $l);
                        $apos += $l;
                    }
                    elsif ($afnum == 2 && $awire == 2) {
                        my $l = ord(substr($any_bytes, $apos++, 1));
                        $value = substr($any_bytes, $apos, $l);
                        $apos += $l;
                    }
                    else {
                        last;
                    }
                }
                push @details, { type_url => $type_url, value => $value };
            }
            else {
                last;
            }
        }
    };

    return Google::gRPC::Status->new(
        code    => $code,
        message => $message,
        details => \@details,
    );
}

sub from_trailer {
    my ($class, $raw) = @_;
    return $class->parse_status_details($raw);
}


=head1 NAME

Google::gRPC::Status - gRPC Status Codes and Details

=head1 SYNOPSIS

    use Google::gRPC::Status;

=head1 DESCRIPTION

This module provides grpc status codes and details functionality for the Google gRPC Perl client SDK.

=head1 AUTHOR

C.J. Collier E<lt>cjac@google.comE<gt>

=head1 LICENSE

Apache License 2.0

=cut

1;
