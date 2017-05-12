# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Genezzo-Contrib-Clustered.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 5;
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
# adds committed change to verify it persists across startup recovery.

my $dbinit   = 0;
my $gnz_home = File::Spec->catdir("t", "gnz_home");
#rmtree($gnz_home, 1, 1);
#mkpath($gnz_home, 1, 0755);

{
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

    ok(0,"failed to create t2")
        unless($dbh->do("create table t2(tid int, val char)"));

    ok(0,"failed to insert into t2")
        unless($dbh->do("insert into t2 values (1, 'initialized')"));

    ok(0,"failed commit ceate t2")
        unless($dbh->do("commit"));

    # omitting shutdown

    ok(1);
}
