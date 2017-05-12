# Copyright (c) 2003, 2004 Jeffrey I Cohen.  All rights reserved.
#
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..85\n"; }
END {print "not ok 1\n" unless $loaded;}
use Genezzo::Block::Std;
use Genezzo::Block::RowDir;
use Genezzo::Block::RDBlkA;
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

our $splicetype = 1;

if (0)
{
    
    # XXX XXX: need to test bad negative offsets and negative lengths...

    splicecheck (-12, -50);
    splicecheck (-12, -50, qw(aa bb cc dd ee ff gg hh ii));
    splicecheck (-12, -50, qw(aa bb cc dd));
}
if (1)
{
    splicecheck ();
    splicecheck (-1);
    splicecheck (10);
    splicecheck (10,5);
    splicecheck (10, 5, qw(aa bb cc dd));
    splicecheck (10, 20, qw(aa bb cc dd));
    splicecheck (3, 2, qw(aa bb cc));
    splicecheck (10, 5, qw(aa bb cc dd ee ff gg hh ii));

    splicecheck (12,5);
    splicecheck (12, 5, qw(aa bb cc dd ee ff gg hh ii));
    splicecheck (12, 5, qw(aa bb cc dd ee ));
    splicecheck (12, 5, qw(aa bb ));

    splicecheck (12, -5);
    splicecheck (12, -5, qw(aa bb cc dd ee ff gg hh ii));
    splicecheck (12, -5, qw(aa bb cc dd ));
    splicecheck (-12, -5);
    splicecheck (-12, -5, qw(aa bb cc dd ee ff gg hh ii));
    splicecheck (-12, -5, qw(aa bb cc dd));
    splicecheck (-12,  5);
    splicecheck (-12,  5, qw(aa bb cc dd ee ff gg hh ii));
    splicecheck (-12,  5, qw(aa bb cc dd ));
}
{
    splicecheck (10, 0,  qw(aa));
    splicecheck (0, 10,  qw(aa));
    splicecheck (0, 0,  qw(aa));
    splicecheck (1, 0,  qw(aa));
    splicecheck (1, 1,  qw(aa));
    splicecheck (0, 1,  qw(aa));

}

if (1)
{
    ordcheck(3, 2, 1);
    ordcheck(10, 7, 5, 6, 3, 2, 1);
    ordcheck(1, 2, 3, 4, 5);

}

if (0)
{
    # XXX: need a way to check error string
    local $splicetype = 0;
    splicecheck(50, 5);
}


sub ordcheck
{
    use Genezzo::Util;
    my @args = @_;
#    whoami @_;

    local $Genezzo::Block::Std::DEFBLOCKSIZE = 5000;
    my $buff = "\0" x 5000;
    
    my %h1;
    
    my $tie_thing = tie %h1, "Genezzo::Block::RDBlkA", (refbufstr => \$buff);

    my @a1;        
     
    my $v1 = shift @args;
    push (@a1, $v1);
    $tie_thing->HPush($v1);
   
    foreach my $val (@args)
    {
        my ($i, $i2);

        {
            my $arrsize = scalar(@a1);

            $i = 0;
            for (; $i < $arrsize; $i++)
            {
                # break if can insert key before 
                last
                    if ($val < $a1[$i]);
            }

            if ($i < $arrsize)
            {
                splice (@a1, $i, 0, $val);
            }
            else
            {
                push @a1, $val;
            }
        }

        {
            $i2 = 0;
            my ($kk, $vv);
            my $a = scalar keys %h1;
            while (($kk, $vv) = each(%h1))
            {
#                print "$kk : $vv\n";
                last
                    if ($val < $vv);
                
                $i2++;
            }

            if (defined($kk))
            {
                $tie_thing->HSplice($i2, 0, $val);
            }
            else
            {
                $tie_thing->PUSH($val);
            }

        }
    } # end foreach

#    greet %h1;
#    greet @a1;

    my $loopfail = 0;
    if (scalar(keys(%h1)) == scalar(@a1))
    {

        my $i = 0;
        while ( my ($kk, $vv) = each(%h1))
        {
            unless ($vv eq $a1[$i])
            {
                $loopfail = 1;
                last;
            }
            $i++;
        }
    }
    else
    {
#        print scalar(keys(%h1)), " !=  ", scalar(@a1), "\n";
        $loopfail = 1;
    }

    if ($loopfail)
    {
        not_ok( "mismatch between pushed and fetched values" );
    }
    else { ok(); }


}

