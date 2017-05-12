package GD::Arrow;
# $Id: Arrow.pm,v 1.7 2004/10/25 17:22:27 tcaine Exp $

use strict;
use warnings;
use vars qw( $VERSION @ISA );
use GD;

$VERSION = '0.01';
@ISA = qw( GD::Polygon );

sub x1    { shift->{X1}    }
sub y1    { shift->{Y1}    }
sub x2    { shift->{X2}    }
sub y2    { shift->{Y2}    }
sub width { shift->{WIDTH} }

package GD::Arrow::Full;

use strict;
use warnings;
use vars qw( $VERSION @ISA );
use Carp;
use GD;

$VERSION = '0.01';
@ISA = qw( GD::Arrow );

sub new {
    my $class = shift;
    my %arg = @_;
    my ($x1, $y1, $x2, $y2, $width);
    my $self = $class->SUPER::new();

    foreach ( keys %arg ) {
        if    (/^-?X1$/i)    { $self->{X1} = $x1 = $arg{$_} }
        elsif (/^-?Y1$/i)    { $self->{Y1} = $y1 = $arg{$_} }
        elsif (/^-?X2$/i)    { $self->{X2} = $x2 = $arg{$_} }
        elsif (/^-?Y2$/i)    { $self->{Y2} = $y2 = $arg{$_} }
        elsif (/^-?WIDTH$/i) { $self->{WIDTH} = $width = $arg{$_} }
    }

    $self->{WIDTH} = $width = 6 if !defined($self->{WIDTH});

    croak "" . __PACKAGE__ . "->new() requires 4 named parameters"
        if !defined($self->{X1}) || 
           !defined($self->{Y1}) ||
           !defined($self->{X2}) ||
           !defined($self->{Y2});

    my $double_width = $width * 2;
    my $theta = atan2($y1-$y2,$x1-$x2);

    $self->addPt(
        sprintf('%.0f', $x2+$width*sin($theta)),
        sprintf('%.0f', $y2-$width*cos($theta))
    );
    $self->addPt(
        sprintf('%.0f', $x2-$width*sin($theta)),
        sprintf('%.0f', $y2+$width*cos($theta))
    );
    $self->addPt(
        sprintf('%.0f', $x1-$width*sin($theta)-$double_width*cos($theta)),
        sprintf('%.0f', $y1-$double_width*sin($theta)+$width*cos($theta))
    );
    $self->addPt(
        sprintf('%.0f', $x1-$double_width*sin($theta)-$double_width*cos($theta)),
        sprintf('%.0f', $y1-$double_width*sin($theta)+$double_width*cos($theta))
    );
    $self->addPt($x1,$y1);
    $self->addPt(
        sprintf('%.0f', $x1+$double_width*(sin($theta)-cos($theta))),
        sprintf('%.0f', $y1+$double_width*(-sin($theta)-cos($theta)))
    );
    $self->addPt(
        sprintf('%.0f', $x1+$width*sin($theta)-$double_width*cos($theta)),
        sprintf('%.0f', $y1-$double_width*sin($theta)-$width*cos($theta))
    );

    return $self; 
}

package GD::Arrow::LeftHalf;

use strict;
use warnings;
use vars qw( $VERSION @ISA );
use Carp;
use GD;

$VERSION = '0.01';
@ISA = qw( GD::Arrow );

sub new {
    my $class = shift;
    my %arg = @_;
    my ($x1, $y1, $x2, $y2, $width);
    my $self = $class->SUPER::new();

    foreach ( keys %arg ) {
        if    (/^-?X1$/i)    { $self->{X1} = $x1 = $arg{$_} }
        elsif (/^-?Y1$/i)    { $self->{Y1} = $y1 = $arg{$_} }
        elsif (/^-?X2$/i)    { $self->{X2} = $x2 = $arg{$_} }
        elsif (/^-?Y2$/i)    { $self->{Y2} = $y2 = $arg{$_} }
        elsif (/^-?WIDTH$/i) { $self->{WIDTH} = $width = $arg{$_} }
    }

    $self->{WIDTH} = $width = 6 if !defined($self->{WIDTH});

    croak "" . __PACKAGE__ . "->new() requires 4 named parameters"
        if !defined($self->{X1}) || 
           !defined($self->{Y1}) ||
           !defined($self->{X2}) ||
           !defined($self->{Y2});

    my $double_width = $width * 2;
    my $theta = atan2($y1-$y2,$x1-$x2);

    $self->addPt($x2, $y2);
    $self->addPt(
        sprintf('%.0f', $x2+$width*sin($theta)),
        sprintf('%.0f', $y2-$width*cos($theta))
    );
    $self->addPt(
        sprintf('%.0f', $x1+$width*sin($theta)-$double_width*cos($theta)),
        sprintf('%.0f', $y1-$double_width*sin($theta)-$width*cos($theta))
    );
    $self->addPt(
        sprintf('%.0f', $x1+$double_width*(sin($theta)-cos($theta))),
        sprintf('%.0f', $y1+$double_width*(-sin($theta)-cos($theta)))
    );
    $self->addPt($x1,$y1);

    return $self;
}

