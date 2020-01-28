#! perl

use strict;
use warnings;
use utf8;
use charnames ':full';

-d 't' && chdir 't';

use Test::More tests => 2;
BEGIN { use_ok('HarfBuzz::Shaper') };

my $hb = HarfBuzz::Shaper->new;

$hb->set_font('Lohit-Devanagari.ttf');
$hb->set_size(36);
$hb->set_text(
  "\N{DEVANAGARI LETTER TA}".
  "\N{DEVANAGARI LETTER MA}".
  "\N{DEVANAGARI VOWEL SIGN AA}".
  "\N{DEVANAGARI LETTER NGA}".
  "\N{DEVANAGARI SIGN VIRAMA}".
  "\N{DEVANAGARI LETTER GA}"
);
my $info = $hb->shaper;
#use DDumper; DDumper($info);
my $result = [
  {
#    ax => '21.384',		# harfbuzz 1.8.7
    ax => '21.348',		# harfbuzz 2.6.4
    ay => 0,
    dx => 0,
    dy => 0,
    g => 341,
    name => 'tadeva',
  },
  {
    ax => '20.34',
    ay => 0,
    dx => 0,
    dy => 0,
    g => 351,
    name => 'madeva',
  },
  {
#    ax => '9.36',		# harfbuzz 1.8.7
    ax => '9.324',		# harfbuzz 2.6.4
    ay => 0,
    dx => 0,
    dy => 0,
    g => 367,
    name => 'aasigndeva',
  },
  {
    ax => '23.904',
    ay => 0,
    dx => 0,
    dy => 0,
    g => 611,
    name => 'ngadeva_viramadeva_gadeva',
  },
];

ok(compare( $info, $result ), "content" );

sub compare {
    my ( $soll, $ist ) = @_;
    unless ( @$ist == @$soll ) {
	diag( scalar(@$ist) . " elements, must be " . scalar(@$soll) );
	return;
    }

    for ( 0 .. @$ist-1 ) {
	my $i = $ist->[$_];
	my $j = $soll->[$_];
	unless ( $i->{g} == $j->{g} ) {
	    diag( "CId $i->{g} must be $j->{g}" );
	    return;
	}
	unless ( $i->{name} eq $j->{name} ) {
	    diag( "Name $i->{name} must be $j->{name}" );
	    return;
	}
	for ( qw( ax ay dx dy ) ) {
	    next if $i->{$_} == $j->{$_};
	    unless ( abs( $i->{$_} - $j->{$_} ) <= abs($j->{$_} / 100) ) {
		diag( "$_ $i->{$_} must be $j->{$_}" );
		return;
	    }
	}
    }
    return 1;
}
