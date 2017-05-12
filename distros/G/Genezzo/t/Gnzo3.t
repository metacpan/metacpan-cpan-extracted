# Copyright (c) 2003, 2004, 2005 Jeffrey I Cohen.  All rights reserved.
#
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..15\n"; }
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
    if ($fb->Parseall("addfile"))
    {       
        ok();
    }
    else
    {
        not_ok ("could not addfile");
    }
    if ($fb->Parseall("addfile"))
    {       
        ok();
    }
    else
    {
        not_ok ("could not addfile");
    }
    if ($fb->Parseall("addfile"))
    {       
        ok();
    }
    else
    {
        not_ok ("could not addfile");
    }

    if ($fb->Parseall("ct test1 col1=c col2=c col3=c col4=c"))
    {
        ok();
    }
    else
    {
        not_ok ("could not create table");
    }

    if ($fb->Parseall("i test1 a b c d  e f g h  i j k l"))
    {
        ok();
    }
    else
    {
        not_ok ("could not insert");
    }

    if ($fb->Parseall('insert into test1 values (\'a1\', \'b1\', \'c1\', \'d1\', \'e1\', \'f1\', \'g1\', \'h1\')'))
    {
        ok();
    }
    else
    {
        not_ok ("could not insert");
    }

    my $dictobj = $fb->{dictobj};

    my $tstable = $dictobj->DictTableGetTable (tname => "test1");

    my $tv = tied(%{$tstable});

    greet $tstable;
#    greet $tstable, $tv;
    greet "colcnt is ", $tv->HCount();

    my @plist; 

    my @glist = qw( alphabravo delta_echo golf_hotel lima__mike );

    for my $jj (@glist)
    {
        my $vv = $jj x 200; # make 2k bytes each

        push @plist, $vv;
    }

    # XXX XXX: Note that direct manipulation of the hash lets you insert
    # more columns than specified in the create table statement

    greet $tv->HPush (\@plist);
    greet $tv->HPush (\@plist);
    greet $tv->HPush (\@plist);
    greet $tv->HPush (\@plist);
#    greet $tv->HSuck (value => \@plist);


    for my $jj (1..10)
    {
        $fb->Parseall("i test1 a b c d  e f g h  i j k l");
        $fb->Parseall('insert into test1 values (\'a1\', \'b1\', \'c1\', \'d1\', \'e1\', \'f1\', \'g1\', \'h1\')');
        $tv->HPush (\@plist);
        for my $ii (1..1000)
        {
            last
                unless ($tv->HPush(\@glist));
        }
    }

    my @ggg = $tv->FirstCount();
    greet @ggg;

    while (scalar(@ggg) > 4)
    {
        @ggg = $tv->NextCount(@ggg);

        my @g2 = @ggg;
        my $kk = shift @g2;
        my $est    = shift @g2;
        my $sum    = shift @g2;
        my $sumsq  = 0;
           $sumsq  = shift @g2;
        my $ccnt   = shift @g2;
        my $tot    = shift @g2;
        my $pct    = ($ccnt/$tot) *100;

        my $var = 0;
        $var = ($sumsq - (($sum**2)/$ccnt))/($ccnt - 1)
            unless ($ccnt < 2); # var = 0 when numelts = 1

#        my $stddev = sqrt($sumsq);
        my $stddev = sqrt($var);

        # confidence interval : 1-alpha ~= 2 for 90% conf, 
        # 60+ samples, student-t, GAUSSIAN DATA ONLY
        #
        # mean +/-  2*stddev/sqrt(samplesize)

        my $alpha = 100; # 2

        my $conf = $alpha*$stddev/sqrt($ccnt);

#        greet "estimate $est, current $sum, stddev $stddev, $pct % complete";
#        printf "est %.2f+/-%.1f%%, curr %d, ", $est,  ($conf*100/$est), $sum,
        printf "est %.2f, curr %d, ", $est, $sum,
        printf "stddev %.2f, %.2f %% \n",  $stddev,  $pct;
        last 
            unless (defined($kk));

    }


    if ($fb->Parseall("commit"))
    {
        ok();
    }
    else
    {
        not_ok ("could not commit");
    }

    if ($fb->Parseall("shutdown"))
    {
        ok();
    }
    else
    {
        not_ok ("could not shutdown");
    }

}

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

    my $tstable = $dictobj->DictTableGetTable (tname => "_col1");

    my $tv = tied(%{$tstable});

    my $filter = sub {
        my ($tabdef, $rid, $outarr) = @_;
        return 1
            if (defined($outarr) &&
                scalar(@{$outarr}) &&
                ($outarr->[1] =~ m/pref1/));

        return 0;
    };

    my $f1 = {filter => $filter};
    my $sth = $tv->SQLPrepare(filter => $f1);
    $sth->SQLExecute();
    my @outi = (1,1);

    while (scalar(@outi) && defined($outi[0]))
    {
        @outi = $sth->SQLFetch();
        greet @outi;
    }

    $filter = sub {
        my ($tabdef, $rid, $outarr) = @_;
        return 1
            if (defined($outarr) &&
                scalar(@{$outarr}) &&
                ($outarr->[1] =~ m/(pref1|allfileused)/));

        return 0;
    };

    $f1 = {filter => $filter};
    $sth = $tv->SQLPrepare(filter => $f1);
    $sth->SQLExecute();
    @outi = (1,1);

    while (scalar(@outi) && defined($outi[0]))
    {
        @outi = $sth->SQLFetch();
        greet @outi;
    }

    if ($fb->Parseall("shutdown"))
    {
        ok();
    }
    else
    {
        not_ok ("could not shutdown");
    }

    # should be able to select from col1 even when shutdown

    $tstable = $dictobj->DictTableGetTable (tname => "_col1");

    $tv = tied(%{$tstable});

    $filter = sub {
        my ($tabdef, $rid, $outarr) = @_;
        return 1
            if (defined($outarr) &&
                scalar(@{$outarr}) &&
                ($outarr->[1] =~ m/pref1/));

        return 0;
    };

    $f1 = {filter => $filter};
    $sth = $tv->SQLPrepare(filter => $f1);
    $sth->SQLExecute();
    @outi = (1,1);

    while (scalar(@outi) && defined($outi[0]))
    {
        @outi = $sth->SQLFetch();
        greet @outi;
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

