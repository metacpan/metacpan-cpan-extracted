use strict;
use warnings;

use Test::More tests => 2;

use HTML::Widget;
use lib 't/lib';
use HTMLWidget::TestLib;

my $w1 = HTML::Widget->new;

$w1->element( 'Textfield', 'foo' );

# Valid
{
    my $query = HTMLWidget::TestLib->mock_query( { foo => [ 'one', 'two' ], } );

    my $result = $w1->process($query);

    ok( $result->valid('foo'), 'foo valid' );

    my $params = $result->params;

    is_deeply(
        $params,
        { foo => [ 'one', 'two' ] },
        '$result->params is_deeply'
    );
}
