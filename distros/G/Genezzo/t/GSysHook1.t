# Copyright (c) 2003-2007 Jeffrey I Cohen.  All rights reserved.
#
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl GSysHook1.t

# NOTE: the magic_writeblock hook is for testing purposes only, and
# should *not* be installed on production databases.

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 14;
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
rmtree($gnz_home, 1, 1);
#mkpath($gnz_home, 1, 0755);


{
    my $fb = Genezzo::GenDBI->new(exe => $0, 
                             gnz_home => $gnz_home, 
                             dbinit => $dbinit);

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

        print "do: $lin\n";
        
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

        print "do: $lin\n";
        
        fail ("could not create table syshook")
            unless ($dbh->do($lin));
    }

    ok ($dbh->do("commit"));
}

my @basic_stuff = ('nothing to see here',
                   'or here',
                   'special: my block number is __MAGIC_BLOCK_NUM__',
                   'big finish');


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


    ok(0,"failed to create t1")
        unless($dbh->do("create table t1(val char)"));

    my $ins1 = "insert into t1 values (\'BIND_IT\')";

    for my $vv (@basic_stuff)
    {
        my $ins2 = $ins1;
        $ins2 =~ s/BIND_IT/$vv/gm;
        ok(0,"failed to insert into t1")
            unless($dbh->do($ins2));
    }

    ok(0,"failed commit create t1")
        unless($dbh->do("commit"));


    my $sth = $dbh->prepare("select val from t1");

    ok(0,"prepare select failed") unless defined($sth);
    
    ok(0,"execute failed")
        unless $sth->execute();
    
    for my $vv (@basic_stuff)
    {
        
        my @row1 = $sth->fetchrow_array();

        fail("mismatch")
            unless ($row1[0] eq $vv);
        print $row1[0], "  ", $vv, "\n";
    }
    

    my $bigSQL =<<EOF_SQL ;
insert into sys_hook (xid, pkg, hook, replace, xtype, xname, 
                      args, owner, creationdate, version) values 
(33000, 'Genezzo::BufCa::BCFile', '_init_filewriteblock', '_init_fwb_Hook', 
'require', 'Genezzo::Havok::Examples', 'magic_writeblock', 
'SYSTEM', TODAY, '1')
EOF_SQL

    my $now = Genezzo::Dict::time_iso8601();
    $bigSQL =~ s/TODAY/\'$now\'/gm;


    ok ($dbh->do($bigSQL));

    ok ($dbh->do("commit"));
    ok($dbh->do("shutdown"));
}

