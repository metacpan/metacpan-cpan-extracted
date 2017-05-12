use strict;
use warnings;

use Test::More tests => 8;

use HTML::Widget;
use lib 't/lib';
use HTMLWidget::TestLib;

my $w = HTML::Widget->new;

$w->element( 'Textfield', 'foo' );
$w->element( 'Textfield', 'bar' );

$w->constraint( 'DependOn', 'foo', 'bar' );

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

# Valid
{
    my $query = HTMLWidget::TestLib->mock_query( { other => 'whatever' } );

    my $f = $w->process($query);

    ok( !$f->errors, 'no errors' );
}

# Valid
{
    my $query = HTMLWidget::TestLib->mock_query( { bar => 'only' } );

    my $f = $w->process($query);

    is( $f->param('bar'), 'only', 'bar value' );

    ok( !$f->errors, 'no errors' );
}

# Invalid
{
    my $query = HTMLWidget::TestLib->mock_query( { foo => 'yada' } );

    my $f = $w->process($query);

    is( $f->param('foo'), 'yada', 'foo value' );

    ok( $f->errors('bar'), 'bar has errors' );
}
