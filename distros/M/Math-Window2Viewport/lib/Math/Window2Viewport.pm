package Math::Window2Viewport;
use strict;
use warnings FATAL => 'all';
our $VERSION = '1.01';

sub new {
    my $class = shift;
    my $self  = bless {@_}, $class;

    $self->{Sx} = ( $self->{Vr} - $self->{Vl} ) / ( $self->{Wr} - $self->{Wl} );
    $self->{Sy} = ( $self->{Vt} - $self->{Vb} ) / ( $self->{Wt} - $self->{Wb} );
    $self->{Tx} = ( $self->{Vl} * $self->{Wr} - $self->{Wl} * $self->{Vr} ) / ( $self->{Wr} - $self->{Wl} );
    $self->{Ty} = ( $self->{Vb} * $self->{Wt} - $self->{Wb} * $self->{Vt} ) / ( $self->{Wt} - $self->{Wb} );
    
    return $self;
}

sub Dx {
    my ($self,$x) = @_;
    return $self->{Sx} * $x + $self->{Tx};
}

sub Dy {
    my ($self,$y) = @_;
    return $self->{Sy} * $y + $self->{Ty};
}

1;

__END__
=head1 NAME

Math::Window2Viewport - Just another window to viewport mapper.

=head1 SYNOPSIS

  use Math::Window2Viewport;

  my $mapper = Math::Window2Viewport->new(
      Wb => 0, Wt => 1, Wl => 0, Wr => 1,
      Vb => 9, Vt => 0, Vl => 0, Vr => 9,
  );

  my ($x, $y) = (0.5, 0.6);
  my $x2 = int( $mapper->Dx( $x ) );
  my $y2 = int( $mapper->Dy( $y ) );

=head1 DESCRIPTION

This module will convert one set of coordinates (the World Window)
into another set (the Viewport) for the purposes of graphing any
set of points from one system to another.

=head1 METHODS

=over 4

=item * C<new()>

Constructs object. Required parameters:

         Wt                  Vt
    +----------+       +------------+
    |          |       |            |
  Wl|  window  |Wr   Vl|  viewport  |Vr
    |          |       |            |
    +----------+       +------------+
         Wb                  Vb

=back

=over 8

=item * C<Wb>

  world window bottom

=item * C<Wt>

  world window top

=item * C<Wl>

  world window left

=item * C<Wr>

  world window right

=item * C<Vb>

  viewport bottom

=item * C<Vt>

  viewport top

=item * C<Vl>

  viewport left

=item * C<Vr>

  viewport right

=back

=over 4

=item * C<Dx( x )>

Calculates new point C<Dx> for given point C<x>.
Client is responsible for casting value to int.

=item * C<Dy( y )>

Calculates new point C<Dy> for given point C<y>.
Client is responsible for casting value to int.

=back

=head1 EXAMPLE

The following will generate a Fourier synthesized
square wave via L<GD::Simple>:

  use GD::Simple;
  use Math::Window2Viewport;

  my ($width, $height, $res) = (500, 300, .02);
  my $img = GD::Simple->new( $width, $height );
  my $mapper = Math::Window2Viewport->new(
      Wb => -1, Wt => 1, Wl => -1, Wr => 1,
      Vb => $height, Vt => 0, Vl => 0, Vr => $width,
  );

  my (%curr,%prev);
  for (my $x = -1; $x <= 1; $x += $res) {
      my $y = 0;
      for (my $i = 1; $i < 20; $i += 2) {
          $y += 1 / $i * cos( 2 * 3.1459 * $i * $x + ( -3.1459 / 2 ) );
      }
      %curr = ( dx => $mapper->Dx( $x ), dy => $mapper->Dy( $y ) );
      $img->moveTo( @prev{qw(dx dy)} );
      $img->lineTo( @curr{qw(dx dy)} );
      %prev = %curr;
  }

  print $img->png;

Try changing the value for C<$res>. See the example
directory for more.

=begin HTML

<h1>RENDERED EXAMPLES</h1>
<p><img src="https://raw.githubusercontent.com/jeffa/Math-Window2Viewport/master/examples/bar-chart.png" alt="Bar chart" /></p>
<p><img src="https://raw.githubusercontent.com/jeffa/Math-Window2Viewport/master/examples/sine.png" alt="Sine wave" /></p>
<p><img src="https://raw.githubusercontent.com/jeffa/Math-Window2Viewport/master/examples/sawtooth.png" alt="Sawtooth wave" /></p>
<p><img src="https://raw.githubusercontent.com/jeffa/Math-Window2Viewport/master/examples/triangle.png" alt="Triangle wave" /></p>
<p><img src="https://raw.githubusercontent.com/jeffa/Math-Window2Viewport/master/examples/square.png" alt="Square wave" /></p>
<p><img src="https://raw.githubusercontent.com/jeffa/Math-Window2Viewport/master/examples/fsquare.png" alt="Fourier square" /></p>

=end HTML

=head1 SEE ALSO

=over 4

=item * L<https://www.cs.mtsu.edu/~jhankins/files/4250/notes/WinToView/WinToViewMap.html>

=back

=head1 AUTHOR

Jeff Anderson, C<< <jeffa at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2017 Jeff Anderson.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut
