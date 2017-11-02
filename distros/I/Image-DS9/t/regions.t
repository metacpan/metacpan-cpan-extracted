#! perl
use strict;
use warnings;

use Test::More tests => 58;
use Image::DS9;

require './t/common.pl';

my $ds9 = start_up();
$ds9->file( 'data/m31.fits.gz' );
$ds9->zoom(0);

test_stuff( $ds9, (
                   regions =>
                   [
                    ( map { ('format' => $_) }
                         qw( ciao saotng saoimage pros xy ds9 )
                    ),
                    ( map { (sky => $_) }
                         qw( fk4 fk5 icrs galactic ecliptic )
                    ),
                    ( map { (skyformat => $_) }
                         qw( degrees sexagesimal )
                    ),
                    ( map { ( system => $_ ) }
                      ( qw( image physical wcs ),
                        map { 'wcs' . $_ } ('a'..'z') )
                    ),
                    ( map { (color => $_) }
                          qw( white black red green blue cyan magenta yellow )
                    ),
                    width => 3,
                    width => 1,
                    strip => 0,
                    strip => 1,
                   ],
                  ) );


# ok, now we get to play

eval {
  $ds9->regions( 'deleteall' );
};
diag( $@ )if $@;
ok( ! $@, "regions deleteall" );

# center the image and grab the coords
$ds9->frame( 'center' );
my $coords = $ds9->pan( 'wcs', 'fk5', 'sexagesimal' );

my $region = "fk5;text($coords->[0],$coords->[1]) # color=yellow text={Hello}";
my $expected_region = qr/fk5\s#\s*text\(00?:42:44\.477,\+41:16:04\.(53|529)\) color=yellow text=\{Hello\}/;

eval {
  $ds9->regions( $region );
};
diag( $@ )if $@;
ok( ! $@, "regions scalar set" );

eval {
  $ds9->regions( 'deleteall' );
  $ds9->regions( \$region );
};
diag( $@ )if $@;
ok( ! $@, "regions scalarref set" );

$ds9->regions( format => 'ds9' );
$ds9->regions( sky => 'fk5' );
$ds9->regions( system => 'wcs' );
$ds9->regions( strip => 0 );


my $found = 0;
my @lines = split("\n", $ds9->regions );

# remove header lines
shift @lines while $lines[0] =~ /^#/;

# next line should list attributes
shift @lines if $lines[0] =~ /^global/;

# and the rest should match the expected region defined above.
like( join("\n", @lines), $expected_region, "regions get" );
