#! perl

use strict;
use warnings;
use utf8;

-d 't' && chdir 't';

use Test::More tests => 3;
BEGIN { use_ok('HarfBuzz::Shaper') };

my $hb = HarfBuzz::Shaper->new;

$hb->set_font('NimbusRoman-Regular.otf');
$hb->set_size(36);
$hb->set_text("fiets");

# Ligatures are ususally enabled by default.
$hb->set_features( 'liga=0' );
my $info = $hb->shaper;
$info = $hb->get_extents;

my $result = [
  { g => 71, height => -24.588, width => 13.068, x_bearing => 0.720, y_bearing => 24.588 },
  { g => 74, height => -24.588, width =>  8.532, x_bearing => 0.576, y_bearing => 24.588 },
  { g => 70, height => -16.920, width => 14.364, x_bearing => 0.900, y_bearing => 16.560 },
  { g => 85, height => -21.204, width =>  9.576, x_bearing => 0.468, y_bearing => 20.844 },
  { g => 84, height => -16.920, width => 10.692, x_bearing => 1.836, y_bearing => 16.560 },
];

ok(compare( $info, $result ), "content no liga" );

# With ligatures.
$info = $hb->shaper( [ 'liga=1' ] );
$info = $hb->get_extents;

$result = [
  { g =>109, height => -24.588, width => 17.640, x_bearing => 1.116, y_bearing => 24.588,},
  { g => 70, height => -16.920, width => 14.364, x_bearing => 0.900, y_bearing => 16.560 },
  { g => 85, height => -21.204, width =>  9.576, x_bearing => 0.468, y_bearing => 20.844 },
  { g => 84, height => -16.920, width => 10.692, x_bearing => 1.836, y_bearing => 16.560 },
];

ok(compare( $info, $result ), "content with liga" );

sub compare {
    my ( $ist, $soll ) = @_;
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
	for ( qw( x_bearing y_bearing width height ) ) {
	    next if $i->{$_} == $j->{$_};
	    unless ( abs( $i->{$_} - $j->{$_} ) <= abs($j->{$_} / 100) ) {
		diag( "$_ $i->{$_} must be $j->{$_}" );
		return;
	    }
	}
    }
    return 1;
}
