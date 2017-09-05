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
our $VERSION = 0.02;
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

# A grid consists of at least one vertical and a horizontal line:
  $self->_add_line($V_or_H);

} #_}
#_{ add-…-track
sub add_vertical_track { #_{
#_{ POD
=head2 add_vertical_track

    my  $track_v           = $gl->add_vertical_track(…);
    my ($track_v, $line_v) = $gl->add_vertical_track(…);

Adds a L<< vertical track|Grid::Layout::Track >> on the right side of the grid and returns it.

If called in I<list context>, it returns the newly created L<Grid::Layout::Track> and L<Grid::Layout::Line>.
Otherwise, it returns the newly created L<Grid::Layout::Track>.

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

    my  $track_h           = $gl->add_horizontal_track(…);
    my ($track_h, $line_h) = $gl->add_horizontal_track(…);

Adds a L<< horizontal track|Grid::Layout::Track >> at the bottom of the grid and returns it.

If called in I<list context>, it returns the newly created L<Grid::Layout::Track> and L<Grid::Layout::Line>.
Otherwise, it returns the newly created L<Grid::Layout::Track>.

=cut
#_}
  my $self = shift;

  my $y = $self->size_y;
  for my $x (0 .. $self->size_x()-1) {
    $self->_add_cell($x, $y);
  }

  return ($self->_add_track('H'));

} #_}
#_}
sub get_horizontal_line { #_{
#_{ POD
=head2 new

    my $logical_width = 5;
    my $fourth_horizontal_line = $gl->get_horizontal_line($logical_width);

Returns the horizontal line that is C<< $logical_width >> units from the I<< zero-line >> apart.

=cut
#_}

  my $self     = shift;
  my $position = shift;

  return $self->_get_line('H', $position);

} #_}
sub get_vertical_line { #_{
#_{ POD
=head2 new

    my $logical_width = 4;
    my $third_horizontal_line = $gl->get_horizontal_line($logical_width);

Returns the vertical line that is C<< $logical_width >> units from the I<< zero-line >> apart.

=cut
#_}
  
  my $self     = shift;
  my $position = shift;
  return $self->_get_line('V', $position);

} #_}
sub _get_line { #_{
  my $self     = shift;
  my $V_or_H   = shift;
  my $position = shift;

  return ${$self->{$V_or_H}{lines}}[$position];

} #_}
sub add_horizontal_line { #_{
#_{ POD
=head2 add_horizontal_line

    my  $new_line              = $gl->add_horizontal_line(…);
    my ($new_line, $new_track) = $gl->add_horizontal_line(…);

Adds a horizontal L<< line|Grid::Layout::Line >> (and by implication also a horizontal
L<< track||Grid::Layout::Track >>).

If called in list contect, it returns both, if called in scalar contect, it returns the
new line only.

=cut
#_}

  my $self   = shift;

  my ($new_track, $new_line) = $self->add_horizontal_track(@_);

  return $new_line, $new_track if wantarray;
  return $new_line;

} #_}
sub add_vertical_line { #_{
#_{ POD
=head2 add_vertical_line

    my  $new_line              = $gl->add_vertical_line(…);
    my ($new_line, $new_track) = $gl->add_vertical_line(…);

Adds a vertical L<< line|Grid::Layout::Line >> (and by implication also a vertical
L<< track||Grid::Layout::Track >>).

If called in list contect, it returns both, if called in scalar contect, it returns the
new line only.

=cut
#_}
  my $self   = shift;

  my ($new_track, $new_line) = $self->add_vertical_track(@_);

  return $new_line, $new_track if wantarray;
  return $new_line;
} #_}
sub _add_track { #_{
#_{ POD
=head2 _add_track

    my $track = $gl->_add_track($V_or_H);

Internal function. Returns a vertical or horizontal L<< track|Grid::Layout::Track >>, depending on the value of C<< $V_or_H >> (whose should be either C<'V'> or C<'H'>).

=cut
#_}

  my $self   = shift;
  my $V_or_H = shift;

  my $new_track = Grid::Layout::Track->new($self, $V_or_H, scalar @{$self->{$V_or_H}->{tracks}});

# $self->_add_line($V_or_H) unless @{$self->{$V_or_H}->{tracks}}; # An extra line (the first one) needs to be added for the first vertical and horizontal track.
  my $new_line = $self->_add_line($V_or_H);

  push @{$self->{$V_or_H}{tracks}}, $new_track;

  return ($new_track, $new_line) if wantarray;
  return  $new_track;

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

# print "\n\n  ***\n    ", scalar @{$self->{$V_or_H}->{lines}}, "\n\n    *****\n";

  my $new_line = Grid::Layout::Line->new($self, $V_or_H, scalar @{$self->{$V_or_H}->{lines}});

  push @{$self->{$V_or_H}->{lines}}, $new_line;

  return $new_line;

} #_}
sub area { #_{
#_{ POD
=head2 area

    $gl->area(…)

Create an L<< area|Grid::Layout::Area >>

=head3 creating an area from lines

    my $vertical_line_from    = $gl->add_vertical_line(…);
    my $horizontal_line_from  = $gl->add_vertical_line(…);

    my $vertical_line_to      = $gl->add_vertical_line(…);
    my $horizontal_line_to    = $gl->add_vertical_line(…);

    my $area = $gl->area (
      $vertical_line_from, $horizontal_line_from,
      $vertical_line_to   ,$horizontal_line_to
    );

=head3 creating an area from tracks

    my $vertical_track_from   = $gl->add_vertical_track(…);
    my $horizontal_track_from = $gl->add_vertical_track(…);

    my $vertical_track_to     = $gl->add_vertical_track(…);
    my $horizontal_track_to   = $gl->add_vertical_track(…);

    my $area = $gl->area($vertical_track_from, $horizontal_track_from, $vertical_track_to, $vertical_track_to);


Define an L<< area|Grid::Layout::Area >> bound by the four tracks. Both the from and the to tracks are included.

An area that lies on only I<one> L<< track|Grid::Layout::Track >> can be created with
L<< Grid::Layout::Track/area >>.

=cut
#_}
  
  my $self = shift;

  if ($_[0]->isa('Grid::Layout::Track')) { #_{

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
  elsif ($_[0]->isa('Grid::Layout::Line')) { #_{

     my $line_v_from = shift;
     my $line_h_from = shift;
     my $line_v_to   = shift;
     my $line_h_to   = shift;

        print($line_v_from, "\n");
        print($line_h_from, "\n");
        print($line_v_to  , "\n");
        print($line_h_to  , "\n");

        print "Strawberry\n";
        $line_v_from->_next_track;
        $line_h_from->_next_track;
        $line_v_to->_previous_track;
        $line_h_to->_previous_track;
   
     croak 'line_v_from is not a Grid::Layout::Line' unless $line_v_from->isa('Grid::Layout::Line');
     croak 'line_v_to   is not a Grid::Layout::Line' unless $line_v_to  ->isa('Grid::Layout::Line');
     croak 'line_h_from is not a Grid::Layout::Line' unless $line_h_from->isa('Grid::Layout::Line');
     croak 'line_h_to   is not a Grid::Layout::Line' unless $line_h_to  ->isa('Grid::Layout::Line');
   

     print "---->\n";
    return $self->area($line_v_from->_next_track    , $line_h_from->_next_track,
                       $line_v_to  ->_previous_track, $line_h_to  ->_previous_track);

  } #_}

  croak "need 4 Grid::Layout::Track's or 4 Grid::Layout::Line's";

} #_}
sub size_x { #_{
#_{ POD
=head2 size_x

    my $x = $gl->size_x();

Returns the horizontal size (x axis) in logical cell units.

=cut
#_}
  my $self = shift;
  return scalar @{$self->{'V'}{lines}} -1;
} #_}
sub size_y { #_{
#_{ POD
=head2 size_y

    my $y = $gl->size_y();

Returns the vertical size (y axis) in logical cell units.

=cut
#_}
  my $self = shift;
  return scalar @{$self->{'H'}{lines}} -1;
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

  croak 'need V or H'     unless $V_or_H eq 'V' or $V_or_H eq 'H';
  croak 'need a position' unless $position =~ /^\d+$/;

  return ${$self->{$V_or_H}->{lines}}[$position];

} #_}
sub _track { #_{
#_{ POD
=head2 _track

    my $track = $gl->_track($V_or_H, $position)

Returns the C<< $position >>th track in vertical or horizontal direction.

=cut
#_}

  my $self     = shift;
  my $V_or_H   = shift;
  my $position = shift;

  croak 'need V or H'     unless $V_or_H eq 'V' or $V_or_H eq 'H';
  croak 'need a position' unless $position =~ /^\d+$/;

  return ${$self->{$V_or_H}->{tracks}}[$position];

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
#_{ POD: Source Code

=head1 Source Code

The source code is on L<< github|https://github.com/ReneNyffenegger/perl-Grid-Layout >>. Meaningful pull requests are welcome.

=cut

#_}

'tq84';
