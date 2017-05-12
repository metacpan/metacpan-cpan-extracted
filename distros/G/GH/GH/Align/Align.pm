package GH::Align;

require 5.005_62;
use strict;
use warnings;

require Exporter;
require DynaLoader;

our @ISA = qw(Exporter DynaLoader);

our @EXPORT_OK = qw(globalMinDifferences
		    boundedGlobalMinDifferences
		    boundedHirschbergGlobalMinDiffs
		    );

our @EXPORT = qw();

our $VERSION = '0.01';

bootstrap GH::Align $VERSION;

# Preloaded methods go here.

1;
__END__

=head1 NAME

GH::Align - a perl package for doing alignments

=head1 SYNOPSIS

  # this example (and this man page) may be out of date.  Think twice.

  use GH::Align qw(globalMinDifferences boundedGlobalMinDifferences);
  use GH::Status;

  # in reality, these would be real sequences.
  $s1 = "acgcttac";
  $s1 = "ttacgcactatcct";

  $arrayRef = globalMinDifferences($s1, $s2);

  $status = $$arrayRef[0];
  if ($status != STAT_OK) {
    # do something drastic
  }
  $cost = $$arrayRef[1];

  $editOpsRef = $$arrayRef[2];
  foreach $op (@{$opsRef}) {
    print $op->getOpName, " ", $op->getCount;
    if ($op->getCount == 1) {
      print " base.\n";
    }
    else {
      print " bases.\n";
    }
  }

  $arrayRef = boundedGlobalMinDifferences($s1, $s2, 5);
  # same as above.

=head1 DESCRIPTION

GH::Align supplies a set of routines for doing sequence alignments.

=head1 EXPORT

None by default.

=head1 EXPORT_OK

globalMinDifferences
boundedGlobalMinDifferences

=head1 BUGS

Not so far.

=head1 AUTHOR

George Hartzell, hartzell@cs.berkeley.edu

=head1 SEE ALSO

GH::Status
GH::MspTools

perl(1)

=cut
  
