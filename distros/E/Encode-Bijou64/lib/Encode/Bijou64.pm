package Encode::Bijou64;

use strict;
use warnings;
use Exporter qw(import);

our @EXPORT  = qw( encode_bijou64 decode_bijou64);
our $VERSION = '0.01';

################################################################################
################################################################################

# tag, num_bytes, max
my @TIERS = (
	[0xF8, 1,                    248],
	[0xF9, 2,                    504],
	[0xFA, 3,                 66_040],
	[0xFB, 4,             16_843_256],
	[0xFC, 5,          4_311_810_552],
	[0xFD, 6,      1_103_823_438_328],
	[0xFE, 7,    282_578_800_148_984],
	[0xFF, 8, 72_340_172_838_076_920],
);

my %DECODE;
for my $tier (@TIERS) {
    my ($tag, $bytes, $base) = @$tier;

    $DECODE{$tag} = [$bytes, $base];
}

################################################################################

sub encode_bijou64 {
	my ($n) = @_;

	if (!defined($n)) {
		die("encode_bijou64(): undefined value");
	}

	if ($n !~ /^\d+\z/) {
		die("encode_bijou64(): positive integer required");
	}

	return pack("C", $n)
	if $n <= 0xF7;

	for my $tier (@TIERS) {
		my ($tag, $bytes, $base) = @$tier;

		my $max = $base + (1 << ($bytes * 8)) - 1;

		if ($n <= $max) {
			my $v   = $n - $base;
			my $out = pack("C", $tag);

			for (reverse 0 .. $bytes - 1) {
				$out .= pack("C", ($v >> ($_ * 8)) & 0xFF);
			}

			return $out;
		}
	}

	die "encode_bijou64(): integer too large";
}

sub decode_bijou64 {
	my ($buf) = @_;

	if (!defined($buf)) {
		die("decode_bijou64(): undefined value");
	}

	if (!length($buf)) {
		die("decode_bijou64(): empty buffer");
	}

	my $tag = ord substr($buf, 0, 1);

	# Short/simple decode
	if ($tag <= 0xF7) {
		return $tag;
	}

	my $tier = $DECODE{$tag};

	if (!$tier) {
		my $msg = sprintf("decode_bijou64(): invalid tag 0x%02X", $tag);
		die($msg);
	}

	my ($bytes, $base) = @$tier;

	if (length($buf) != 1 + $bytes) {
		die("decode_bijou64(): buffer too short");
	}

	my $v = 0;
	for my $i (0 .. $bytes - 1) {
		$v = ($v << 8) | ord(substr($buf, 1 + $i, 1));
	}

	return $base + $v;
}

1;

################################################################################
################################################################################

=encoding utf8

=head1 NAME

Encode::Bijou64 - Encode and decode Bijou64 integers

=head1 SYNOPSIS

  use Encode::Bijou64;

  my $bytes = encode_bijou64(123456);
  my $num   = decode_bijou64($bytes);

=head1 DESCRIPTION

Encode::Bijou64 implements the Bijou64 variable-length
integer encoding format described by Ink & Switch.

Small integers occupy fewer bytes while preserving
efficient decoding.

=head1 FUNCTIONS

=head2 encode_bijou64($integer)

Encodes a non-negative integer into a Bijou64 byte string.

=head2 decode_bijou64($bytes)

Decodes a Bijou64 byte string and returns the integer value.

=head1 SEE ALSO

https://www.inkandswitch.com/tangents/bijou64/

=head1 AUTHOR

Scott Baker

=head1 LICENSE

Same terms as Perl itself.

=cut

# vim: tabstop=4 shiftwidth=4 noexpandtab autoindent softtabstop=4
