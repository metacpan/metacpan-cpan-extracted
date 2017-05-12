# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Genezzo-Contrib-Clustered.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 23;
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

# creates database and initilizes undo for test in second script
# verifies that without G:C:C synced changes are not rolled back

my $dbinit   = 1;
my $gnz_home = File::Spec->catdir("t", "gnz_home");
rmtree($gnz_home, 1, 1);
#mkpath($gnz_home, 1, 0755);


{
    my $fb = Genezzo::GenDBI->new(exe => $0, 
                             gnz_home => $gnz_home, 
                             dbinit => $dbinit,
                             dbsize => "1M");

    unless (defined($fb))
    {
        fail ("could not create database");
        exit 1;
    }
    ok(1);
    $dbinit = 0;

}

{
    use Genezzo::Util;

    my $fb = Genezzo::GenDBI->new(exe => $0, 
                             gnz_home => $gnz_home, 
                             dbinit => $dbinit);

    unless (defined($fb))
    {
        fail ("could not find database");
        exit 1;
    }
    ok(1);
    $dbinit = 0;

}

{
    use Genezzo::Contrib::Clustered::PrepUndo;
    use Genezzo::Havok;
    use Genezzo::Havok::SysHook;

    ok(Genezzo::Contrib::Clustered::PrepUndo::prepareUndo(
	gnz_home => $gnz_home,
	number_of_processes => 3,
    	undo_blocks_per_process => 20));
}


{
    use Genezzo::Util;
    use Genezzo::Havok;
    use Genezzo::Contrib::Clustered::PrepUndo;
    use Genezzo::Havok;
    use Genezzo::Havok::SysHook;

    my $dbh = Genezzo::GenDBI->connect($gnz_home, "NOUSER", "NOPASSWORD");
#    my $dbh = Genezzo::GenDBI->new(exe => $0, gnz_home => $gnz_home,  defs => {_QUIETWHISPER=>0});


    unless (defined($dbh))
    {
        fail ("could not find database");
        exit 1;
    }
    ok(1);

    ok($dbh->do("startup"));

    my $bigSQL = Genezzo::Havok::MakeSQL(); # get the string

    my @bigarr = split(/\n/, $bigSQL);
#    greet @bigarr;

    for my $lin (@bigarr)
    {
#        print $lin, "\n";

        if ($lin =~ m/commit/) 
        {
            ok(1); # stop at commit
            last;
        }

        next # ignore comments (REMarks)
            if ($lin =~ m/REM/);
        
        next
            unless (length($lin));

        $lin =~ s/;(\s*)$//; # remove trailing semi
        
        fail ("could not create table havok")
            unless ($dbh->do($lin));
    }

    ok ($dbh->do("commit"));

    $bigSQL = Genezzo::Havok::SysHook::MakeSQL(); # get the string

    @bigarr = split(/\n/, $bigSQL);
#    greet @bigarr;

    for my $lin (@bigarr)
    {
#        print $lin, "\n";

        if ($lin =~ m/commit/) 
        {
            ok(1); # stop at commit
            last;
        }

        next # ignore comments (REMarks)
            if ($lin =~ m/REM/);
        
        next
            unless (length($lin));

        $lin =~ s/;(\s*)$//; # remove trailing semi
        
        fail ("could not create table syshook")
            unless ($dbh->do($lin));
    }

    ok ($dbh->do("commit"));
}

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
    # here test that without Genezzo::Contrib::Clustered sync-ed data
    # is not rolled back
    ok(0,"failed to create t1")
        unless($dbh->do("create table t1(tid int, val char)"));

    ok(0,"failed to insert into t1")
        unless($dbh->do("insert into t1 values (1, 'initialized')"));

    ok(0,"failed commit ceate t1")
        unless($dbh->do("commit"));

    ok(0,"failed update t1 to second")
        unless($dbh->do("update t1 set val='second'"));

    ok(0,"failed sync")
        unless($dbh->do("sync"));

    ok(0,"failed rollback")
        unless($dbh->do("rollback"));

    # now expect to find 'second', since it was sync-ed
    my $sth = $dbh->prepare("select val from t1");

    ok(0,"prepare select failed") unless defined($sth);

    ok(0,"execute failed")
        unless $sth->execute();

    my $row = $sth->fetchrow_hashref();

    ok(0,"row not found")
        unless defined($row);

    if($row->{val} eq "second"){
        ok(1);
    }else{
        ok(0,"expected 'second', found $row->{val}");
    }

    my $bigSQL = Genezzo::Contrib::Clustered::PrepUndo::MakeSQL(); # get the string

    my @bigarr = split(/\n/, $bigSQL);
    greet @bigarr;

    for my $lin (@bigarr)
    {
#        print $lin, "\n";

        if ($lin =~ m/commit/) 
        {
            ok(1); # stop at commit
            last;
        }

        next # ignore comments (REMarks)
            if ($lin =~ m/REM/);
        
        next
            unless (length($lin));

        $lin =~ s/;(\s*)$//; # remove trailing semi
        
        print $lin, "\n";

#        my @ll2 = split(//, $lin);
        $lin =~ s/;//; # NO SEMICOLONS !!??
        ok ($dbh->do($lin));
    }

    ok ($dbh->do("commit"));
    ok($dbh->do("shutdown"));
}
