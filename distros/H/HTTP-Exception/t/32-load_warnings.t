use strict;
use warnings;

use Test::More tests => 1;
use Test::NoWarnings;

# "emulating" warnings under mod_perl
eval "use HTTP::Exception";
eval "use HTTP::Exception";
