use Test::More tests => 8;

use warnings;
use strict;

use Lorem::Style;

my $style = Lorem::Style->new;

$style->set_margin_left(100);
is( $style->margin_left, 100, 'margin_left set/retrieved' );

$style->set_margin_right(100);
is( $style->margin_right, 100, 'margin_right set/retrieved' );

$style->set_margin_top(100);
is( $style->margin_top, 100, 'margin_top set/retrieved' );

$style->set_margin_bottom(100);
is( $style->margin_bottom, 100, 'margin_bottom set/retrieved' );


$style = Lorem::Style->new;
$style->set_margin('10');
is_deeply( [$style->margin_top, $style->margin_right, $style->margin_bottom, $style->margin_left],
           [10,10,10,10],
           'set_margin (group set: 1 arg)');

$style = Lorem::Style->new;
$style->set_margin('10 20');
is_deeply( [$style->margin_top, $style->margin_right, $style->margin_bottom, $style->margin_left],
           [10,20,10,20],
           'set_margin (group set: 2 args)');

$style = Lorem::Style->new;
$style->set_margin('10 20 30');
is_deeply( [$style->margin_top, $style->margin_right, $style->margin_bottom, $style->margin_left],
           [10,20,30,20],
           'set_margin (group set: 3 args)');

$style = Lorem::Style->new;
$style->set_margin('10 20 30 40');
is_deeply( [$style->margin_top, $style->margin_right, $style->margin_bottom, $style->margin_left],
           [10,20,30,40],
           'set_margin (group set: 4 args)');

