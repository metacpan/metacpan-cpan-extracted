use strict;
use Test::More;

use IO::File::WithPath;
use FindBin;
use File::Spec;
my $script_path = File::Spec->rel2abs("$FindBin::Bin/02_regression.t");

my $io = IO::File::WithPath->new($script_path);

# hmm, internal impl check
is ${*$io}{'IO::File::WithPath'} => $script_path;

done_testing();


