use strict;
use warnings;

use Test::More tests => 19;

use HTML::Widget;
use lib 't/lib';
use HTMLWidget::TestLib;

my $w = HTML::Widget->new;

my $elem_foo = $w->element( 'Textfield', 'foo' );
my $elem_bar = $w->element( 'Textfield', 'bar' );
my $elem_baz = $w->element( 'Textfield', 'baz' );

my $constraint = $w->constraint( 'Equal', 'foo', 'bar', 'baz' );

# Valid
{
    my $query = HTMLWidget::TestLib->mock_query( {
            foo => 'yada',
            bar => 'yada',
            baz => 'yada',
        } );

    my $f = $w->process($query);

    is( $f->param('foo'), 'yada', 'foo value' );

    is( $f->param('foo'), $f->param('bar'), 'foo eq bar' );

    ok( !$f->errors, 'no errors' );
}

# Valid (blank 1)
SKIP: {
    skip "drunken feature", 1;
    my $query = HTMLWidget::TestLib->mock_query( {
            foo => '',
            bar => 'yada',
        } );

    my $f = $w->process($query);
    is( "$f", <<EOF, 'XML output is filled out form' );
<form id="widget" method="post"><fieldset class="widget_fieldset"><input class="textfield" id="widget_foo" name="foo" type="text" /><input class="textfield" id="widget_bar" name="bar" type="text" value="yada" /></fieldset></form>
EOF
}

# Valid (blank 2)
SKIP: {
    skip "drunken feature", 1;
    my $query = HTMLWidget::TestLib->mock_query( {
            foo => 'yada',
            bar => '',
        } );

    my $f = $w->process($query);
    is( "$f", <<EOF, 'XML output is filled out form' );
<form id="widget" method="post"><fieldset class="widget_fieldset"><input class="textfield" id="widget_foo" name="foo" type="text" value="yada" /><input class="textfield" id="widget_bar" name="bar" type="text" /></fieldset></form>
EOF
}

# Invalid
{
    my $query = HTMLWidget::TestLib->mock_query( {
            foo => 'yada',
            bar => 'nada',
            baz => 'yada',
        } );

    my $f = $w->process($query);

    ok( $f->errors('foo'), 'foo has errors' );
    ok( $f->errors('bar'), 'bar has errors' );
    ok( $f->errors('baz'), 'baz has errors' );

    ok( !$f->param('foo'), 'param foo is undef due to error' );
    ok( !$f->param('bar'), 'param bar is undef due to error' );
    ok( !$f->param('baz'), 'param baz is undef due to error' );
}

# Display error on first value only
{
    $constraint->render_errors(qw/ foo /);
    my $query = HTMLWidget::TestLib->mock_query( {
            foo => 'yada',
            bar => 'nada',
            baz => 'nada',
        } );

    my $f = $w->process($query);

    ok( $f->errors('foo'), 'foo has errors' );
    ok( $f->errors('bar'), 'bar has errors' );
    ok( $f->errors('baz'), 'baz has errors' );

    is( "$f", <<EOF, 'XML output is filled out form' );
<form id="widget" method="post"><fieldset class="widget_fieldset"><span class="fields_with_errors"><input class="textfield" id="widget_foo" name="foo" type="text" value="yada" /></span><span class="error_messages" id="widget_foo_errors"><span class="equal_errors" id="widget_foo_error_equal">Invalid Input</span></span><input class="textfield" id="widget_bar" name="bar" type="text" value="nada" /><input class="textfield" id="widget_baz" name="baz" type="text" value="nada" /></fieldset></form>
EOF
}

# Display error on some
{
    $constraint->render_errors(qw/ foo bar /);
    my $query = HTMLWidget::TestLib->mock_query( {
            foo => 'yada',
            bar => 'nada',
            baz => 'something completely different',
        } );

    my $f = $w->process($query);

    ok( $f->errors('foo'), 'foo has errors' );
    ok( $f->errors('bar'), 'bar has errors' );
    ok( $f->errors('baz'), 'baz has errors' );

    is( "$f", <<EOF, 'XML output is filled out form' );
<form id="widget" method="post"><fieldset class="widget_fieldset"><span class="fields_with_errors"><input class="textfield" id="widget_foo" name="foo" type="text" value="yada" /></span><span class="error_messages" id="widget_foo_errors"><span class="equal_errors" id="widget_foo_error_equal">Invalid Input</span></span><span class="fields_with_errors"><input class="textfield" id="widget_bar" name="bar" type="text" value="nada" /></span><span class="error_messages" id="widget_bar_errors"><span class="equal_errors" id="widget_bar_error_equal">Invalid Input</span></span><input class="textfield" id="widget_baz" name="baz" type="text" value="something completely different" /></fieldset></form>
EOF
}

