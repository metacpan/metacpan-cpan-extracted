use Test::More tests => 21;

use warnings;
use strict;

#use Lorem::U
use Lorem::Style;

my $style = Lorem::Style->new;
ok( $style, 'created style');


my @widths = qw/thin thick medium/;
my @border_styles = qw/none hidden dotted dashed solid groove ridge inset outset/;
my @colors = qw/red green blue yellow black white cyan magenta/;

## PARSE INPUT

## just a width
#for my $w ( @widths ){
#    my @parsed = $style->_parse_border_input( $w );
#    is_deeply( \@parsed, [$w, undef, undef], qq[parsed $w]);   
#}
#
## just style
#for my $b ( @border_styles ) {
#    my @parsed = $style->_parse_border_input( $b );
#    is_deeply( \@parsed, [undef, $b, undef], qq[parsed $b]);
#}
#
## just color
#for my $c ( @colors ) {
#    my @parsed = $style->_parse_border_input( $c );
#    is_deeply( \@parsed, [undef, undef, $c], qq[parsed $c]);
#}
#
## width and style
#for my $w ( @widths ) {
#    for my $b ( @border_styles ) {
#        my $input = join ' ', $w, $b;
#        my @parsed = $style->_parse_border_input( $input );
#        is_deeply( \@parsed, [$w, $b, undef], qq[parsed $w $b]);
#    }
#}
#
## width and color
#for my $w ( @widths ) {
#    for my $c ( @colors ) {
#        my $input = join ' ', $w, $c;
#        my @parsed = $style->_parse_border_input( $input );
#        is_deeply( \@parsed, [$w, undef, $c], qq[parsed $w $c]);
#    }
#}

## style and color
#for my $b ( @border_styles ) {
#    for my $c ( @colors ) {
#        # width style and color
#        my $input = join ' ', $b, $c;
#        my @parsed = $style->_parse_border_input( $input );
#        is_deeply( \@parsed, [undef, $b, $c],  qq[parsed $input] );
#    }
#}
#
## width, style, and color
#for my $w ( @widths ) {
#    for my $b ( @border_styles ) {
#        for my $c ( @colors ) {
#            # width style and color
#            my $input = join ' ', $w, $b, $c;
#            my @parsed = $style->_parse_border_input( $input );
#            is_deeply( \@parsed, [$w, $b, $c],  qq[parsed $input] );
#        }
#    }
#}

## test setting style from input

# just a width
for my $w ( @widths ){
    my $style = Lorem::Style->new;
    $style->set_border_width( $w );
    
    is_deeply( [
        $style->border_left_width,
        $style->border_right_width,
        $style->border_top_width,
        $style->border_bottom_width
    ], [$w, $w, $w, $w], qq[set_border_width set all width values ($w)]);   
}

# just a style
for my $b ( @border_styles ){
    my $style = Lorem::Style->new;
    $style->set_border_style( $b );
    
    is_deeply( [
        $style->border_left_style,
        $style->border_right_style,
        $style->border_top_style,
        $style->border_bottom_style
    ], [$b, $b, $b, $b], qq[set_border_style set all style values ($b)]);   
}

# just a color
for my $c ( @colors ){
    my $style = Lorem::Style->new;
    $style->set_border_color( $c );
    
    is_deeply( [
        $style->border_left_color,
        $style->border_right_color,
        $style->border_top_color,
        $style->border_bottom_color
    ], [$c, $c, $c, $c], qq[set_border_color set all color values ($c)]);   
}

