package Math::JSpline;

use 5.010001;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Math::JSpline ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	JSpline
);

our $VERSION = '0.02';



# Do a J-Spline, with facility to handle ending points properly as well (or do loops too)
sub JSpline { # link=0 (join), 1 (simple clamp), 2 (tangent clamp), or 3 (loop)
  my ($sl,$a,$b,$link,@pts)=@_;	# sl usually ~ 5.  a=b=1 for b-spline, a=b=0 for 4-point subdiv, etc
  my @ret;

  foreach my $px(@pts) {

    my(@x)=@{$px}; 	# Where the spline gets built

    my $k = 0;
    while ( $k++ < $sl ) {

      if($link==1) {	# simple clamping	0Pn = 20Pn–1 – 0Pn–2 and 0Pn+1 = 20Pn–1 – 0Pn–3.
        push(@x,$x[$#x]*2-$x[$#x-1]);		# 0P–1 = 20P0 – 0P1 and 0P–2 = 20P0 – 0P2. 
        push(@x,$x[$#x-1]*2-$x[$#x-3]);
        my $px1=$x[0]*2-$x[1];		# 0Pn = 20Pn–1 – 0Pn–2 and 0Pn+1 = 20Pn–1 – 0Pn–3.
        my $px2=$x[0]*2-$x[2];
        @x=($px2,$px1,@x);
  
  
      } elsif($link==2) { # tangent preservation	0P–1 = (9–s)/4 0P0 + (s–3)/2 0P1 + (1–s)/4 0P2 and 0P–2 = (12–s)/2 0P0 + (s–8) 0P1 + (6–s)/2 0P2 
        my $px1=(9-$a)/4  * $x[0] + ($a-3)/2 * $x[1] + (1-$a)/4 * $x[2];
        my $px2=(12-$a)/2 * $x[0] + ($a-8)   * $x[1] + (6-$a)/2 * $x[2];
        @x=($px2,$px1,@x);
        $px1=(9-$a)/4  * $x[$#x] + ($a-3)/2 * $x[$#x-1] + (1-$a)/4 * $x[$#x-2];
        $px2=(12-$a)/2 * $x[$#x] + ($a-8)   * $x[$#x-1] + (6-$a)/2 * $x[$#x-2];
        push @x,$px1; push @x,$px2;
      }
  
      my $j = 0; my (@tx,$ptx);
      while ( $j <= $#x ) {
        last if(($j==$#x)&&($link!=3));
        if (( $j == 0 ) && ($link!=3)){    	# Anchor start of output line to the start point
          push( @tx, $x[$j] );
        }
  
        elsif(( $j + 1 <= $#x )||($link==3)) {    # 
	  if($link==3) {
            $ptx = ( $a * $x[( $j - 1 )%($#x+1)] + ( 8 - 2 * $a ) * $x[$j] + $a * $x[( $j + 1 )%($#x+1)] ) / 8;
	  } else {
            $ptx = ( $a * $x[ $j - 1 ] + ( 8 - 2 * $a ) * $x[$j] + $a * $x[ $j + 1 ] ) / 8;
	  }
          push( @tx, $ptx );
        }
  
        if (($link==3)||( $j + 2 <= $#x && $j > 0)) {
          my ( $ptx );
	  if($link==3) {
            $ptx = ( ( $b - 1 ) * $x[($j -1)%($#x+1)] + ( 9 - $b ) * $x[ $j ] + ( 9 - $b ) * $x[( $j + 1 )%($#x+1)] + ( $b - 1 ) * $x[( $j + 2 )%($#x+1)] ) / 16;
          } else {
            $ptx = ( ( $b - 1 ) * $x[$j -1] + ( 9 - $b ) * $x[ $j ] + ( 9 - $b ) * $x[ $j + 1 ] + ( $b - 1 ) * $x[ $j + 2 ] ) / 16;
	  }
          push( @tx, $ptx );
        }
        $j++;
      }


      if($link==3) {
        # skip push
      } elsif($link>0) {
        @tx=@tx[3..$#tx-2];
      } else {
        push( @tx, $x[$#x] );
      }
      
      @x=@tx;
    }
    if($link==3) {
      push @x,$x[0]; #join end to start for drawing
    }
    push @ret,\@x;
  }
  return @ret;
} # jsplinexyl


# Preloaded methods go here.

1;
__END__

=head1 NAME

Math::JSpline - Native perl extension for multi-dimensional J-Spline curves (open and closed)

=head1 SYNOPSIS

  use Math::JSpline;
  my($newx,$newy)=&JSpline($subdivision_level, $a, $b, $end_type, \@x, \@y);

where

  $subdivision_level determines how many points to interpolate (1 doubles $#x in the above example). 
  when $a = $b, this is the "s" paramater described below
  $end_type is how you want to deal with the start and end points.
	3=join them up (loop). 2=tangent clamp, 1=end clamp, 0=simple join (refer "see also" below)
  \@x... any number of array references come next

=head1 DESCRIPTION

J-Splines are awesome: they're a class of spline curves that take a 
shape parameter, s.  Setting s=1 yields uniform cubic B-spline curves,
s=0 gives four-point subdivision curves, s=0.5 are uniform quintic
B-splines - and more. "s" basically governs the "snappiness" of the
curve.

Math::JSpline, lets you choose any combination of J-Spline parameters
for any number of input arrays, with a range of different starting
and ending schemes (eg: open or closed loops).  Use it for 2D drawing,
3D graphics, or any other kind of interpolation you might need.

=head2 EXPORT

JSpline

=head2 EXAMPLE

  #!perl -w
  use Math::JSpline;
  my ($x)=&JSpline(1,0.5,0.5,3,[1,2,3,4]);
  print join(" ",@{$x});

returns

  1.25 1.375 2 2.5 3 3.625 3.75 2.5 1.25

=head2 2D Demo

The example source included in this distro produces the following
output (see also: the js.pdf below)

=begin html

<p><center><img src="http://www.chrisdrake.com/draw-some-jsplines.gif" width="900" height="300" alt="Example output from draw-some-jsplines (JSpline.pm)" /></center></p>

=end html


=head1 SEE ALSO

http://faculty.cs.tamu.edu/schaefer/research/js.pdf


=head1 AUTHOR

Chris Drake, E<lt>cdrake@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Chris Drake

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
