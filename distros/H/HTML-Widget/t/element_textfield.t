use strict;
use warnings;

use Test::More tests => 2;

use HTML::Widget;
use lib 't/lib';
use HTMLWidget::TestLib;

my $w = HTML::Widget->new;

$w->element( 'Textfield', 'foo' )->value('foo')->size(30)->label('Foo');
$w->element( 'Textfield', 'bar' );

$w->constraint( 'Integer', 'foo' );
$w->constraint( 'Integer', 'bar' );

# Without query
{
    my $f = $w->process;
    is( "$f", <<EOF, 'XML output is filled out form' );
<form id="widget" method="post"><fieldset class="widget_fieldset"><label for="widget_foo" id="widget_foo_label">Foo<input class="textfield" id="widget_foo" name="foo" size="30" type="text" value="foo" /></label><input class="textfield" id="widget_bar" name="bar" type="text" /></fieldset></form>
EOF
}

# With mocked basic query
{
    my $query = HTMLWidget::TestLib->mock_query( {
            foo => 'yada',
            bar => '23',
        } );

    my $f = $w->process($query);
    is( "$f", <<EOF, 'XML output is filled out form' );
<form id="widget" method="post"><fieldset class="widget_fieldset"><label class="labels_with_errors" for="widget_foo" id="widget_foo_label">Foo<span class="fields_with_errors"><input class="textfield" id="widget_foo" name="foo" size="30" type="text" value="yada" /></span></label><span class="error_messages" id="widget_foo_errors"><span class="integer_errors" id="widget_foo_error_integer">Invalid Input</span></span><input class="textfield" id="widget_bar" name="bar" type="text" value="23" /></fieldset></form>
EOF
}
