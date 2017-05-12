use Test::More tests => 6;

use warnings;
use strict;

use Lorem::Style;

my $style = Lorem::Style->new;

$style->set_width(100);
is( $style->width, 100, 'width set/retrieved' );

$style->set_height(100);
is( $style->height, 100, 'height set/retrieved' );

$style->set_min_width(100);
is( $style->min_width, 100, 'width set/retrieved' );

$style->set_min_height(100);
is( $style->min_height, 100, 'height set/retrieved' );

$style->set_max_width(100);
is( $style->min_width, 100, 'width set/retrieved' );

$style->set_max_height(100);
is( $style->min_height, 100, 'height set/retrieved' );
