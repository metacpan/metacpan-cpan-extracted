# Copyright (c) 2003, 2004 Jeffrey I Cohen.  All rights reserved.
#
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..325\n"; }
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
    # look for XXX XXX: most interesting line
    # to observe packing 

    tt1(150);
    tt1(200);
    tt1(1000);

    tt2(150);
    tt2(200);
    tt2(1000);
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
        "Genezzo::Block::RDBlock", (refbufstr => \$buffarr[$i])
            or
            not_ok( "Couldn't create new RDBlock" );
        ok();
        push @tiearr, $tie_thing;
    }

    my @plist = qw(alpha bravo charlie delta echo foxtrot golf hotel
                   india juliet kilo lima mike november oscar papa quebec
                   romeo sierra tango uniform victor whiskey xray 
                   yankee zulu);

    my ($place, $off, $frag) = $tiearr[0]->HSuck (value =>\@plist);

    # should be able to pack partially
    if (defined($place))
    {
        ok();
    }
    else
    {
        not_ok( "suck");
    }
    my $jj = 0;

    {
        my $next;

        if (defined($frag))
        {
            $next = $frag . ":";
        }
        else
        {
            $next = ":"
        }
        $next .= $jj . '/' . $place;

        $jj++;

        # pack remainder or fail out...
        while (defined($off))
        {

            ($place, $off, $frag) = $tiearr[$jj]->HSuck (
                                                         value =>\@plist, 
                                                         next => $next,
                                                         offset => $off
                                                         );

            unless (defined($place))
            {
                not_ok( "suck2");
                return undef;
            }

            if (defined($frag))
            {
                $next = $frag . ":";
            }
            else
            {
                $next = ":"
            }
            $next .= $jj . '/' . $place;

            $jj++;
        }
    }
    ok();

    $jj--;

    # unpack the the most recent piece, which is the head
    my @rw1 = $tiearr[$jj]->_fetch2($place);
    my @foo = UnPackRow($rw1[0]); 

    my @pl2; # build an array as unpack

    my $gotFrag = 0;

    # really a while loop, but fix iteration to prevent infinite loop on error
    for my $i (1..$cnt+5)
    {
#        greet @foo; # XXX XXX: most interesting line to watch

        if ($gotFrag)
        { # fragmented - merge the next piece
            my $h1 = shift @foo;
            $pl2[-1] .= $h1;
        }

        # we packed tail to head, and we unpack head to tail
        push @pl2, @foo;
        my $nextp = pop @foo;

#        greet $nn;
        # cheap test for next ptr
        last
            unless (defined($nextp) && ($nextp =~ m:/: ));

        pop @pl2 ; # last elt was next ptr, so remove it

        my ($frag, $nn) = split(':', $nextp);

        my ($chunk, $slice) = split('/', $nn);

        $gotFrag = (defined($frag)) && ($frag =~ m/F/);

#        greet $chunk, $slice;
        @rw1 = $tiearr[$chunk]->_fetch2($slice);
        @foo = UnPackRow($rw1[0]); 
    }

#    greet @pl2;

    if (scalar(@pl2) == scalar(@plist))
    {
        ok();
    }
    else
    {
        not_ok( "count mismatch");
    }

    for my $i (0..(scalar(@pl2)-1))
    {
        unless ($pl2[$i] eq $plist[$i])
        {
            not_ok( "$i : " . $pl2[$i] . " vs " . $plist[$i]);
            last;
        }

    }
    ok();

    return 1;
} # end tt1

sub tt2 
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
        "Genezzo::Block::RDBlock", (refbufstr => \$buffarr[$i])
            or
            not_ok( "Couldn't create new RDBlock" );
        ok();
        push @tiearr, $tie_thing;
    }

    my @plist = 
        qw(
           alpha_bravo_charlie_delta_echo_foxtrot_golf_hotel
           india_juliet_kilo_lima_mike_november_oscar_papa_quebec
           romeo_sierra_tango_uniform_victor_whiskey_xray_yankee_zulu
           );

    my ($place, $off, $frag) = $tiearr[0]->HSuck (value =>\@plist);

#    greet $place, $off, $frag;

    # should be able to pack partially
    if (defined($place))
    {
        ok();
    }
    else
    {
        not_ok( "suck");
        return undef;
    }
    my $jj = 0;

    {
        my $next;

        if (defined($frag))
        {
            $next = $frag . ":";
        }
        else
        {
            $next = ":"
        }
        $next .= $jj . '/' . $place;

        $jj++;

        # pack remainder or fail out...
        while (defined($off))
        {

            ($place, $off, $frag) = $tiearr[$jj]->HSuck (
                                                         value =>\@plist, 
                                                         next => $next,
                                                         offset => $off
                                                         );

            unless (defined($place))
            {
                not_ok( "suck2");
                return undef;
            }

            if (defined($frag))
            {
                $next = $frag . ":";
            }
            else
            {
                $next = ":"
            }
            $next .= $jj . '/' . $place;

            $jj++;
        }
    }
    ok();

    $jj--;

    # unpack the the most recent piece, which is the head
    my @foo = UnPackRow( $tiearr[$jj]->FETCH($place));

    my @pl2; # build an array as unpack

    if (0)
    {
        my $ggg = 10; # split('/',$foo[-1]);
        while ($ggg)
        {
            greet UnPackRow( $tiearr[$ggg]->FETCH(0));
            $ggg--;
        }
    }

    my $gotFrag = 0;

    # really a while loop, but fix iteration to prevent infinite loop on error
    for my $i (1..$cnt+5)
    {
#        greet @foo; # XXX XXX: most interesting line to watch

        if ($gotFrag)
        { # fragmented - merge the next piece
            my $h1 = shift @foo;
            $pl2[-1] .= $h1;
        }

        # we packed tail to head, and we unpack head to tail
        push @pl2, @foo;
        my $nextp = pop @foo;

#        greet $nextp;
        # cheap test for next ptr
        last
            unless (defined($nextp) && ($nextp =~ m:/: ));

        pop @pl2 ; # last elt was next ptr, so remove it

        my ($frag, $nn) = split(':', $nextp);

        my ($chunk, $slice) = split('/', $nn);

        $gotFrag = (defined($frag)) && ($frag =~ m/F/);

#        greet $chunk, $slice;
        @foo = UnPackRow( $tiearr[$chunk]->FETCH($slice));

    }

#    greet @pl2;

    if (scalar(@pl2) == scalar(@plist))
    {
        ok();
    }
    else
    {
        not_ok( "count mismatch");
    }

    for my $i (0..(scalar(@pl2)-1))
    {
        unless ($pl2[$i] eq $plist[$i])
        {
            not_ok( "$i : " . $pl2[$i] . " vs " . $plist[$i]);
            last;
#            greet $pl2[$i]; 
        }

    }
    ok();

    return 1;
} # end tt2



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

