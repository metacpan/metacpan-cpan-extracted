package GH::Msp;

require 5.005_62;
use strict;
use warnings;

require Exporter;
require DynaLoader;

our @ISA = qw(Exporter DynaLoader);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use GH::Msp ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
 our %EXPORT_TAGS = ( 'all' => [ qw(
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
);

our $VERSION = '0.01';

bootstrap GH::Msp $VERSION;

# Preloaded methods go here.

1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

GH::Msp - A simple perl object (implemented in C) that represents a
maximal segment pair.

=head1 SYNOPSIS

  use GH::Msp;
  
  $msp->setPos1(10);
  $pos1 = $msp->getPos1();

  $msp->setPos2(23456);
  $pos2 = $msp->getPos2();

  $msp->setLen(98765);
  $len = $msp->getLen();

  $msp->setScore(10);
  $score = $msp->getScore();

=head1 DESCRIPTION

GH::Msp provides an object that encapsulates a maximal segment pair.
The pos1 value is the start position in the first sequence, the pos2
value is the start position in the second sequence, and the len value
is the length of the segment pair.  Positions are offsets from the
beginning of the sequence, the first base is at position 0.  The score
value contains the score of the msp.  The particular value depends on
the scoring scheme used to create the msp.

=head2 EXPORT

None.

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
