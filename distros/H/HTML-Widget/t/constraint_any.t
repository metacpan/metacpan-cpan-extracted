use strict;
use warnings;

use Test::More tests => 10;

use HTML::Widget;
use lib 't/lib';
use HTMLWidget::TestLib;

my $w = HTML::Widget->new;

$w->element( 'Textfield', 'foo' );
$w->element( 'Textfield', 'bar' );

my $constraint = $w->constraint( 'Any', 'foo', 'bar' );

# Valid
{
    my $query = HTMLWidget::TestLib->mock_query( { foo => 'yada' } );

    my $f = $w->process($query);

    is( $f->param('foo'), 'yada', 'foo value' );

    ok( !$f->errors, 'no errors' );
}

# Invalid
{
    my $query = HTMLWidget::TestLib->mock_query( { baz => 23 } );

    my $f = $w->process($query);

    ok( $f->errors('foo'), 'foo has errors' );
    ok( $f->errors('bar'), 'bar has errors' );
}

# Multiple invalid, error only on one
{
    $constraint->render_errors(qw/ foo /);
    my $query = HTMLWidget::TestLib->mock_query( { baz => 23 } );

    my $f = $w->process($query);

    ok( $f->errors('foo'), 'foo has errors' );
    ok( $f->errors('bar'), 'bar has errors' );

    is( "$f", <<EOF, 'XML output is filled out form' );
<form id="widget" method="post"><fieldset class="widget_fieldset"><span class="fields_with_errors"><input class="textfield" id="widget_foo" name="foo" type="text" /></span><span class="error_messages" id="widget_foo_errors"><span class="any_errors" id="widget_foo_error_any">Alternative Missing</span></span><input class="textfield" id="widget_bar" name="bar" type="text" /></fieldset></form>
EOF
}

# Multiple invalid, error on both (explicitly)
{
    $constraint->render_errors(qw/ foo bar /);
    my $query = HTMLWidget::TestLib->mock_query( { baz => 23 } );

    my $f = $w->process($query);

    ok( $f->errors('foo'), 'foo has errors' );
    ok( $f->errors('bar'), 'bar has errors' );

    is( "$f", <<EOF, 'XML output is filled out form' );
<form id="widget" method="post"><fieldset class="widget_fieldset"><span class="fields_with_errors"><input class="textfield" id="widget_foo" name="foo" type="text" /></span><span class="error_messages" id="widget_foo_errors"><span class="any_errors" id="widget_foo_error_any">Alternative Missing</span></span><span class="fields_with_errors"><input class="textfield" id="widget_bar" name="bar" type="text" /></span><span class="error_messages" id="widget_bar_errors"><span class="any_errors" id="widget_bar_error_any">Alternative Missing</span></span></fieldset></form>
EOF
}
