use strict;
use warnings;
use Test::More;

eval "use Test::Vars; 1"
    or plan skip_all => 'Test::Vars required';

all_vars_ok();
