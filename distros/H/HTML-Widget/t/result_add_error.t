use strict;
use warnings;

use Test::More tests => 5;

use HTML::Widget;
use lib 't/lib';
use HTMLWidget::TestLib;

my $w = HTML::Widget->new;

$w->element( 'Textfield', 'foo' )->value('foo');

# Without query
{
    my $f = $w->process;
    is( "$f", <<EOF, 'XML output is filled out form' );
<form id="widget" method="post"><fieldset class="widget_fieldset"><input class="textfield" id="widget_foo" name="foo" type="text" value="foo" /></fieldset></form>
EOF
}

# With mocked basic query
{
    my $query = HTMLWidget::TestLib->mock_query( { foo => 'yada' } );

    my $result = $w->process($query);

    is( "$result", <<EOF, 'XML output is filled out form' );
<form id="widget" method="post"><fieldset class="widget_fieldset"><input class="textfield" id="widget_foo" name="foo" type="text" value="yada" /></fieldset></form>
EOF

    $result->add_error( {
            name    => 'foo',
            message => 'bad foo',
        } );

    ok( $result->has_errors('foo') );

    ok( !$result->valid('foo') );

    is( "$result", <<EOF, 'XML output is filled out form' );
<form id="widget" method="post"><fieldset class="widget_fieldset"><span class="fields_with_errors"><input class="textfield" id="widget_foo" name="foo" type="text" value="yada" /></span><span class="error_messages" id="widget_foo_errors"><span class="custom_errors" id="widget_foo_error_custom">bad foo</span></span></fieldset></form>
EOF
}
