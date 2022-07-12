package main;

use 5.018;

use strict;
use warnings;

use Mars;
use Scalar::Util;
use Test::More;

is !false, 1;
is !true, '';
is 0+false, 0;
is 0+true, 1;
is false, 0;
is int!false, 1;
is int!true, 0;
is true, 1;

ok true ne false;

ok Scalar::Util::isdual(!false);
ok Scalar::Util::isdual(!true);
ok Scalar::Util::isdual(false);
ok Scalar::Util::isdual(true);

done_testing;
