#!/usr/bin/perl

use strict;
use FindBin;
use lib $FindBin::Bin;
use Test;
BEGIN { plan tests => 3 }

require Filter::Macro;
ok(Filter::Macro->VERSION);

use my_macro;
ok(1/2, 0);
ok(__LINE__, 14);
