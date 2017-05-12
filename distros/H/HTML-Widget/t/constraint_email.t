use strict;
use warnings;

use Test::More tests => 8;

use HTML::Widget;
use lib 't/lib';
use HTMLWidget::TestLib;

my $w = HTML::Widget->new;

$w->element( 'Textfield', 'foo' );

$w->constraint( 'Email', 'foo' );

# Valid
{
    my $query = HTMLWidget::TestLib->mock_query( { foo => 'sri@oook.de' } );

    my $f = $w->process($query);

    is( $f->param('foo'), 'sri@oook.de', 'foo value' );

    ok( !$f->errors, 'no errors' );
}

# Invalid
{
    my $query = HTMLWidget::TestLib->mock_query( { foo => 'invalid' } );

    my $f = $w->process($query);

    ok( $f->errors('foo'), 'foo has errors' );
}

# Multiple Valid
{
    my $query = HTMLWidget::TestLib->mock_query(
        { foo => [ 'sri@oook.de', 'sri@oook.de' ], } );

    my $f = $w->process($query);

    is( $f->valid('foo'), 1, "Valid" );

    my @results = $f->param('foo');
    is( $results[0], 'sri@oook.de', "Multiple valid values" );
    is( $results[1], 'sri@oook.de', "Multiple valid values" );

    ok( !$f->errors, 'no errors' );
}

# Multiple Invalid
{
    my $query
        = HTMLWidget::TestLib->mock_query( { foo => [ 'yada', 'bar' ], } );

    my $f = $w->process($query);

    ok( $f->errors('foo'), 'foo has errors' );
}
