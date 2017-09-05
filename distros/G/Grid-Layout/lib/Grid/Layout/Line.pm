#_{ Encoding and name
=encoding utf8
=head1 NAME

Grid::Layout::Line

=cut
#_}
package Grid::Layout::Line;
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

A C<< Grid::Layout::Line >> is an indefinitismal thin line that runs either
horizontally or vertically from one end of a grid to the other.

The 

Of course, when the grid is rendered, the line might become thicker than indefinitismal thin (think border).

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

    my $line = Grid::Layout::Line->new($V_or_H);

This function should not be called by a user. It is called by L<< Grid::Layout/_add_line >>.

=cut
#_}

  my $class       = shift;
  my $grid_layout = shift;
  my $V_or_H      = shift; # TODO not used...
  my $position    = shift;

  croak "need a Grid::Layout" unless $grid_layout->isa('Grid::Layout');
  croak "need a V or an H"    unless $V_or_H eq 'V' or $V_or_H eq 'H';
  croak "need a position"     unless $position =~ /^\d+$/;

  my $self = {};
  bless $self, $class;

  $self->{grid_layout} = $grid_layout;
  $self->{V_or_H     } = $V_or_H;
  $self->{position   } = $position;
  return $self;

} #_}
sub _previous_track { #_{

  my $self = shift;
  
  croak 'Cannot return previous track, I am line zero' unless $self->{position};

  return $self->{grid_layout}->_track($self->{V_or_H}, $self->{position}-1);

} #_}
sub _next_track { #_{

  my $self = shift;

  croak 'Cannot return next track, I am last line' unless $self->{position} < $self->{grid_layout}->_size($self->{V_or_H});

  return $self->{grid_layout}->_track($self->{V_or_H}, $self->{position});

} #_}
sub previous_line { #_{

  my $self = shift;
  my $dist = shift // 1;
  
  croak "Cannot return previous line $dist, I am line $self->{position}" unless $self->{position}-$dist >= 0;

  return $self->{grid_layout}->_line($self->{V_or_H}, $self->{position}-$dist);

} #_}
sub next_line { #_{

  my $self = shift;
  my $dist = shift // 1;

  croak "Cannot return next line $dist, I am line $self->{position} and the size is " . $self->{grid_layout}->_size($self->{V_or_H}) unless $self->{position}+$dist <= $self->{grid_layout}->_size($self->{V_or_H});

  return $self->{grid_layout}->_line($self->{V_or_H}, $self->{position}+$dist);

} #_}
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
