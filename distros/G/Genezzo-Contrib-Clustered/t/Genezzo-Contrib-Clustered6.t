# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Genezzo-Contrib-Clustered.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 7;
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
# adds large committed and rolled back rows
# pads undo blocks to test multi-undo block commit and rollback

my $dbinit   = 0;
my $gnz_home = File::Spec->catdir("t", "gnz_home");
#rmtree($gnz_home, 1, 1);
#mkpath($gnz_home, 1, 0755);

{
    $Genezzo::Contrib::Clustered::pad_undo = 1;

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

    ok(0,"failed to create t3")
        unless($dbh->do("create table t3(tid int, val char)"));

    my $bigrow = 'Z' x ($Genezzo::Block::Std::DEFBLOCKSIZE/5);

    my $numrows = 30;
    my $cnt;
    for($cnt = 0; $cnt < $numrows; $cnt++){
	#print STDERR "inserting row $cnt\n";
        ok(0,"failed to insert into t3")		
            unless($dbh->do("insert into t3 values ($cnt, '$bigrow')"));
    }

    ok(0,"failed commit create t3")
        unless($dbh->do("commit"));

    my $sth = $dbh->prepare("select count(*) from t3");

    ok(0,"prepare select failed") unless defined($sth);

    ok(0,"execute failed")
        unless $sth->execute();

    my $row = $sth->fetchrow_arrayref();

    ok(0,"row not found")
        unless defined($row);

    if($row->[0] == $numrows){
        ok(1);
    }else{
        ok(0,"expected $numrows, found $row->[0]");
    }

    for($cnt = $numrows; $cnt < $numrows*2; $cnt++){
	#print STDERR "inserting row $cnt\n";
        ok(0,"failed to insert into t3")		
            unless($dbh->do("insert into t3 values ($cnt, '$bigrow')"));
    }

    #$Genezzo::Util::QUIETWHISPER = 0;

    ok(0,"failed rollback t3")
        unless($dbh->do("rollback"));

    #$Genezzo::Util::QUIETWHISPER = 1;

    $sth = $dbh->prepare("select count(*) from t3");

    ok(0,"prepare select failed") unless defined($sth);

    ok(0,"execute failed")
        unless $sth->execute();

    $row = $sth->fetchrow_arrayref();

    ok(0,"row not found")
        unless defined($row);

    if($row->[0] == $numrows){
        ok(1);
    }else{
        ok(0,"expected $numrows, found $row->[0]");
    }

    ok(0,"failed rollback 2")
        unless($dbh->do("rollback"));

    ok(0,"failed rollback 3")
        unless($dbh->do("rollback"));

    ok(1);
}
