use Test::More;
use strict;
use warnings;

my $lib;
BEGIN { $lib = -d 't' ? 't/lib' : 'test/lib' }

use lib $lib;
use TestFileShare1;

pass 'Works when $_ is readonly';

done_testing;
