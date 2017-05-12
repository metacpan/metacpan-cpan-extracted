# Copyright (c) 2006 Jeffrey I Cohen.  All rights reserved.
#
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..18\n"; }
END {print "not ok 1\n" unless $loaded;}
use Genezzo::GenDBI;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):
use strict;
use warnings;
use File::Path;
use File::Spec;

my $TEST_COUNT;

$TEST_COUNT = 2;

my $dbinit   = 1;
my $gnz_home = File::Spec->catdir("t", "gnz_home");
my $gnz_restore = File::Spec->catdir("t", "restore");
#rmtree($gnz_home, 1, 1);
#mkpath($gnz_home, 1, 0755);

{
    use Genezzo::TestSetup;

    my $fb = 
        Genezzo::TestSetup::CreateOrRestoreDB( 
                                               gnz_home => $gnz_home,
                                               restore_dir => $gnz_restore);

    unless (defined($fb))
    {
        not_ok ("could not create database");
        exit 1;
    }
    ok();
    $dbinit = 0;

}


{
    use Genezzo::Util;

    my $dbh = Genezzo::GenDBI->connect($gnz_home, "NOUSER", "NOPASSWORD");

    unless (defined($dbh))
    {
        not_ok ("could not find database");
        exit 1;
    }
    ok();

    if ($dbh->do("startup"))
    {       
        ok();
    }
    else
    {
        not_ok ("could not startup");
    }

    # case sensitivity testing

    if ($dbh->do("ct CaSeChEcK aAa=c bBb=c dDd=c"))
    {
        ok();
    }
    else
    {
        not_ok ("could not create table");
    }

    if ($dbh->do("ci cc_IDX CASechECK AaA ddd"))
    {
        ok();
    }
    else
    {
        not_ok ("could not create index");
    }

    if ($dbh->do("i cAsEcHeCK 1 2 3 4 5 6"))
    {
        ok();
    }
    else
    {
        not_ok ("could not insert");
    }


    my $sth = $dbh->prepare('select rid, aaa, bbb, ddd from casecheck where AaA = 1');

    print $sth->execute(), " rows \n";

    my @ftchary;

    while (1)
    {
        my @ggg = $sth->fetchrow_array();

        last
            unless (scalar(@ggg));
        @ftchary = @ggg;
    }
    greet @ftchary;
    print join(" ", @ftchary), "\n";

    my $rid1 = shift @ftchary;

    my $upd = "u CASEcheck $rid1 7 8 9";

    if ($dbh->do($upd))
    {
        ok();
    }
    else
    {
        not_ok ("could not update");
    }

    $sth = $dbh->prepare('select rid, AAA, BBB, DDD FROM CASECHECK WHERE AAA = 7');

    print $sth->execute(), " rows \n";

    while (1)
    {
        my @ggg = $sth->fetchrow_array();

        last
            unless (scalar(@ggg));
        @ftchary = @ggg;
    }
    greet @ftchary;
    print join(" ", @ftchary), "\n";
    my $del = "d caseCHECK $rid1 ";

    if ($dbh->do($del))
    {
        ok();
    }
    else
    {
        not_ok ("could not delete");
    }

    $sth = $dbh->prepare('select count(*) from CAseCHeCK');

    print $sth->execute(), " rows \n";

    while (1)
    {
        my @ggg = $sth->fetchrow_array();

        last
            unless (scalar(@ggg));
        @ftchary = @ggg;
    }
    greet @ftchary;
    print join(" ", @ftchary), "\n";

    my $cnt = shift @ftchary;

    if ($cnt == 1)
    {       
        ok();
    }
    else
    {
        not_ok ("delete failed");
    }

#    print "space table\n";
    # quoted identifiers with spaces in name

    if ($dbh->do('create table "space table" ("space aaa" char(10),  bbb char(10),  ddd char(10))'))
    {
        ok();
    }
    else
    {
        not_ok ("could not create table");
    }

    if ($dbh->do('create index "space idx" on  "space table" ("space aaa", ddd)'))
    {
        ok();
    }
    else
    {
        not_ok ("could not create index");
    }

    if ($dbh->do('insert into "space table" values (1, 2, 3, 4, 5, 6)'))
    {
        ok();
    }
    else
    {
        not_ok ("could not insert");
    }


    $sth = $dbh->prepare('select rid, "space aaa", bbb, ddd from "space table" where "space aaa" = 1');

    print $sth->execute(), " rows \n";

    while (1)
    {
        my @ggg = $sth->fetchrow_array();

        last
            unless (scalar(@ggg));
        @ftchary = @ggg;
    }
    greet @ftchary;
    print join(" ", @ftchary), "\n";

    $rid1 = shift @ftchary;

    $upd = 'update "space table" set "space aaa" = 7 where rid = \'' .  $rid1 .'\'';

    if ($dbh->do($upd))
    {
        ok();
    }
    else
    {
        not_ok ("could not update");
    }

    $sth = $dbh->prepare('select rid, "space aaa", bbb, ddd from "space table" where "space aaa" = 7');

    print $sth->execute(), " rows \n";

    while (1)
    {
        my @ggg = $sth->fetchrow_array();

        last
            unless (scalar(@ggg));
        @ftchary = @ggg;
    }
    greet @ftchary;
    print join(" ", @ftchary), "\n";
    $del = 'delete from  "space table" where rid = \'' . $rid1 . '\'' ;

    if ($dbh->do($del))
    {
        ok();
    }
    else
    {
        not_ok ("could not delete");
    }

    $sth = $dbh->prepare('select count(*) from "space table"');

    print $sth->execute(), " rows \n";

    while (1)
    {
        my @ggg = $sth->fetchrow_array();

        last
            unless (scalar(@ggg));
        @ftchary = @ggg;
    }
    greet @ftchary;
    print join(" ", @ftchary), "\n";

 $cnt = shift @ftchary;

    if ($cnt == 1)
    {       
        ok();
    }
    else
    {
        not_ok ("delete failed");
    }



    if ($dbh->do("commit"))
    {       
        ok();
    }
    else
    {
        not_ok ("could not commit");
    }
    if ($dbh->do("shutdown"))
    {
        ok();
    }
    else
    {
        not_ok ("could not shutdown");
    }

}


sub ok
{
    print "ok $TEST_COUNT\n";
    
    $TEST_COUNT++;
}


sub not_ok
{
    my ( $message ) = @_;
    
    print "not ok $TEST_COUNT #  $message\n";
        
        $TEST_COUNT++;
}


sub skip
{
    my ( $message ) = @_;
    
    print "ok $TEST_COUNT # skipped: $message\n";
        
        $TEST_COUNT++;
}

