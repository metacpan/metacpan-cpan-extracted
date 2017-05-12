use strict;
use warnings;

use Test::More tests => 1;

use HTML::Widget;
use lib 't/lib';
use HTMLWidget::TestLib;

my $w = HTML::Widget->new;

$w->element( 'Textfield', 'foo' );

$w->filter( '+HTMLWidget::CustomFilter', 'foo' );

# With mocked basic query
{
    my $query = HTMLWidget::TestLib->mock_query( {foo => 'Foo'} );

    my $f = $w->process($query);

    is( $f->param('foo', 'foo', 'foo value' );
}

