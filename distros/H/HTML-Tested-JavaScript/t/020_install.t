use strict;
use warnings FATAL => 'all';

use File::Basename qw(dirname);
use File::Temp qw(tempdir);
use Test::More tests => 2;

my $td = tempdir("/tmp/htj-XXXXXXX", CLEANUP => 1);
chdir(dirname($0) . "/../");
my $cmd = "make install PREFIX=$td 2>&1 > /dev/null";
is(system($cmd), 0);
ok(-f "$td/local/share/libhtml-tested-javascript-perl/serializer.js");
