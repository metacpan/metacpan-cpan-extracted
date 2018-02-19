#!perl
use 5.006;
use strict;
use warnings;

use Capture::Tiny ':all';
use FindBin qw($Bin);
use Test::More;

BEGIN {
    local $ENV{DEVEL_SCOPE_DEBUG} = 3;

    eval 'require Devel::Scope;';
    my $begin_bad_env = $@;
    if (defined $begin_bad_env) {
        pass("Caught invalid environmental variable.");
        note("Message: $begin_bad_env");
    } else {
        fail("Should have caught invalid environmental variable.");
    }

    note("Removing Devel/Scope.pm from \%INC so we can reload.");
    delete $INC{'Devel/Scope.pm'};

    note("Removing invalid key DEVEL_SCOPE_DEBUG from \%ENV.");
    delete $ENV{DEVEL_SCOPE_DEBUG};

    note("Turning off warnings");
    $SIG{__WARN__} = sub { my $warn = shift; return; };

    eval 'use Devel::Scope qw( debug debug_enable debug_disable )';
    BAIL_OUT($@) if $@;
    pass("Reloaded Devel::Scope");

    note("Turning on warnings");
    $SIG{__WARN__} = sub { my $warn = shift; warn $warn; };

    pass("End of BEGIN tests");
};

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

eval {
    debug("OK! Debugging from within an eval");
    sleep 1;
    debug("OK! Debugging from within an eval [ slow statement - notice the stars! ]");
};

my $level0 = run_fixture(0);
match_all( $level0, qw(
           0:Main-Block
));
match_none($level0, qw(
           1:Main-Block
));

my $level1 = run_fixture(1);
match_all( $level1, qw(
           0:Main-Block
           1:Main-Block
           1:Foo-Begin
           1:Foo-Block
           1:Foo-End
));
match_none($level1, qw(
           2:Main-Block
           2:
));

my $level2 = run_fixture(2);
match_none($level2, qw(
           3:
));

my $level3 = run_fixture(3);
match_none($level3, qw(
           4:
));

my $level5 = run_fixture(5);
pass("All output:\n$level5");

unless( Test::More->builder->is_passing ) {
    note("Adding all output to a fail() block so it shows up in Test Report.");
    fail("All output:\n$level5");
}

done_testing();

sub _match {
    my ($sense, $txt, @strings) = @_;

    for my $string (@strings) {
        my $re = qr|\Q$string\E|s; # Multi-line match of literal string
        if ($sense) {
            # Match
            ok( $txt =~ $re, "Got $string") or diag("Got:\n$txt");
        } else {
            # Do not match
            ok( $txt !~ $re, "Did not get $string") or diag("Got:\n$txt");             }
    }
}

sub match_all {
    my ($txt, @strings) = @_;

    _match(1,$txt,@strings);
}

sub match_none {
    my ($txt, @strings) = @_;

    _match(0,$txt,@strings);
}

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
