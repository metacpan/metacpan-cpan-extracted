use Test::More tests => 2;
BEGIN { $^W = 1 }
use strict;

my $module = 'List::Extract';

require_ok($module);
use_ok($module);
