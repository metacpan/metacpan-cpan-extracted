use strict;
use warnings;

use Test::More tests => 4;

use_ok('Math::Matlab::Engine');

my $ep = Math::Matlab::Engine->new();
ok(1);
ok(ref($ep),"Math::Matlab::Engine");

ok($ep->Close);
