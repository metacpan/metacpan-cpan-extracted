# This tests the "max depth" feature added so that the JSON Test Suite
# silly test with 100,000 open { and [ doesn't cause an error.

use FindBin '$Bin';
use lib "$Bin";
use JPT;

my $jp = JSON::Parse->new ();

# Test setting to "one" so that two [[ will cause an error.

$jp->set_max_depth (1);
my $ok = eval {
    $jp->run ('[[[["should fail due to depth"]]]]');
    1;
};
ok (! $ok, "fails to parse array when max depth is set to 1");
my $md = $jp->get_max_depth ();
cmp_ok ($md, '==', 1, "got back the max depth");

# Test setting back to default using zero argument.

$jp->set_max_depth (0);
my $mdd = $jp->get_max_depth ();
cmp_ok ($mdd, '==', 10000, "got back the default max depth");

done_testing ();
