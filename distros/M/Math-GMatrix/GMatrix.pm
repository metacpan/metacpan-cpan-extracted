# -----------------------------------------------------------------------------
#
#			Math::GMatrix
#
# $Id: GMatrix.pm,v 1.5 2004/02/05 12:17:44 acester Exp $
#
# -----------------------------------------------------------------------------
#
#
#
# Version History:
# ----------------
# $Date: 2004/02/05 12:17:44 $
# $Revision: 1.5 $
# $Log: GMatrix.pm,v $
# Revision 1.5  2004/02/05 12:17:44  acester
# added docs and test script
#
# Revision 1.4  2004/02/05 06:41:31  acester
# eps variable introduced (epsilon, floating point calculation accuracy)
#
# Revision 1.3  2004/02/04 15:45:27  acester
# short description added
#
# -----------------------------------------------------------------------------

package Math::GMatrix;
use vars qw($VERSION $eps);

use 5.006;
use strict;
use warnings;

require Exporter;
use AutoLoader qw(AUTOLOAD);
use Carp;

use Math::Matrix;
our @ISA = qw(Math::Matrix Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Math::GMatrix ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);
our $VERSION = '0.2';


# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__

# -----------------------------------------------------------------------------
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Math::GMatrix - Extension of Math::Matrix for (2D graphics-)vector manipulation

=head1 SYNOPSIS

  use Math::GMatrix;

=head1 DESCRIPTION

The following methods are available:

=head2 new

Constructor arguments are a list of references to arrays of the
same length. The arrays are copied. The method returns undef in
case of error.

	$a = new Math::Matrix ([rand,rand,rand],
			       [rand,rand,rand],
			       [rand,rand,rand]);

As s special case you can pass a single argument 'I' for
getting an identity matrix.

If you call C<new> as method, a zero filled matrix with identical
deminsions is returned.

=head2 xform

You can transform one or more vectors by calling:

	@V1=(1.5,3.7);

        @V2 = $M->xform(@V1);


	@L1=( [1.5,3.7], [4.6,6.8], [5.1,-0.7] );

        @L2 = $M->xform(@L1);

=head2 translate

You can pan (move by x and y offset) your graphics by calling:

        $M2 = $M->translate(2.5,10.2);

=head2 rotate

You can rotate your graphics by calling:

        $M2 = $M->rotate(-90);

=head2 scale

You can scale (factor_x and factor_y) your graphics by calling:

        $M2 = $M->rotate(2,2);

=head1 EXAMPLE

	@ListOfVectors = [
		[0,1],
		[3,5],
		[2,7],
		[8,-1],
	];
	$paperwidth = 21;               # DIN A4 is 21x29.7 cm
	$M = new Math::Matrix('I');     # get an identity matrix
	$M = $M->translate(-1,-1)->rotate(90)->translate($paperwidth-1,1);
	@Result = $M->xform(@ListOfVectors);

=head1 AUTHOR

A. Cester, E<lt>albert.cester@web.deE<gt>

=cut

# -----------------------------------------------------------------------------

$eps = 0.00001;

sub new {
    my $that = shift;
    my $class = ref($that) || $that;
    my $self;
    if (($#_ >= 0)&&($#_ <= 1)&&($_[0] eq "I")) {
      $self = $that->SUPER::new([1,0,0],[0,1,0],[0,0,1]);
    }
    else {
      $self = $that->SUPER::new(@_);
    }
    bless ($self, $class);
    return $self;
}

# -----------------------------------------------------------------------------

sub xform {
    my $self  = shift;
    my ($x,$y);
    my @result=();
    while ($#_ >= 0) {
      $x = shift @_;
      my $fl_ref = 0;
      if (ref($x)) {
	($x,$y) = @{$x};
	$fl_ref = 1;
      }
      else {
	$y = shift @_;
      }
      @A=($x,$y,1);
      @B=(0,0,1);
      my ($i,$j);
      foreach $i (0..$#A) {
	my $sum = 0;
	foreach $j (0..$#A) {
	  $sum += ($A[$j] * $self->[$j]->[$i]);
	}
	$B[$i] = $sum;
      }
      pop @B;
      if ($fl_ref) {
	push(@result,[@B]);
      }
      else {
	push(@result,@B);
      }
    }
    return @result;
}  # xform

# -----------------------------------------------------------------------------

sub translate($$$) {
  my ($self,$x,$y) = @_;
  my $m = new Math::GMatrix ([1,0,0],[0,1,0],[$x,$y,1]);
#  print "========\n";
#  $self->print("multiply M:\n");
#  print "========\n";
#  $m->print("by m:\n");
#  print "========\n";
  my $result = $self->multiply($m);
#  $result->print("gives:\n");
#  print "========\n";
  return $result;
}

# -----------------------------------------------------------------------------

sub rotate($$) {
  my ($self,$angle) = @_;
  $angle = $angle * 3.14159265358979323846 / 180.0;
  my $s = sin($angle);
  my $c = cos($angle);
  my $m = new Math::GMatrix ([$c,$s,0],[-$s,$c,0],[0,0,1]);
  return $self->multiply($m);
}

# -----------------------------------------------------------------------------

sub scale($$$) {
  my ($self,$sx,$sy) = @_;
  $sy = $sx unless defined $sy;
  my $m = new Math::GMatrix ([$sx,0,0],[0,$sy,0],[0,0,1]);
  return $self->multiply($m);
}

# -----------------------------------------------------------------------------
