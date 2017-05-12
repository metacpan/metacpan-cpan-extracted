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


# Pod::Coverage had trouble with our original take on exporting DEBUG and debuggit--it kept marking
# them as naked subroutines of the importing package.  This test insures that that problem has been
# resolved.

my $pc = Pod::Coverage->new(package => 'WithPod');                      # uses t/lib/WithPod.pm
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
