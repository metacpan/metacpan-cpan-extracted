use strict;
use warnings;

use Test::More tests => 1 + 1;    # +1 is for Test::NoWarnings
use Test::NoWarnings;

use HTML::Widget;
use lib 't/lib';
use HTMLWidget::TestLib;

{
    my $w = HTML::Widget->new;

    $w->element( 'Textfield', 'foo' );

    my $query = HTMLWidget::TestLib->mock_query( { foo => 'yada' } );

    my $result = $w->process($query);

    my @elements = $result->elements;

    ok( @elements == 1, '@elements contains 1 value' );
}
