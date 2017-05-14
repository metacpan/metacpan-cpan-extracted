#!/usr/bin/perl

# Test for the proper handling of "account" settings.

# $Id$

use strict;
use FindBin qw($Bin);
use lib ("$Bin/../lib");
use Log::Log4perl qw(:easy);
use Test::More;
use File::Which;
use Grid::Request;
use Grid::Request::Test;

Log::Log4perl->init("$Bin/testlogger.conf");

my $qacct = which("qacct");
my $req = Grid::Request::Test->get_test_request();

# Get the configured temporary directory
my $drm = $req->_config()->val($Grid::Request::HTC::config_section, "drm");

if ($drm ne "SGE") {
   plan skip_all => "Test written for SGE. The 'drm' is set to another grid type: $drm.";
}  else {
    if (! defined $qacct) {
       plan skip_all => "Couldn't find qacct in the PATH.";
    } else {
       plan tests => 8;
    }
}

my $account = random_word(8);

my (@ids);
eval {
    $req->command(which("echo"));
    $req->account($account);
    @ids = $req->submit_and_wait();
};
ok(! $@, "No exceptions on submit_and_wait.") or
    Grid::Request::Test->diagnose();

is(scalar(@ids), 1, "Got the correct number of ids.");

my $id = $ids[0];
ok(defined($id) && $id > 0, "Got a valid id.") or
    diag("Invalid id: \"$id\".");

# TODO: From here down, the logic to determine if setting the
# name really worked, is DRM dependent, specifically SGE dependent.

check_output($id, $account);

# Now test an account with 2 words in it
$account = random_word(5) . " " . random_word(5);
my $req2 = Grid::Request::Test->get_test_request();
$req2->account($account);
$req2->command(which("echo"));

my @ids2;
eval {
    @ids2 = $req2->submit_and_wait();
};
ok($@, "Got an error when using an account with whitespace.");
is(scalar(@ids2), 0, "Got an empty number of ids.");

#############################################################################

sub check_output {
    my ($id, $expected_account) = @_;

    # Sometimes there is a delay before data becomes available to qacct.
    if ($id) {
        my $ready = wait_for_qacct($id);
        if (! $ready) {
            print STDERR "Unable to query for job status.\n";
            exit 1;
        }

        open (QACCT, "$qacct -j $id |");
        my @lines = <QACCT>;
        close QACCT;
        ok(scalar(@lines) > 0, "Got valid output from qacct -j $id.");
        @lines = grep { /account/ } @lines;
        is(scalar(@lines), 1, "Correct number of lines matching 'account'.");
        my $account_line = $lines[0];
        $account_line =~ s|^account\s+||;
        chomp($account_line);
        $account_line =~ s/\s+$//;
        
        is($account_line, $expected_account, "account correctly made it to the output.");
    } else {
        # Need to 'fail' the above 3 tests.
        fail("Can't check qacct output because there is no id.");
        fail("Can't check qacct output validity because there is none.");
        fail("Can't check account in the out output because there is none.");
    }
}

# Generate a random word for use as the "account"
sub random_word {
    my $length = shift;
    my $word = "";
    my $_rand;
 
    my @chars = qw(a b c d e f g h i j k l m n o p q r s t u v w x y z - _ 0 1 2 3 4 5 6 7 8 9);
    srand;
 
    for (my $i=0; $i < $length; $i++) {
       $_rand = int(rand scalar(@chars));
       $word .= $chars[$_rand];
    }
    return $word;
}

sub wait_for_qacct {
    my $id = shift;
    sleep 1;
    my $ready = 0;
    for my $attempt qw(1 2 3 4) {
        sleep $attempt;
        system("qacct -j $id 1>/dev/null 2>/dev/null");

        my $exit_value = $? >> 8;
        if ($exit_value == 0) {
            $ready = 1;
            last;
        }
    }
    return $ready;
}
