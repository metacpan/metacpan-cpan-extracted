use strict;
use Test::More tests => 3;

chdir "/";

use Find::Lib '../mylib';
use MyLib a => 1, b => 42;

ok $MyLib::imported{'a'};
is $MyLib::imported{'b'}, 42;

BEGIN { chdir '/tmp' };
