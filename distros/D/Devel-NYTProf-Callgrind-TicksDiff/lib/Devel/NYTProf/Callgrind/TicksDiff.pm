package Devel::NYTProf::Callgrind::TicksDiff; # Calculates a delta between 2 callgrind files

use v5.10;
use strict;
use warnings;
use Devel::NYTProf::Callgrind::Ticks;
use Carp;

our $VERSION = '0.04';

# If you do a performance analysis with NYTProf over different
# computers and want to know what makes the application
# slower on the second machine, it might be usefull to
# see the difference.
#
# TicksDiff takes the callgrind files, you can get with
# nytprofcg and calculates the delta between 2 files to
# a new callgrind file.
#
# It is nice to open the resulting file with kcachegrind to
# see it in a graphical way.
#
# SYNOPSIS
# ========
# 
# The command line way:
#
#  # Output to STDOUT
#  callgrind diff fileA.callgrind fileB.callgrind
#
#  # Output to a file
#  callgrind diff fileA.callgrind fileB.callgrind --out callgrind
#
#  # With normalization (see below)
#  callgrind diff fileA.callgrind fileB.callgrind --out callgrind --normalize
#
#
# The Perl way:
#
#  use Devel::NYTProf::Callgrind::TicksDiff;
#  my $tickdiff = Devel::NYTProf::Callgrind::TicksDiff->new( files => [$fileA,$fileB], normalize => 1 );
#  print $ticksdiff->getDiffText();
#
#
# Normalize
# =========
# The comand line and the contructor can take the argument 'normalize'.
# It will avoid to truncate negative values.
#
# To understand it, ive got to explain what happens in TicksDiff:
# If you have to runs of a perl script (Run A and B) with different amount of ticks.
#
#  A     B     function
#  100   120   foo()
#  120   100   bar()
#
# And you make a diff of it, TicksDiff would assume, you want to know how many ticks MORE the run B needs than A.
# The result would be:
#
#  A     B     diff   function
#  100   120   20     foo()
#  120   100   0      bar()       # -20 is the real diff
#
# The negative values will ne truncated to 0 because it is not possible to have negative ticks
# (maybe in a black whole ;-)
#
# If you dont want that truncation, you can raise the whole level with the biggest negative value.
# So the result would be:
#
#  A     B     normalized diff   function
#  100   120   40                foo()
#  120   100   0                 bar()
#
#
# AUTHOR
# ======
# Andreas Hernitscheck - ahernit AT cpan.org
#
# LICENCE
# =======
# You can redistribute it and/or modify it under the conditions of
# LGPL and Artistic Licence.


use Moose;

# callgrind files to be compared
has 'files' => (
    is => 'rw',
    isa => 'ArrayRef',
    required => 1,
    default => sub {[]},
);



has 'file_out' => (
    is => 'rw',
    isa => 'ArrayRef',
    default => sub {[]},
);

# Objects of ticks Devel::NYTProf::Callgrind::TicksD
has 'ticks_objects' => (
    is => 'rw',
    isa => 'ArrayRef',
    builder => '_loadFiles',
);


has 'ticks_object_out' => (
    is => 'rw',
    default => undef,
);

# enable normalization
has 'normalize' => (
    is => 'rw',
    isa => 'Bool',
    default => 0,
);


# if negative ticks are allowed or be truncated to 0
has 'allow_negative' => (
    is => 'rw',
    isa => 'Bool',
    default => 0,
);


sub _loadFiles{ 
    my $self = shift;
    my $reffiles = $self->files() or croak("files must be set");
    my @files = @{ $reffiles };
    my @objs;

    foreach my $file (@files){
        
        my $ticks = Devel::NYTProf::Callgrind::Ticks->new( file => $file );
        push @objs, $ticks;
    }

    
    $self->ticks_objects( \@objs );
  
    return \@objs; # for Moose builder
}



# starts the compare process. So far it compares only
# two files. Returning infos in a hash.
sub compare{ # HashRef 
    my $self = shift;
    my $objs = $self->ticks_objects(); 
    my $result = {};

    my $obj_a = $objs->[0];
    my $obj_b = $objs->[1];

    my $notfound = 0;
    my $delta_total = 0;
    my $delta_less = 0;
    my $delta_more = 0;
    my $max_less = 0;


    ## remember deltas for new blocks
    my $deltaInfo = [];

    foreach my $block_a ( @{ $obj_a->list() } ){

       my $block_b = $obj_b->getBlockEquivalent( $block_a );

       if ( $block_b ){
            my $delta = $self->diffBlocks( $block_a, $block_b );
            $delta_total += $delta;
            
            if ( $delta > 0 ){
                $delta_more += $delta;
            }else{
                $delta_less += $delta;

                # remember the biggest negative value.
                # to enable shifting when normalize is on
                if ( $delta < $max_less ){
                    $max_less = $delta;
                }
            }

            push @$deltaInfo, {
                            delta   => $delta,
                            block_a => $block_a,
                            block_b => $block_b,
                              };


            #print $delta."\n";

       }else{
            $notfound++;
       }

    }



    ## build new delta blocks.
    ## iterate over the stored delta info list with
    ## refs to the original blocks
    
    ## new ticks object to store the delta info in
    my $nobj =  Devel::NYTProf::Callgrind::Ticks->new();
    my $norm = $self->normalize();
    my $allow_negative = $self->allow_negative(); 
    foreach my $deltaInfo ( @{ $deltaInfo } ){

            my $block_a = $deltaInfo->{'block_a'};

            ## now build a new block
            my $nblock = {};
            %{ $nblock } = %{ $block_a }; # copy the existing block

            if ( scalar( keys %$nblock ) == 0 ){ next }; # skip empty

            my $nticks = $deltaInfo->{'delta'}; # using the delta as ticks
            
            # normalization?
            # It will shift up all values by the maximum nagative delta
            # to have the lowest value as 0.
            if ( $norm ){
                $nticks = $nticks - $max_less; # it is a negative value
            }

            ## do not allow negative deltas.
            ## to avoid wrong info, you may use normalize
            if ( ($nticks < 0) && (!$allow_negative)){
                $nticks = 0;
            }

            $nblock->{'ticks'} = $nticks;
            
            # store to the new ticks object
            $nobj->addBlock( $nblock );        
    }
    
    ## save to official location
    $self->ticks_object_out( $nobj );


    $result = {
                not_found   => $notfound,
                delta_more  => $delta_more,
                delta_less  => $delta_less,
                delta_total => $delta_total,
                max_less    => $max_less,
              };




    return $result;
}


