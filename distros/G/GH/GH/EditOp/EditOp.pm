package GH::EditOp;

require 5.005_62;
use strict;
use warnings;
use Carp;

require Exporter;
require DynaLoader;
use AutoLoader;

our @ISA = qw(Exporter DynaLoader);

# make sure that this corresponds to the defines in editop.h
use constant NOP => 0;
use constant MATCH => 1;
use constant MISMATCH => 2;
use constant INSERT_S1 => 3;
use constant INSERT_S2 => 4;
use constant OVERHANG_S1 => 5;
use constant OVERHANG_S2 => 6;

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use GH::Msp ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	NOP
	INSERT_S1
	INSERT_S2
	MATCH
	MISMATCH
        OVERHANG_S1
        OVERHANG_S2
        printOps
        printPositions
        printAlignments
        printProblems
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	NOP
	INSERT_S1
	INSERT_S2
	MATCH
	MISMATCH
        OVERHANG_S1
        OVERHANG_S2
        printOps
        printPositions
        printAlignment
        printProblems
);

our $VERSION = '0.01';

our @editOpName = ();
$editOpName[NOP] = "nop";
$editOpName[MATCH] = "match";
$editOpName[MISMATCH] = "mismatch";
$editOpName[INSERT_S1] = "insert_s1";
$editOpName[INSERT_S2] = "insert_s2";
$editOpName[OVERHANG_S1] = "overhang_s1";
$editOpName[OVERHANG_S2] = "overhang_s2";

sub getOpName {
  my($self) = @_;
  return($editOpName[$self->getType()]);
}

sub printOps {
  my($opsRef, $filehandle) = @_;
  my($op);
  foreach $op (@{$opsRef}) {
    printf($filehandle "%13s %7d", $op->getOpName, $op->getCount);
    if ($op->getCount == 1) {
      print $filehandle " base.\n";
    }
    else {
      print $filehandle " bases.\n";
    }
  }
}

sub printPositions {
  my($opsRef, $filehandle) = @_;
  my($op);
  my($s1pos, $s2pos) = (1, 1);
  
  foreach $op (@{$opsRef}) {
    if ($op->getType == NOP) {
    }
    elsif ($op->getType == MATCH) {
      printf($filehandle "There is a %d base MATCH starting at position %d in sequence 1 and position %d in sequence 2.\n", $op->getCount, $s1pos, $s2pos);
      $s1pos += $op->getCount;
      $s2pos += $op->getCount;      
    }
    elsif ($op->getType == MISMATCH) {
      printf($filehandle "There is a %d base MISMATCH starting at position %d in sequence 1 and position %d in sequence 2.\n", $op->getCount, $s1pos, $s2pos);
      $s1pos += $op->getCount;
      $s2pos += $op->getCount;      
    }
    elsif ($op->getType == INSERT_S1) {
      printf($filehandle "There is a %d base INSERT in sequence 1, starting at position %d.\n", $op->getCount, $s1pos);
      $s1pos += $op->getCount;
    }
    elsif ($op->getType == INSERT_S2) {
      printf($filehandle "There is a %d base INSERT in sequence 2, starting at position %d.\n", $op->getCount, $s2pos);
      $s2pos += $op->getCount;
    }
    else {
      
    }
  }
}

sub printAlignment {
  my($s1, $s2, $opsRef, $lineLength, $filehandle) = @_;
  my($op);
  my($a1, $a2, $a3) = ("", "", "");
  my($s1off, $s2off) = (0, 0);
  my($alignLength, $offset);

  foreach $op (@{$opsRef}) {
    if ($op->getType == NOP) {
    }
    elsif ($op->getType == MATCH) {
      $a1 .= substr($s1, $s1off, $op->getCount);
      $a2 .= "|" x $op->getCount;
      $a3 .= substr($s2, $s2off, $op->getCount);
      $s1off += $op->getCount;
      $s2off += $op->getCount;      
    }
    elsif ($op->getType == MISMATCH) {
      $a1 .= substr($s1, $s1off, $op->getCount);
      $a2 .= "X" x $op->getCount;
      $a3 .= substr($s2, $s2off, $op->getCount);
      $s1off += $op->getCount;
      $s2off += $op->getCount;      
    }
    elsif (($op->getType == INSERT_S1) || ($op->getType == OVERHANG_S1)) {
      $a1 .= substr($s1, $s1off, $op->getCount);
      $a2 .= "+" x $op->getCount;
      $a3 .= "-" x $op->getCount;
      $s1off += $op->getCount;
    }
    elsif (($op->getType == INSERT_S2) || ($op->getType == OVERHANG_S2)) {
      $a1 .= "-" x $op->getCount;
      $a2 .= "+" x $op->getCount;
      $a3 .= substr($s2, $s2off, $op->getCount);
      $s2off += $op->getCount;
    }
    else {
      
    }
  }

  $alignLength = length($a1);
  $offset = 0;
  while($offset < $alignLength) {
    printf($filehandle "%-10d%-*s\n", $offset, $lineLength,
	   substr($a1, $offset, $lineLength));
    printf($filehandle
	   "          %-*s\n", $lineLength, substr($a2, $offset, $lineLength));
    printf($filehandle
	   "          %-*s\n", $lineLength, substr($a3, $offset, $lineLength));
    print $filehandle "\n";
    $offset += $lineLength;    
  }

}

