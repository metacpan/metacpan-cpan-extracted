use Test::More tests => 10;

use warnings;
use strict;



use Lorem;

my $doc = Lorem->new_document;
$doc->style->set_margin( 50 );

my $page  = $doc->new_page;

my $div   = $page->new_div( style => 'border: solid; font-weight: bold; width: 100%; padding: 5' );
$div->new_text( content => 'TEXT1' );
$div->new_text( content => 'TEXT2' );

my $style = $div->style;

is $style->border_right_style, 'solid', 'border right solid';
is $style->border_left_style, 'solid', 'border left solid';
is $style->border_top_style, 'solid', 'border top solid';
is $style->border_bottom_style, 'solid', 'border bottom solid';
is $style->font_weight, 'bold', 'font-weight bold';
is $style->width, '100%', 'width set';
is $style->padding_left, 5, 'padding left set';
is $style->padding_right, 5, 'padding right set';
is $style->padding_top, 5, 'padding top set';
is $style->padding_bottom, 5, 'padding bottom set';