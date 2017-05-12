use strict;
use warnings;

use Test::More tests => 3;

use HTML::Widget;

#       <form action="x">
#        <fieldset class="widget_fieldset">
#          <input name="x"/>
#          <fieldset class="widget_fieldset">
#           <input name="y"/>
#          </fieldset>
#        </fieldset>
#       </form>

# Old style

my $wo = HTML::Widget->new('foo')->action('/foo');

my $fso1 = HTML::Widget->new('main');
$fso1->element( 'Textfield', 'bar' );

my $fso2 = HTML::Widget->new('nested');
$fso2->element( 'Textfield', 'baz' );

$fso1->embed_into_first($fso2);
$wo->embed($fso1);

my $fo = $wo->process;
is( $fo->as_xml, <<EOF, 'XML output is form' );
<form action="/foo" id="foo" method="post"><fieldset class="widget_fieldset" id="foo_main"><input class="textfield" id="foo_main_bar" name="bar" type="text" /><fieldset class="widget_fieldset" id="foo_main_nested"><input class="textfield" id="foo_main_nested_baz" name="baz" type="text" /></fieldset></fieldset></form>
EOF

# New style

my $w = HTML::Widget->new('foo')->action('/foo');

my $fs1 = $w->element( 'Fieldset', 'main' );
$fs1->element( 'Textfield', 'bar' );

my $fs2 = $fs1->element( 'Fieldset', 'nested' );
$fs2->element( 'Textfield', 'baz' );

my $f = $w->process;
is( $f->as_xml, <<EOF, 'XML output is form' );
<form action="/foo" id="foo" method="post"><fieldset class="widget_fieldset" id="foo_main"><input class="textfield" id="foo_main_bar" name="bar" type="text" /><fieldset class="widget_fieldset" id="foo_main_nested"><input class="textfield" id="foo_main_nested_baz" name="baz" type="text" /></fieldset></fieldset></form>
EOF

# CHECK BOTH EXAMPLES PRODUCE SAME OUTPUT

is( "$fo", "$f", 'widgets are identical' );