sub splicecheck
{
    use Genezzo::Util;
    my @args = @_;
    whoami @_;

    local $Genezzo::Block::Std::DEFBLOCKSIZE = 5000;
    my $buff = "\0" x 5000;
    
    my %h1;
    
    my $tie_thing = tie %h1, "Genezzo::Block::RDBlkA", (refbufstr => \$buff);

    my @a1;        
        
    for my $val (1..10)
    {
        my $vv = "a_" . $val . "_1";
        $tie_thing->PUSH($vv);
        push @a1, $vv;
    }
    for my $val (1..10)
    {
        my $vv = "b_" . $val . "_1";
        $tie_thing->PUSH($vv);
        push @a1, $vv;
    }

    # test if push was successful for both pushhash and array
    my $loopfail = 0;
    if (scalar(keys(%h1)) == scalar(@a1))
    {

        my $i = 0;
        while ( my ($kk, $vv) = each(%h1))
        {
            unless ($vv eq $a1[$i])
            {
                $loopfail = 1;
                last;
            }
            $i++;
        }
    }
    else
    {
#        print scalar(keys(%h1)), " !=  ", scalar(@a1), "\n";
        $loopfail = 1;
    }

    if ($loopfail)
    {
        not_ok( "mismatch between pushed and fetched values" );
    }
    else { ok(); }

    my @b1;
    if (1)
    {
        my $off = (@_) ? shift : 0;    
        my $hadlen = (@_);
        my $len = $hadlen ? shift : scalar(@a1);
        @b1   = splice @a1, $off, $len, @_;
    }
    else
    {
        # this doesn't work correctly
         @b1   = splice @a1, @_;
    }
    my @outi;
    if (1 == $splicetype)
    {
        @outi = $tie_thing->HSplice(@args);
    }
    else
    {
        my $errstr;

        @outi = $tie_thing->HeSplice(\$errstr, @args);

        print "error is: $errstr\n";
    }
    whoami "outi",@outi;
    whoami "h1",values(%h1);
    whoami "b1",@b1;
    whoami "a1",@a1;

    $loopfail = 0;
    
    if (scalar(@outi) == scalar(@b1))
    {

        for (my $i = 0; $i < scalar(@outi); $i++)
        {
#            print "$i : ",$outi[$i]," -- ", $b1[$i], "\n";
            unless ($outi[$i] eq $b1[$i])
            {
                $loopfail = 1;
#                last;
            }

        }
    }
    else
    {
#        print scalar(@outi), " !=  ", scalar(@b1), "\n";
        $loopfail = 1;
    }
    if ($loopfail)
    {
        not_ok( "mismatch between pushed and fetched values (" 
                . $args[0] . " " . $args[1] . ")"
                );
    }
    else { ok(); }

#    print "hash : ";

    $loopfail = 0;

    if (scalar(keys(%h1)) == scalar(@a1))
    {

        my $i = 0;
        while ( my ($kk, $vv) = each(%h1))
        {
#            print "$kk : $vv -- ", $a1[$i], "\n";
            unless ($vv eq $a1[$i])
            {
                $loopfail = 1;
#                last;
            }
            $i++;
        }
    }
    else
    {
#        print scalar(keys(%h1)), " !=  ", scalar(@a1), "\n";
        $loopfail = 1;
    }

    if ($loopfail)
    {
        not_ok( "mismatch between pushed and fetched values" );
    }
    else { ok(); }
    
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

