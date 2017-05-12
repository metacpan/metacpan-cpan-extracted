# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Genezzo-Contrib-Clustered.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 6;
BEGIN { use_ok('Genezzo::Contrib::Clustered') };
BEGIN { use_ok('Genezzo::Contrib::Clustered::PrepUndo') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

use strict;
use warnings;
use File::Path;
use File::Spec;

my $TEST_COUNT;

$TEST_COUNT = 2;

# uses database initialized in previous test
# verifies uncommited change is rolled back when block is read by different PID

my $dbinit   = 0;
my $gnz_home = File::Spec->catdir("t", "gnz_home");
#rmtree($gnz_home, 1, 1);
#mkpath($gnz_home, 1, 0755);

{
    # sets PID so different process will recover block
    $Genezzo::Contrib::Clustered::starting_pid = 2;

    use Genezzo::Util;

    my $dbh = Genezzo::GenDBI->connect($gnz_home, "NOUSER", "NOPASSWORD");
#    my $dbh = Genezzo::GenDBI->new(exe => $0, gnz_home => $gnz_home,  defs => {_QUIETWHISPER=>0});


    unless (defined($dbh))
    {
        fail ("could not find database");
        exit 1;
    }
    ok(1);

    ok($dbh->do("startup"));

    my $sth = $dbh->prepare("select val from t2");

    ok(0,"prepare select failed") unless defined($sth);

    ok(0,"execute failed")
        unless $sth->execute();

    my $row = $sth->fetchrow_hashref();

    ok(0,"row not found")
        unless defined($row);

    if($row->{val} eq "initialized"){
        ok(1);
    }else{
        ok(0,"expected 'initialized', found $row->{val}");
    }

    # omitting shutdown
    ok(1);
}
