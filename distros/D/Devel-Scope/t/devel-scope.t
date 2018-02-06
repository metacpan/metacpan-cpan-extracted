#!perl
use 5.006;
use strict;
use warnings;

use Capture::Tiny ':all';
use FindBin qw($Bin);
use Test::More;

use Devel::Scope qw( debug );

debug("ERROR! Testing Devel::Scope::debug from main");
$ENV{'DEVEL_SCOPE_DEPTH'} = 1;
debug("OK! Testing Devel::Scope::debug from main");

my $fixture = "$Bin/devel-scope.fixture";
ok(-f $fixture, "Fixture $fixture exists");
my ($bad_env) = capture_merged {
    system("DEVEL_SCOPE_DEBUG=3 perl $fixture");
};
ok($bad_env =~ m|Invalid Devel::Scope env variable|s, "Caught invalid environmental variable")
    or diag("Got: $bad_env");

pass("Running: DEVEL_SCOPE_DEPTH=0 perl $fixture");
my ($level0) = capture_merged {
    system("DEVEL_SCOPE_DEPTH=0 perl $fixture");
};
ok($level0 =~ m|0:Main-Block|, "Got 0:Main-Block") or diag("Got: $level0");
ok($level0 !~ m|1:Main-Block|, "Did not get 1:Main-Block") or diag("Got: $level0");

pass("Running: DEVEL_SCOPE_DEPTH=1 perl $fixture");
my ($level1) = capture_merged {
    system("DEVEL_SCOPE_DEPTH=1 perl $fixture");
};

ok($level1 =~ m|0:Main-Block|, "Got 0:Main-Block")         or diag("Got:\n $level1");
ok($level1 =~ m|1:Main-Block|, "Got 1:Main-Block")         or diag("Got:\n $level1");
ok($level1 =~ m|1:Foo-Block|,  "Got 1:Foo-Begin")          or diag("Got:\n $level1");
ok($level1 =~ m|1:Foo-Block|,  "Got 1:Foo-Block")          or diag("Got:\n $level1");
ok($level1 =~ m|1:Foo-Block|,  "Got 1:Foo-End")            or diag("Got:\n $level1");
ok($level1 !~ m|2:Main-Block|, "Did not get 2:Main-Block") or diag("Got:\n $level1");
ok($level1 !~ m| 2:|, "Did not get any 2:")                or diag("Got:\n $level1");

pass("Running: DEVEL_SCOPE_DEPTH=2 perl $fixture");
my ($level2) = capture_merged {
    system("DEVEL_SCOPE_DEPTH=2 perl $fixture");
};
ok($level2 !~ m| 3:|, "Did not get any 3:")                or diag("Got:\n $level2");

pass("Running: DEVEL_SCOPE_DEPTH=3 perl $fixture");
my ($level3) = capture_merged {
    system("DEVEL_SCOPE_DEPTH=3 perl $fixture");
};
ok($level3 !~ m| 4:|, "Did not get any 4:")                or diag("Got:\n $level3");

pass("Running: DEVEL_SCOPE_DEPTH=5 perl $fixture");
my ($level5) = capture_merged {
    system("DEVEL_SCOPE_DEPTH=5 perl $fixture");
};
pass("All output:\n$level5");

done_testing();
1;
