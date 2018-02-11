#!perl
use 5.006;
use strict;
use warnings;

use Capture::Tiny ':all';
use FindBin qw($Bin);
use Test::More;

use Devel::Scope qw( debug debug_disable debug_enable );

note("Testing debug from main via DEVEL_SCOPE_DEPTH environmental variable");
debug("ERROR! Testing Devel::Scope::debug from main");
$ENV{'DEVEL_SCOPE_DEPTH'} = 1;
debug("OK! Testing Devel::Scope::debug from main");

note("Testing debug from main via debug_disable and debug_enable methods");
note("Running debug_disable - there should be no debug line after this line.");
debug_disable();
debug("ERROR! Testing Devel::Scope::debug from main");
note("Running debug_enable(1)");
debug_enable(1);
debug("OK! Testing Devel::Scope::debug from main");

test_from_subroutine();

my $fixture = "$Bin/devel-scope.fixture";
ok(-f $fixture, "Fixture $fixture exists");
my ($bad_env) = do {
    local $ENV{DEVEL_SCOPE_DEBUG} = 3;
    run_fixture();
};
ok($bad_env =~ m|Invalid Devel::Scope env variable|s, "Caught invalid environmental variable")
    or diag("Got: $bad_env");

my $level0 = run_fixture(0);
ok($level0 =~ m|0:Main-Block|, "Got 0:Main-Block") or diag("Got: $level0");
ok($level0 !~ m|1:Main-Block|, "Did not get 1:Main-Block") or diag("Got: $level0");

my $level1 = run_fixture(1);
ok($level1 =~ m|0:Main-Block|, "Got 0:Main-Block")         or diag("Got:\n $level1");
ok($level1 =~ m|1:Main-Block|, "Got 1:Main-Block")         or diag("Got:\n $level1");
ok($level1 =~ m|1:Foo-Block|,  "Got 1:Foo-Begin")          or diag("Got:\n $level1");
ok($level1 =~ m|1:Foo-Block|,  "Got 1:Foo-Block")          or diag("Got:\n $level1");
ok($level1 =~ m|1:Foo-Block|,  "Got 1:Foo-End")            or diag("Got:\n $level1");
ok($level1 !~ m|2:Main-Block|, "Did not get 2:Main-Block") or diag("Got:\n $level1");
ok($level1 !~ m| 2:|, "Did not get any 2:")                or diag("Got:\n $level1");

my $level2 = run_fixture(2);
ok($level2 !~ m| 3:|, "Did not get any 3:")                or diag("Got:\n $level2");

my $level3 = run_fixture(3);
ok($level3 !~ m| 4:|, "Did not get any 4:")                or diag("Got:\n $level3");

my $level5 = run_fixture(5);
pass("All output:\n$level5");

done_testing();

sub run_fixture {
    my ($scope_depth) = @_;
    local %ENV = %ENV;
    if ( defined $scope_depth ) {
        $ENV{DEVEL_SCOPE_DEPTH} = $scope_depth;
    } else {
        delete $ENV{DEVEL_SCOPE_DEPTH};
    }
    my $env_desc = join ' ', map { "$_=" . $ENV{$_} } grep { m|^DEVEL_SCOPE_| } keys %ENV;
    pass("Running: $env_desc $^X $fixture");
    my $output = capture_merged {
        system($^X, $fixture);
    };
    return $output;
}

sub test_from_subroutine {
    note("Testing debug from subroutine");
    note("Unsetting DEVEL_SCOPE_DEPTH - there should be no debug message right after this line.");
    delete $ENV{'DEVEL_SCOPE_DEPTH'};
    debug("ERROR! Testing Devel::Scope::debug from subroutine");
    note("Setting DEVEL_SCOPE_DEPTH=1");
    $ENV{'DEVEL_SCOPE_DEPTH'} = 1;
    debug("OK! Testing Devel::Scope::debug from subroutine");
}

1;
