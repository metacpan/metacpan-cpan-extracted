use strict;
use warnings;

use Test::More;

use lib './lib'; # actually use the module, not other versions installed
use_ok 'Geo::Coder::OpenCage';
done_testing();
