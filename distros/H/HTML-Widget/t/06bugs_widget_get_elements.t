use strict;
use warnings;

use Test::More tests => 3;

use HTML::Widget;

my $w = HTML::Widget->new;

$w->element( 'Textfield', 'foo' );
$w->element( 'Textfield', 'bar' );
$w->element( 'Textarea',  'bar' );

my @elems = $w->get_elements( name => 'bar', type => 'Textfield' );

is( scalar(@elems), 1, 'correct number of elements' );

is( $elems[0]->name, 'bar', 'correct name' );

like( ref($elems[0]), qr/Textfield$/, 'correct type' );
