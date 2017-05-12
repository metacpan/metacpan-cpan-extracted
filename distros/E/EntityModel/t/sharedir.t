use strict;
use warnings;

use Test::More tests => 2;
use File::ShareDir ':ALL';

ok(my $base_dir = dist_dir('EntityModel'), 'get distribution directory');
note "sharedir = $base_dir";
ok(-d $base_dir, 'directory exists');

