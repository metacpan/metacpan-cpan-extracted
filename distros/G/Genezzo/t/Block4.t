# Copyright (c) 2003, 2004 Jeffrey I Cohen.  All rights reserved.
#
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..57\n"; }
END {print "not ok 1\n" unless $loaded;}
use Genezzo::Block::Std;
use Genezzo::Block::RowDir;
use Genezzo::Block::RDBlock;
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
    tt1(150);
#    tt1(200);
#    tt1(1000);

#    tt2(150);
#    tt2(200);
#    tt2(1000);
}

sub tt1 
{
    my $bsize = shift;

    local $Genezzo::Block::Std::DEFBLOCKSIZE = $bsize;
    my @buffarr;

    my $cnt = 50;
    
    my @hasharr;


    # build an array of hashes to tie, plus some byte buffers
    for my $i (1..$cnt)
    {
        push @hasharr, {};
        push @buffarr,  "\0" x (1+$bsize);

    }

    my @tiearr;

    # tie all the hashes
    for my $i (0..$cnt-1)
    {
        my $tie_thing = tie %{$hasharr[$i]}, 
        "Genezzo::Block::RDBlock", (refbufstr => \$buffarr[$i], 
                                 blocknum => $i)
            or
            not_ok( "Couldn't create new RDBlock" );
        ok();
        push @tiearr, $tie_thing;
    }

#    greet @tiearr;

    my $stat = $tiearr[0]->_update_meta_zero("alpha", "bravo")
        or
        not_ok( "Couldn't update metadata" );
    ok();

    $stat = $tiearr[0]->_update_meta_zero("charlie", "delta")
        or
        not_ok( "Couldn't update metadata" );
    ok();
    
    if ($tiearr[0]->_fetchmeta("alpha") =~  m/bravo/)
    {
        ok();
    }
    else
    {
        not_ok( "Couldn't find metadata" );
    }
    if ($tiearr[0]->_fetchmeta("charlie") =~  m/delta/)
    {
        ok();
    }
    else
    {
        not_ok( "Couldn't find metadata" );
    }

    my @plist = qw(romeo sierra tango);
    greet @plist;

    $stat = $tiearr[0]->_set_meta_row("I", \@plist)
        or
        not_ok( "Couldn't set metarow" );
    ok();

    greet $tiearr[0]->_fetchmeta("I");

    my $glist = $tiearr[0]->_get_meta_row("I");
    
    greet $glist;

    if (scalar(@{$glist}) != scalar(@plist))
    {
        not_ok("row size mismatch");
        not_ok("col mismatch");
    }
    else
    {
        for my $i (0..(scalar(@plist) - 1))
        {
            unless ($glist->[$i] eq $plist[$i])
            {
                not_ok("col mismatch");
            }
        }
        ok();
    }

#    for my $i (@tiearr)
#    {
#        greet $i->_fetchmeta('#');
#    }



} # end tt1

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

