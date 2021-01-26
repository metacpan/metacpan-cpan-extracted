# This is a test for a false syntax error produced by this module on
# legitimate input.

use FindBin '$Bin';
use lib "$Bin";
use JPT;

eval {
    my $json = read_json ("$Bin/syntax-error-1.json");
};
note ($@);
ok (! $@);
done_testing ();
