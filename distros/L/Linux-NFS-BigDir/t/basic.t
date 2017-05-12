use warnings;
use strict;
use Test::More tests => 2;

my $mod = 'Linux::NFS::BigDir';
require_ok($mod);
can_ok($mod, qw(getdents getdents_safe));
