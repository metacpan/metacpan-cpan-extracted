use warnings;
use strict;

# At the moment this only tests for compilability.

use Test::More tests => 1;
BEGIN { use_ok('Directory::Diff::Copy') };
use Directory::Diff::Copy qw/copy_diff_only/;

