use strict;
use warnings;

use Test::More tests => 12;

use HTML::Widget;
use lib 't/lib';
use HTMLWidget::TestLib;

my $w = HTML::Widget->new;

$w->element( 'Textfield', 'foo' );

$w->constraint( 'Integer', 'foo' );

# Valid
{
    my $query = HTMLWidget::TestLib->mock_query( { foo => 23 } );

    my $f = $w->process($query);

    is( $f->param('foo'), 23, 'foo value' );

    ok( !$f->errors, 'no errors' );
}

# Invalid
{
    my $query = HTMLWidget::TestLib->mock_query( { foo => 'yada' } );

    my $f = $w->process($query);

    ok( $f->errors('foo'), 'foo has errors' );
}

# Multiple Valid
{
    my $query
        = HTMLWidget::TestLib->mock_query( { foo => [ 123, 321, 111 ], } );

    my $f = $w->process($query);

    is( $f->valid('foo'), 1, "Valid" );

    my @results = $f->param('foo');
    is( $results[0], 123, "Multiple valid values" );
    is( $results[2], 111, "Multiple valid values" );
}

# Multiple Invalid
{
    my $query
        = HTMLWidget::TestLib->mock_query( { foo => [ 123, 'foo', 321 ], } );

    my $f = $w->process($query);

    ok( $f->errors('foo'), 'foo has errors' );
}

{    # undef valid
    my $query = HTMLWidget::TestLib->mock_query( { foo => undef } );

    my $f = $w->process($query);

    ok( $f->valid('foo') );
}

{    # zero valid
    my $query = HTMLWidget::TestLib->mock_query( { foo => 0 } );

    my $f = $w->process($query);

    ok( $f->valid('foo') );

    is( $f->param('foo'), 0, 'foo value' );
}

{    # decimal invalid
    my $query = HTMLWidget::TestLib->mock_query( { foo => '1.1' } );

    my $f = $w->process($query);

    ok( $f->errors('foo'), 'foo has errors' );
}

{    # invalid
    my $query = HTMLWidget::TestLib->mock_query( { foo => '10foo' } );

    my $f = $w->process($query);

    ok( $f->errors('foo'), 'foo has errros' );
}
