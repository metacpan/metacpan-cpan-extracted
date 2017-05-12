use strict;
use warnings;

use Test::More tests => 9;

use HTML::Widget;
use lib 't/lib';
use HTMLWidget::TestLib;

my $w = HTML::Widget->new;

$w->element( 'Textfield', 'foo' );

$w->constraint( 'SingleValue', 'foo' );

# Valid
{
    my $query = HTMLWidget::TestLib->mock_query( { foo => 1 } );

    my $f = $w->process($query);

    is( $f->param('foo'), 1, 'foo value' );

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

# Multiple Invalid
{
    my $query = HTMLWidget::TestLib->mock_query( { foo => [ 1, 0 ], } );

    my $f = $w->process($query);

    ok( !$f->valid('foo'), 'foo not valid' );

    ok( $f->errors('foo'), 'foo has errors' );
}

# Multiple Invalid
{
    my $query = HTMLWidget::TestLib->mock_query( { foo => [ 'foo', 'bar' ], } );

    my $f = $w->process($query);

    ok( !$f->valid('foo'), 'foo not valid' );

    ok( $f->errors('foo'), 'foo has errors' );
}

