# Test the generation of literals as single objects, i.e. "true" on
# its own as a single thing, not within an array or an object.

use FindBin '$Bin';
use lib "$Bin";
use JCT;
use JSON::Create::Bool;

my $single = true;
my $sj = create_json ($single);
is ($sj, 'true', "Single true to JSON ok");
my $singlef = false;
my $sjf = create_json ($singlef);
is ($sjf, 'false', "Single false to JSON ok");
my $singlen = undef;
my $sjn = create_json ($singlen);
is ($sjn, 'null', "Single undef to JSON null ok");

done_testing ();
