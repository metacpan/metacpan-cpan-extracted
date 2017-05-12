# Copyright (c) 2003, 2004, 2005 Jeffrey I Cohen.  All rights reserved.
#
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..20\n"; }
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

if (0)
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

if (0)
{
    use Genezzo::Util;

    my $fb = Genezzo::GenDBI->new(exe => $0, 
                             gnz_home => $gnz_home, 
                             dbinit => $dbinit);

    unless (defined($fb))
    {
        not_ok ("could not find database");
        exit 1;
    }
    ok();
    $dbinit = 0;

    if ($fb->Parseall("startup"))
    {       
        ok();
    }
    else
    {
        not_ok ("could not startup");
    }


    my $dictobj = $fb->{dictobj};

    my $tstable = $dictobj->DictTableGetTable (tname => "test1");

    my $tv = tied(%{$tstable});

}

if (1) 
{

    my $starttime = time();

    my %t3arg = (
#                 maxsize => 0,
                 key_type => "n"
                 );

    my $bt = Genezzo::Index::bt2->new(%t3arg);


    # insert 600 values in index, alternating 
    # ascending and descending sequences
    my $off = 0;
    for my $kk (0..2)
    {
        for my $ii (0..99)
        {
            my $jj = $ii + $off;
            $bt->insert($jj, "val_$jj");
        }

        $off += 100;

        for my $ii (0..99)
        {
            my $jj = $off + (99 - $ii);
            $bt->insert($jj, "val_$jj");
        }

        $off += 100;
    }
#    greet $bt;

    greet $bt->stats();

    greet time() - $starttime;

    greet $bt->search(220);

    greet time() - $starttime;

    # scan the index forward and backwards, using hashkey and array offset
    # iterators

    my $place = $bt->offsetFIRSTKEY();

    my $ocount = 0;
    while (defined($place))
    {
        my @row = $bt->offsetFETCH($place);

        unless ($row[0] == $ocount)
        {
            greet $ocount, $place, @row;
            my ($kk, $val) = @row;
            not_ok ("fwd fetch by offset - bad row at $place, count $ocount, key $kk, val $val" );
        }
        $place = $bt->offsetNEXTKEY($place);
        $ocount++;
    }
    greet time() - $starttime;
    if ($ocount != 600)
    {
        not_ok ("fwd fetch by offset - count $ocount, not 600");
    }
    else
    {
        ok ();
    }

    $place = $bt->hkeyFIRSTKEY();
    
    $ocount = 0;
    while (defined($place))
    {
        my @row = $bt->hkeyFETCH($place);

        unless ($row[0] == $ocount)
        {
            greet $ocount, $place, @row;
            my ($kk, $val) = @row;
            not_ok ("fwd fetch by hkey - bad row at $place, count $ocount, key $kk, val $val" );
        }
        $place = $bt->hkeyNEXTKEY($place);
        $ocount++;
    }

    greet time() - $starttime;

    if ($ocount != 600)
    {
        not_ok ("fwd fetch by hkey - count $ocount, not 600");
    }
    else
    {
        ok ();
    }

    $place = $bt->hkeyLASTKEY();
    
    $ocount = 599;
    while (defined($place))
    {
        my @row = $bt->hkeyFETCH($place);

#        greet @row;

        unless ($row[0] == $ocount)
        {
            greet $ocount, $place, @row;
            my ($kk, $val) = @row;
            not_ok ("rev fetch by hkey - bad row at $place, count $ocount, key $kk, val $val" );
        }
        $place = $bt->hkeyPREVKEY($place);
        $ocount--;
    }

    greet time() - $starttime;

    if ($ocount != -1)
    {
        not_ok ("rev fetch by hkey - count $ocount, not -1");
    }
    else
    {
        ok ();
    }

    $place = $bt->offsetLASTKEY();
    $ocount = 599;
    while (defined($place))
    {
        my @row = $bt->offsetFETCH($place);

        unless ($row[0] == $ocount)
        {
            greet $ocount, $place, @row;
            my ($kk, $val) = @row;
            not_ok ("rev fetch by offset - bad row at $place, count $ocount, key $kk, val $val" );

        }

        $place = $bt->offsetPREVKEY($place);
        $ocount--;
    }

    greet time() - $starttime;

    if ($ocount != -1)
    {
        not_ok ("rev fetch by offset - count $ocount, not -1");
    }
    else
    {
        ok ();
    }

    { # search
        my $sth = $bt->SQLPrepare(start_key => 40, stop_key => 60);

        $sth->SQLExecute() ? ok() : not_ok("could not execute");

        my @row = $sth->SQLFetch();

        my $fcnt = 40;
        while (scalar(@row) > 1)
        {
#            greet @row;
            unless ($fcnt == $row[0])
            {
                my ($kk, $vv) = ($row[0], $row[1]);
                not_ok("cnt $fcnt : key $kk, val $vv");
            }
            @row = $sth->SQLFetch();
            $fcnt++;
        }

        greet time() - $starttime;

        if ($fcnt == 61)
        {
            ok();
        }
        else
        {
            not_ok ("stopped at $fcnt, not 61");
        }

        # re-execute - but no stopkey on fetch
        $sth = $bt->SQLPrepare(start_key => 40);
        $sth->SQLExecute() ? ok() : not_ok("could not execute");

        @row = $sth->SQLFetch();

        $fcnt = 40;
        while (scalar(@row) > 1)
        {
#            greet @row;
            unless ($fcnt == $row[0])
            {
                my ($kk, $vv) = ($row[0], $row[1]);
                not_ok("cnt $fcnt : key $kk, val $vv");
            }
            @row = $sth->SQLFetch();
            $fcnt++;
        }

        greet time() - $starttime;

        if ($fcnt == 600)
        {
            ok();
        }
        else
        {
            not_ok ("stopped at $fcnt, not 600");
        }

        # re-execute - but no startkey on fetch
        $sth = $bt->SQLPrepare(stop_key => 60);
        $sth->SQLExecute() ? ok() : not_ok("could not execute");

        @row = $sth->SQLFetch();

        $fcnt = 0;
        while (scalar(@row) > 1)
        {
#            greet @row;
            unless ($fcnt == $row[0])
            {
                my ($kk, $vv) = ($row[0], $row[1]);
                not_ok("cnt $fcnt : key $kk, val $vv");
            }
            @row = $sth->SQLFetch();
            $fcnt++;
        }

        greet time() - $starttime;

        if ($fcnt == 61)
        {
            ok();
        }
        else
        {
            not_ok ("stopped at $fcnt, not 61");
        }

    } # end search

}

