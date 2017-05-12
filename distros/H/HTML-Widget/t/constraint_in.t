use strict;
use warnings;

use Test::More tests => 7;

use HTML::Widget;
use lib 't/lib';
use HTMLWidget::TestLib;

my $w = HTML::Widget->new;

$w->element( 'Textfield', 'foo' );

$w->constraint( 'In', 'foo' )->in( 'one', 'two', 'three' );

# Valid
{
    my $query = HTMLWidget::TestLib->mock_query( { foo => 'one' } );

    my $f = $w->process($query);

    is( $f->param('foo'), 'one', 'foo value' );

    ok( !$f->errors, 'no errors' );
}

# Valid
{
    my $query = HTMLWidget::TestLib->mock_query( { foo => 'two' } );

    my $f = $w->process($query);

    is( $f->param('foo'), 'two', 'foo value' );

    ok( !$f->errors, 'no errors' );
}

# Valid
{
    my $query = HTMLWidget::TestLib->mock_query( { foo => 'three' } );

    my $f = $w->process($query);

    is( $f->param('foo'), 'three', 'foo value' );

    ok( !$f->errors, 'no errors' );
}

# Invalid
{
    my $query = HTMLWidget::TestLib->mock_query( { foo => 'four' } );

    my $f = $w->process($query);

    ok( $f->errors('foo'), 'foo has errors' );
}

