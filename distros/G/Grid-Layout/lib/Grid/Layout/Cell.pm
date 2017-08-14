#_{ Encoding and name
=encoding utf8
=head1 NAME
Grid::Layout::Cell
=cut
#_}
package Grid::Layout::Cell;
#_{ use …
use warnings;
use strict;
use utf8;

use Carp;
 #_}
our $VERSION = 0.01;
#_{ Synopsis

=head1 SYNOPSIS
=cut
#_}
#_{ Description

=head1 DESCRIPTION

A C<< Grid::Layout::Cell >> is the intersection of two orthogonal
L<< Grid::Layout::Track >>s.

It is the smallest unit with size in a grid.

Although the I<logical size> for all cells is equal, the I<physical size> of rendered cell can vary.

=cut
#_}
#_{ Methods
#_{ POD
=head1 METHODS
=cut
#_}
sub new { #_{
#_{ POD
=head2 new

=cut
#_}


  my $class       = shift;

  my $grid_layout = shift;
  my $x           = shift;
  my $y           = shift;

  croak 'Grid::Layout expected' unless $grid_layout->isa('Grid::Layout'       );
  croak 'Number expected'       unless $x =~ /^\d+/;
  croak 'Number expected'       unless $y =~ /^\d+/;

  my $self        = {};

  $self->{grid_layout} = $grid_layout;
  $self->{x          } = $x;
  $self->{y          } = $y;

  bless $self, $class;
  return $self;

} #_}
#_{ x/y
sub x { #_{
  my $self = shift;
  return $self->{x};
} #_}
sub y { #_{
  my $self = shift;
  return $self->{y};
} #_}
#_}
#_}
#_{ POD: Copyright

=head1 Copyright
Copyright © 2017 René Nyffenegger, Switzerland. All rights reserved.
This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at: L<http://www.perlfoundation.org/artistic_license_2_0>
=cut

#_}

'tq84';
