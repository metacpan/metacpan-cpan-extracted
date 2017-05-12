#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 17;
use File::Spec::Functions ':ALL';
use Imager::Search                 ();
use Imager::Search::Image          ();
use Imager::Search::Pattern        ();
use Imager::Search::Driver::HTML24 ();

my $small = catfile( 't', 'data', 'basic', 'small1.bmp' );
ok( -f $small, 'Found small file' );

my $big = catfile( 't', 'data', 'basic', 'big1.bmp' );
ok( -f $big, 'Found big file' );





#####################################################################
# Execute the search

my $pattern = Imager::Search::Pattern->new(
	driver => 'Imager::Search::Driver::HTML24',
	file   => $small,
);
isa_ok( $pattern, 'Imager::Search::Pattern' );

my $target = Imager::Search::Image->new(
	driver => 'Imager::Search::Driver::HTML24',
	file   => $big,
);
isa_ok( $target, 'Imager::Search::Image' );

my @matches = $target->find( $pattern );
my $boolean = $target->find_any( $pattern );




#####################################################################
# Check the results

is( scalar(@matches), 2, 'Found 2 matches' );
is( $boolean, 1, 'find_any ok' );

isa_ok( $matches[0], 'Imager::Search::Match' );
is( $matches[0]->left,     0, '->left ok'     );
is( $matches[0]->right,    0, '->right ok'    );
is( $matches[0]->top,      0, '->top ok'      );
is( $matches[0]->bottom,   1, '->bottom ok'   );
is( $matches[0]->center_x, 0, '->center_x ok' );
is( $matches[0]->center_y, 0, '->center_y ok' );
is( $matches[0]->centre_x, 0, '->centre_x ok' );
is( $matches[0]->centre_y, 0, '->centre_y ok' );
is( $matches[0]->height,   2, '->height ok'   );
is( $matches[0]->width,    1, '->width ok'    );
