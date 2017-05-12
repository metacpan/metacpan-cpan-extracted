=head1 NAME

Encode::DosHebrew - DOS Hebrew Encoding

=head1 SYNOPSIS

  use Encode;
  use Encode::DosHebrew;
  use File::BOM;

  # Hebrew word for "newspaper"
  my $dosTxt = "\x92\xA0\xFA\xED\x8F\xA7";

  open $outF, ">:utf8:via(File::BOM)", 'unicode.txt'
	  or die "can't write: $!\n";
  print $outF decode('DosHebrew', $dosTxt), "\n";
  close $outF;

=head1 ABSTRACT

This module implements a DOS 8-bit encoding of Hebrew, which includes vowels (nikud),
as well as pointed (dagesh) consonants, in addition to the standard consonants.  It
is a superset of Code page 862 (which includes only consonants).

Although data files exist that use this "DosHebrew" encoding, its origin is unclear,
and there are no known standards which describe it.

=head1 BUGS

Only the "decode" function is implemented at this time.

=head1 DESCRIPTION

To find how to use this module in detail, see Encode.

=head1 SEE ALSO

Encode

=head1 AUTHOR

Tzadik Vanderhoof, E<lt>tzadikv@cpan.orgE<gt>

=cut

package Encode::DosHebrew;
use strict;
use warnings;
use base 'Encode::Encoding';
use feature ":5.10";
use Carp;

our $VERSION = '0.5';

__PACKAGE__->Define('DosHebrew');

my %dos2uni;

sub hebChr {
	my ($c) = @_;
	
	return chr(0x0500 + $c);
}

sub initDos2Uni {
	my $data = dos2UniData();
	open my $dataF, '<', \$data or die "Can't open data";
	while (<$dataF>) {
		my @x = m|\b([0-9a-f]{2})\b|ig or next;
		my $from = chr(hex(shift @x));
		my $to = join '', map { hebChr hex $_ } @x;
		$dos2uni{$from} = $to;
	}
	close $dataF;
}

sub decode_char {
	my ($c) = @_;

	my $toC;
	
	given ($c) {
		when (m|[\s\x21-\x3F]|) {
			$toC = $c;
		}
		when (m|[\x80-\x9A]|) {
			$toC = hebChr(ord($c) + 0x50);
		}
		default {
			$toC = $dos2uni{$c};
		}
	}
	
	return $toC;
}

sub decode($$;$) {
	my ($obj, $s, $chk) = @_;
	
	return join '', map { decode_char $_ } split //, $s;
}

sub encode {
	croak "'encode' not yet implemented";
}

initDos2Uni;

sub dos2UniData {
	return <<'END_DATA';

dotted consonants:
e1 d1 bc beis
e2 d2 bc gimel dagesh
e3 d3 bc dalet dagesh
e4 d4 bc heh dagesh
e5 d5 bc vav shuruk
e6 d6 bc zayin dagesh
e7 da b0 chof sofit shva
e8 ea bc taf
e9 d9 bc yood dagesh
eb db bc cof
ec dc bc lamed dagesh
ed d5 b9 vav holam
ee de bc mem dagesh
ef dc b9 lamed holam
f0 e0 bc nun dagesh
f1 e1 bc samech dagesh
f2 da b8 chof sofit kametz
f4 e4 bc peh
f5 e9 c1 shin
f6 e6 bc tzadi dagesh
f7 e7 bc koof dagesh
f8 e9 c1 bc shin dagesh
f9 e9 c2 bc sin dagesh
fa ea bc tof
fb e9 c2 sin
fc d6 b9 zayin holom
ff unknown (ignore)

vowels:
9b b1 segel shva
9c b3 qamats shva
9d b2 patach shva
9e b6 segel
9f b5 tzare
a0 b4 chirik
a1 b0 shva
a2 b8 kometz
a3 b7 patach
a4 bb kubutz
a5 b9 holam
a7 bottom of nun sofit (ignore)

END_DATA

}

1;