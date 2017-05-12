
use strict;
use warnings;

use Test::More tests => 1;
use FindBin;
use lib "$FindBin::Bin/07_files/lib";

use Example_01;

# This is a bug, TODO make it suck less
local $TODO = "Not sure if this can even be solved. Docs are sub-par and the Sub::Exporter code is a mess";
my $err;
is(
  do {
    local $@;
    my $x = eval { Example_01->test(); q[passed] };
    $err = $@;
    $x;
  },
  'passed',
  'Peculiar grammar messes up in a well defined way'
);
note explain $err;
