use strict;
use warnings;

use Test::More tests => 3;

use HTML::Widget;
use lib 't/lib';
use HTMLWidget::TestLib;

my $w = HTML::Widget->new;

$w->element( 'Textfield', 'foo' );

$w->constraint( 'ASCII', 'foo' );

my $query = HTMLWidget::TestLib->mock_query( { foo => ' ' } );

my $f = $w->process($query);

ok( !$f->has_errors, 'no errors' );

ok( $f->valid('foo'), 'foo valid' );

is( $f->param('foo'), ' ', 'value is space character' );