if (1)
{
    my %t3arg = (
                 key_type => ["n", "c", "n"]
                 );

    my $bt = Genezzo::Index::bt2->new(%t3arg);

    my @foo = ([1, "alpha", 1], 
               [5, "charlie", 1], 
               [7, "golf", 1], 
               [1, "bravo", 11], 
               [1, "bravo", 21], 
               [1, "bravo", 1], 
               [1, "alpha", 3], 
               [1, "alpha", 9], 
               [1, "alpha", 7],
               [21, "bravo", 1], 
               [12, "alpha", 3], 
               [11, "alpha", 19], 
               [11, "alpha", 9], 
               [11, "delta", 9], 
               [11, "echo", 9], 
               [11, "foxy", 9], 
               [11, "bravo", 9], 
               [11, "alpha", 7]
               );

    my $jj = 0;
    for my $i (@foo)
    {
#        greet $i;
        $bt->insert($i, "val_$jj");
        $jj++;
    }
    my $place = $bt->offsetFIRSTKEY();

#    greet $bt;

    my $ocount = 0;
    while (defined($place))
    {
        my @row = $bt->offsetFETCH($place);
#        greet @row;
        $place = $bt->offsetNEXTKEY($place);
    }

}

if (0)
{
    my %t3arg = (
                 key_type => [ "c", "c"]
                 );

    my $bt = Genezzo::Index::bt2->new(%t3arg);

    my @foo = (
               ["cooper", "jeff"],
               ["cooper", "dina"],
               ["cooper", "raphael"],
               ["cooper", "ben"],
               ["alpha", "ben"],
               ["alpha", "lin"],
               ["alpha", "abe"],
               ["delta", "jeff"],
               ["delta", "alice"],
               ["delta", "dina"],
               );

    my $jj = 0;
    for my $i (@foo)
    {
#        greet $i;
        $bt->insert($i, "val_$jj");
        $jj++;
    }
    my $place = $bt->offsetFIRSTKEY();

#    greet $bt;

    my $ocount = 0;
    while (defined($place))
    {
        my @row = $bt->offsetFETCH($place);
        greet @row;
        $place = $bt->offsetNEXTKEY($place);
    }

}

if (0)
{
    my %t3arg = (
                 maxsize => 0,
                 key_type => "n"
                 );

    my $bt = Genezzo::Index::bt2->new(%t3arg);

    for my $kk (0..1000)
    {
            $bt->insert($kk, "val_$kk");
    }

    greet $bt->stats();

}

