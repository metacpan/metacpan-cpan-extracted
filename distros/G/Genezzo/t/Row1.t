# Copyright (c) 2003, 2004 Jeffrey I Cohen.  All rights reserved.
#
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..45\n"; }
END {print "not ok 1\n" unless $loaded;}
use Genezzo::Block::Std;
use Genezzo::Row::RSBlock;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):
use Genezzo::Util;
use strict;
use warnings;

my $TEST_COUNT;

$TEST_COUNT = 2;

my $bufsize = $Genezzo::Util::DEFBLOCKSIZE + 1;

# loop contains 9? tests...
foreach my $phclass qw(
                     Genezzo::Row::RSBlock
                       )
{
    # NOTE: add nometazero to rsblock tie to prevent default metadata
    # for row zero

    # basic push (insert) and fetch integrity test

    my $insert_num = 100;
    my $delete_num = 50;

    my $buff = "\0" x $bufsize;
    my %td_hash = ();

    
    my $foo;
    
    my $tiehash = 
        tie %td_hash, $phclass, (refbufstr => \$buff,
                                 nometazero => 1) or
            not_ok( "Couldn't create new PushHash" );
    
    ok( ); 

    my $icnt;
    my (@tempo1, @tempo2);
    for  $icnt (1..$insert_num)
    {
        push @tempo1, $tiehash->HPush("foo1 $icnt");
        push @tempo2, "foo1 $icnt";
    }
    
    if (scalar(@tempo1) != $insert_num)
    {
        not_ok( "Could not push into pushhash" );
    }
    else { ok(); }

    if ($tiehash->HCount() != $insert_num)
    {
        not_ok( "Could not HCount pushhash" );
    }
    else { ok(); }
    
    my $loopfail;
    foreach $icnt (0..($insert_num - 1)) # array index starts at zero
    {
#    print $td_hash{$tempo1[$icnt]}, "\t", $tempo2[$icnt], "\n";
        unless ($td_hash{$tempo1[$icnt]} eq $tempo2[$icnt])
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

    foreach $icnt (0..($insert_num - 1)) # array index starts at zero
    {
#    print $td_hash{$tempo1[$icnt]}, "\t", $tempo2[$icnt], "\n";
        unless ($tiehash->FETCH($tempo1[$icnt]) eq $tempo2[$icnt])
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

#    print $phclass;
#    print scalar(keys(%td_hash)), "\t", ($insert_num - $delete_num), "\n";

# XXX: reverse delete since PHArray can only delete last element
    for  $icnt (1..($delete_num ))
    {
        # use tied var to delete
        my $d1 =
            $tiehash->DELETE($tempo1[(-1 * $icnt)]);
        my $d2 = pop @tempo2;

#        print $tempo1[$icnt], "\t", $d1, "\t", $d2, "\n";
        unless ($d1 eq $d2)
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

    if (scalar(keys(%td_hash)) != ($insert_num - $delete_num))
    {
        print $phclass;
        print scalar(keys(%td_hash)), "\t", ($insert_num - $delete_num), "\n";
        not_ok( "incomplete delete " );
    }
    else { ok(); }

#    print $phclass;
#    print scalar(keys(%td_hash)), "\t", ($insert_num - $delete_num), "\n";

# XXX: reverse delete since PHArray can only delete last element
    for  $icnt (1..($delete_num ))
    {
        # delete another $delete_num from the tied hash
        my $d1 =
            delete $td_hash{($tempo1[(-1 * ($icnt+ $delete_num ))])};
        my $d2 = pop @tempo2;

#        print $tempo1[$icnt], "\t", $d1, "\t", $d2, "\n";
        unless ($d1 eq $d2)
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

    if (scalar(keys(%td_hash)) != ($insert_num - (2 * $delete_num)))
    {
# print $phclass;
# print scalar(keys(%td_hash)), "\t", ($insert_num - (2 * $delete_num)), "\n";
        not_ok( "incomplete delete " );
    }
    else { ok(); }

}

# loop contains 3 tests...
foreach my $phclass qw(
                     Genezzo::Row::RSBlock
                       )
{

    # basic push (insert) and fetch integrity test

    my $insert_num = 100;
    my $delete_num = 50;

    my $buff = "\0" x $bufsize;
    my %td_hash = ();

    
    my $foo;
    
    my $tiehash = 
        tie %td_hash, $phclass, (refbufstr => \$buff,
                                 nometazero => 1) or
            not_ok( "Couldn't create new PushHash" );
    
    ok( ); 

    my $icnt;
    my (@tempo1, @tempo2);
    for  $icnt (1..$insert_num)
    {
        push @tempo1, $tiehash->STORE("PUSH", "foo1 $icnt");
        push @tempo2, "foo1 $icnt";
    }
    
    if (scalar(@tempo1) != $insert_num)
    {
        not_ok( "Could not push into pushhash" );
    }
    else { ok(); }
    
    my $loopfail;
    foreach $icnt (0..($insert_num - 1)) # array index starts at zero
    {
#    print $tempo1[$icnt], "\t", $tempo2[$icnt], "\n";
        unless ($tempo1[$icnt] eq $tempo2[$icnt])
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

# loop contains 3 tests...
foreach my $phclass qw(
                     Genezzo::Row::RSBlock
                       )
{

    # basic push (insert) and fetch integrity test

    my $insert_num = 5;

    my $buff = "\0" x $bufsize;
    my %td_hash = ();

    
    my $foo;
    
    my $tiehash = 
        tie %td_hash, $phclass, (refbufstr => \$buff,
                                 nometazero => 1) or
            not_ok( "Couldn't create new PushHash" );
    
    ok( ); 

    my $icnt;
    my (@tempo1, @tempo2);
    for  $icnt (1..$insert_num)
    {
        $td_hash{PUSH} = "foo1 $icnt";
        push @tempo2, "foo1 $icnt";
    }
    
    if (scalar(keys(%td_hash)) != $insert_num)
    {
        not_ok( "Could not push into pushhash" );
    }
    else { ok(); }
    
# XXX: should work for these implementations if less than 10 values - 
# problem with sorting of:
# 1048924128.0
# 1048924128.1
# 1048924128.11
# 1048924128.111
# 1048924128.2

    @tempo1 = sort(keys(%td_hash)) ; 

#    print join ("\n", @tempo1), "\n";

    my $loopfail;
    foreach $icnt (0..($insert_num - 1)) # array index starts at zero
    {
#    print $phclass, $td_hash{$tempo1[$icnt]}, "\t", $tempo2[$icnt], "\n";
        unless ($td_hash{$tempo1[$icnt]} eq $tempo2[$icnt])
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

# updates
foreach my $phclass qw(
                     Genezzo::Row::RSBlock
                       ) #                     Genezzo::PushHash::PHNoUpdate
{

    # basic push (insert) and fetch integrity test

    my $insert_num = 100;
    my $update_num = 5;

    my $buff = "\0" x $bufsize;
    my %td_hash = ();

    
    my $foo;
    
    my $tiehash = 
        tie %td_hash, $phclass, (refbufstr => \$buff,
                                 nometazero => 1) or
            not_ok( "Couldn't create new PushHash" );
    
    ok( ); 

    my $icnt;
    my (@tempo1, @tempo2);
    for  $icnt (1..$insert_num)
    {
        push @tempo1, $tiehash->HPush("foo1 $icnt");
        push @tempo2, "foo1 $icnt";
    }
    
    if (scalar(@tempo1) != $insert_num)
    {
        not_ok( "Could not push into pushhash" );
    }
    else { ok(); }

    if ($tiehash->HCount() != $insert_num)
    {
        not_ok( "Could not HCount pushhash" );
    }
    else { ok(); }
    
    my $loopfail;
    foreach $icnt (0..($insert_num - 1)) # array index starts at zero
    {
#    print $td_hash{$tempo1[$icnt]}, "\t", $tempo2[$icnt], "\n";
        unless ($td_hash{$tempo1[$icnt]} eq $tempo2[$icnt])
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


    for  $icnt (1..$update_num )
    {
        # use tied var to update
        my $d1 =
            $tiehash->STORE($tempo1[($icnt)], "baz1 $update_num");
        my $d2 = $tempo2[$icnt] = "baz1 $update_num";

#        print $tempo1[$icnt], "\t", $d1, "\t", $d2, "\n";
        unless ($d1 eq $d2)
        {
            $loopfail = 1;
            last;
        }
    }
    if ($loopfail)
    {
        not_ok( "update mismatch" );
    }
    else { ok(); }

    for  $icnt (1..($update_num ))
    {
        # delete another $delete_num from the tied hash
        my $d1 = $td_hash{($tempo1[$icnt + $update_num])} = "baz2 $update_num";
        my $d2 = $tempo2[$icnt + $update_num] = "baz2 $update_num";

#        print $tempo1[$icnt], "\t", $d1, "\t", $d2, "\n";
        unless ($d1 eq $d2)
        {
            $loopfail = 1;
            last;
        }
    }
    if ($loopfail)
    {
        not_ok( "update mismatch" );
    }
    else { ok(); }

    foreach $icnt (0..($insert_num - 1)) # array index starts at zero
    {
#    print $td_hash{$tempo1[$icnt]}, "\t", $tempo2[$icnt], "\n";
        unless ($td_hash{$tempo1[$icnt]} eq $tempo2[$icnt])
        {
            $loopfail = 1;
            last;
        }
    }
    if ($loopfail)
    {
        not_ok( "mismatch between updated and fetched values" );
    }
    else { ok(); }
    foreach $icnt (0..($insert_num - 1)) # array index starts at zero
    {
#    print $td_hash{$tempo1[$icnt]}, "\t", $tempo2[$icnt], "\n";
        unless (exists $td_hash{$tempo1[$icnt]})
        {
            $loopfail = 1;
            last;
        }
    }
    if ($loopfail)
    {
        not_ok( "exists mismatch" );
    }
    else { ok(); }

#
# pharray?
#    if (exists $td_hash{"no such value"})
#    {
#        print $phclass, $td_hash{"no such value"} , "\n";
#        not_ok( "exists mismatch 2" );
#    }
#    else { ok(); }
#
#    if ($tiehash->EXISTS("no such value"))
#    {
#        print $phclass, $td_hash{"no such value"} , "\n";
#        not_ok( "exists mismatch 3" );
#    }
#    else { ok(); }

}

foreach my $phclass qw(
                     Genezzo::Row::RSBlock
                       )
{

    # basic push (insert) and fetch integrity test

    my $insert_num = 100;
    my $delete_num = 50;

    my $buff = "\0" x $bufsize;
    my %td_hash = ();

    
    my $foo;
    
    my $tiehash = 
        tie %td_hash, $phclass, (refbufstr => \$buff,
                                 nometazero => 1) or
            not_ok( "Couldn't create new PushHash" );
    
    ok( ); 

    my $icnt;
    my (@tempo1, @tempo2);
    for  $icnt (1..$insert_num)
    {
        push @tempo1, $tiehash->HPush("foo1 $icnt");
        push @tempo2, "foo1 $icnt";
    }
    
    if (scalar(@tempo1) != $insert_num)
    {
        not_ok( "Could not push into pushhash" );
    }
    else { ok(); }

    if ($tiehash->HCount() != $insert_num)
    {
        not_ok( "Could not HCount pushhash" );
    }
    else { ok(); }

    %td_hash = (); # clear

    if ($tiehash->HCount() != 0)
    {
        not_ok( "Could not clear pushhash" );
    }
    else { ok(); }
}
foreach my $phclass qw(
                     Genezzo::Row::RSBlock
                       )
{

    # basic push (insert) and fetch integrity test

    my $insert_num = 100;
    my $delete_num = 50;

    my $buff = "\0" x $bufsize;
    my %td_hash = ();

    
    my $foo;
    
    my $tiehash = 
        tie %td_hash, $phclass, (refbufstr => \$buff,
                                 nometazero => 1) or
            not_ok( "Couldn't create new PushHash" );
    
    ok( ); 

    my $icnt;
    my (@tempo1, @tempo2);
    for  $icnt (1..$insert_num)
    {
        push @tempo1, $tiehash->HPush("foo1 $icnt");
        push @tempo2, "foo1 $icnt";
    }
    
    if (scalar(@tempo1) != $insert_num)
    {
        not_ok( "Could not push into pushhash" );
    }
    else { ok(); }

    if ($tiehash->HCount() != $insert_num)
    {
        not_ok( "Could not HCount pushhash" );
    }
    else { ok(); }

    $tiehash->CLEAR();

    if ($tiehash->HCount() != 0)
    {
        not_ok( "Could not clear pushhash" );
    }
    else { ok(); }
}
   

{
    my $buff = "\0" x $bufsize;
    
    my %h1;
    
    my $tie_thing = tie %h1, "Genezzo::Row::RSBlock", (refbufstr => \$buff,
                                                    nometazero => 1)
        or
            not_ok( "Couldn't create new RSBlock" );
    ok();
    
    my @plist = qw(alpha bravo charlie delta echo foxtrot golf hotel
                   india juliet kilo lima mike november oscar papa quebec
                   romeo sierra tango uniform victor whiskey xray 
                   yankee zulu);

    my $icnt;
    my $loopfail;

    foreach $icnt (@plist)
    {
        $h1{PUSH} = $icnt;
    }

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

    if ($tie_thing->HCount() == scalar(@plist))
    {
        ok();
    }
    else
    {
        not_ok( "hcount");
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

    if ($tie_thing->HCount() == (scalar(@plist) - 11))
    {
        ok();
    }
    else
    {
        not_ok( "HCount");
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

    foreach $icnt ( "alpha2", "bravo2", "charlie2")
    {
        $h1{PUSH} = $icnt;
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
}
{
    my $buff = "\0" x $bufsize;
    
    my %h1;
    
    my $tie_thing = tie %h1, "Genezzo::Row::RSBlock", (refbufstr => \$buff,
                                                    nometazero => 1)
        or
            not_ok( "Couldn't create new RSBlock" );
    ok();
    
    my @plist = qw(alpha bravo charlie delta echo foxtrot golf hotel
                   india juliet kilo lima mike november oscar papa quebec
                   romeo sierra tango uniform victor whiskey xray 
                   yankee zulu);

    my $icnt;
    my $loopfail;

    foreach $icnt (@plist)
    {
        $h1{PUSH} = $icnt;
    }

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

    if ($tie_thing->HCount() == scalar(@plist))
    {
        ok();
    }
    else
    {
        not_ok( "hcount");
    }

    # grow and shrink an entry and make sure it doesn't corrupt
    # adjacent values and the freespace calculation is correct

    $h1{1} = "A";
    my $href = {};
    $href->{bigbuf} = \$buff;
    my ($blocktype, $numelts, $freespace) = GetStdHdr($href);
    my $oldfreespace = $freespace;
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

