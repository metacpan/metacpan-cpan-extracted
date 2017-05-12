# Copyright (c) 2003, 2004 Jeffrey I Cohen.  All rights reserved.
#
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..34\n"; }
END {print "not ok 1\n" unless $loaded;}
use Genezzo::Block::Std;
use Genezzo::Block::RowDir;
use Genezzo::Block::RDBlock;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):
use strict;
use warnings;

local $Genezzo::Block::Std::xtraHdr = "";       # XXX XXX: no fancy system headers
local $Genezzo::Block::Std::LenFtrTemplate = 0;

my $TEST_COUNT;

$TEST_COUNT = 2;

{
    my $href = {};
    my $buf = "G" x $Genezzo::Block::Std::DEFBLOCKSIZE;
    $href->{bigbuf} = \$buf;
    my $insert_num = 100;
    
    if (SetHdr(href => $href,
               BlockType => 1,
               NumElts => 2,
               FreeSpace => 3))
    {
        ok();
    }
    else
    {
        not_ok( "SetHdr: could not set" );
    }
    my ($blocktype, $numelts, $freespace) = GetStdHdr($href);
    
    if (($blocktype == 1) && ($numelts == 2) && ($freespace == 3))
    {
        ok();
    }
    else
    {
        not_ok( "StdHdr: $blocktype $numelts $freespace versus 1 2 3" );
    }
    
    if (ClearStdBlock($href))
    {
        ok();
    }
    else
    {
        not_ok( "ClearStdBlock");
    }
    ($blocktype, $numelts, $freespace) = GetStdHdr($href);
    
    if (($blocktype == 0) && ($numelts == 0) && ($freespace == 0))
    {
        ok();
    }
    else
    {
        not_ok( "StdHdr: $blocktype $numelts $freespace versus 0 0 0" );
    }
    
    my $icnt;
    
    my @tempo = ();
    
    for $icnt (0..$insert_num)
    {
        push @tempo, [$icnt, $icnt, $icnt];
        SetRDEntry($href, $icnt, $icnt, $icnt, $icnt);
    }
    
    my $loopfail;
    for $icnt (0..$insert_num)
    {
        my $rd1 = $tempo[$icnt];

#        print GetRDEntry($href, $icnt), "\n";
        my ($status, $posn, $len) = GetRDEntry($href, $icnt);
        
        unless (   ($status == $rd1->[0]) 
                && ($posn   == $rd1->[1])
                && ($len    == $rd1->[2])
                )
        {
            $loopfail = 1;
            last;
        }
    }
    if ($loopfail)
    {
        not_ok( "mismatch between pushed and fetched values" );
    }
    else { ok(); }
    
}

{
    # NOTE: add nometazero to rdblock tie to prevent default metadata
    # for row zero

    local $Genezzo::Block::Std::DEFBLOCKSIZE = 50;
    my $buff = "\0" x 5000;
    
    my %h1;
    
    my $tie_thing = tie %h1, "Genezzo::Block::RDBlock", (refbufstr => \$buff, 
                                                      nometazero => 1)
        or
            not_ok( "Couldn't create new RDBlock" );
    ok();
    
    my @plist = qw(foo bar baz );

    # only room for two in small block
    if ($tie_thing->PUSH (@plist) == 2)
    {
        ok();
    }
    else
    {
        not_ok( "push");
    }

    my $icnt;
    my $loopfail;

    for $icnt (0..1)
    {
        unless ($h1{$icnt} eq $plist[$icnt])
        {
            $loopfail = 1;
            last;
        }
    }
    if ($loopfail)
    {
        not_ok( "mismatch between pushed and fetched values" );
    }
    else { ok(); }

    if ($tie_thing->FETCHSIZE() == 2)
    {
        ok();
    }
    else
    {
        not_ok( "fetchsize");
    }
    %h1 = ();
    if ($tie_thing->FETCHSIZE() == 0)
    {
        ok();
    }
    else
    {
        not_ok( "fetchsize");
    }
    
    
} 

