#_{ Encoding and name
=encoding utf8
=head1 NAME

Grid::Layout::Area

=cut
#_}
package Grid::Layout::Render;
#_{ use …
use warnings;
use strict;
use utf8;

use Carp;

use Grid::Layout;
 #_}
our $VERSION = $Grid::Layout::VERSION;
#_{ Synopsis

=head1 SYNOPSIS

C<Grid::Layout::Render> iterate over an L<< Grid::Layout >> and call appropriate call backs so as to render the grid on a device.

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
sub top_to_bottom_left_to_right { #_{
#_{ POD
=head2 new

    use Grid::Layout;

    my $gl = Grid::Layout->new(…);

    Grid::Layout::Render::top_to_bottom_left_to_right(
      $gl,
      sub { # call back for next horizontal L<< track|Grid::Layout::Track >>.
        my vertical_track = shift;
      },
      sub { # call back for each L<< cell|Grid::Layout::Cell> in the horizontal track
        my $cell = shift;
      },
      sub { # call back when a horizontal track is finished
        my vertical_track = shift;
      }
    );    

=cut
#_}

  my $gl              = shift;
  my $sub_next_track  = shift;
  my $sub_next_cell   = shift;
  my $sub_track_done  = shift;

  croak "Need a Grid::Layout"            unless $gl->isa('Grid::Layout');
  croak "Need a code ref for next track" unless ref($sub_next_track) eq 'CODE';
  croak "Need a code ref for next cell"  unless ref($sub_next_cell ) eq 'CODE';
  croak "Need a code ref for track done" unless ref($sub_track_done) eq 'CODE';

  for my $track_h (@{$gl->{H}->{tracks}}) {
    &$sub_next_track($track_h);

    for my $cell ($track_h->cells) {
      &$sub_next_cell($cell);
    }
   
    &$sub_track_done($track_h);
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

