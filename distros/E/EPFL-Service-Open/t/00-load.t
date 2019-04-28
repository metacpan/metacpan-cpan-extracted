# Original work (c) ECOLE POLYTECHNIQUE FEDERALE DE LAUSANNE, Switzerland, VPSI, 2018.
# Modified work (c) William Belle, 2018-2019.
# See the LICENSE file for more details.

use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
  use_ok('EPFL::Service::Open') || print "Bail out!\n";
}

diag("Testing EPFL::Service::Open $EPFL::Service::Open::VERSION, Perl $], $^X");
