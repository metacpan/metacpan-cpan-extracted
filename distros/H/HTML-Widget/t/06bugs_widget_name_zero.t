use strict;
use warnings;

use Test::More tests => 1;

use HTML::Widget;

my $w = HTML::Widget->new(0);

is( $w->name, 0, 'widget name 0' );
