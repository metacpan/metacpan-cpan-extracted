use strict;
use warnings;

use Test::More tests => 2;

use HTML::Widget;
use lib 't/lib';
use HTMLWidget::TestLib;

my $w = HTML::Widget->new;

$w->element( 'Password', 'foo' )->value('foo')->size(30)->maxlength(30)
    ->label('Foo');
$w->element( 'Password', 'bar' )->fill(1);

$w->constraint( 'Integer', 'foo' );
$w->constraint( 'Integer', 'bar' );

# Without query
{
    my $f = $w->process;
    is( "$f", <<EOF, 'XML output is filled out form' );
<form id="widget" method="post"><fieldset class="widget_fieldset"><label for="widget_foo" id="widget_foo_label">Foo<input class="password" id="widget_foo" maxlength="30" name="foo" size="30" type="password" /></label><input class="password" id="widget_bar" name="bar" type="password" /></fieldset></form>
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
<form id="widget" method="post"><fieldset class="widget_fieldset"><label class="labels_with_errors" for="widget_foo" id="widget_foo_label">Foo<span class="fields_with_errors"><input class="password" id="widget_foo" maxlength="30" name="foo" size="30" type="password" /></span></label><span class="error_messages" id="widget_foo_errors"><span class="integer_errors" id="widget_foo_error_integer">Invalid Input</span></span><input class="password" id="widget_bar" name="bar" type="password" value="23" /></fieldset></form>
EOF
}
