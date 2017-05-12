use strict;
use warnings;
use Test::More;

plan tests => 1;
ok( eval { require Mail::DKIM::Iterator },"loaded");

