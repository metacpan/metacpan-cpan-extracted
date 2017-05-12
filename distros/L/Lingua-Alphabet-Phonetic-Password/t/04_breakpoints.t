#
# $Id: 04_breakpoints.t 141 2004-11-30 19:06:15Z james $
#

use strict;
use warnings;

use Test::More;
eval "use Test::NoBreakpoints 0.10";
plan skip_all => "Test::NoBreakpoints 0.10 required for testing" if $@;
plan 'no_plan';
all_files_no_brkpts_ok();

#
# EOF
