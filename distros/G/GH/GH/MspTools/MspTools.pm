package GH::MspTools;

require 5.005_62;
use strict;
use warnings;

require Exporter;
require DynaLoader;

our @ISA = qw(Exporter DynaLoader);

our @EXPORT_OK = qw(getMSPs
		    getMSPsBulk
		    findBestOverlap
		    findBestInclusion
		    findBestInclusionBulk
		    tmpPlace
		    MSPMismatches
		    );

our @EXPORT = qw();

our $VERSION = '0.01';

bootstrap GH::MspTools $VERSION;

# Preloaded methods go here.

$GH::MspTools::tableSize = 32767;
$GH::MspTools::wordSize = 12;
$GH::MspTools::extensionThreshold = 12;
$GH::MspTools::mspThreshold = 12;
$GH::MspTools::matchScore = 1;
$GH::MspTools::mismatchScore = -5;
$GH::MspTools::ovFudge = 30;

1;
__END__

=head1 NAME

GH::MspTools - a perl package for doing "amazing" tricks with MSPs.

=head1 SYNOPSIS

  # this example (and this man page) may be out of date.  Think twice.

  use GH::Msp;
  use GH::MspTools qw(getMSPs findBestOverlap findBestInclusion);

  # in reality, these would be real sequences.
  $s1 = "acgcttac";
  $s2 = "ttacgcactatcct";

  $arrayRef = getMSPs($s1, $s2);
  if (defined($arrayRef)) {
    @sortedmsps = sort {$a->getLen() <=> $b->getLen()} @{$arrayRef};
    foreach $msp (@sortedmsps) {
      print $msp->dump(), "\n";
    }
  }

  $bestOverlapRef = findBestOverlap($s1, $s2);
  if (defined($bestOverlapRef)) {
    ($cost, $leftStart, $leftEnd, $rightStart, $rightEnd) = 
         @{$bestOverlapRef};
  }

  $bestInclusionRef = findBestInclusion($s1, $s2);
  if (defined($bestInclusionRef)) {
    ($cost, $leftStart, $leftEnd, $rightStart, $rightEnd) = 
         @{$bestOverlapRef};
  }

  # tuning/twiddling/finger-poken knobs, and their default
  # values.
  $GH::MspTools::tableSize = 32767;
  $GH::MspTools::wordSize = 12;
  $GH::MspTools::extensionThreshold = 12;
  $GH::MspTools::mspThreshold = 12;
  $GH::MspTools::matchScore = 1;
  $GH::MspTools::mismatchScore = -5;
  $GH::MspTools::ovFudge = 30;

=head1 DESCRIPTION

GH::MspTools supplies a set of routines that find simliar regions in
DNA sequences.

getMSPs() simply finds a set of maximal segment pairs for two
sequences and returns a reference to the array containing them.  See
GH::Msp for more information on what the msps contain.  Changing the
order of the arguments will interchange the pos1 and pos2 values in
the msps, but the set will be essentially the same.

findBestOverlap($seq1, $seq2) finds the best overlap between the first
sequence and the second.  It assumes that seq1 is on the left and that
seq2 is on the right.  It does not reverse complement either sequence.
A complete search to see if a pair of sequences overlap might look like:
 
 $aRef1 = findBestOverlap($s1, $s2);
 $aRef2 = findBestOverlap($s1, $s2rev);
 $aRef3 = findBestOverlap($s1rev, $s2);
 $aRef4 = findBestOverlap($s1rev, $s2rev);

findBestInclusion($seq1, $seq2) find the best way to include the
second sequence in the first sequence.  In otherwords, is seq2 a
subsequence of seq1.  To check if seq1 is a subsequence of seq2, you
need to interchange the arguments findBestInclusion($seq2, $seq1).

=head1 CONFIGURATION VARIABLES.

There are several knobs and sliders that are available for
finger-poken.  This section describes them, at least from a 35,000
foot level.

=head2 $GH::MspTools::tableSize 

This variable set's the size of the hash table that the msp package
uses.  32kb seems to be a good starting point.

=head2 $GH::MspTools::wordSize

This variable sets the size of the string that the hash table uses.
The hashing function is length dependent, 12 to 15 seem to be a useful 
range.

=head2 $GH::MspTools::extensionThreshold 

This variable controls whether or not a proto-MSP is extended or
cut-off.  It's value is intimately tied to matchScore and
misMatchScore.

=head2 $GH::MspTools::matchScore

This value is the score that the MSP searching algorithm gives to a
pair of characters that match.  In a simple dynamic programming
algorithm, this would be the score for a "match".

=head2 $GH::MspTools::mismatchScore

This value is the score that the MSP searching algorithm gives to a
pair of characters that do not match.  In a simple dynamic programming
algorithm, this would be the score for a "mismatch".

=head2 $GH::MspTools::mspThreshold

This is the threshold for deciding whether a proto-MSP is accepted or
rejected.  Scores must be above this threshold.

=head2 $GH::MspTools::ovFudge

This is the amount of "slop" that the various routines which build
paths from sets of MSPS (e.g. overlap finding, inclusion finding) will 
allow and still be willing to "join" a pair of MSPs.

=head1 EXPORT

None by default.

=head1 EXPORT_OK

getMSP
findBestOverlap
findBestInclusion

=head1 BUGS

The parameters for finding and stringing together msps should be
documented and made tunable.

=head1 AUTHOR

George Hartzell, hartzell@cs.berkeley.edu

=head1 SEE ALSO

GH::Msp

perl(1)

=cut
  