{
    local $Genezzo::Block::Std::DEFBLOCKSIZE = 1000;
    my $buff = "\0" x 5000;
    
    my %h1;
    
    my $tie_thing = tie %h1, "Genezzo::Block::RDBlock", (refbufstr => \$buff, 
                                                      nometazero => 1)
        or
            not_ok( "Couldn't create new RDBlock" );
    ok();
    
    my @plist = qw(alpha bravo charlie delta echo foxtrot golf hotel
                   india juliet kilo lima mike november oscar papa quebec
                   romeo sierra tango uniform victor whiskey xray 
                   yankee zulu);

    # only room for two in small block
    if ($tie_thing->PUSH (@plist) == scalar(@plist))
    {
        ok();
    }
    else
    {
        not_ok( "push");
    }

    my $icnt;
    my $loopfail;

    for $icnt (0..(scalar(@plist) - 1))
    {
        unless ($h1{$icnt} eq $plist[$icnt])
        {
            $loopfail = 1;
            last;
        }
    }
    if ($loopfail)
    {
        not_ok( "mismatch between pushed and fetched values" );
    }
    else { ok(); }

    if ($tie_thing->FETCHSIZE() == scalar(@plist))
    {
        ok();
    }
    else
    {
        not_ok( "fetchsize");
    }

    for $icnt (0..10)
    {
        my $vv = delete $h1{$icnt};
        unless ($vv eq $plist[$icnt])
        {
            $loopfail = 1;
            last;
        }
    }
    if ($loopfail)
    {
        not_ok( "delete mismatch" );
    }
    else { ok(); }

    if ($tie_thing->FETCHSIZE() == (scalar(@plist) - 11))
    {
        ok();
    }
    else
    {
        not_ok( "fetchsize");
    }

    while ( my ($kk, $vv) = each(%h1))
    {
#        print "$kk: $vv\n";
        unless ($vv eq $plist[$kk])
        {
            $loopfail = 1;
            last;
        }
    }
    if ($loopfail)
    {
        not_ok( "mismatch between pushed and fetched values" );
    }
    else { ok(); }

    if ($tie_thing->PUSH( "alpha2", "bravo2", "charlie2") == 3)    
    {
        ok();
    }
    else
    {
        not_ok( "push");
    }

    # XXX: assumption - don't reuse first slots in block even if they
    # are deleted
    push (@plist, "alpha2", "bravo2", "charlie2");

    while ( my ($kk, $vv) = each(%h1))
    {
#        print "$kk: $vv\n";
        unless ($vv eq $plist[$kk])
        {
            $loopfail = 1;
            last;
        }
    }
    if ($loopfail)
    {
        not_ok( "mismatch between pushed and fetched values" );
    }
    else { ok(); }

    # get the std header info to see freespace savings for pack delete
    my $href = {};
    $href->{bigbuf} = \$buff;
    my ($blocktype, $numelts, $freespace) = GetStdHdr($href);
#    print "$blocktype, $numelts, $freespace \n";

    # should be able to pack the 11 deleted rows and save 57 bytes
    if ($tie_thing->_packdeleted() == 11)
    {
        ok();
    }
    else
    {
        not_ok( "pack delete 1");
    }

    $href = {};
    $href->{bigbuf} = \$buff;
    my $oldfreespace = $freespace;
    ($blocktype, $numelts, $freespace) = GetStdHdr($href);
 #   print "$blocktype, $numelts, $freespace \n";
    if ($oldfreespace < $freespace)
    {
        ok();
    }
    else
    {
        not_ok( "pack delete freespace");
    }

    # no more rows to pack
    if ($tie_thing->_packdeleted() == 0)
    {
        ok();
    }
    else
    {
        not_ok( "pack delete 2");
    }
    
} 

