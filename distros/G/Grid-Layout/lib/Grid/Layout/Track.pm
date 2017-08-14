#_{ Encoding and name
=encoding utf8
=head1 NAME
Grid::Layout::Track
=cut
#_}
package Grid::Layout::Track;
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

a C<< Grid::Layout::Track >> is the space between to adjacent L<< Grid::Layout::Line >>s.

Usually, a horizontal track is referred to as a row, a vertical track as a column.

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

Creates a C<< Grid::Layout::Track >>. Should not be called by the user.
The constructor is called by L<< Grid::Layout/add_track >> instead.

=cut
#_}

  my $class       = shift;
  my $grid_layout = shift;
  my $V_or_H      = shift;
  my $position    = shift;

  croak 'Grid::Layout expected' unless $grid_layout->isa('Grid::Layout');
  croak 'V or H expected'       unless $V_or_H eq 'V' or $V_or_H eq 'H';
  croak 'position not a number' unless $position =~ /^\d+$/;

  my $self        = {};

  $self -> {grid_layout} = $grid_layout;
  $self -> {V_or_H     } = $V_or_H;
  $self -> {position   } = $position;


  bless $self, $class;
  return $self;

} #_}
#_{ line_left/right/above/beneath
sub line_left { #_{
#_{ POD
=head2 line_left

Returns the line to the left of the track.

Only applicable if the track is vertical (C<< $self->{V_or_H} eq 'V' >>).

=cut
#_}

  my $self = shift;

  croak 'Type of track is not vertical' unless $self->{V_or_H} eq 'V';

  return $self->{grid_layout}->line_x($self->{position});

} #_}
sub line_right { #_{
#_{ POD
=head2 line_right

Returns the line to the right of the track.

Only applicable if the track is vertical (C<< $self->{V_or_H} eq 'V' >>).

=cut
#_}

  my $self = shift;

  croak 'Type of track is not vertical' unless $self->{V_or_H} eq 'V';

  return $self->{grid_layout}->line_x($self->{position} + 1);

} #_}
sub line_above { #_{
#_{ POD
=head2 line_left

Returns the line above the track.

Only applicable if the track is vertical (C<< $self->{V_or_H} eq 'H' >>).

=cut
#_}

  my $self = shift;

  croak 'Type of track is not horizontal' unless $self->{V_or_H} eq 'H';

  return $self->{grid_layout}->line_y($self->{position});

} #_}
sub line_beneath { #_{
#_{ POD
=head2 line_beneath

Returns the line beneath the track.

Only applicable if the track is vertical (C<< $self->{V_or_H} eq 'H' >>).

=cut
#_}

  my $self = shift;

  croak 'Type of track is not horizontal' unless $self->{V_or_H} eq 'H';

  return $self->{grid_layout}->line_y($self->{position} + 1);
} #_}
#_}
sub cells { #_{
#_{ POD
=head2 cells

    my @cells = $track->cells();

Return an array of the L<< cells|Grid::Layout::Cell >> in the track.

=cut
#_}

  my $self = shift;

  my @ret=();
  for my $p (0 .. $self->{grid_layout}->_size(Grid::Layout::VH_opposite($self->{V_or_H}))-1) {
    if ($self->{V_or_H} eq 'V') {
      push @ret, $self->{grid_layout}->cell($self->{position}, $p);
    }
    else {
      push @ret, $self->{grid_layout}->cell($p, $self->{position});
    }
  }

  return @ret;

} #_}
sub area { #_{
#_{ POD
=head2 area

=cut
#_}

  my $self       = shift;
  my $track_from = shift;
  my $track_to   = shift;

  croak '$track_from must be a Grid::Layout::Track' unless $track_from->isa('Grid::Layout::Track');
  croak '$track_to   must be a Grid::Layout::Track' unless $track_to  ->isa('Grid::Layout::Track');

  croak '$track_from must be other direction' unless $track_from->{V_or_H} eq Grid::Layout::VH_opposite($self->{V_or_H});
  croak '$track_from must be other direction' unless $track_to  ->{V_or_H} eq Grid::Layout::VH_opposite($self->{V_or_H});

  if ($self->{V_or_H} eq 'V') {
    return $self->{grid_layout}->area($self, $track_from, $self, $track_to);
  }
  else {
    return $self->{grid_layout}->area($track_from, $self, $track_to, $self);
  }


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
