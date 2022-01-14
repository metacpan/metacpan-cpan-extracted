#! perl

use strict;
use warnings;
use utf8;

-d 't' && chdir 't';

use Test::More tests => 7;
BEGIN { use_ok('HarfBuzz::Shaper') };

my $hb = HarfBuzz::Shaper->new;

$hb->set_font('NimbusRoman-Regular.otf');
$hb->set_size(36);
$hb->set_text("fiets");

my $e = $hb->get_font_extents;
ok( $e, "have font extents" );
my $result =
  { ascender => '24.588', descender => '-11.412', line_gap => '7.2' };
is_deeply( $e, $result, "font ltr extents" );
$e = $hb->get_font_extents('ttb');
ok( $e, "have ttb font extents" );
$result =
  { ascender => '18', descender => '-18', line_gap => '0' };
is_deeply( $e, $result, "font ttb extents" );

# Ligatures are ususally enabled by default.
$hb->set_features( 'liga=0' );
my $info = $hb->shaper;
$info = $hb->get_extents;
augment($info);

$result = [
	   { g => 71,
	     x_bearing =>   0.720, 'y_bearing' =>  24.588,
	     height    => -24.588, width       =>  13.068,
	     xMin      =>   0.720, yMin        =>   0.000,
	     xMax      =>  13.788, yMax        =>  24.588,
	   },
	   { g => 74,
	     x_bearing =>   0.576, 'y_bearing' =>  24.588,
	     height    => -24.588, width       =>   8.532,
	     xMin      =>   0.576, yMin        =>   0.000,
	     xMax      =>   9.108, yMax        =>  24.588,
	   },
	   { g => 70,
	     x_bearing =>   0.900, 'y_bearing' =>  16.560,
	     height    => -16.920, width       =>  14.364,
	     xMin      =>   0.900, yMin        =>  -0.360,
	     xMax      =>  15.264, yMax        =>  16.560,
	   },
	   { g => 85,
	     x_bearing =>   0.468, 'y_bearing' =>  20.844,
	     height    => -21.204, width       =>   9.576,
	     xMin      =>   0.468, yMin        =>  -0.360,
	     xMax      =>  10.044, yMax        =>  20.844,
	   },
	   { g => 84,
	     x_bearing =>   1.836, 'y_bearing' =>  16.560,
	     height    => -16.920, width       =>  10.692,
	     xMin      =>   1.836, yMin        =>  -0.360,
	     xMax      =>  12.528, yMax        =>  16.560,
	   },
	  ];

ok(compare( $info, $result ), "content without ligatures" );

# With ligatures.
$info = $hb->shaper( [ 'liga=1' ] );
$info = $hb->get_extents;
augment($info);

$result = [
	   { g => 109,
	     x_bearing =>   1.116, 'y_bearing' =>  24.588,
	     height    => -24.588, width       =>  17.640,
	     xMin      =>   1.116, yMin        =>   0.000,
	     xMax      =>  18.756, yMax        =>  24.588,
	   },
	   { g => 70,
	     x_bearing =>   0.900, 'y_bearing' =>  16.560,
	     height    => -16.920, width       =>  14.364,
	     xMin      =>   0.900, yMin        =>  -0.360,
	     xMax      =>  15.264, yMax        =>  16.560,
	   },
	   { g => 85,
	     x_bearing =>   0.468, 'y_bearing' =>  20.844,
	     height    => -21.204, width       =>   9.576,
	     xMin      =>   0.468, yMin        =>  -0.360,
	     xMax      =>  10.044, yMax        =>  20.844,
	   },
	   { g => 84,
	     x_bearing =>   1.836, 'y_bearing' =>  16.560,
	     height    => -16.920, width       =>  10.692,
	     xMin      =>   1.836, yMin        =>  -0.360,
	     xMax      =>  12.528, yMax        =>  16.560,
	   },
	  ];

ok(compare( $info, $result ), "content with ligatures" );

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
	for ( qw( xMin yMin xMax yMax ) ) {
	    last unless defined $j->{$_};
	    next if $i->{$_} == $j->{$_};
	    unless ( abs( $i->{$_} - $j->{$_} ) <= abs($j->{$_} / 100) ) {
		diag( "$_ $i->{$_} must be $j->{$_}" );
		return;
	    }
	}
    }
    return 1;
}

sub augment {
    my $info = shift;
    for my $e ( @$info ) {
	$e->{xMin} = $e->{x_bearing};
	$e->{yMin} = $e->{y_bearing} + $e->{height}; # height is negative
	$e->{xMax} = $e->{x_bearing} + $e->{width};
	$e->{yMax} = $e->{y_bearing};
    }
}
