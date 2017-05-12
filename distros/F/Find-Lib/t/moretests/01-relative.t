use strict;
use Test::More tests => 3;

use Find::Lib '../mylib', 'mytestlib';
use MyLib a => 1, b => 42+42;

ok $MyLib::imported{'a'};
is $MyLib::imported{'b'}, 84;
