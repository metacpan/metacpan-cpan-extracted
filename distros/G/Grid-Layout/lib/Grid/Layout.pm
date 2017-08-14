#_{ Encoding and name
=encoding utf8
=head1 NAME
Grid::Layout - Create grid based layouts.
=cut
#_}
package Grid::Layout;
#_{ use …
use warnings;
use strict;
use utf8;

use Carp;

use Grid::Layout::Area;
use Grid::Layout::Cell;
use Grid::Layout::Line;
use Grid::Layout::Track;
 #_}
our $VERSION = 0.01;
#_{ Synopsis

=head1 SYNOPSIS

=cut
#_}
#_{ Description

=head1 DESCRIPTION
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

    use Grid::Layout;

    my $gl = Grid::Layout->new();

=cut
#_}


  my $class = shift;

  my $self = {};

  bless $self, $class;

  $self->_init_V_or_H('V');
  $self->_init_V_or_H('H');

  $self->{cells} = [];

  return $self;

} #_}
sub _init_V_or_H { #_{
#_{ POD
=head2 _init_V_or_H

    $self->_init_V_or_H('V');
    $self->_init_V_or_H('H');

This method is called by L</new> twice to initialize the vertical and the horizontal components of the layout.

The parameter C<'V'> or C<'H'> indiciates which componenents to initialize.

=cut
#_}

  my $self   = shift;
  my $V_or_H = shift;

  $self->{$V_or_H}{tracks} = [];
  $self->{$V_or_H}{lines } = [];

} #_}
sub add_vertical_track { #_{
#_{ POD
=head2 add_vertical_track

=cut
#_}
  my $self = shift;


  my $x = $self->size_x();
  for my $y (0 .. $self->size_y() -1) {
    $self->_add_cell($x, $y);
  }

  return $self->_add_track('V');

} #_}
sub add_horizontal_track { #_{
#_{ POD
=head2 add_horizontal_track

=cut
#_}
  my $self = shift;

  my $y = $self->size_y;
  for my $x (0 .. $self->size_x()-1) {
    $self->_add_cell($x, $y);
  }

  return $self->_add_track('H');

} #_}
sub _add_track { #_{
#_{ POD
=head2 _add_track

=cut
#_}

  my $self   = shift;
  my $V_or_H = shift;

  my $new_track = Grid::Layout::Track->new($self, $V_or_H, scalar @{$self->{$V_or_H}->{tracks}});

  $self->_add_line($V_or_H) unless @{$self->{$V_or_H}->{tracks}}; # An extra line (the first one) needs to be added for the first vertical and horizontal track.
  $self->_add_line($V_or_H);

  push @{$self->{$V_or_H}{tracks}}, $new_track;

  return $new_track;

} #_}
sub _add_line { #_{
#_{ POD
=head2 _add_line

    $self->_add_line($V_or_H);

Internal function, called by L</_add_track>, to add a vertical or horizontal L<< Grid::Layout::Line >>.

=cut
#_}

  my $self   = shift;
  my $V_or_H = shift;

  push @{$self->{$V_or_H}->{lines}}, Grid::Layout::Line->new($self);

} #_}
sub area { #_{
#_{ POD
=head2 area

    my $vertical_track_from   = $gl->add_vertical_track(…);
    my $horizontal_track_from = $gl->add_vertical_track(…);

    my $vertical_track_to     = $gl->add_vertical_track(…);
    my $horizontal_track_to   = $gl->add_vertical_track(…);

    my $area = $gl->area($vertical_track_from, $horizontal_track_from, $vertical_track_to, $vertical_track_to);


Define an L<< Area|Grid::Layout::Area >> bound by the four Tracks;

=cut
#_}
  
  my $self = shift;

  my $track_v_from = shift;
  my $track_h_from = shift;
  my $track_v_to   = shift;
  my $track_h_to   = shift;

  croak 'track_v_from is not a Grid::Layout::Track' unless $track_v_from->isa('Grid::Layout::Track');
  croak 'track_v_to   is not a Grid::Layout::Track' unless $track_v_to  ->isa('Grid::Layout::Track');
  croak 'track_h_from is not a Grid::Layout::Track' unless $track_h_from->isa('Grid::Layout::Track');
  croak 'track_h_to   is not a Grid::Layout::Track' unless $track_h_to  ->isa('Grid::Layout::Track');

  croak 'track_v_from is not a vertical' unless $track_v_from->{V_or_H} eq 'V';
  croak 'track_v_to   is not a vertical' unless $track_v_to  ->{V_or_H} eq 'V';
  croak 'track_h_from is not a vertical' unless $track_h_from->{V_or_H} eq 'H';
  croak 'track_h_to   is not a vertical' unless $track_h_to  ->{V_or_H} eq 'H';

  for my $x ($track_v_from->{position} .. $track_v_to->{position}) {
  for my $y ($track_h_from->{position} .. $track_h_to->{position}) {
    if ($self->cell($x, $y)->{area}) {
       croak "cell $x/$y already belongs to an area";
    }
  }}

  my $area = Grid::Layout::Area->new($track_v_from, $track_h_from, $track_v_to, $track_h_to);

  for my $x ($track_v_from->{position} .. $track_v_to->{position}) {
  for my $y ($track_h_from->{position} .. $track_h_to->{position}) {
    $self->cell($x, $y)->{area}= $area;
  }}

  return $area;

} #_}
sub size_x { #_{
#_{ POD
=head2 size_x

    my $x = $gl->size_x();

Returns the horizontal size (x axis) in logical cell units.

=cut
#_}
  my $self = shift;
  return scalar @{$self->{'V'}{tracks}};
} #_}
sub size_y { #_{
#_{ POD
=head2 size_y

    my $y = $gl->size_y();

Returns the vertical size (y axis) in logical cell units.

=cut
#_}
  my $self = shift;
  return scalar @{$self->{'H'}{tracks}};
} #_}
sub size { #_{
#_{ POD
=head2 size

Returns size of grid (nof vertical tracks x nof horizontal tracks);

    my ($v, $h) = $gl -> size();

=cut
#_}

  my $self = shift;

  return ($self->size_x, $self->size_y);
} #_}
sub _size { #_{
#_{ POD
=head2 _size

Internal use.


=cut
#_}

  my $self   = shift;
  my $V_or_H = shift;

  return scalar @{$self->{$V_or_H}{tracks}},

} #_}
sub cell { #_{
#_{ POD
=head2 cell

    my $track_v = $gl->add_vertical_track(…);
    my $track_h = $gl->add_horizontal_track(…);

    my $cell_1 = $gl->cell($x, $y);
    my $cell_2 = $gl->cell($track_v, $track_h);

Return the L<< Grid::Layout::Cell >> at horizontal position C<$x> and vertical position C<$y> or where C<$track_v> and C<$track_h> intersects.

=cut
#_}

  my $self = shift;
  my $x    = shift;
  my $y    = shift;

  unless ($x =~ /^\d+$/) {
    if ($x->isa('Grid::Layout::Track')) {
      croak '$x is not a vertical track' unless $x->{V_or_H} eq 'V';
      $x = $x->{position};
    }
    else {
      croak '$x neither number nor Grid::Layout::Track';
    }
  }
  unless ($y =~ /^\d+$/) {
    if ($y->isa('Grid::Layout::Track')) {
      croak '$y is not a vertical track' unless $y->{V_or_H} eq 'H';
      $y = $y->{position};
    }
    else {
      croak '$y neither number nor Grid::Layout::Track';
    }
  }

  return $self->{cells}->[$x][$y];

} #_}
sub _add_cell { #_{
#_{ POD
=head2 _add_cell

Internal use.

=cut
#_}

  my $self = shift;
  my $x    = shift;
  my $y    = shift;

  $self->{cells}->[$x][$y] = Grid::Layout::Cell->new($self, $x, $y);

} #_}
sub line_x { #_{
#_{ POD
=head2 line_x

    my $line = $gl->line_x($postition);

Returns the C<< $position >>th line in  horizontal direction.

=cut
#_}

  my $self     = shift;
  my $position = shift;
  return $self->_line('V', $position);

} #_}
sub line_y { #_{
#_{ POD
=head2 line_y

    my $line = $gl->line_y($postition);

Returns the C<< $position >>th line in  vertical direction.

=cut
#_}

  my $self     = shift;
  my $position = shift;

  return $self->_line('H', $position);

} #_}
sub _line { #_{
#_{ POD
=head2 _line

    my $line = $gl->_line($V_or_H, $position)

Returns the C<< $position >>th line in vertical or horizontal direction.

=cut
#_}

  my $self     = shift;
  my $V_or_H   = shift;
  my $position = shift;

  return ${$self->{$V_or_H}->{lines}}[$position];

} #_}
sub VH_opposite { #_{
#_{ POD
=head2 VH_opposite

    my $o1 = Grid::Layout::VH_opposite('H');
    my $02 = Grid::Layout::VH_opposite('V');

Static method. Returns C<'V'> if passed C<'H'> and vice versa.

=cut
#_}

  my $V_or_H = shift;

  return 'H' if $V_or_H eq 'V';
  return 'V' if $V_or_H eq 'H';

  croak "$V_or_H is neither H nor V";

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
