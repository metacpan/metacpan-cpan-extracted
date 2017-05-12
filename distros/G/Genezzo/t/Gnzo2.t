# Copyright (c) 2003, 2004, 2005 Jeffrey I Cohen.  All rights reserved.
#
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..31\n"; }
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


    for my $ii (2..10)
    {
        if ($fb->Parseall("addfile filesize=32K"))
        {       
            ok();
        }
        else
        {
            not_ok ("could not addfile $ii");
        }
    }
    if ($fb->Parseall("addfile filesize=10M"))
    {       
        ok();
    }
    else
    {
        not_ok ("could not addfile");
    }

    if ($fb->Parseall("ct test1 col1=c col2=c col3=c col4=c"))
    {
        ok();
    }
    else
    {
        not_ok ("could not create table");
    }

    if ($fb->Parseall("i test1 a b c d  e f g h  i j k l"))
    {
        ok();
    }
    else
    {
        not_ok ("could not insert");
    }

    if ($fb->Parseall('insert into test1 values (\'a1\', \'b1\', \'c1\', \'d1\', \'e1\', \'f1\', \'g1\', \'h1\')'))
    {
        ok();
    }
    else
    {
        not_ok ("could not insert");
    }

    my $dictobj = $fb->{dictobj};

    my $tstable = $dictobj->DictTableGetTable (tname => "test1");

    my $tv = tied(%{$tstable});

    greet $tstable;
#    greet $tstable, $tv;
    greet "colcnt is ", $tv->HCount();

    my @plist; 

    my @glist = qw( alphabravo delta_echo golf_hotel lima__mike );

    for my $jj (@glist)
    {
        my $vv = $jj x 200; # make 2k bytes each

        push @plist, $vv;
    }

    # XXX XXX: Note that direct manipulation of the hash lets you insert
    # more columns than specified in the create table statement

    my (@foo, $k1, $rowv1, @rowv);

    for my $ii (1..3)
    {

        greet "push $ii";

        @foo = $tv->HSuck (value =>\@plist);

        $k1 = $foo[0];

#    greet keys(%{$tstable});
#    greet $tstable, @foo;

        $rowv1 = $tstable->{$k1}; # fetch the big row
        @rowv = @{$rowv1};

        if (scalar(@rowv) == scalar(@plist))
        {
            ok();
        }
        else
        {
            not_ok( "count mismatch - push $ii");
        }
        for my $i (0..(scalar(@plist)-1))
        {
            unless ($rowv[$i] eq $plist[$i])
            {
                not_ok( "$i : " . $rowv[$i] . " vs " . $plist[$i] . " - push $ii");
                last;
            }
        }
        ok();
    }
#    greet $tstable->{$k1};
    my @pl2 = qw(a1a b2b c3c d4d);
    $tstable->{$k1} = \@pl2;
#    greet $tstable->{$k1};
    $rowv1 = $tstable->{$k1}; # fetch the big row
    @rowv  = @{$rowv1};

    if (scalar(@rowv) == scalar(@pl2))
    {
        ok();
    }
    else
    {
        not_ok( "count mismatch 2");
    }
    for my $i (0..(scalar(@pl2)-1))
    {
        unless ($rowv[$i] eq $pl2[$i])
        {
            not_ok( "$i : " . $rowv[$i] . " vs " . $pl2[$i]);
            last;
        }
    }
    ok();

#    _storesplit($tv, $k1, \@pl2);

    $k1 = $tv->HPush (\@plist);

    $rowv1 = $tstable->{$k1}; # fetch the big row
    @rowv = @{$rowv1};

    if (scalar(@rowv) == scalar(@plist))
    {
        ok();
    }
    else
    {
        not_ok( "count mismatch 3");
    }
    for my $i (0..(scalar(@plist)-1))
    {
        unless ($rowv[$i] eq $plist[$i])
        {
            not_ok( "$i : " . $rowv[$i] . " vs " . $plist[$i]);
            last;
        }
    }
    ok();

    @pl2 = qw(aaa bbb ccc ddd);

    $k1 = $tv->HPush (\@pl2);
    $tstable->{$k1} = \@plist;
#    greet $tv->STORE($k1, \@plist);

    $rowv1 = $tstable->{$k1}; # fetch the big row
