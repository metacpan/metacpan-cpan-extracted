use strict;
use warnings;

use Test::More tests => 2;

use HTML::Widget;
use lib 't/lib';
use HTMLWidget::TestLib;

my $w = HTML::Widget->new;

$w->element( 'Select', 'foo' )->label('Foo')
    ->options( foo => 'Foo', bar => 'Bar' );

$w->constraint( 'Integer', 'foo' );
$w->constraint( 'Integer', 'bar' );

# Without query
{
    my $f = $w->process();

    is( $f->submitted, 0, 'Form was not submitted' );
}

# With mocked basic query
{
    my $query = HTMLWidget::TestLib->mock_query( {
            foo => 'foo',
            bar => [ 'yada', 23 ],
        } );

    my $f = $w->process($query);
    is( $f->submitted, 1, 'Form was submitted' );
}
