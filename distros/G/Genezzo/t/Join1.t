# Copyright (c) 2006 Jeffrey I Cohen.  All rights reserved.
#
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..10\n"; }
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

sub bintodec {
    unpack("N", pack("B32", substr("0" x 32 . shift, -32)));
}

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


    if ($dbh->do("ct jtest1 col1=n"))
    {
        ok();
    }
    else
    {
        not_ok ("could not create table");
    }

    my $sth = $dbh->prepare('insert into jtest1 values ( 0, 1 )');

    greet $sth->rows;

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

    $sth = $dbh->prepare("select * from jtest1 as t1,jtest1  as t2,jtest1  as t3,jtest1  as t4,jtest1  as t5,jtest1  as t6,jtest1  as t7,jtest1  as t8");
    
    print $sth->execute(), " rows \n";

    # since jtest1 only has 2 rows (0 and 1), the 8 way join is a
    # cartesian product, which generates all 256 bit patterns from
    # 00000000 to 11111111.  

    my @allvals;
    while (1)
    {
        my @ggg = $sth->fetchrow_array();

        last
            unless (scalar(@ggg));

        my $binstr = join("",@ggg);

#        print $binstr, "\n";
        # convert to decimal
        push @allvals, bintodec($binstr);
    }

    # the bit patterns aren't guaranteed to be in ascending order...
    my @sortvals = sort {$a <=> $b} @allvals;

    my $cnt = 0;

    # make sure count is right
    if (scalar(@allvals) == (2**8))
    {
        ok();
    }
    else
    {
        my $ggg = scalar(@allvals);
        not_ok ("got $ggg values, not 2^8")       
    }

    # should have all the numbers from 0 to 255
    for my $ii (@sortvals)
    {
#        print $ii, " ", $cnt, "\n";
        if ($ii != $cnt)
        {
            not_ok("$ii != $cnt");
            last;
        }
        $cnt++
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