#    greet $rowv1;
    @rowv = @{$rowv1};

    if (scalar(@rowv) == scalar(@plist))
    {
        ok();
    }
    else
    {
        not_ok( "count mismatch 4");
    }
    for my $i (0..(scalar(@plist)-1))
    {
        unless ($rowv[$i] eq $plist[$i])
        {
            not_ok( "$i : " . $rowv[$i] . " vs " . $plist[$i]);
            last;
        }
    }
    ok();

#    $fb->Parseall("dump files");

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

# XXX XXX: obsolete - now part of RSTab
sub _storesplit
{
    my ($self, $place, $value) = @_;
#    greet $self;

    my @fetcha = $self->_fetch2($place); # HPHRowBlk method

    return undef
        unless (   (scalar(@fetcha) > 1)
                && defined($fetcha[0]) 
                && defined($fetcha[1]) 
                && Genezzo::Block::RDBlock::_isheadrow($fetcha[1]));
    
    my @rowpiece = UnPackRow($fetcha[0]); # first row piece 
    
    # Note: just return if row was not split.  Avoid the extra push in
    # the while loop
    return ($self->STORE($place, $value))
        if (Genezzo::Block::RDBlock::_istailrow($fetcha[1]));

    my @packa;
    my @rowpa;
    my @techa;
    my @placa;

    push @placa, $place;

    my $gotFrag = 0;

    my @outarr;

    # Fetch the remaining row pieces, and re-assemble the row.  If the
    # piece isn't the tail (end) of the row, the last column is a
    # "next pointer", a pointer to the next piece, with a flag which
    # indicates whether the last column (the real last column, not the
    # aforementioned next pointer) was split.
    
  L_rowpiece:
    while (1)
    {
        my $foo;

        $foo = [];
        push @{$foo}, @rowpiece;

        push @packa, $fetcha[0];
        push @rowpa, $foo;
        push @techa, [length($fetcha[0]), scalar(@{$foo}), $gotFrag] ;

        if ($gotFrag)
        { # column was fragmented - merge the next column piece 
            my $h1 = shift @rowpiece;
            $outarr[-1] .= $h1; # append remainder to end of last column
        }
        
        # append next set of columns to existing row
        push @outarr, @rowpiece;

        last L_rowpiece # done when last piece of row is fetched
            if (Genezzo::Block::RDBlock::_istailrow($fetcha[1]));

        my $nextp = pop @outarr; # last column was pointer to next piece,
                                 # so remove it from output

        # check next pointer to see if column was fragmented (split)
        my ($frag, $pieceplace) = split(':', $nextp);

        # XXX XXX: clean this up - centralize knowledge of frag flag somewhere
        $gotFrag = (defined($frag)) && ($frag =~ m/F/);

        # get the next piece
        @fetcha   = $self->_fetch2($pieceplace);

        unless (   (scalar(@fetcha) > 1)
                && defined($fetcha[0]) 
                && defined($fetcha[1]) 
               )
        { # ERROR: remainder of row not found
            if  (scalar(@outarr))
            {
                my $tname = $self->{tablename};
                whisper "table $tname: malformed row $place at $pieceplace";
#                carp    "table $tname: malformed row $place at $pieceplace"
#                    if warnings::enabled();
            }
            return undef;
        }

        push @placa, $pieceplace;
        @rowpiece = UnPackRow($fetcha[0]); 
    } # end while l_rowpiece
    
#    greet @packa, @rowpa, @techa;
    greet  @rowpa, @techa, @placa;

    my @sukk = $self->HSuck (value => $value, headless => 1);
    my @fakerow;
    push @fakerow, ""; # blank col1
    push @fakerow, "F:".$sukk[0];
    my $sstat = $self->_realStore($place, \@fakerow, 1);
    # clear the tail flag
    $fetcha[1] &= ~($Genezzo::Block::RDBlock::RowStats{tail});
    my @estat = $self->_exists2($place, $fetcha[1]); # HPHRowBlk method

    shift @placa;

    for my $pl1 (@placa)
    {
        whisper "delete $pl1";
        $self->DELETE($pl1);
    }

    return ($sstat);
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

