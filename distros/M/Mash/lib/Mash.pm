#!/usr/bin/env perl
package Mash;
use strict;
use warnings;
use Exporter qw(import);
use File::Basename qw/fileparse basename dirname/;
use Data::Dumper;

use JSON ();
use Encode qw/encode decode/;

our $VERSION = 0.1;

our @EXPORT_OK = qw(raw_mash_distance);

local $0=basename $0;

# If this is used in a scalar context, $self->toString() is called
use overload '""' => 'toString';

=pod

=head1 NAME

Mash

=head1 SYNOPSIS

A module to read `mash info` output and transform it

  use strict;
  use warnings;
  use Mash;

  # Quick example

  # Sketch all fastq files into one mash file.
  system("mash sketch *.fastq.gz > all.msh");
  die if $?;
  # Read the mash file.
  my $msh = Mash->new("all.msh");
  # All-vs-all distances
  my $distHash = $msh->dist($msh);

=head1 DESCRIPTION

This is a module to read mash files produced by the Mash executable. For more information on Mash, see L<mash.readthedocs.org>.  This module is capable of reading mash files.  Future versions will read/write mash files.

=head1 METHODS

=over

=item Mash->new("filename.msh",\%options);

Create a new instance of Mash.  One object per set of files.

  Arguments:  Sketch filename
              Hash of options (none so far)
  Returns:    Mash object

=back

=cut

sub new{
  my($class,$filename,$settings)=@_;

  my $self={
    file      => $filename,
    kmer      => -1, # eg, 21
    alphabet  => "", # eg, AGCT
    canonical => -1, # eg, true/false
    sketchSize=> -1, # eg, 1000
    hashType  => "", # eg, "MurmurHash3_x64_128"
    hashBits  => -1, # eg, 64
    hashSeed  => -1, # eg, 42
    sketches  => [], # Array of hashes. Each hash has keys
                     #  name    => original filename
                     #  length  => integer of estimated genome size
                     #  comment => string description
                     #  hashes  => list of integers
  };
  bless($self,$class);
  $self->file($filename);

  return $self;
}


=pod

=over

=item $msh->file("filename.msh")

Changes which file is used in the object and updates internal object information. This method is ordinarily used internally only.

  Arguments: One mash file
  Returns:   self

=back

=cut

sub file{
  my($self,$msh)=@_;
  
  if(!   $msh){
    die "ERROR: no file was given to \$self->file";
    return {};
  }
  if(!-e $msh){
    die "ERROR: could not find file $msh";
  }

  my $json=JSON->new;
  $json->utf8;           # If we only expect characters 0..255. Makes it fast.
  $json->allow_nonref;   # can convert a non-reference into its corresponding string
  $json->allow_blessed;  # encode method will not barf when it encounters a blessed reference
  $json->pretty;         # enables indent, space_before and space_after

  my $jsonStr = `mash info -d $msh`;
  die "ERROR running mash on $msh" if $?;

  # Need to check for valid utf8 or not
  eval{ my $strCopy=$jsonStr; decode('utf8', $strCopy, Encode::FB_CROAK) }
    or die "ERROR: mash info -d yielded non-utf8 characters for this file: $msh";

  my $mashInfo = $json->decode($jsonStr);

  for my $key(qw(kmer alphabet canonical sketchSize= hashType hashBits hashSeed sketches)){
    $$self{$key} = $$mashInfo{$key};
  }
  
  return $self;
}

=pod

=over

=item $msh->dist($msh2)

Returns a hash describing distances between sketches represented by
this object and another object. If there are multiple sketches per
object, then all sketches in this object will be compared against
all sketches in the other object.

  Arguments: One Mash object
  Returns:   reference to a hash of hashes. Each value is a number.

Aliases: distance(), mashDist()

=back

=cut

sub dist{
  my($self, $other)=@_;
  my %dist = ();

  my $k = $$self{kmer};

  # TODO check class of $other

  my $numFromSketches = scalar(@{ $self->{sketches} });
  my $numToSketches   = scalar(@{ $other->{sketches} });

  for(my $i=0; $i<$numFromSketches; $i++){
    my $fromHashes = $$self{sketches}[$i]{hashes};
    my $fromName   = $$self{sketches}[$i]{name};
    for(my $j=0; $j<$numToSketches; $j++){
      my $toHashes = $$other{sketches}[$j]{hashes};
      my $toName   = $$other{sketches}[$j]{name};

      my ($common, $total) = raw_mash_distance($fromHashes, $toHashes);
      my $jaccard = $common/$total;
      my $mashDist= -1/$k * log(2*$jaccard / (1+$jaccard));
      $mashDist = sprintf("%0.7f", $mashDist); # rounding to maintain compatibility with exec
      $dist{$fromName}{$toName} = $mashDist;
      $dist{$toName}{$fromName} = $mashDist;
    }
  }
  return \%dist;
}
# Some aliases for dist()
sub distance{
  goto &dist;
}
sub mashDist{
  goto &dist;
}

=pod

=over

=item Mash::raw_mash_distance($array1, $array2)

Returns the number of sketches in common and the total number of sketches between two lists.
The return type is an array of two elements.

  Arguments: A list of integers
             A list of integers
  Returns:   (countOfInCommon, totalNumber)

  Example:
    
    my $R1 = [1,2,3];
    my $R2 = [1,2,4];
    my($common, $total) = Mash::raw_mash_distance($R1,$R2);
    # $common => 2
    # $total  => 3

=back

=cut

# https://github.com/onecodex/finch-rs/blob/master/src/distance.rs#L34
sub raw_mash_distance{
  my($hashes1, $hashes2) = @_;

  my @sketch1 = sort {$a <=> $b} @$hashes1;
  my @sketch2 = sort {$a <=> $b} @$hashes2;

  my $i      = 0;
  my $j      = 0;
  my $common = 0;
  my $total  = 0;

  my $sketch_size = @sketch1;
  while($total < $sketch_size && $i < @sketch1 && $j < @sketch2){
    my $ltgt = ($sketch1[$i] <=> $sketch2[$j]); # -1 if sketch1 is less than, +1 if sketch1 is greater than

    if($ltgt == -1){
      $i += 1;
    } elsif($ltgt == 1){
      $j += 1;
    } elsif($ltgt==0) {
      $i += 1;
      $j += 1;
      $common += 1;
    } else {
      die "Internal error";
    }

    $total += 1;
  }

  if($total < $sketch_size){
    if($i < @sketch1){
      $total += @sketch1 - 1;
    }

    if($j < @sketch2){
      $total += @sketch2 - 1;
    }

    if($total > $sketch_size){
      $total = $sketch_size;
    }
  }

  return ($common, $total);
}


##### Utility methods

sub toString{
  my($self)=@_;
  my $return="Mash object with " .scalar(@{ $self->{sketches} })." file(s):\n";
  for my $sketch(@{ $self->{sketches} }){
    $return.=$$sketch{name}."\n";
  }
  
  return $return;
}

=pod

=head1 COPYRIGHT AND LICENSE

MIT license.

=head1 AUTHOR

Author:  Lee Katz <lkatz@cdc.gov>

For additional help, go to https://github.com/lskatz/perl-mash

CPAN module at http://search.cpan.org/~lskatz/perl-mash

=cut

1; # gotta love how we we return 1 in modules. TRUTH!!!

