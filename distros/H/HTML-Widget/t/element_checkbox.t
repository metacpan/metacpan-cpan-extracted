use strict;
use warnings;

use Test::More tests => 2;

use HTML::Widget;
use lib 't/lib';
use HTMLWidget::TestLib;

my $w = HTML::Widget->new;

$w->element( 'Checkbox', 'foo' )->value('foo')->label('Foo');
$w->element( 'Checkbox', 'bar' )->checked('checked');
$w->element( 'Checkbox', 'bar' )->checked('checked')->value('b');

$w->constraint( 'Integer', 'foo' );
$w->constraint( 'Integer', 'bar' );

# Without query
{
    my $f = $w->process;
    is( "$f", <<EOF, 'XML output is filled out form' );
<form id="widget" method="post"><fieldset class="widget_fieldset"><label for="widget_foo" id="widget_foo_label"><input class="checkbox" id="widget_foo" name="foo" type="checkbox" value="foo" />Foo</label><input checked="checked" class="checkbox" id="widget_bar_1" name="bar" type="checkbox" value="1" /><input checked="checked" class="checkbox" id="widget_bar_2" name="bar" type="checkbox" value="b" /></fieldset></form>
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
<form id="widget" method="post"><fieldset class="widget_fieldset"><label class="labels_with_errors" for="widget_foo" id="widget_foo_label"><span class="fields_with_errors"><input class="checkbox" id="widget_foo" name="foo" type="checkbox" value="foo" /></span>Foo</label><span class="error_messages" id="widget_foo_errors"><span class="integer_errors" id="widget_foo_error_integer">Invalid Input</span></span><input class="checkbox" id="widget_bar_1" name="bar" type="checkbox" value="1" /><input class="checkbox" id="widget_bar_2" name="bar" type="checkbox" value="b" /></fieldset></form>
EOF
}
