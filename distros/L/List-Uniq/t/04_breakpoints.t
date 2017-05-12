#
# $Id: 04_breakpoints.t 4496 2010-06-18 15:19:43Z james $
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
