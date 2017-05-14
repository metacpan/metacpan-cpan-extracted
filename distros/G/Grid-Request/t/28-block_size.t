#!/usr/bin/perl

# $Id$

use strict;
use FindBin qw($Bin);
use File::Which;
use lib ("$Bin/../lib");
use Log::Log4perl qw(:easy);
use Test::More tests => 13;
use Grid::Request;
use Grid::Request::Test;

Log::Log4perl->init("$Bin/testlogger.conf");

my $TEST = undef;

my $req = Grid::Request::Test->get_test_request();
$req->command(which("echo"));

my @arg_array = (1, 2, 3);
$req->add_param('$(Name)', \@arg_array, "ARRAY");

read_block_size($req);
write_block_size($req);
positive_integer($req);
numeric_enforcement($req);

# Test integer enforcement
undef $@;
eval {
    $req->block_size(100.1);
};
ok(defined $@, "Caught error when attempting a positive number, but not an integer.");

my $code_ref = sub {
    my $cmd_obj = shift;
    my $size = shift;
    $TEST = "FLAG";
    return 1000;
};

$req->block_size($code_ref);
# Test 7
ok(ref $req->block_size() eq "CODE", "Able to set block size to a code ref.");

# Test 8
# $TEST should not be defined yet
ok(! defined $TEST, "Code ref did not run prematurely");

eval {
    my @ids = $req->submit();
};

ok(! $@, "No exception when submitting job via submit().") or
    Grid::Request::Test->diagnose();

# Now it should be set.
# Test 9
is($TEST, "FLAG", "Code reference for block size ran successfully.");

bad_code_refs();

###########################################################################

# Test the positive integer enforcement
sub positive_integer {
    my $req = shift;
    undef $@;
    eval {
        $req->block_size(-2000);
    };
    ok(defined $@, "Caught error when attempting a negative block size.");
}

sub bad_code_refs {
    # Need to test that bad code refs cause errors...
    my $bad_code_ref = sub {};
    my $req2 = Grid::Request::Test->get_test_request();
    $req2->command(which("echo"));
    $req2->add_param('$(Name)', \@arg_array, "ARRAY");
    $req2->block_size($bad_code_ref);
    undef $@;

    eval {
        # This call should trigger an exception because of the bad
        # code ref that doesn't return anything...
        $req2->submit();
    };

    ok(defined $@, "The submission with a bad block_size coderef caused an error.");
    ok($@ =~ m/block/i && $@ =~ m/size/i, "Error relates to block size.");
}

sub numeric_enforcement {
    my $req = shift;

    # Test the numeric enforcement
    undef $@;
    eval {
        $req->block_size("abc");
    };
    ok(defined $@, "Caught error when attempting a non-numeric block size.");
}

sub read_block_size {
    my $req = shift;
    my $block_size = $req->block_size();

    ok(defined $block_size, "Request has a defined block size.");

    ok(defined $block_size, "Request has a defined block size.");
    is($block_size, 100, "Request has correct default block size.");
}

sub write_block_size {
    my $req = shift;
    # Now try setting the block size.
    my $new_block_size = 2000;
    $req->block_size($new_block_size);
    my $block_size = $req->block_size();

    is($block_size, $new_block_size, "Setting a new block size succeeded.");
}
