use strict;
use warnings;

use Test::More tests => 3;

use HTML::Widget;
use lib 't/lib';
use HTMLWidget::TestLib;

my $w = HTML::Widget->new;

$w->element( 'Textfield', 'foo' );
$w->element( 'Textfield', 'bar' );

$w->filter_all('UpperCase');

# this element shouldn't get a filter added
$w->element( 'Textfield', 'baz' );

# With mocked basic query
{
    my $query = HTMLWidget::TestLib->mock_query( {
            foo => 'Foo',
            bar => 'Bar',
            baz => 'yada',
        } );

    my $f = $w->process($query);

    is( $f->param('foo'), 'FOO',  'foo value' );
    is( $f->param('bar'), 'BAR',  'bar value' );
    is( $f->param('baz'), 'yada', 'bar value' );
}

