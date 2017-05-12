# Copyright (c) 2003, 2004, 2005 Jeffrey I Cohen.  All rights reserved.
#
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..14\n"; }
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
    my $fb = Genezzo::GenDBI->new(exe => $0, 
                                  gnz_home => $gnz_home, 
                                  dbinit => $dbinit
                                  );

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

    if ($fb->Parseall("select * from _tab1"))
    {
        ok();
    }
    else
    {
        not_ok ("could not select");
    }

    if ($fb->Parseall("s _tab1 *"))
    {
        ok();
    }
    else
    {
        not_ok ("could not select2");
    }

    if ($fb->Parseall("ct test1 col1=c col2=c col3=c"))
    {
        ok();
    }
    else
    {
        not_ok ("could not create table");
    }

    if ($fb->Parseall("i test1 a b c d e f g h i"))
    {
        ok();
    }
    else
    {
        not_ok ("could not insert");
    }

    if ($fb->Parseall('insert into test1 values (\'a1\', \'b1\', \'c1\', \'e1\', \'f1\', \'g1\')'))
    {
        ok();
    }
    else
    {
        not_ok ("could not insert");
    }

    if ($fb->Parseall("s test1 nosuchcol"))
    {
        not_ok ("no such column to select");
    }
    else
    {
        ok();
    }

    if ($fb->Parseall("s test1 col2 col3 col1"))
    {
        ok();
    }
    else
    {
        not_ok ("could not select3");
    }

    if ($fb->Parseall("SELECT col2 as MYCOLUMN1, col3 FROM test1 "))
    {
        ok();
    }
    else
    {
        not_ok ("could not select4");
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

