use Test::More tests => 8;

use warnings;
use strict;

use Lorem::Style;

my $style = Lorem::Style->new;

$style->set_padding_left(100);
is( $style->padding_left, 100, 'padding_left set/retrieved' );

$style->set_padding_right(100);
is( $style->padding_right, 100, 'padding_right set/retrieved' );

$style->set_padding_top(100);
is( $style->padding_top, 100, 'padding_top set/retrieved' );

$style->set_padding_bottom(100);
is( $style->padding_bottom, 100, 'padding_bottom set/retrieved' );

$style = Lorem::Style->new;

$style = Lorem::Style->new;
$style->set_padding('10');
is_deeply( [$style->padding_top, $style->padding_right, $style->padding_bottom, $style->padding_left],
           [10,10,10,10],
           'set_padding (group set: 1 arg)');

$style = Lorem::Style->new;
$style->set_padding('10 20');
is_deeply( [$style->padding_top, $style->padding_right, $style->padding_bottom, $style->padding_left],
           [10,20,10,20],
           'set_padding (group set: 2 args)');

$style = Lorem::Style->new;
$style->set_padding('10 20 30');
is_deeply( [$style->padding_top, $style->padding_right, $style->padding_bottom, $style->padding_left],
           [10,20,30,20],
           'set_padding (group set: 3 args)');

$style = Lorem::Style->new;
$style->set_padding('10 20 30 40');
is_deeply( [$style->padding_top, $style->padding_right, $style->padding_bottom, $style->padding_left],
           [10,20,30,40],
           'set_padding (group set: 4 args)');
