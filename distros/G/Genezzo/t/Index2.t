# Copyright (c) 2003, 2004, 2005 Jeffrey I Cohen.  All rights reserved.
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

#my $ins_count = 1000;
my $ins_count = 400;

if (1)
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

if (1)
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

    if ($fb->Parseall("af filesize=16K"))
    {       
        ok();
    }
    else
    {
        not_ok ("could not addfile");
    }
    if ($fb->Parseall("af filesize=16k"))
    {       
        ok();
    }
    else
    {
        not_ok ("could not addfile");
    }
    if ($fb->Parseall("af "))
    {       
        ok();
    }
    else
    {
        not_ok ("could not addfile");
    }

    if ($fb->Parseall("ct EMP index id=n cname=c"))
    {       
        ok();
    }
    else
    {
        not_ok ("could not create table");
    }   

    for my $ii (1..$ins_count)
    {
        my $ins = "i EMP $ii foo_$ii";

        if ($fb->Parseall($ins))
        {       
#            ok();
        }
        else
        {
            not_ok ("could not insert: $ins");
            last;
        }   
    }
    ok ();

    if ($fb->Parseall("commit"))
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

