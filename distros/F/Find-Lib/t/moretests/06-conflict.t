use strict;
use Test::More tests => 3;

## this is potentially conflicting with backward
## except that we're smart enough to detect it
use Find::Lib 'libs', '../mylib', 'mytestlib';
use MyLib a => 1, b => 42+42;

ok $MyLib::imported{'a'};
is $MyLib::imported{'b'}, 84;

