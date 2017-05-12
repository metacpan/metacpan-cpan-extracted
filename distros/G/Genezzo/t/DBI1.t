# Copyright (c) 2003, 2004, 2005 Jeffrey I Cohen.  All rights reserved.
#
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..48\n"; }
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
        for my $ii (1..100)
        {
            last
                unless ($tv->HPush(\@glist));
        }
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

    my $sth = $dbh->prepare('insert into test1 values (\'a\',\'b\',\'c\',\'d\',\'e\',\'f\',\'g\',\'h\')');

    greet $sth->rows;
    print $sth->execute(), " rows \n";
    print $sth->execute(), " rows \n";
    greet $sth->rows;

    if ($dbh->do("ct test2 col1=c col2=c col3=c col4=c"))
    {
        ok();
    }
    else
    {
        not_ok ("could not create table");
    }

    $sth = $dbh->prepare('insert into test2 values ( \'alpha\', \'bravo\', \'charlie\', \'delta\', \'echo\', \'foxtrot\', \'golf\', \'hotel\')');

    greet $sth->rows;

    for my $ii (1..10)
    {
        if (2 == $sth->execute())
        {
            ok();
        }
        else
        {
            not_ok ("could insert 2 rows");
        }
        if (2 == $sth->rows())
        {
            ok();
        }
        else
        {
            not_ok ("could not get row count");
        }
    }

    $sth = $dbh->prepare("select * from test2");
    
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

    $sth = $dbh->prepare("select count(*) from test2");

    print $sth->execute(), " rows \n";

    my $lastfetch;
    while (1)
    {
        my $ggg = $sth->fetchrow_hashref();
    
        last
            unless (defined($ggg));
        $lastfetch = $ggg;
    }
    if (exists($lastfetch->{'COUNT(*)'})
        && $lastfetch->{'COUNT(*)'} == 20)
    {
        ok();
    }
    else
    {
        not_ok ("could not fetch count(*)");
    }

    greet "test1 ecount";

    $sth = $dbh->prepare("s test1 ecount");

    print $sth->execute(), " rows \n";

    @ftchary = ();
    while (1)
    {
        my @ggg = $sth->fetchrow_array();

        last
            unless (scalar(@ggg));
        @ftchary = @ggg;
    }
    shift @ftchary; # clear off the estimate
    if ($ftchary[0] == 1073)
    {
        ok();
    }
    else
    {
        not_ok ("could not fetch ecount(*)");
    }

    $sth = $dbh->prepare("s test1 count");
    
    print $sth->execute(), " rows \n";

    @ftchary = ();
    while (1)
    {
        my @ggg = $sth->fetchrow_array();
    
        last
            unless (scalar(@ggg));
        @ftchary = @ggg;
    }
    greet @ftchary;
    if ($ftchary[0] == 1073)
    {
        ok();
    }
    else
    {
        not_ok ("could not fetch ecount(*)");
    }

    $sth = 
        $dbh->prepare("select rid \"ROWid\", rownum as \"NuMbEr\", col1 \"BAKER\", col2 as \"CHUCK\" from test2");

    print $sth->execute(), " rows \n";

    if ($sth->{NUM_OF_FIELDS} == 4)
    {
        ok();
    }
    else
    {
        not_ok ("could get number of fields");
    }

    my @name1;
    push @name1, @{$sth->{NAME}};
    
    for my $nn ('ROWid', 'NuMbEr', 'BAKER', 'CHUCK')
    {
        my $n2 = shift @name1;
        if ($n2 eq $nn)
        {
            ok();
        }
        else
        {
            not_ok ("invalid field names $n2, $nn");
        }
    }

    $lastfetch = ();
    while (1)
    {
        my $ggg = $sth->fetch;

        last
            unless (defined($ggg));
        $lastfetch = $ggg;
    }

    greet $sth->rows;

    @ftchary = $dbh->selectrow_array("select count(*) from test2");
    if (scalar(@ftchary)
        && $ftchary[0]  == 20)
    {
        ok();
    }
    else
    {
        not_ok ("could not fetch array count(*)");
    }

    $lastfetch = $dbh->selectrow_hashref("select count(*) from test2");
    if (exists($lastfetch->{'COUNT(*)'})
        && $lastfetch->{'COUNT(*)'} == 20)
    {
        ok();
    }
    else
    {
        not_ok ("could not fetch hash count(*)");
    }

    $lastfetch = $dbh->selectrow_arrayref("select count(*) from test2");
    if (scalar(@{$lastfetch})
        && $lastfetch->[0] == 20)
    {
        ok();
    }
    else
    {
        not_ok ("could not fetch ary ref count(*)");
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

