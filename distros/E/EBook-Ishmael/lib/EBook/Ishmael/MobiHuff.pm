package EBook::Ishmael::MobiHuff;
use 5.016;
our $VERSION = '1.03';
use strict;
use warnings;

use List::Util qw(max min);

our $UNPACK_Q = !!eval { pack "Q>", 1 };

# Many thanks to Calibre, much of the code in this module was based on their
# huffman decoder.

my $HUFF_HDR = pack "A4 N", 'HUFF', 24;
my $CDIC_HDR = pack "A4 N", 'CDIC', 16;

sub _load_huff {

	my $self = shift;
	my $huff = shift;

	unless (substr($huff, 0, 8) eq $HUFF_HDR) {
		die "Invalid MOBI HUFF header\n";
	}

	my @off = unpack "N N", substr $huff, 8, 8;

	@{ $self->{dict1} } = map {

		my $len  = $_ & 0x1f;
		my $term = $_ & 0x80;
		my $max  = $_ >> 8;

		if ($len == 0) {
			die "Invalid MOBI HUFF dictionary\n";
		}

		if ($len <= 8 and !$term) {
			die "Invalid MOBI HUFF dictionary\n";
		}

		$max = (($max + 1) << (32 - $len)) - 1;

		[ $len, $term, $max ];

	} unpack "N256", substr $huff, $off[0], 4 * 256;

	my @dict2 = unpack "N64", substr $huff, $off[1], 4 * 64;

	my @mins = (0, map { $dict2[$_] } grep { $_ % 2 == 0 } (0 .. $#dict2));
	my @maxs = (0, map { $dict2[$_] } grep { $_ % 2 != 0 } (0 .. $#dict2));

	$self->{mincode} = [ map { $mins[$_] << (32 - $_) } (0 .. $#mins) ];
	$self->{maxcode} = [ map { (($maxs[$_] + 1) << (32 - $_)) - 1 } (0 .. $#maxs) ];

	return 1;

}

sub _load_cdic {

	my $self = shift;
	my $cdic = shift;

	unless (substr($cdic, 0, 8) eq $CDIC_HDR) {
		die "Invalid MOBI CDIC header\n";
	}

	my ($phrases, $bits) = unpack "N N", substr $cdic, 8, 8;

	my $n = min(1 << $bits, $phrases - @{ $self->{dictionary} });

	push @{ $self->{dictionary} }, map {

		my $blen = unpack "n", substr $cdic, 16 + $_;

		[
			substr($cdic, 18 + $_, $blen & 0x7fff),
			$blen & 0x8000,
		];

	} unpack "n$n", substr $cdic, 16;

	return 1;

}

sub new {

	my $class = shift;
	my $huff  = shift;
	my @cdic  = @_;

	my $self = {
		dict1 => [],
		dictionary => [],
		mincode => [],
		maxcode => [],
	};

	bless $self, $class;

	$self->_load_huff($huff);

	for my $c (@cdic) {
		$self->_load_cdic($c);
	}

	return $self;

}

sub decode {

	my $self = shift;
	my $data = shift;

	my $left = length($data) * 8;
	$data .= "\x00" x 8;
	my $pos = 0;
	my $x = unpack "Q>", $data;
	my $n = 32;

	my $s = '';

	while (1) {

		if ($n <= 0) {
			$pos += 4;
			$x = unpack "Q>", substr $data, $pos, 8;
			$n += 32;
		}
		my $code = ($x >> $n) & ((1 << 32) - 1);

		my ($len, $term, $max) = @{ $self->{dict1}[$code >> 24] };
		unless ($term) {
			$len += 1 while $code < $self->{mincode}[$len];
			$max = $self->{maxcode}[$len];
		}

		$n    -= $len;
		$left -= $len;
		last if $left < 0;

		my $r = ($max - $code) >> (32 - $len);

		my ($slice, $flag) = @{ $self->{dictionary}[$r] };

		unless ($flag) {
			$self->{dictionary}[$r] = [];
			$slice = $self->decode($slice);
			$self->{dictionary}[$r] = [ $slice, 1 ];
		}

		$s .= $slice;

	}

	return $s;

}

1;

=head1 NAME

EBook::Ishmael::MobiHuff - Huff/CDIC decoder for MOBI/AZW

=head1 SYNOPSIS

  use EBook::Ishmael::MobiHuff;

  my $mh = EBook::Ishmael::MobiHuff->new($huff, @cdics);
  my $decode = $mh->decode($data);

=head1 DESCRIPTION

B<EBook::Ishmael::MobiHuff> is a module that provides an object-oriented
interface for decoding Huff/CDIC-encoded data found in MOBI/AZW ebooks. This is
developer documentation, please consult the L<ishmael> manual for user
documentation.

=head1 METHODS

=over 4

=item $mh = EBook::Ishmael::MobiHuff->new($huff, @cdics)

Returns a blessed C<EBook::Ishmael::MobiHuff> object and reads Huff/CDIC data
from C<$huff> and C<@cdics>. C<$huff> is the record data for the C<HUFF> record,
C<@cdics> is an array of record data for eacah C<CDIC> record.

=item $data = $mh->decode($encode)

Returns the decoded C<$data> from C<$encode>.

=back

=head1 AUTHOR

Written by Samuel Young, E<lt>samyoung12788@gmail.comE<gt>.

This project's source can be found on its
L<Codeberg Page|https://codeberg.org/1-1sam/ishmael>. Comments and pull
requests are welcome!

=head1 COPYRIGHT

Copyright (C) 2025 Samuel Young

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

=cut
