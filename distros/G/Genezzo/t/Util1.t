# Copyright (c) 2003, 2004 Jeffrey I Cohen.  All rights reserved.
#
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..12\n"; }
END {print "not ok 1\n" unless $loaded;}
use Genezzo::Util;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):
use strict;
use warnings;

my $TEST_COUNT;

$TEST_COUNT = 2;

{
    my $bverbose = 0; # NOTE: set to 1 to print out warnings

    if (NumVal(
               verbose => $bverbose,
               name => "test 2",
               val => 1,
               MIN => 2))
    {
        not_ok("val 1 < 2");
    }
    else
    {
        ok();
    }

    if (NumVal(
               verbose => $bverbose,
               name => "test 3",
               val => 2,
               MIN => 1,
               MAX => 3))
    {
        ok();
    }
    else
    {
        not_ok("val 1 < 2 < 3");
    }

    if (NumVal(
               verbose => $bverbose,
               name => "test 4",
               val => 5,
               MIN => 1,
               MAX => 3))
    {
        not_ok("val 5 > 3");
    }
    else
    {
        ok();
    }


    if (NumVal(
               verbose => $bverbose,
               name => "test 5",
               val => 0,
               MIN => 1,
               MAX => 3))
    {
        not_ok("val 0 < 1");
    }
    else
    {
        ok();
    }

    if (NumVal(
               verbose => $bverbose,
               name => "test 6",
               val => 1,
               MIN => "aa"))
    {
        not_ok("not a number");
    }
    else
    {
        ok();
    }

    if (NumVal(
               verbose => $bverbose,
               name => "test 7",
               val => 1,
               MIN => "bb",
               MAX => "aa"))
    {
        not_ok("not a number");
    }
    else
    {
        ok();
    }

    if (NumVal(
               verbose => $bverbose,
               name => "test 8",
               val => "cc",
               MIN => "bb",
               MAX => "aa"))
    {
        not_ok("not a number");
    }
    else
    {
        ok();
    }






}

{
    my $bverbose = 0; # NOTE: set to 1 to print out warnings

    my @validops = qw(
                      yankee
                      doodle
                      dandy
                      );

    my $subop = checkKeyVal(
                            verbose => $bverbose,
                            kvpair => "yankee=vermont",
                            validlist => \@validops);

    if (defined($subop))
    {
        ok();
    }
    else
    {
        not_ok("yankee = vermont");
    }

    $subop = checkKeyVal(
                         verbose => $bverbose,
                         kvpair => "monkey=vermont",
                         validlist => \@validops);

    if (defined($subop))
    {
        not_ok("bad monkey");
    }
    else
    {
        ok();
    }

    $subop = checkKeyVal(
                         verbose => $bverbose,
                         kvpair => "yankee*vermont",
                         validlist => \@validops);

    if (defined($subop))
    {
        not_ok("bad =");
    }
    else
    {
        ok();
    }

    $subop = checkKeyVal(
                         verbose => $bverbose,
                         kvpair => "yankee=vermont",
                         validlist => undef);

    if (defined($subop))
    {
        not_ok("no valid list");
    }
    else
    {
        ok();
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

