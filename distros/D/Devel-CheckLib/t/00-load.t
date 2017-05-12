use strict;
# compatible use warnings
BEGIN{ if (not $] < 5.006) { require warnings; warnings->import } }

use Test::More tests => 1;

eval "use Devel::CheckLib";
ok($@ =~ /Couldn't find your C compiler/ || !$@, "Can load module");
