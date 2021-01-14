use warnings;
use strict;

use File::Copy;
use Test::More;

use lib 't/lib';
use Helper qw(:all);

my $file = "$ENV{HOME}/dist-mgr.json.bak";

if (defined $file && -e $file) {
    copy $file, "$ENV{HOME}/dist-mgr.json";
}

ok 1;
done_testing();
