use strict;
use warnings;

use lib 't/lib';

use Test::More      0.88                            ;
use Test::Exception 0.31                            ;


eval "use Pod::Coverage";
if ($@)
{
    plan skip_all => "Pod::Coverage required for testing pod coverage export exposure";
}


# See t/pod_coverage.t.  I really would prefer to keep this test with the other, but then it whines
# about redefining DEBUG (see t/redefine.t), so the easiest thing to do was just put it in a
# separate test file.

my $pc = Pod::Coverage->new(package => 'WithPodDebugOn');               # uses t/lib/WithPodDebugOn.pm
if (defined $pc->coverage)
{
    is scalar($pc->naked), 0, "Pod::Coverage doesn't count Debuggit routines as naked"
            or diag("showing as naked: " . join(', ', $pc->naked));
}
else
{
    diag("can't determine coverage because: ", $pc->why_unrated);
    fail;
}


done_testing;
