# This was a bug in reading long strings.

# https://github.com/benkasminbullock/JSON-Parse/issues/44

use FindBin '$Bin';
use lib "$Bin";
use JPT;
my $in = read_json ("$Bin/string-bug-44.json");
cmp_ok (length ($in->{x}), '==', 4080, "Length as expected");
done_testing ();
