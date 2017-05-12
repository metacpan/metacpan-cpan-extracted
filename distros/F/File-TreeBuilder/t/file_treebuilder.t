use strict;
use warnings;

use Test::More;

use_ok('File::TreeBuilder', 'build_tree') or exit;
can_ok(__PACKAGE__, 'build_tree');

done_testing();