# Compares two single blocks (HasRefs) provided
# by the Ticks class of this package. It returns
# the tick difference between B and A. Means
# B-Ticks - A-Ticks.
sub diffBlocks{ # $ticks ( \%blockA, \%blockB )
    my $self = shift;
    my $blocka = shift or die "block as hashref required";
    my $blockb = shift or die "block as hashref required";
    
    my $ta = $blocka->{'ticks'};
    my $tb = $blockb->{'ticks'};

    return $tb - $ta;
}


# just a wrapper around ticks_object_out
sub getDeltaTicksObject{ # $Object
    my $self = shift;

    return $self->ticks_object_out();
}


# Saves the difference to a callgrind file
sub saveDiffFile{ # void ( $filename )
    my $self = shift;
    my $file = shift or die "need filename";

    my $obj = $self->ticks_object_out();
    $obj->saveFile( $file );

    if ( ! -f $file ){ die "Did not create file $file" };

}

# Returns the callgrind text of the diff.
sub getDiffText{ # $text
    my $self = shift;

    my $obj = $self->ticks_object_out();
    return $obj->getAsText();
}


1;


#################### pod generated by Pod::Autopod - keep this line to make pod updates possible ####################

=head1 NAME

Devel::NYTProf::Callgrind::TicksDiff - Calculates a delta between 2 callgrind files


=head1 SYNOPSIS


The command line way:

 # Output to STDOUT
 callgrind diff fileA.callgrind fileB.callgrind

 # Output to a file
 callgrind diff fileA.callgrind fileB.callgrind --out callgrind

 # With normalization (see below)
 callgrind diff fileA.callgrind fileB.callgrind --out callgrind --normalize


The Perl way:

 use Devel::NYTProf::Callgrind::TicksDiff;
 my $tickdiff = Devel::NYTProf::Callgrind::TicksDiff->new( files => [$fileA,$fileB], normalize => 1 );
 print $ticksdiff->getDiffText();




=head1 DESCRIPTION

If you do a performance analysis with NYTProf over different
computers and want to know what makes the application
slower on the second machine, it might be usefull to
see the difference.

TicksDiff takes the callgrind files, you can get with
nytprofcg and calculates the delta between 2 files to
a new callgrind file.

It is nice to open the resulting file with kcachegrind to
see it in a graphical way.



=head1 REQUIRES

L<Devel::NYTProf::Callgrind::TicksDiff> 

L<Moose> 

L<Devel::NYTProf::Callgrind::Ticks> 


=head1 METHODS


=head2 compare

 my \%hashref = $this->compare();

starts the compare process. So far it compares only
two files. Returning infos in a hash.


=head2 diffBlocks

 my $ticks = $this->diffBlocks(\%blockA, \%blockB);

Compares two single blocks (HasRefs) provided
by the Ticks class of this package. It returns
the tick difference between B and A. Means
B-Ticks - A-Ticks.


=head2 getDeltaTicksObject

 my $Object = $this->getDeltaTicksObject();

just a wrapper around ticks_object_out


=head2 getDiffText

 my $text = $this->getDiffText();

Returns the callgrind text of the diff.


=head2 saveDiffFile

 $this->saveDiffFile($filename);

Saves the difference to a callgrind file



=head1 LICENCE

You can redistribute it and/or modify it under the conditions of
LGPL and Artistic Licence.


=head1 Normalize

The comand line and the contructor can take the argument 'normalize'.
It will avoid to truncate negative values.

To understand it, ive got to explain what happens in TicksDiff:
If you have to runs of a perl script (Run A and B) with different amount of ticks.

 A     B     function
 100   120   foo()
 120   100   bar()

And you make a diff of it, TicksDiff would assume, you want to know how many ticks MORE the run B needs than A.
The result would be:

 A     B     diff   function
 100   120   20     foo()
 120   100   0      bar()       # -20 is the real diff

The negative values will ne truncated to 0 because it is not possible to have negative ticks
(maybe in a black whole ;-)

If you dont want that truncation, you can raise the whole level with the biggest negative value.
So the result would be:

 A     B     normalized diff   function
 100   120   40                foo()
 120   100   0                 bar()




=head1 AUTHOR

Andreas Hernitscheck - ahernit AT cpan.org



=cut

