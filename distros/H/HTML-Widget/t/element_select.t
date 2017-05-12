use strict;
use warnings;

use Test::More tests => 6;

use HTML::Widget;
use lib 't/lib';
use HTMLWidget::TestLib;

my $w = HTML::Widget->new;

$w->element( 'Select', 'foo' )->label('Foo')
    ->options( foo => 'Foo', bar => 'Bar' )->selected('foo');
$w->element( 'Select', 'bar' )->options( 23 => 'Baz', yada => 'Yada' );
$w->element( 'Select', 'stool' )->options( 1 => 'one', 2 => 'two' )->size(2);
$w->element( 'Select', 'pigeon' )->options( 3 => 'three', 4 => 'four' )
    ->multiple(1)->selected('4');

$w->constraint( 'Integer', 'foo' );
$w->constraint( 'Integer', 'stool' );

# Without query
{
    my $f = $w->process;
    is( "$f", <<EOF, 'XML output is filled out form' );
<form id="widget" method="post"><fieldset class="widget_fieldset"><label for="widget_foo" id="widget_foo_label">Foo<select class="select" id="widget_foo" name="foo"><option selected="selected" value="foo">Foo</option><option value="bar">Bar</option></select></label><select class="select" id="widget_bar" name="bar"><option value="23">Baz</option><option value="yada">Yada</option></select><select class="select" id="widget_stool" name="stool" size="2"><option value="1">one</option><option value="2">two</option></select><select class="select" id="widget_pigeon" multiple="multiple" name="pigeon"><option value="3">three</option><option selected="selected" value="4">four</option></select></fieldset></form>
EOF
}

# With mocked basic query
{
    my $query = HTMLWidget::TestLib->mock_query( {
            foo    => 'foo',
            bar    => [ 'yada', 23 ],
            stool  => 2,
            pigeon => [ 3, 4 ],
        } );

    my $f = $w->process($query);

    ok( !$f->valid('foo') );
    ok( !$f->valid('bar') );
    ok( $f->valid('stool') );
    ok( $f->valid('pigeon') );

    is( "$f", <<EOF, 'XML output is filled out form' );
<form id="widget" method="post"><fieldset class="widget_fieldset"><label class="labels_with_errors" for="widget_foo" id="widget_foo_label">Foo<select class="select" id="widget_foo" name="foo"><option selected="selected" value="foo">Foo</option><option value="bar">Bar</option></select></label><span class="error_messages" id="widget_foo_errors"><span class="integer_errors" id="widget_foo_error_integer">Invalid Input</span></span><select class="select" id="widget_bar" name="bar"><option selected="selected" value="23">Baz</option><option selected="selected" value="yada">Yada</option></select><span class="error_messages" id="widget_bar_errors"><span class="multiple_errors" id="widget_bar_error_multiple">Multiple Selections Not Allowed</span></span><select class="select" id="widget_stool" name="stool" size="2"><option value="1">one</option><option selected="selected" value="2">two</option></select><select class="select" id="widget_pigeon" multiple="multiple" name="pigeon"><option selected="selected" value="3">three</option><option selected="selected" value="4">four</option></select></fieldset></form>
EOF
}
