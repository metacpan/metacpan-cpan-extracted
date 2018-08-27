use strict;
use warnings;
use FindBin qw/$RealBin/;

use Test::More tests => 1;

use lib "$RealBin/../lib";
use_ok 'File::Generator';
