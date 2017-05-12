use strict;
use warnings;
use Test::More tests => 1;

ok eval { symlink '', ''; 1 }, "$^O has symlinks";
