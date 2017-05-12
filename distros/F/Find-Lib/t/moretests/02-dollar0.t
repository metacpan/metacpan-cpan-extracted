use strict;
use Test::More tests => 3;

$0 = "Renammed";
use Find::Lib '../mylib';
use MyLib a => 1, b => 42;

ok $MyLib::imported{'a'};
is $MyLib::imported{'b'}, 42;

## would that BEGIN moved up before the 'use'
## it would break Find::Lib, see the other test
BEGIN { $0 = "Renammed"; }
