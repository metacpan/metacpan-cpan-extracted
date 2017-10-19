# This is a test for a false syntax error produced by this module on
# legitimate input.

use warnings;
use strict;
use FindBin '$Bin';
use Test::More;
use JSON::Parse 'json_file_to_perl';
eval {
    my $json = json_file_to_perl ("$Bin/syntax-error-1.json");
};
note ($@);
ok (! $@);
done_testing ();
