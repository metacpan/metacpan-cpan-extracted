use strict;
use warnings;

use Test::More tests => 3;
use Linux::Prctl qw(:constants :functions);
use File::Basename;

my $name = basename($^X);
is(get_name, $name, "Name initially should be $name");
is(set_name("p3rl"), 0, "Setting name to p3rl");
is(get_name, "p3rl", "Name should now be p3rl");
