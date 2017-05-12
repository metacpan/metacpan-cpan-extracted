#!/usr/bin/perl

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

my $project = Grid::Request::Test->get_test_project();

my $qacct = which("qacct");
if (! defined $qacct) {
   plan skip_all => "Couldn't find qacct in the PATH.";
} else {
   plan tests => 7;
}

my $account = random_word(8);

my ($htc, @ids);
eval {
    $htc = Grid::Request->new( project => $project );
    $htc->command("/bin/echo");
    $htc->account($account);
    @ids = $htc->submit_and_wait();
};

is(scalar(@ids), 1, "Got the correct number of ids.");

my $id = $ids[0];
diag("Id $id.");
ok($id > 0, "Got a valid id.");

check_output($id, $account);

# Now test a project with 2 words in it
$account = random_word(5) . " " . random_word(5);
my $htc2 = Grid::Request->new( project => $project );
$htc2->account($account);
$htc2->command("/bin/echo");

my @ids2;
eval {
    @ids2 = $htc2->submit_and_wait();
};
ok(length($@)>0, "Got an error when using an account with whitespace.");
is(scalar(@ids2), 0, "Got an empty number of ids.");

#############################################################################

sub check_output {
    my ($id, $expected_account) = @_;

    # sometimes there is a delay before data becomes available to qacct.
    sleep 3;

    open (QACCT, "$qacct -j $id |");
    my @lines = <QACCT>;
    close QACCT;
    ok(@lines > 0, "Got valid output from qacct -j $id.");
    @lines = grep { /account/ } @lines;
    is(scalar(@lines), 1, "Correct number of lines matching 'account'.");
    my $account_line = $lines[0];
    $account_line =~ s|^account\s+||;
    chomp($account_line);
    $account_line =~ s/\s+$//;
    
    is($account_line, $expected_account, "account correctly made it to the output.");
}

# Generate a random word for use as the "account"
sub random_word {
    my $word;
    my $_rand;
    my $length = shift;
 
    my @chars = split(" ",
    "a b c d e f g h i j k l m n o
     p q r s t u v w x y z - _ % #
     0 1 2 3 4 5 6 7 8 9");

    srand;
 
    for (my $i=0; $i <= $length; $i++) {
       $_rand = int(rand 41);
       $word .= $chars[$_rand];
    }
    return $word;
}
