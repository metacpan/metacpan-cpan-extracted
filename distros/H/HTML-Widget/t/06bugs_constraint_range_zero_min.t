use strict;
use warnings;

use Test::More tests => 4;

use HTML::Widget;
use lib 't/lib';
use HTMLWidget::TestLib;

my $w = HTML::Widget->new;

$w->element( 'Textfield', 'foo' );

$w->constraint( 'Range', 'foo' )->min(0)->max(4);

# Valid
{
    my $query = HTMLWidget::TestLib->mock_query( { foo => 0 } );

    my $f = $w->process($query);

    ok( $f->valid('foo'), 'foo valid' );

    ok( !$f->errors, 'no errors' );
}

# Invalid
{
    my $query = HTMLWidget::TestLib->mock_query( { foo => -1 } );

    my $f = $w->process($query);

    ok( !$f->valid('foo'), 'foo not valid' );

    ok( $f->errors, 'errors' );
}

