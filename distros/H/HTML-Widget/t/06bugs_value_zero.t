use strict;
use warnings;

use Test::More tests => 1;

use HTML::Widget;
my $w = HTML::Widget->new;

$w->element( 'Textfield', 'foo' )->value(0);
$w->element( 'RadioGroup', 'bar' )->values( 0, 1 )->value(0);

$w->constraint( 'All', 'foo', 'bar' );

my $f = $w->process();
is( "$f", <<EOF, 'XML output is filled out form' );
<form id="widget" method="post"><fieldset class="widget_fieldset"><input class="textfield" id="widget_foo" name="foo" type="text" value="0" /><fieldset class="radiogroup_fieldset" id="widget_bar"><span class="radiogroup"><label for="widget_bar_1" id="widget_bar_1_label"><input checked="checked" class="radio" id="widget_bar_1" name="bar" type="radio" value="0" />0</label><label for="widget_bar_2" id="widget_bar_2_label"><input class="radio" id="widget_bar_2" name="bar" type="radio" value="1" />1</label></span></fieldset></fieldset></form>
EOF
