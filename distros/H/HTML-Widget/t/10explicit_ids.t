use strict;
use warnings;

use Test::More tests => 2;

use HTML::Widget;
use lib 't/lib';
use HTMLWidget::TestLib;

my $w = HTML::Widget->new->explicit_ids(1);

$w->element( 'Textfield', 'foo' );
$w->element( 'Textfield', 'bar' )->attributes->{id} = 'my_bar';

# Without query
{
    my $f = $w->process;
    is( "$f", <<EOF, 'XML output is filled out form' );
<form id="widget" method="post"><fieldset class="widget_fieldset"><input class="textfield" name="foo" type="text" /><input class="textfield" id="my_bar" name="bar" type="text" /></fieldset></form>
EOF
}

# With mocked basic query
{
    my $query = HTMLWidget::TestLib->mock_query( {
            foo => 'yada',
            bar => '23',
        } );

    # Add an id to the top-level widget too
    $w->attributes->{id} = 'my_form';

    my $f = $w->process($query);
    is( "$f", <<EOF, 'XML output is filled out form' );
<form id="my_form" method="post"><fieldset class="widget_fieldset"><input class="textfield" name="foo" type="text" value="yada" /><input class="textfield" id="my_bar" name="bar" type="text" value="23" /></fieldset></form>
EOF
}
