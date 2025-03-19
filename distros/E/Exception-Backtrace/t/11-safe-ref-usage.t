use strict;
use warnings;
use Test::More;
use Test::Warnings;

use Exception::Backtrace;

local $_;
Exception::Backtrace::get_backtrace_string_pp($_);
Exception::Backtrace::get_backtrace($_);
Exception::Backtrace::safe_wrap_exception(\$_);

ok 1;
done_testing;
