#! perl

use strict;
use warnings;
use utf8;

-d 't' && chdir 't';

use Test::More tests => 2;
BEGIN { use_ok('HarfBuzz::Shaper') };

my $hb = HarfBuzz::Shaper->new;

$hb->set_font('NimbusRoman-Regular.otf');
$hb->set_size(36);
$hb->set_text("Hell€!");
my $info = $hb->shaper;
# use DDumper; DDumper($info);
# It's a pity this font does not have glyph names.
my $result = [
  {
    ax => '25.992',
    ay => 0,
    dx => 0,
    dy => 0,
    g => 41,
    name => '',
  },
  {
    ax => '15.192',
    ay => 0,
    dx => 0,
    dy => 0,
    g => 70,
    name => '',
  },
  {
    ax => '10.008',
    ay => 0,
    dx => 0,
    dy => 0,
    g => 77,
    name => '',
  },
  {
    ax => '10.008',
    ay => 0,
    dx => 0,
    dy => 0,
    g => 77,
    name => '',
  },
  {
    ax => 18,
    ay => 0,
    dx => 0,
    dy => 0,
    g => 347,
    name => '',
  },
  {
    ax => '11.988',
    ay => 0,
    dx => 0,
    dy => 0,
    g => 2,
    name => '',
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
