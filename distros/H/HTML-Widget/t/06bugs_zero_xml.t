use strict;
use warnings;

use Test::More tests => 6;

use HTML::Widget;
use lib 't/lib';
use HTMLWidget::TestLib;

my $w1 = HTML::Widget->new;

$w1->element( 'Textfield', 'foo' );
$w1->element( 'Textfield', '0' );

# Valid
{
    my $query = HTMLWidget::TestLib->mock_query( {
            foo => 'yada',
            0   => 'a',
        } );

    my $result = $w1->process($query);

    ok( $result->valid(0), '0 valid' );

    ok( !$result->has_errors(0), '0 not error' );

    like(
        "$result",
        qr/\Q id="widget_0" name="0" type="text" value="a" /,
        'name 0 XML ok'
    );
}

# Embed test
{
    my $query = HTMLWidget::TestLib->mock_query( {
            foo => 'yada',
            0   => 'a',
        } );

    my $w2 = new HTML::Widget;

    $w1->name('embed');

    $w2->embed($w1);

    my $result = $w2->process($query);

    ok( $result->valid(0), '0 valid' );

    ok( !$result->has_errors(0), '0 not error' );

    is( "$result", <<EOF, 'XML output is filled out form' );
<form id="widget" method="post"><fieldset class="widget_fieldset" id="widget_embed"><input class="textfield" id="widget_embed_foo" name="foo" type="text" value="yada" /><input class="textfield" id="widget_embed_0" name="0" type="text" value="a" /></fieldset></form>
EOF
}
