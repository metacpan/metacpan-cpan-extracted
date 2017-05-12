use strict;
use warnings;

use Test::More tests => 7;

use HTML::Widget;
use lib 't/lib';
use HTMLWidget::TestLib;

my $w = HTML::Widget->new;

$w->element( 'Textfield', 'foo' );

$w->constraint( 'String', 'foo' );

# Valid
{
    my $query = HTMLWidget::TestLib->mock_query( { foo => 'yada' } );

    my $f = $w->process($query);

    is( $f->param('foo'), 'yada', 'foo value' );

    ok( !$f->errors, 'no errors' );
}

# Invalid
{
    my $query = HTMLWidget::TestLib->mock_query( { foo => '!@#$%' } );

    my $f = $w->process($query);

    ok( $f->errors('foo'), 'foo has errors' );
}

# Multiple Valid
{
    my $query = HTMLWidget::TestLib->mock_query( { foo => [ 'bar', 'yada' ] } );

    my $f = $w->process($query);

    is( $f->valid('foo'), 1, "Valid" );

    my @results = $f->param('foo');
    is( $results[0], 'bar',  "Multiple valid values" );
    is( $results[1], 'yada', "Multiple valid values" );
}

# Multiple Invalid
{
    my $query = HTMLWidget::TestLib->mock_query( { foo => [ 'yada', '-' ] } );

    my $f = $w->process($query);

    ok( $f->errors('foo'), 'foo has errors' );
}