if (1)
{

    # XXX XXX XXX XXX: very fragile test.  Try to get each contiguous
    # set of numbers on a block boundary, so [0,10] is 1st block,
    # [50,60] is next, and then [100,100].  The specified start/stop
    # keys don't exist, so searchR has to find the "nearest" key.  In
    # some cases, that may mean searching in the right neighbor.
    # SQLFetch has a similar case where it passes the stopkey.

    my $starttime = time();

    my $maxm = 13;

    my %t3arg = (
                 maxsize => $maxm,
                 key_type => "n"
                 );

    my $bt = Genezzo::Index::bt2->new(%t3arg);

    my $kk = 0;
    for my $jj ($kk..($kk+$maxm-3)) # adjust for metadata rows
    {
        $bt->insert($jj, "val_$jj");
    }
    $kk = 50;
    for my $jj ($kk..($kk+$maxm-3))
    {
        $bt->insert($jj, "val_$jj");
    }
    $kk = 100;
    for my $jj ($kk..($kk+$maxm-3))
    {
        $bt->insert($jj, "val_$jj");
    }
#    greet $bt;

    my $place = $bt->hkeyFIRSTKEY();

    my $ocount = 0;
    while (defined($place))
    {
        my @row = $bt->hkeyFETCH($place);
#        greet $place, @row;
        $place = $bt->hkeyNEXTKEY($place);
        $ocount++;
    }
    if (33 == $ocount)
    {
        ok();
    }
    else
    {
        not_ok ("count was $ocount, not 33");
    }

    greet $bt->stats();

    greet time() - $starttime;

    { # search
        my $sth = $bt->SQLPrepare(start_key => 40, stop_key => 90);

        $sth->SQLExecute() ? ok() : not_ok("could not execute");

        my @row = $sth->SQLFetch();

        my $fcnt = 50;
        while (scalar(@row) > 1)
        {
#            greet "AAA", @row;
            unless ($fcnt == $row[0])
            {
                my ($kk, $vv) = ($row[0], $row[1]);
                not_ok("cnt $fcnt : key $kk, val $vv");
            }
            @row = $sth->SQLFetch();
            $fcnt++;
        }
        greet $fcnt;
        greet time() - $starttime;

        if ($fcnt == 61)
        {
            ok();
        }
        else
        {
            not_ok ("stopped at $fcnt, not 61");
        }

        # re-execute - but no stopkey on fetch
        $sth = $bt->SQLPrepare(start_key => 40);
        $sth->SQLExecute() ? ok() : not_ok("could not execute");

        @row = $sth->SQLFetch();

        $fcnt = 50;
        while (scalar(@row) > 1)
        {
#            greet "BBB", @row;
            unless ($fcnt == $row[0])
            {
                my ($kk, $vv) = ($row[0], $row[1]);
                not_ok("cnt $fcnt : key $kk, val $vv");
            }
            @row = $sth->SQLFetch();
            $fcnt++;
            $fcnt = 100 if ($fcnt == 61);
        }
        greet $fcnt;
        greet time() - $starttime;

        if ($fcnt == 111)
        {
            ok();
        }
        else
        {
            not_ok ("stopped at $fcnt, not 111");
        }
        # re-execute - but no startkey on fetch
        $sth = $bt->SQLPrepare(stop_key => 90);
        $sth->SQLExecute() ? ok() : not_ok("could not execute");

        @row = $sth->SQLFetch();

        $fcnt = 0;
        while (scalar(@row) > 1)
        {
#            greet "CCC", @row;
            unless ($fcnt == $row[0])
            {
                my ($kk, $vv) = ($row[0], $row[1]);
                not_ok("cnt $fcnt : key $kk, val $vv");
            }
            @row = $sth->SQLFetch();
            $fcnt++;
            $fcnt = 50  if ($fcnt == 11);
#            $fcnt = 100 if ($fcnt == 61);
        }
        greet $fcnt;
        greet time() - $starttime;

        if ($fcnt == 61)
        {
            ok();
        }
        else
        {
            not_ok ("stopped at $fcnt, not 61");
        }
        # re-execute - look in empty interval
        $sth = $bt->SQLPrepare(stop_key => 40, start_key => 40);
        $sth->SQLExecute() ? ok() : not_ok("could not execute");

        @row = $sth->SQLFetch();

        $fcnt = 0;
        while (scalar(@row) > 1)
        {
#            greet "CCC", @row;
            unless ($fcnt == $row[0])
            {
                my ($kk, $vv) = ($row[0], $row[1]);
                not_ok("cnt $fcnt : key $kk, val $vv");
            }
            @row = $sth->SQLFetch();
            $fcnt++;
            $fcnt = 50  if ($fcnt == 11);
#            $fcnt = 100 if ($fcnt == 61);
        }
        greet $fcnt;
        greet time() - $starttime;

        if ($fcnt == 0)
        {
            ok();
        }
        else
        {
            not_ok ("stopped at $fcnt, not 0");
        }

    } # end search

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

