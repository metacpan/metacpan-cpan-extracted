use strict;
use warnings;

use Test::More tests => 1;

use HTML::Widget;
my $w = HTML::Widget->new;

$w->element( 'Textfield', 'foo' )->value('');

my $f = $w->process();

like( "$f", qr/\Q value="" /x, 'empty value appears in XML' );

