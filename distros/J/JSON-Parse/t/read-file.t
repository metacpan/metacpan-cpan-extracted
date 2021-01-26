# This tests reading a file using the two different names of the
# routine.

use FindBin '$Bin';
use lib "$Bin";
use JPT;

my $p = json_file_to_perl ("$Bin/test.json");
ok ($p->{distribution} eq 'Algorithm-NGram');
my $q = read_json ("$Bin/test.json");
ok ($q->{distribution} eq 'Algorithm-NGram');
done_testing ();
