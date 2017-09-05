use strict;
use warnings;

use Test::More tests => 1;

use Grid::Layout;

my $layout = Grid::Layout->new();

isa_ok($layout, 'Grid::Layout');
