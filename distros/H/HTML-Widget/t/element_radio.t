use strict;
use warnings;

use Test::More tests => 3;

use HTML::Widget;
use lib 't/lib';
use HTMLWidget::TestLib;

my $w = HTML::Widget->new;

$w->element( 'Radio', 'foo' )->value('foo')->label('Foo');
$w->element( 'Radio', 'bar' )->value(23)->label('Bar');
$w->element( 'Radio', 'bar' )->checked('checked')->label('Bar2');
$w->element( 'Radio', 'bar' )->label('Bar3');

$w->constraint( 'Integer', 'foo' );
$w->constraint( 'Integer', 'bar' );

# Without query
{
    my $f = $w->process;
    is( "$f", <<EOF, 'XML output is filled out form' );
<form id="widget" method="post"><fieldset class="widget_fieldset"><label for="widget_foo" id="widget_foo_label"><input class="radio" id="widget_foo" name="foo" type="radio" value="foo" />Foo</label><label for="widget_bar_1" id="widget_bar_1_label"><input class="radio" id="widget_bar_1" name="bar" type="radio" value="23" />Bar</label><label for="widget_bar_2" id="widget_bar_2_label"><input checked="checked" class="radio" id="widget_bar_2" name="bar" type="radio" value="1" />Bar2</label><label for="widget_bar_3" id="widget_bar_3_label"><input class="radio" id="widget_bar_3" name="bar" type="radio" value="1" />Bar3</label></fieldset></form>
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
<form id="widget" method="post"><fieldset class="widget_fieldset"><label class="labels_with_errors" for="widget_foo" id="widget_foo_label"><span class="fields_with_errors"><input class="radio" id="widget_foo" name="foo" type="radio" value="foo" /></span>Foo</label><span class="error_messages" id="widget_foo_errors"><span class="integer_errors" id="widget_foo_error_integer">Invalid Input</span></span><label for="widget_bar_1" id="widget_bar_1_label"><input checked="checked" class="radio" id="widget_bar_1" name="bar" type="radio" value="23" />Bar</label><label for="widget_bar_2" id="widget_bar_2_label"><input class="radio" id="widget_bar_2" name="bar" type="radio" value="1" />Bar2</label><label for="widget_bar_3" id="widget_bar_3_label"><input class="radio" id="widget_bar_3" name="bar" type="radio" value="1" />Bar3</label></fieldset></form>
EOF
}

# With mocked basic query and container
{
    my $w1 = HTML::Widget->new;

    $w1->element( 'Radio', 'foo' )->value('foo')->label('Foo');
    $w1->element( 'Radio', 'bar' )->value(23)->label('Bar');
    $w1->element( 'Radio', 'bar' )->checked('checked')->label('Bar2');
    $w1->element( 'Radio', 'bar' )->label('Bar3');

    $w1->constraint( 'Integer', 'foo' );
    $w1->constraint( 'Integer', 'bar' );

    my $query = HTMLWidget::TestLib->mock_query( {
            foo => 'yada',
            bar => '23',
        } );

    my $w2 = HTML::Widget->new('something');
    $w2->embed($w1);

    my $f = $w2->process($query);
    is( "$f", <<EOF, 'XML output is filled out form' );
<form id="something" method="post"><fieldset class="widget_fieldset" id="something_widget"><label class="labels_with_errors" for="something_widget_foo" id="something_widget_foo_label"><span class="fields_with_errors"><input class="radio" id="something_widget_foo" name="foo" type="radio" value="foo" /></span>Foo</label><span class="error_messages" id="something_widget_foo_errors"><span class="integer_errors" id="something_widget_foo_error_integer">Invalid Input</span></span><label for="something_widget_bar_1" id="something_widget_bar_1_label"><input checked="checked" class="radio" id="something_widget_bar_1" name="bar" type="radio" value="23" />Bar</label><label for="something_widget_bar_2" id="something_widget_bar_2_label"><input class="radio" id="something_widget_bar_2" name="bar" type="radio" value="1" />Bar2</label><label for="something_widget_bar_3" id="something_widget_bar_3_label"><input class="radio" id="something_widget_bar_3" name="bar" type="radio" value="1" />Bar3</label></fieldset></form>
EOF
}
