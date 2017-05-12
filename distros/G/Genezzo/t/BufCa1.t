# Copyright (c) 2003, 2004 Jeffrey I Cohen.  All rights reserved.
#
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..484\n"; }
END {print "not ok 1\n" unless $loaded;}
use Genezzo::BufCa::BufCa;
use Genezzo::BufCa::BufCaElt;
use Genezzo::BufCa::BCFile;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):
use strict;
#use warnings; 
no warnings;   # NOTE: turn on warnings to see error messages from BufCa

my $TEST_COUNT;

$TEST_COUNT = 2;

{
    my $bce = Genezzo::BufCa::BufCaElt->new(blocksize => 10)
        or
            not_ok( "Couldn't create new BufCaElt" );
    ok();
    
    my $ref = $bce->{bigbuf};
    
    if ($bce->_dirty())
    {
        not_ok("should be clean");
    }
    else
    {
        ok();
    }
    $$ref = "foo";
    
    if ($$ref eq "foo")
    { ok();}
    else
    {
        not_ok("should be foo");
    }
    if ($bce->_dirty())
    {
        ok();
    }
    else
    {
        not_ok("should be dirty");
    }
    if ($bce->_dirty(0))
    {
        not_ok("should be clean");
    }
    else
    {
        ok();
    }

    $$ref = "baz";

    if ($$ref eq "baz")
    { ok();}
    else
    {
        not_ok("should be baz");
    }
    if ($bce->_dirty())
    {
        ok();
    }
    else
    {
        not_ok("should be dirty");
    }
}

{
#    print "start bufca test\n";
    my $bc = Genezzo::BufCa::BufCa->new(blocksize => 1, numblocks => 0);
    if (defined($bc))
    {
        not_ok("numblocks too small");
    }
    else
    {
        ok();
    }
    $bc = Genezzo::BufCa::BufCa->new(blocksize => 0, numblocks => 1);
    if (defined($bc))
    {
        not_ok("blocksize too small");
    }
    else
    {
        ok();
    }
    $bc = Genezzo::BufCa::BufCa->new(blocksize => "aa", numblocks => 1);
    if (defined($bc))
    {
        not_ok("bad blocksize");
    }
    else
    {
        ok();
    }
    $bc = Genezzo::BufCa::BufCa->new(blocksize => 1, numblocks => "aa");
    if (defined($bc))
    {
        not_ok("bad numblocks");
    }
    else
    {
        ok();
    }
#    print "end bufca test\n";
}

{
    my $bc = Genezzo::BufCa::BufCa->new(blocksize => 10, numblocks => 2)
        or
            not_ok( "Couldn't create new bc" );
    ok();

    my $bceref = $bc->ReadBlock(blocknum => 1)
        or
            not_ok( "Couldn't get BufCaElt" );
    ok();

    my $bce = $$bceref;
    {
        my $ref = $bce->{bigbuf};
    
        if ($bce->_dirty())
        {
            not_ok("should be clean");
        }
        else
        {
            ok();
        }
        $$ref = "foo";
        
        if ($$ref eq "foo")
        { ok();}
        else
        {
            not_ok("should be foo");
        }
        if ($bce->_dirty())
        {
            ok();
        }
        else
        {
            not_ok("should be dirty");
        }
        if ($bce->_dirty(0))
        {
            not_ok("should be clean");
        }
        else
        {
            ok();
        }
        
        $$ref = "baz";

        if ($$ref eq "baz")
        { ok();}
        else
        {
            not_ok("should be baz");
        }
        if ($bce->_dirty())
        {
            ok();
        }
        else
        {
            not_ok("should be dirty");
        }
    }

    $bceref = $bc->ReadBlock(blocknum => 0)
        or
            not_ok( "Couldn't get BufCaElt" );
    ok();

    $bce = $$bceref;
    {
        my $ref = $bce->{bigbuf};
    
        if ($bce->_dirty())
        {
            not_ok("should be clean");
        }
        else
        {
            ok();
        }
        $$ref = "foo";
        
        if ($$ref eq "foo")
        { ok();}
        else
        {
            not_ok("should be foo");
        }
        if ($bce->_dirty())
        {
            ok();
        }
        else
        {
            not_ok("should be dirty");
        }
        if ($bce->_dirty(0))
        {
            not_ok("should be clean");
        }
        else
        {
            ok();
        }
        
        $$ref = "baz";

        if ($$ref eq "baz")
        { ok();}
        else
        {
            not_ok("should be baz");
        }
        if ($bce->_dirty())
        {
            ok();
        }
        else
        {
            not_ok("should be dirty");
        }
    }

    $bceref = $bc->ReadBlock(blocknum => 4);
    if (defined($bceref))
    {
        not_ok("no such block");
    }
    else { ok(); }
}

