# Copyright (c) 2005 Jeffrey I Cohen.  All rights reserved.
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
rmtree($gnz_home, 1, 1);
#mkpath($gnz_home, 1, 0755);


# TESTING FOR PREFERENCES, command-line definitions and file header definitions

my %fhdefs = ('a space' => 'b space',
              'c c c' => 'd d d');

my %other_defs = ('foo' => 'bar',
                  'baz' => 'ztesch' );

{
    my $fb = Genezzo::GenDBI->new(exe => $0, 
                                  gnz_home => $gnz_home, 
                                  dbinit => $dbinit,
                                  fhdefs => \%fhdefs,
                                  defs => \%other_defs
                                  );

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

    my $dictobj = $fb->{dictobj};
    
    while (my ($kk, $vv) = each (%other_defs))
    {
        print "$kk: $vv\n";

        not_ok ("could not find $kk")
            unless (exists($dictobj->{prefs}->{$kk}));
        my $pval = $dictobj->{prefs}->{$kk};
        not_ok ("$kk: mismatch - $pval not equal $vv")
            unless ($vv eq $pval);
    }
    ok();
    while (my ($kk, $vv) = each (%fhdefs))
    {
        print "$kk: $vv\n";

        not_ok ("could not find $kk")
            unless (exists($dictobj->{fileheaderinfo}->{$kk}));
        my $pval = $dictobj->{fileheaderinfo}->{$kk};
        not_ok ("$kk: mismatch - $pval not equal $vv")
            unless ($vv eq $pval);
    }
    ok();

    my $foo = $dictobj->DictSetFileInfo(newkey => "look at this",
                                        newval => "what a trick");

    $fhdefs{"look at this"} = "what a trick";

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
    while (my ($kk, $vv) = each (%fhdefs))
    {
        print "$kk: $vv\n";

        not_ok ("could not find $kk")
            unless (exists($dictobj->{fileheaderinfo}->{$kk}));
        my $pval = $dictobj->{fileheaderinfo}->{$kk};
        not_ok ("$kk: mismatch - $pval not equal $vv")
            unless ($vv eq $pval);
    }
    ok();

    my $foo = $dictobj->DictSetFileInfo(newkey => "look at this",
                                        newval => "teeny");

    $fhdefs{"look at this"} = "teeny";

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
    while (my ($kk, $vv) = each (%fhdefs))
    {
        print "$kk: $vv\n";

        not_ok ("could not find $kk")
            unless (exists($dictobj->{fileheaderinfo}->{$kk}));
        my $pval = $dictobj->{fileheaderinfo}->{$kk};
        not_ok ("$kk: mismatch - $pval not equal $vv")
            unless ($vv eq $pval);
    }
    ok();

    my $foo = $dictobj->DictSetFileInfo(newkey => "look at this",
                                        newval => "monster super size me very big");

    $fhdefs{"look at this"} = "monster super size me very big";

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
    while (my ($kk, $vv) = each (%fhdefs))
    {
        print "$kk: $vv\n";

        not_ok ("could not find $kk")
            unless (exists($dictobj->{fileheaderinfo}->{$kk}));
        my $pval = $dictobj->{fileheaderinfo}->{$kk};
        not_ok ("$kk: mismatch - $pval not equal $vv")
            unless ($vv eq $pval);
    }
    ok();


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

