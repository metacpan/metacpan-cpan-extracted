use strict;
use warnings;

use Test::More tests => 2;
BEGIN { use_ok('List::OrderBy') };

my @sorted = order_by { length } qw/zzz z zz/;

is_deeply \@sorted, [qw/z zz zzz/];
