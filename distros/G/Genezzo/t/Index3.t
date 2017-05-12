# Copyright (c) 2003, 2004, 2005 Jeffrey I Cohen.  All rights reserved.
#
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..23\n"; }
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

my $ins_count = 50;
my $dup_count = 4;

if (1) 
{
    use Genezzo::Util;
    my $starttime = time();

    my %t3arg = (
                 unique_key   => 1,
                 key_type     => ["n", "c"],
                 use_keycount => 1
                 );

    my $bt = Genezzo::Index::bt2->new(%t3arg);

    my @foo = qw(alpha bravo charlie delta echo foxtrot golf hotel india juliet kilo lima mike november oscar papa quebec romeo sierra tango uniform victor whiskey xray yankee zulu);

    # 5 * 26 rows
    for my $frid (@foo)
    {
        not_ok("failed to insert 1 $frid")
            unless ($bt->insert([1, $frid], undef));
    }
    for my $frid (@foo)
    {
        not_ok("failed to insert 2 $frid")
            unless ($bt->insert([2, $frid], undef));
    }
    for my $frid (@foo)
    {
        not_ok("failed to insert 3 $frid")
            unless ($bt->insert([3, $frid], undef));
    }
    for my $frid (@foo)
    {
        not_ok("failed to insert 4 $frid")
            unless ($bt->insert([4, $frid], undef));
    }
    for my $frid (@foo)
    {
        not_ok("failed to insert 5 $frid")
            unless ($bt->insert([5, $frid], undef));
    }


    # dup test
    if ( $bt->insert([3, "echo"], undef))
    {
        not_ok("duplicate key echo");
    }
    else
    {
        ok()
    }
    if ($bt->insert([3, "golf"], undef))
    {
        not_ok("duplicate key golf");
    }
    else
    {
        ok()
    }

    greet $bt->stats();


    my $hcount = $bt->HCount();
    if ($hcount == 130)
    {
        ok();
    }
    else
    {
        not_ok("count mismatch - $hcount vs 130");
    }

    greet time() - $starttime;


#    greet $bt;

    { # search
        my $sth = $bt->SQLPrepare(start_key => [1, ""], stop_key => [3, ""]);

        $sth->SQLExecute() ? ok() : not_ok("could not execute");

        my @row = $sth->SQLFetch();

        my $fcnt = 0;
        while (scalar(@row) > 1)
        {
#            greet @row;

            unless ($row[0]->[-1] eq $row[1])
            {
                my ($kk, $vv) = ($row[0], $row[1]);
                not_ok("val mismatch: key $kk, val $vv");
            }
            if ($fcnt < 26)
            {
                unless ($row[0]->[0] == 1)
                {
                    my ($kk, $vv) = ($row[0], $row[1]);
                    not_ok("key 1:  key $kk, val $vv");
                }
            }
            else
            {
                unless ($row[0]->[0] == 2)
                {
                    my ($kk, $vv) = ($row[0], $row[1]);
                    not_ok("key 2: key $kk, val $vv");
                }
            }

            @row = $sth->SQLFetch();
            $fcnt++;
        }

        if ($fcnt == 52)
        {
            ok();
        }
        else
        {
            not_ok("count mismatch - $fcnt vs 52");
        }


        greet time() - $starttime;


    }

}

if (1)
{
    use Genezzo::TestSetup;

    my $fb = 
        Genezzo::TestSetup::CreateOrRestoreDB( 
                                               gnz_home => $gnz_home,
                                               restore_dir => $gnz_restore
                                             );

    unless (defined($fb))
    {
        not_ok ("could not create database");
        exit 1;
    }
    ok();
    $dbinit = 0;

}

