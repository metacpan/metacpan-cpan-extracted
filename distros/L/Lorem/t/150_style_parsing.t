use Test::More tests => 35;

use warnings;
use strict;

use Lorem::Style;

my $style = Lorem::Style->new;

# border widths
for my $s (qw/left right top bottom/) {
    my $att = "border_$s" . "_width";
    $style->parse("$att: thick");
    is ($style->$att, 'thick', "parsed $att");
}

# border color
for my $s (qw/left right top bottom/) {
    my $att = "border_$s" . "_color";
    $style->parse("$att: red");
    is ($style->$att, 'red', "parsed $att");
}

# border style
for my $s (qw/left right top bottom/) {
    my $att = "border_$s" . "_style";
    $style->parse("$att: dotted");
    is ($style->$att, 'dotted', "parsed $att");
}

# border
$style = Lorem::Style->new;
$style->parse("border: thick dashed blue;");
is_deeply( [$style->border_left_width, $style->border_right_width, $style->border_top_width, $style->border_bottom_width],
           [qw/thick thick thick thick/], q[border width set from 'border' attribute]);
is_deeply( [$style->border_left_style, $style->border_right_style, $style->border_top_style, $style->border_bottom_style],
           [qw/dashed dashed dashed dashed/], q[border style set from 'border' attribute]);
is_deeply( [$style->border_left_color, $style->border_right_color, $style->border_top_color, $style->border_bottom_color],
           [qw/blue blue blue blue/], q[border color set from 'border' attribute]);

# border-left border-rigth border-top border-bottom
$style = Lorem::Style->new;
$style->parse('border-left: ' . 'thick dashed blue');
is_deeply( [$style->border_left_width, $style->border_left_style, $style->border_left_color],
           [qw/thick dashed blue/], qq[left border atts set from 'left-border' attribute]);

$style = Lorem::Style->new;
$style->parse('border-right: ' . 'thick dashed blue');
is_deeply( [$style->border_right_width, $style->border_right_style, $style->border_right_color],
           [qw/thick dashed blue/], qq[right border atts set from 'right-border' attribute]);

$style = Lorem::Style->new;
$style->parse('border-top: ' . 'thick dashed blue');
is_deeply( [$style->border_top_width, $style->border_top_style, $style->border_top_color],
           [qw/thick dashed blue/], qq[top border atts set from 'top-border' attribute]);

$style = Lorem::Style->new;
$style->parse('border-bottom: ' . 'thick dashed blue');
is_deeply( [$style->border_bottom_width, $style->border_bottom_style, $style->border_bottom_color],
           [qw/thick dashed blue/], qq[bottom border atts set from 'bottom-border' attribute]);


# margins
for my $s (qw/left right top bottom/) {
    my $att = "margin_$s";
    $style->parse("$att: 50");
    is ($style->$att, '50', "parsed $att");
}

$style = Lorem::Style->new;
$style->parse('margin: 10');
is_deeply( [$style->margin_top, $style->margin_right, $style->margin_bottom, $style->margin_left],
           [10, 10, 10, 10],
           q[margin set from 'margin' property (1 arg)]);

$style = Lorem::Style->new;
$style->parse('margin: 10 20');
is_deeply( [$style->margin_top, $style->margin_right, $style->margin_bottom, $style->margin_left],
           [10, 20, 10, 20],
           q[margin set from 'margin' property (2 args)]);

$style = Lorem::Style->new;
$style->parse('margin: 10 20 30');
is_deeply( [$style->margin_top, $style->margin_right, $style->margin_bottom, $style->margin_left],
           [10, 20, 30, 20],
           q[margin set from 'margin' property (3 args)]);

$style = Lorem::Style->new;
$style->parse('margin: 10 20 30 40');
is_deeply( [$style->margin_top, $style->margin_right, $style->margin_bottom, $style->margin_left],
           [10, 20, 30, 40],
           q[margin set from 'margin' property (4 args)]);

# padding
for my $s (qw/left right top bottom/) {
    my $att = "padding_$s";
    $style->parse("$att: 50");
    is ($style->$att, '50', "parsed $att");
}

$style = Lorem::Style->new;
$style->parse('padding: 10');
is_deeply( [$style->padding_top, $style->padding_right, $style->padding_bottom, $style->padding_left],
           [10, 10, 10, 10],
           q[padding set from 'padding' property (1 arg)]);

$style = Lorem::Style->new;
$style->parse('padding: 10 20');
is_deeply( [$style->padding_top, $style->padding_right, $style->padding_bottom, $style->padding_left],
           [10, 20, 10, 20],
           q[padding set from 'padding' property (2 args)]);

$style = Lorem::Style->new;
$style->parse('padding: 10 20 30');
is_deeply( [$style->padding_top, $style->padding_right, $style->padding_bottom, $style->padding_left],
           [10, 20, 30, 20],
           q[padding set from 'padding' property (3 args)]);

$style = Lorem::Style->new;
$style->parse('padding: 10 20 30 40');
is_deeply( [$style->padding_top, $style->padding_right, $style->padding_bottom, $style->padding_left],
           [10, 20, 30, 40],
           q[padding set from 'padding' property (4 args)]);

