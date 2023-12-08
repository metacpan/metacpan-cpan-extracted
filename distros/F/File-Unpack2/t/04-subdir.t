#!perl -T

use Test::More;
use FindBin;
BEGIN { unshift @INC, "$1/../blib/lib" if $FindBin::Bin =~ m{(.*)} };
use File::Unpack2;
use File::Temp;

my $have_unzip =  -f '/usr/bin/unzip';
plan tests => $have_unzip ? 5 : 4;

my $testdir = File::Temp::tempdir("FU_04_XXXXX", TMPDIR => 1, CLEANUP => 1);

my $u = File::Unpack2->new(destdir => $testdir, verbose => 0, logfile => '/dev/stdout');
$u->exclude(vcs => 1, add => ['*.t']);
ok(-d "t/data", "have t/data before unpacking. test is useless without");
ok(-f "t/04-subdir.t", "have t/04-subdir.t before unpacking. calling unpack now");
$u->unpack("t");
ok(-d "$testdir/data", "have $testdir/data after unpacking");
ok(-d "$testdir/data/empty.odt._", "unzipped $testdir/data/empty.odt._") if $have_unzip;
diag("/usr/bin/unzip not found, not tested")                         unless $have_unzip;
ok(!-f "$testdir/04-subdir.t", "have ignored *.t after unpacking");