if (1)
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
    $dbinit = 0;

    if ($dbh->do("startup"))
    {       
        ok();
    }
    else
    {
        not_ok ("could not startup");
    }

    if ($dbh->do("af filesize=16K"))
    {       
        ok();
    }
    else
    {
        not_ok ("could not addfile");
    }
    if ($dbh->do("af filesize=16K"))
    {       
        ok();
    }
    else
    {
        not_ok ("could not addfile");
    }
    if ($dbh->do("af "))
    {       
        ok();
    }
    else
    {
        not_ok ("could not addfile");
    }


    if ($dbh->do("ct duptab id=n cname=c"))
    {       
        ok();
    }
    else
    {
        not_ok ("could not create table");
    }   

    {
        for my $ii (1..$ins_count)
        {
            my $ins = "i duptab $ii foo_$ii";

            if ($dbh->do($ins))
            {       
#            ok();
            }
            else
            {
                not_ok ("could not insert: $ins");
                last;
            }   
        }
    }

    if ($dbh->do("ci dup_idx duptab id"))
    {       
        ok();
    }
    else
    {
        not_ok ("could not create index");
    }   

    for my $jj (1..$dup_count)
    {
        for my $ii (1..$ins_count)
        {
            my $ins = "i duptab $ii foo_$ii";

            if ($dbh->do($ins))
            {       
#            ok();
            }
            else
            {
                not_ok ("could not insert: $ins");
                last;
            }   
        }
    }
    ok ();

    my $fetchcount;
    my $lastfetch = $dbh->selectrow_arrayref("select count(*) from duptab");
    if (scalar(@{$lastfetch}))
    {
        $fetchcount = $lastfetch->[0];

        if ($fetchcount != (($dup_count + 1) * $ins_count))
        {
            not_ok("fetch count $fetchcount mismatch");
        }
        else
        {
            ok();
        }
    }
    else
    {
        not_ok ("could not fetch ary ref count(*)");
    }

    $lastfetch = $dbh->selectrow_arrayref("select count(*) from dup_idx");
    if (scalar(@{$lastfetch}))
    {
        $fetchcount = $lastfetch->[0];

        if ($fetchcount != (($dup_count + 1) * $ins_count))
        {
            not_ok("idx fetch count $fetchcount mismatch");
        }
        else
        {
            ok();
        }
    }
    else
    {
        not_ok ("could not fetch idx ary ref count(*)");
    }

    my $del_posn = int($ins_count/2);

    if ($dbh->do("delete from duptab where id = $del_posn"))
    {       
        ok();
    }
    else
    {
        not_ok ("could not delete");
    }
        
    $lastfetch = $dbh->selectrow_arrayref("select count(*) from duptab");
    if (scalar(@{$lastfetch}))
    {
        $fetchcount = $lastfetch->[0];
        ok();
    }
    else
    {
        not_ok ("could not fetch ary ref count(*)");
    }

    $lastfetch = $dbh->selectrow_arrayref("select count(*) from dup_idx");
    if (scalar(@{$lastfetch}))
    {
        # check that index still has same rowcount as table
        if ($fetchcount != $lastfetch->[0])
        {
            not_ok("idx fetch count $fetchcount mismatch");
        }
        else
        {
            ok();
        }
    }
    else
    {
        not_ok ("could not fetch idx ary ref count(*)");
    }

    $del_posn++;

    my $sth = 
      $dbh->prepare("select rid, id, cname from duptab where id = $del_posn");

    print $sth->execute(), " rows \n";

    for my $ii (1..(int($dup_count/2)))
    {
        my $ggg = $sth->fetchrow_hashref();
    
        last
            unless (defined($ggg));
        $lastfetch = $ggg;
    }
    greet $lastfetch;

    my $del_rid = $lastfetch->{rid};
    my $del_id = $lastfetch->{id};

    my $delstr = 'delete from duptab where rid = \'' . $del_rid . '\'';

    if ($dbh->do($delstr))
    {       
        ok();
    }
    else
    {
        not_ok ("could not delete");
    }

    $sth = 
      $dbh->prepare("select rid, id, \"_trid\" as trid from dup_idx where id = $del_id");

    print $sth->execute(), " rows \n";

    while (1)
    {
        my $ggg = $sth->fetchrow_hashref();
    
        last
            unless (defined($ggg));
        $lastfetch = $ggg;

        if ($lastfetch->{trid} eq $del_rid)
        {
            not_ok("index delete failed : $del_rid");
        }
    }



    if ($dbh->do("commit"))
    {       
        ok();
    }
    else
    {
        not_ok ("could not commit");
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

