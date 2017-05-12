use strict;
use warnings;

use Test::More tests => 2;

use HTML::Widget;
use lib 't/lib';
use HTMLWidget::TestLib;

my $w = HTML::Widget->new;

$w->element( 'Textfield', 'foo' );
$w->element( 'Textfield', 'bar' );

$w->filter( 'HTMLStrip', 'foo' );
$w->filter( 'HTMLStrip', 'bar' );

# With mocked basic query
{
    my $query = HTMLWidget::TestLib->mock_query( {
            foo => '<p>message</p>',
            bar => '<p><b>23</b></p>',
        } );

    my $f = $w->process($query);

    is( $f->param('foo'), 'message', 'foo value' );
    is( $f->param('bar'), 23,        'bar value' );
}

