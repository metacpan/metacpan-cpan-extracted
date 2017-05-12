use strict;
use warnings;

use Test::More tests => 16;

use HTML::Widget;
use lib 't/lib';
use HTMLWidget::TestLib;

my $w = HTML::Widget->new;

my $fs = $w->element( 'Fieldset', 'outer' );

$fs->element( 'Textfield', 'foo' );
$fs->element( 'Textfield', 'bar' );

$w->constraint_all('Bool');

# this element shouldn't get a constraint added
$fs->element( 'Textfield', 'baz' );

# Valid
{
    my $query = HTMLWidget::TestLib->mock_query( {
            foo => 1,
            bar => 0,
            baz => 'yada'
        } );

    my $f = $w->process($query);

    ok( $f->valid('foo'), 'foo value' );
    ok( $f->valid('bar'), 'bar value' );
    ok( $f->valid('baz'), 'baz value' );
    ok( !$f->errors,      'no errors' );

    my @cons = $w->get_constraints;

    is( scalar @cons, 2, '2 constraints' );
}

# Valid
{
    my $query = HTMLWidget::TestLib->mock_query( { foo => 0 } );

    my $f = $w->process($query);

    ok( $f->valid('foo'), 'foo value' );
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
    my $query = HTMLWidget::TestLib->mock_query( { foo => 'yada', bar => 1 } );

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

