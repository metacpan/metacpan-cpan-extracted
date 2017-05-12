use strict;
use warnings;

use Test::More tests => 10;

use HTML::Widget;
use lib 't/lib';
use HTMLWidget::TestLib;

my $w = HTML::Widget->new;

$w->element( 'Textfield', 'foo' );
$w->element( 'Textfield', 'bar' );

$w->constraint( 'All', 'foo', 'bar' );

# Valid
{
    my $query = HTMLWidget::TestLib->mock_query( {
            foo => 'yada',
            bar => 'nada',
        } );

    my $f = $w->process($query);

    is( $f->param('foo'), 'yada', 'foo value' );
    is( $f->param('bar'), 'nada', 'bar value' );

    ok( !$f->errors, 'no errors' );
}

# Invalid
{
    my $query = HTMLWidget::TestLib->mock_query( { foo => 'yada', } );

    my $f = $w->process($query);

    is( $f->param('foo'), 'yada', 'foo value' );

    ok( $f->errors('bar'), 'bar has errors' );
}

# Empty strings - like an empty form as submitted by Firefox - should be error
{
    my $query = HTMLWidget::TestLib->mock_query( {
            foo => '',
            bar => ''
        } );

    my $f = $w->process($query);

    ok( $f->errors('foo'), 'foo has errors' );
    ok( $f->errors('bar'), 'bar has errors' );
}

# "0" as a query value
{
    my $query = HTMLWidget::TestLib->mock_query( { foo => 0 } );

    my $f = $w->process($query);

    ok( $f->valid('foo'), 'foo valid' );
    is( $f->param('foo'), 0, 'foo value' );

    ok( $f->errors('bar'), 'bar has errors' );
}
