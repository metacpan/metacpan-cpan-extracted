

use strict;
use Test::More tests => 3;

use lib qw(t);
use_ok('MyBingo');

ok(my $bingo = MyBingo->new(), 'Testing constructor');

isa_ok($bingo, 'MyBingo', 'Checking object');
