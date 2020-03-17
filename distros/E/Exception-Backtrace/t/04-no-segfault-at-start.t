use strict;
use warnings;
use Test::More;
use Test::Warnings;

use Exception::Backtrace;

Exception::Backtrace::install();

eval "use abc;";
ok $@, "it does not dies";

done_testing;
