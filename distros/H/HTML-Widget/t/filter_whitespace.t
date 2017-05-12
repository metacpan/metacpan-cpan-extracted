use strict;
use warnings;

use Test::More tests => 2;

use HTML::Widget;
use lib 't/lib';
use HTMLWidget::TestLib;

my $w = HTML::Widget->new;

$w->element( 'Textfield', 'foo' );
$w->element( 'Textfield', 'bar' );

$w->filter( 'Whitespace', 'foo' );

# With mocked basic query
my $query = HTMLWidget::TestLib->mock_query( {
        foo => ' foo bar baz ',
        bar => ' 2 3 ',
    } );

my $f = $w->process($query);

is( $f->param('foo'), 'foobarbaz', 'foo value' );
is( $f->param('bar'), ' 2 3 ',     'bar value' );