{
    my $tvar = 1; # gets reset in destroy callback

    { # start foo scope
        my $foo;

        {
            my $baz = tie $foo, "Genezzo::BufCa::PinScalar"
                or 
                    not_ok("no pinscalar");
            ok();
            
            #my $funky   = sub {print "howdy! - I am destroyed\n"};
            my $funky   = sub {
                my ($package, $filename, $line) = caller(1);
#            print "creator: $package, $filename, $line - unpin \n";
                $tvar = 2;
#                print "$tvar \n";
            };
            # register the funky callback
            $baz->_DestroyCB($funky);
            if ($tvar == 1)
            { ok();}
            else
            {
                not_ok("should still be 1");
            }
        }
    } # end foo scope
    # just fiddle a bit to let garbage collection take place
    my $tempo = 1;
    $tempo = 2;
    # end fiddling
    
    # tvar got reset when foo was garbage collected
    if ($tvar == 2)
    { ok();}
    else
    {
        not_ok("should be 2");
    }
}

{
    my $totnumblocks = 50;

    my $bc = Genezzo::BufCa::BufCa->new(blocksize => 10, 
                                     numblocks => $totnumblocks)
        or
            not_ok( "Couldn't create new bc" );
    ok();

    for my $i (0..($totnumblocks - 1))
    {
        my $bceref = $bc->ReadBlock(blocknum => $i)
            or
                not_ok( "Couldn't get BufCaElt" );
        ok();
        
        my $bce = $$bceref;
        {
            my $ref = $bce->{bigbuf};
            
            if ($bce->_dirty())
            {
                not_ok("should be clean");
            }
            else
            {
                ok();
            }
            $$ref = "foo block $i";
        
            if ($$ref eq "foo block $i")
            { ok();}
            else
            {
                not_ok("should be foo block $i");
            }
            if ($bce->_dirty())
            {
                ok();
            }
            else
            {
                not_ok("should be dirty");
            }
        }
    }

    for my $i (0..($totnumblocks - 1))
    {
        my $bceref = $bc->ReadBlock(blocknum => $i)
            or
                not_ok( "Couldn't get BufCaElt" );
        ok();
        
        my $bce = $$bceref;
        {
            my $ref = $bce->{bigbuf};
            
            if ($$ref eq "foo block $i")
            { ok();}
            else
            {
                not_ok("should be foo block $i");
            }
            if ($bce->_dirty())
            {
                ok();
            }
            else
            {
                not_ok("should be dirty");
            }
        }
    }
}

{
    my $totnumblocks = 50;

    my $bc = Genezzo::BufCa::BufCa->new(blocksize => 10, 
                                     numblocks => $totnumblocks)
        or
            not_ok( "Couldn't create new bc" );
    ok();

    my (@bce_arr, @bnum_arr);

    my $i = 0;
  L_f1:
    while (1)
    {
#        print "start loop $i\n";
        my $outi =  $bc->GetFree();

        last L_f1 unless (scalar(@{ $outi }));

        my $bceref   = pop (@{$outi});
        my $blocknum = pop (@{$outi});

        my $bce = $$bceref;
        push @bnum_arr, $blocknum;
        push @bce_arr, $bceref;
        my $ref = $bce->{bigbuf};
        $$ref = "block $blocknum";
        $i++;
     }

#    print "$i \n";
    if ($i == $totnumblocks)
    {
        ok();
    }
    else
    {
        not_ok("should have $totnumblocks blocks");
    }


    for my $jcnt (0..($i - 1))
    {
#        print "$jcnt \n";
        my $blocknum = $bnum_arr[$jcnt];
        my $bceref = $bce_arr[$jcnt];
        my $bce = $$bceref;
        {
            my $ref = $bce->{bigbuf};
            if ($$ref eq "block $blocknum")
            { ok();}
            else
            {
                not_ok("ref doesnt match");
            }
#            print $$ref, "\n";
#            print $bce->_dirty(), "\n";
            if ($bce->_dirty())
            {
                ok();
            }
            else
            {
                not_ok("should be dirty");
            }
        }
    }
    @bce_arr = ();
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

