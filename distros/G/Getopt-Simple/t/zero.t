use strict;
use warnings;

use Test::More tests => 1;

# -----------------

my($result) = `perl t/zero.pl -p 0`;

ok($result == 0, 'Successfully used 0 to override default value 1');