{
    local $Genezzo::Block::Std::DEFBLOCKSIZE = 1000;
    my $buff = "\0" x 5000;
    
    my %h1;
    
    my $tie_thing = tie %h1, "Genezzo::Block::RDBlock", (refbufstr => \$buff, 
                                                      nometazero => 1)
        or
            not_ok( "Couldn't create new RDBlock" );
    ok();
    
    my @plist = qw(alpha bravo charlie delta echo foxtrot golf hotel
                   india juliet kilo lima mike november oscar papa quebec
                   romeo sierra tango uniform victor whiskey xray 
                   yankee zulu);

    # only room for two in small block
    if ($tie_thing->PUSH (@plist) == scalar(@plist))
    {
        ok();
    }
    else
    {
        not_ok( "push");
    }

    my $icnt;
    my $loopfail;

    for $icnt (0..(scalar(@plist) - 1))
    {
        unless ($h1{$icnt} eq $plist[$icnt])
        {
            $loopfail = 1;
            last;
        }
    }
    if ($loopfail)
    {
        not_ok( "mismatch between pushed and fetched values" );
    }
    else { ok(); }

    if ($tie_thing->FETCHSIZE() == scalar(@plist))
    {
        ok();
    }
    else
    {
        not_ok( "fetchsize");
    }

    for $icnt (10..(scalar(@plist) - 1))
    {
        my $vv = delete $h1{$icnt};
        unless ($vv eq $plist[$icnt])
        {
            $loopfail = 1;
            last;
        }
    }
    if ($loopfail)
    {
        not_ok( "delete mismatch" );
    }
    else { ok(); }


    while ( my ($kk, $vv) = each(%h1))
    {
#        print "$kk: $vv\n";
        unless ($vv eq $plist[$kk])
        {
            $loopfail = 1;
            last;
        }
    }
    if ($loopfail)
    {
        not_ok( "mismatch between pushed and fetched values" );
    }
    else { ok(); }

    # get the std header info to see freespace savings for pack delete
    my $href = {};
    $href->{bigbuf} = \$buff;
    my ($blocktype, $numelts, $freespace) = GetStdHdr($href);
#    print "$blocktype, $numelts, $freespace \n";

    # deleting from the end of the block should not require packing
    if ($tie_thing->_packdeleted() == 0)
    {
        ok();
    }
    else
    {
        not_ok( "pack delete 1");
    }

    $href = {};
    $href->{bigbuf} = \$buff;
    my $oldfreespace = $freespace;
    ($blocktype, $numelts, $freespace) = GetStdHdr($href);
 #   print "$blocktype, $numelts, $freespace \n";
    if ($oldfreespace == $freespace)
    {
        ok();
    }
    else
    {
        not_ok( "pack delete freespace");
    }

    # grow and shrink an entry and make sure it doesn't corrupt
    # adjacent values and the freespace calculation is correct

    $h1{1} = "A";
    $href = {};
    $href->{bigbuf} = \$buff;
    ($blocktype, $numelts, $freespace) = GetStdHdr($href);
    $oldfreespace = $freespace;
    ($blocktype, $numelts, $freespace) = GetStdHdr($href);
#    print "$blocktype, $numelts, $freespace \n";

    my $cnt = 1;
    # make sure that space differs by 1 -- need to add 2 to make compare work
    my $oldspace = $freespace + 2;
    for my $val ("A".."Z")
    {
        my $vv = $h1{1} = $val x $cnt;
#        print  $h1{0}, "\t";
#        print  $h1{1}, "\t";
#        print  $h1{2}, "\n";
        my @foo = GetStdHdr($href);
#        print join(" ",@foo), "\n";

        unless (
                   ($h1{0} eq $plist[0])
                && ($h1{2} eq $plist[2])
                && ($h1{1} eq $vv)
#                && ($oldspace == ($foo[2] - 1))
                )
        {
            $loopfail = 1;
            last;
        }
        $oldspace = $foo[2];
        $cnt++;
    }
    if ($loopfail)
    {
        not_ok( "mismatch between pushed and fetched values" );
    }
    else { ok(); }

    my @foo = GetStdHdr($href);
#    print join(" ",@foo), "\n";

    $cnt--;
    for my $val ("A".."Z")
    {
        my $vv = $h1{1} = $val x $cnt;
#        print  $h1{0}, "\t";
#        print  $h1{1}, "\t";
#        print  $h1{2}, "\n";

        unless (
                   ($h1{0} eq $plist[0])
                && ($h1{2} eq $plist[2])
                && ($h1{1} eq $vv)
                )
        {
            $loopfail = 1;
            last;
        }
        $cnt--;
    }
    if ($loopfail)
    {
        not_ok( "mismatch between pushed and fetched values" );
    }
    else { ok(); }

    $href = {};
    $href->{bigbuf} = \$buff;
    $oldfreespace = $freespace;
    ($blocktype, $numelts, $freespace) = GetStdHdr($href);
#    print "$blocktype, $numelts, $freespace \n";

    # h1{2} should be original size so freespace should match
    if ($oldfreespace == $freespace)
    {
        ok();
    }
    else
    {
        not_ok( "update freespace");
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

