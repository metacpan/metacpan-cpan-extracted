use strict;
use warnings;

use Test::More tests => 10;

use HTML::Widget;
use lib 't/lib';
use HTMLWidget::TestLib;

my $w = HTML::Widget->new;

$w->element( 'Textfield', 'foo' );

$w->constraint( 'Range', 'foo' )->min(3)->max(4);

# Valid
{
    my $query = HTMLWidget::TestLib->mock_query( { foo => 4 } );

    my $f = $w->process($query);

    is( $f->param('foo'), 4, 'foo value' );

    ok( !$f->errors, 'no errors' );
}

# Valid ''
{
    my $query = HTMLWidget::TestLib->mock_query( { foo => '' } );

    my $f = $w->process($query);

    ok( $f->valid('foo'), 'foo valid' );

    is( $f->param('foo'), '', 'foo value' );
}

# Invalid
{
    my $query = HTMLWidget::TestLib->mock_query( { foo => 5 } );

    my $f = $w->process($query);

    ok( $f->errors('foo'), 'foo has errors' );
}

# Invalid 'a'
{
    my $query = HTMLWidget::TestLib->mock_query( { foo => 'a' } );

    my $f = $w->process($query);

    ok( $f->errors('foo'), 'foo has errors' );
}

# Multiple Valid
{
    my $query = HTMLWidget::TestLib->mock_query( { foo => [ 4, 4 ] } );

    my $f = $w->process($query);

    is( $f->valid('foo'), 1, "Valid" );

    my @results = $f->param('foo');
    is( $results[0], 4, "Multiple valid values" );
    is( $results[1], 4, "Multiple valid values" );
}

# Multiple Invalid
{
    my $query = HTMLWidget::TestLib->mock_query( { foo => [ 4, 5, 4 ] } );

    my $f = $w->process($query);

    ok( $f->errors('foo'), 'foo has errors' );
}
