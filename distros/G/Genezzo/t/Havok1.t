# Copyright (c) 2003-2007 Jeffrey I Cohen.  All rights reserved.
#
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..26\n"; }
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

}

{
    use Genezzo::Util;
    use Genezzo::Havok;

    my $dbh = Genezzo::GenDBI->connect($gnz_home, "NOUSER", "NOPASSWORD");
#    my $dbh = Genezzo::GenDBI->new(exe => $0, gnz_home => $gnz_home,  defs => {_QUIETWHISPER=>0});


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

    # DEPRECATED: new havok tests should use yml documents and
    # HavokUse function.  soundex function is now part of SQLScalar
    # package.

    if (0)
    {
        my $bigSQL = Genezzo::Havok::MakeSQL(); # get the string
        
        my @bigarr = split(/\n/, $bigSQL);
#    greet @bigarr;
        
        for my $lin (@bigarr)
        {
#        print $lin, "\n";
            
            if ($lin =~ m/commit/) 
            {
                ok(); # stop at commit
                last;
            }
            
            next # ignore comments (REMarks)
                if ($lin =~ m/REM/);
            
            next
                unless (length($lin));

            $lin =~ s/;(\s*)$//; # remove trailing semi
            
            not_ok ("could not create table havok")
                unless ($dbh->do($lin));
        }
    } # end if 0

    if ($dbh->do("commit"))
    {       
        ok();
    }
    else
    {
        not_ok ("could not commit");
    }
    if ($dbh->do("create table sonictest (sname c)"))
    {       
        ok();
    }
    else
    {
        not_ok ("could not create table sonictest");
    }
    if ($dbh->do(
        'insert into sonictest values (\'Euler\', \'Ellery\', \'Gauss\', \'Ghosh\')'))
    {       
        ok();
    }
    else
    {
        not_ok ("could not insert into sonictest");
    }
    if ($dbh->do(
        'insert into sonictest values (\'Hilbert\', \'Heilbronn\', \'Knuth\', \'Kant\')'))
    {       
        ok();
    }
    else
    {
        not_ok ("could not insert into sonictest");
    }
    if ($dbh->do(
        'insert into sonictest values (\'Lloyd\', \'Ladd\', \'Lukasiewicz\', \'Lissajous\')'))
    {       
        ok();
    }
    else
    {
        not_ok ("could not insert into sonictest");
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
    if ($dbh->do("startup"))
    {       
        ok();
    }
    else
    {
        not_ok ("could not startup");
    }


    # Knuth's test data for soundex

    my @ary = qw(
Euler
Ellery
Gauss
Ghosh
Hilbert
Heilbronn
Knuth
Kant
Lloyd
Ladd
Lukasiewicz
Lissajous
                 );


    while (scalar(@ary) > 1)
    {
        my $a1 = shift @ary;
        my $a2 = shift @ary;

        # XXX XXX: may need to concatenate soundex with empty string
        # to force string type.  This happens to work because default
        # compare is string.
        my $s1 = 
               "select sname from sonictest where " .
               ' soundex(sname) = ' .
               ' soundex(\''. $a2 . '\') ' ;

#        greet $s1;
#        print $s1, "\n";

        my $sth = $dbh->prepare($s1);

        print $sth->execute(), " rows \n";

        for my $loopi (1..2)
        {
            my @f1 = $sth->fetchrow_array();

            if (scalar(@f1))
            {
                if ($f1[0] =~ m/$a1|$a2/)
                {
#                    print "$loopi: ",$f1[0], "\n";
                    ok();
                }
                next;
            }
            else
            {
                not_ok ("no match for fetch $loopi: $a1, $a2");
            }
        }

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

sub now # from time_iso8601
{
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) =
        localtime(time);
    
    # example: 2002-12-19T14:02:57
    
    # year is YYYY-1900, mon in (0..11)

    my $tstr = sprintf ("%04d-%02d-%02dT%02d:%02d:%02d", 
                        ($year + 1900) , $mon + 1, $mday, $hour, $min, $sec);
    return $tstr;
}