package GD::Arrow::RightHalf;

use strict;
use warnings;
use vars qw( $VERSION @ISA );
use Carp;
use GD;

$VERSION = '0.01';
@ISA = qw( GD::Arrow );

sub new {
    my $class = shift;
    my %arg = @_;
    my ($x1, $y1, $x2, $y2, $width);
    my $self = $class->SUPER::new();

    foreach ( keys %arg ) {
        if    (/^-?X1$/i)    { $self->{X1} = $x1 = $arg{$_} }
        elsif (/^-?Y1$/i)    { $self->{Y1} = $y1 = $arg{$_} }
        elsif (/^-?X2$/i)    { $self->{X2} = $x2 = $arg{$_} }
        elsif (/^-?Y2$/i)    { $self->{Y2} = $y2 = $arg{$_} }
        elsif (/^-?WIDTH$/i) { $self->{WIDTH} = $width = $arg{$_} }
    }

    $self->{WIDTH} = $width = 6 if !defined($self->{WIDTH});

    croak "" . __PACKAGE__ . "->new() requires 4 named parameters"
        if !defined($self->{X1}) || 
           !defined($self->{Y1}) ||
           !defined($self->{X2}) ||
           !defined($self->{Y2});

    my $double_width = $width * 2;
    my $theta = atan2($y1-$y2,$x1-$x2);

    $self->addPt($x2, $y2);
    $self->addPt(
        sprintf('%.0f', $x2-$width*sin($theta)),
        sprintf('%.0f', $y2+$width*cos($theta))
    );
    $self->addPt(
        sprintf('%.0f', $x1-$width*sin($theta)-$double_width*cos($theta)),
        sprintf('%.0f', $y1-$double_width*sin($theta)+$width*cos($theta))
    );
    $self->addPt(
        sprintf('%.0f', $x1-$double_width*sin($theta)-$double_width*cos($theta)),
        sprintf('%.0f', $y1-$double_width*sin($theta)+$double_width*cos($theta))
    );
    $self->addPt($x1,$y1);

    return $self;
}


1;
__END__

=head1 NAME

GD::Arrow - draw arrows using GD

=head1 SYNOPSIS

  use GD;
  use GD::Arrow;

  my $width = 8;
  my ($x1, $y1) = (100, 10);
  my ($x2, $y2) = (100, 190);
  my ($x3, $y3) = (10, 30);
  my ($x4, $y4) = (190, 75);

  my $arrow = GD::Arrow::Full->new( 
                  -X1    => $x1, 
                  -Y1    => $y1, 
                  -X2    => $x2, 
                  -Y2    => $y2, 
                  -WIDTH => $width,
              );

  my $image = GD::Image->new(200, 200);
  my $white = $image->colorAllocate(255, 255, 255);
  my $black = $image->colorAllocate(0, 0, 0);
  my $blue = $image->colorAllocate(0, 0, 255);
  my $yellow = $image->colorAllocate(255, 255, 0);
  $image->transparent($white);

  $image->filledPolygon($arrow,$blue);
  $image->polygon($arrow,$black);

  my $half_arrow_1 = GD::Arrow::LeftHalf->new( 
                         -X1    => $x3, 
                         -Y1    => $y3, 
                         -X2    => $x4, 
                         -Y2    => $y4, 
                         -WIDTH => $width,
                     );

  my $half_arrow_2 = GD::Arrow::LeftHalf->new( 
                         -X1    => $x4, 
                         -Y1    => $y4, 
                         -X2    => $x3, 
                         -Y2    => $y3, 
                         -WIDTH => $width 
                     );

  $image->filledPolygon($half_arrow_1,$blue);
  $image->polygon($half_arrow_1,$black);

  $image->filledPolygon($half_arrow_2,$yellow);
  $image->polygon($half_arrow_2,$black);

  open IMAGE, "> image.png" or die $!;
  binmode(IMAGE, ":raw");
  print IMAGE $image->png;
  close IMAGE;

  exit(0);

=head1 DESCRIPTION

This is a subclass of GD::Polygon used to draw an arrow between two vertices.

GD::Arrow::Full draws a full arrow between two verticies.

                                  |\
           +----------------------+ \
  (X2, Y2) *                         * (X1, Y1)
           +----------------------+ /
                                  |/

GD::Arrow::RightHalf draws a half arrow between two verticies.

  (X2, Y2) *-------------------------* (X1, Y1)
           +----------------------+ /
                                  |/

GD::Arrow::LeftHalf draws a half arrow between two verticies.

                                  |\
           +----------------------+ \
  (X2, Y2) *-------------------------* (X1, Y1)

=head1 SEE ALSO

GD::Polygon

=head1 CREDITS

The equations used to determine the critical verticies to represent a GD::Arrow was based on Hideki Ono's makefeedmap software.  Makefeedmap can be found at http://www.ono.org/software/makefeedmap/.

=head1 AUTHOR

Todd Caine, E<lt>todd@pobox.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Todd Caine

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

