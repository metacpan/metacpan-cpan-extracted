use strict;
use warnings;

use Test::More tests => 15;

use HTML::Widget;
use lib 't/lib';
use HTMLWidget::TestLib;

my $w = HTML::Widget->new;

$w->element( 'Textfield', 'foo' );

$w->constraint( 'Bool', 'foo' );

# Valid
{
    my $query = HTMLWidget::TestLib->mock_query( { foo => 1 } );

    my $f = $w->process($query);

    is( $f->param('foo'), 1, 'foo value' );

    ok( !$f->errors, 'no errors' );
}

# Valid
{
    my $query = HTMLWidget::TestLib->mock_query( { foo => 0 } );

    my $f = $w->process($query);

    is( $f->param('foo'), 0, 'foo value' );

    ok( !$f->errors, 'no errors' );
}

# undef valid
{
    my $query = HTMLWidget::TestLib->mock_query( { foo => undef } );

    my $f = $w->process($query);

    ok( $f->valid('foo') );
}

# empty valid
{
    my $query = HTMLWidget::TestLib->mock_query( { foo => '' } );

    my $f = $w->process($query);

    ok( $f->valid('foo') );

    is( $f->param('foo'), '', 'foo value' );
}

# Invalid
{
    my $query = HTMLWidget::TestLib->mock_query( { foo => 'yada' } );

    my $f = $w->process($query);

    ok( $f->errors('foo'), 'foo has errors' );
}

# Multiple Valid
{
    my $query = HTMLWidget::TestLib->mock_query( { foo => [ 1, 0, 1 ], } );

    my $f = $w->process($query);

    ok( $f->valid('foo'), 'Valid' );

    my @results = $f->param('foo');

    is_deeply( \@results, [ 1, 0, 1 ], 'Multiple valid values' );
}

# Multiple Invalid
{
    my $query = HTMLWidget::TestLib->mock_query( { foo => [ 1, 0, 2 ], } );

    my $f = $w->process($query);

    ok( !$f->valid('foo'), 'foo not valid' );

    ok( $f->errors('foo'), 'foo has errors' );
}

# invalid
{
    my $query = HTMLWidget::TestLib->mock_query( { foo => '11' } );

    my $f = $w->process($query);

    ok( $f->errors('foo'), 'foo has errors' );
}

# invalid
{
    my $query = HTMLWidget::TestLib->mock_query( { foo => '1.1' } );

    my $f = $w->process($query);

    ok( $f->errors('foo'), 'foo has errors' );
}

# invalid
{
    my $query = HTMLWidget::TestLib->mock_query( { foo => '10foo' } );

    my $f = $w->process($query);

    ok( $f->errors('foo'), 'foo has errros' );
}
