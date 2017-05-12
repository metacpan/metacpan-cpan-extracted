use Test::More tests => 8;

use warnings;
use strict;

use Lorem::Style;

my $style = Lorem::Style->new( 'margin: 10; padding: 10; border: solid;' );

is( $style->padding_left, 10, 'padding left set');
is( $style->padding_right, 10, 'padding right set');
is( $style->padding_top, 10, 'padding top set');
is( $style->padding_bottom, 10, 'padding bottom set');
is( $style->margin_left, 10, 'margin left set');
is( $style->margin_right, 10, 'margin right set');
is( $style->margin_top, 10, 'margin top set');
is( $style->margin_bottom, 10, 'margin bottom set');