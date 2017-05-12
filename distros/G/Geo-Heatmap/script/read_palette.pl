use strict;
use warnings;

use Storable;
use Data::Dumper;

my $palette = Storable::retrieve('www/palette.store');

print Dumper $palette;
