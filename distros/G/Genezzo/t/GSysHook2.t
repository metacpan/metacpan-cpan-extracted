# Copyright (c) 2003-2007 Jeffrey I Cohen.  All rights reserved.
#
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl GSysHook2.t

# NOTE: the magic_writeblock hook is for testing purposes only, and
# should *not* be installed on production databases.

# NOTE: This test is meant to be run immediately after GSysHook1.t,
# which initializes the database with the correct hooks and test table
# data.  It will not work standalone.  

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 4;
BEGIN { use_ok('Genezzo::GenDBI') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

use strict;
use warnings;
use File::Path;
use File::Spec;

my $TEST_COUNT;

$TEST_COUNT = 1;

# creates database and initilizes undo for test in second script

my $dbinit   = 1;
my $gnz_home = File::Spec->catdir("t", "gnz_home");
#rmtree($gnz_home, 1, 1);
#mkpath($gnz_home, 1, 0755);


my @basic_stuff = ('nothing to see here',
                   'or here',
                   'special: my block number is __MAGIC_BLOCK_NUM__',
                   'big finish');



{
    use Genezzo::Util;
    use Genezzo::Havok;
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

    ok(0,"failed to update t1")
        unless($dbh->do("update t1 set val = \'look at this\' where val =~ m/or here/"));

    ok ($dbh->do("commit"));

    $basic_stuff[1] = 'look at this';

    ok(0,"failed commit create t1")
        unless($dbh->do("commit"));

    my $sth = $dbh->prepare("select val from t1");

    ok(0,"prepare select failed") unless defined($sth);
    
    ok(0,"execute failed")
        unless $sth->execute();
    
    for my $vv (@basic_stuff)
    {
        
        my @row1 = $sth->fetchrow_array();

#        fail("mismatch")
#            unless ($row1[0] eq $vv);
        print $row1[0], "  ", $vv, "\n";
    }


    $sth = $dbh->prepare("select val from t1 where val =~ m/MAGIC/");

    ok(0,"prepare select failed") unless defined($sth);
    
    ok(0,"execute failed")
        unless $sth->execute();
    
        
    my @row1 = $sth->fetchrow_array();
    
    fail ("bad magic")
        if (scalar(@row1));


    # this bit is sensitive to row id formatting!!

    $sth = $dbh->prepare("select rid from t1 where val =~ m/look at/");

    ok(0,"prepare select failed") unless defined($sth);
    
    ok(0,"execute failed")
        unless $sth->execute();
            
    @row1 = $sth->fetchrow_array();

    fail ("bad magic")
        unless (scalar(@row1));
    
    my $rid = $row1[0];
    my @slices = split('/', $rid);

    my $blockno = $slices[1];

    print $blockno;

    # mimic the function of the syshook so we can do some matching
    $basic_stuff[2] =~ s/__MAGIC_BLOCK_NUM__/$blockno/g;

$sth = $dbh->prepare("select val from t1");

    ok(0,"prepare select failed") unless defined($sth);
    
    ok(0,"execute failed")
        unless $sth->execute();
    
    for my $vv (@basic_stuff)
    {
        
        @row1 = $sth->fetchrow_array();

        fail("mismatch")
            unless ($row1[0] eq $vv);
        print $row1[0], "  ", $vv, "\n";
    }
    

}
