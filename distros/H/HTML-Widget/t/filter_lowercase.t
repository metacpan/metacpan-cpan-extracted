use strict;
use warnings;

use Test::More tests => 2;

use HTML::Widget;
use lib 't/lib';
use HTMLWidget::TestLib;

my $w = HTML::Widget->new;

$w->element( 'Textfield', 'foo' );
$w->element( 'Textfield', 'bar' );

$w->filter( 'LowerCase', 'foo' );

# With mocked basic query
{
    my $query = HTMLWidget::TestLib->mock_query( {
            foo => 'Foo',
            bar => 'Bar',
        } );

    my $f = $w->process($query);

    is( $f->param('foo'), 'foo', 'foo value' );
    is( $f->param('bar'), 'Bar', 'bar value' );
}