sub printProblems {
  my($s1, $s2, $opsRef, $lineLength, $filehandle) = @_;
  my($op);
  my($a1, $a2, $a3) = ("", "", "");
  my($s1off, $s2off) = (0, 0);
  my($alignLength, $offset) = (0,0);
  my(@problemSpot, $pRef);
  

  foreach $op (@{$opsRef}) {
    $offset += $op->getCount;
    if ($op->getType == NOP) {
    }
    elsif ($op->getType == MATCH) {
      $a1 .= substr($s1, $s1off, $op->getCount);
      $a2 .= "|" x $op->getCount;
      $a3 .= substr($s2, $s2off, $op->getCount);
      $s1off += $op->getCount;
      $s2off += $op->getCount;
    }
    elsif ($op->getType == MISMATCH) {
      push(@problemSpot, [$offset, $s1off, $s2off]);
      $a1 .= substr($s1, $s1off, $op->getCount);
      $a2 .= "X" x $op->getCount;
      $a3 .= substr($s2, $s2off, $op->getCount);
      $s1off += $op->getCount;
      $s2off += $op->getCount;      
    }
    elsif (($op->getType == INSERT_S1) || ($op->getType == OVERHANG_S1)) {
      push(@problemSpot,  [$offset, $s1off, $s2off])
	if ($op->getType == INSERT_S1);	
      $a1 .= substr($s1, $s1off, $op->getCount);
      $a2 .= "+" x $op->getCount;
      $a3 .= "-" x $op->getCount;
      $s1off += $op->getCount;
    }
    elsif (($op->getType == INSERT_S2) ||($op->getType == OVERHANG_S2)) {
      push(@problemSpot, [$offset, $s1off, $s2off])
	if ($op->getType == INSERT_S2);
      $a1 .= "-" x $op->getCount;
      $a2 .= "+" x $op->getCount;
      $a3 .= substr($s2, $s2off, $op->getCount);
      $s2off += $op->getCount;
    }
    else {
      
    }
  }

  foreach $pRef (@problemSpot) {
    printf($filehandle
	   "There is a problem at position %d in seq1 and position %d in seq2.\n\n",
	   @$pRef[1], @$pRef[2]);
    printf($filehandle "   s1 %s\n", substr($a1, @$pRef[0] - 11, 21));
    printf($filehandle "      %s\n", substr($a2, @$pRef[0] - 11, 21));
    printf($filehandle "   s2 %s\n", substr($a3, @$pRef[0] - 11, 21));

    print $filehandle "\n";
  }
}


bootstrap GH::EditOp $VERSION;

# Preloaded methods go here.

1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

GH::EditOp - A simple perl object (implemented in C) that represents 
various edit operations used in sequence alignments.

=head1 SYNOPSIS

  # this example (and this man page) may be out of date.  Think twice.

  use GH::EditOp;
  
  my $editop = new GH::EditOp;
  
  # make the op a "no-op", and see if it worked.
  $editop->setType(NOP);
  Not() if ($editop->getType() != NOP); Ok($i++);
  Not() if ($editop->getOpName() ne "nop"); Ok($i++);
  
  # make the op a "match op" and see if it worked.
  $editop->setType(MATCH);
  Not() if ($editop->getType() != MATCH); Ok($i++);
  Not() if ($editop->getOpName() ne "match"); Ok($i++);
  
  # make the op a "mismatch op" and 
  $editop->setType(MISMATCH);
  Not() if ($editop->getType() != MISMATCH); Ok($i++);
  Not() if ($editop->getOpName() ne "mismatch"); Ok($i++);
  
  $editop->setType(INSERT_S1);
  Not() if ($editop->getType() != INSERT_S1); Ok($i++);
  Not() if ($editop->getOpName() ne "insert_s1"); Ok($i++);
  
  $editop->setType(INSERT_S2);
  Not() if ($editop->getType() != INSERT_S2); Ok($i++);
  Not() if ($editop->getOpName() ne "insert_s2"); Ok($i++);
  
  $editop->setCount(0);
  Not() if ($editop->getCount() != 0); Ok($i++);
  
  $editop->setCount(2345);
  Not() if ($editop->getCount() != 2345); Ok($i++);
  
  print $op->getOpName, " ", $op->getCount;
  if ($op->getCount == 1) {
    print " base.\n";
  }
  else {
    print " bases.\n";
  }

=head1 DESCRIPTION

GH::EditOp provides an object that encapsulates an operation that might
be used in a sequence alignment.  Each object has a name and a count.

=head2 EXPORT

=head2 EXPORT_OK

None.

=head1 BUGS

The scoring scheme should more explicit.

Positions should start at 1.  Except that then there would need to be
a bug about positions starting at 0.

=head1 AUTHOR

George Hartzell, hartzell@cs.berkeley.edu

=head1 SEE ALSO

GH::MspTools.

perl(1).

=cut
