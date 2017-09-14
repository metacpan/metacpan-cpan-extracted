# Encoding and name #_{

=encoding utf8
=head1 NAME

Geo::OSM::Render::Viewport::Clipped - Use a clipped L<<viewport | Geo::OSM::Render::Viewport >> to create a map.

=cut
package Geo::OSM::Render::Viewport::Clipped;
#_}
#_{ use …
use warnings;
use strict;

use utf8;
use Carp;
use Geo::OSM::Render::Viewport;
our @ISA = qw(Geo::OSM::Render::Viewport);

#_}
our $VERSION = 0.01;
#_{ Synopsis

=head1 SYNOPSIS

This class derives from L<<Geo::OSM::Render::Viewporrt>>.

=cut
#_}
#_{ Overview

=head1 OVERVIEW

See L<Geo::OSM::Render::Viewport/OVERVIEW>.

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

    my $proj = Geo::OSM::Render::Viewport::Clipped->new(
      x_of_map_0       => $x_left  ,
      x_of_map_width   => $x_right ,
      y_of_map_0       => $y_bottom,
      y_of_map_height  => $y_top
   );

=cut

#_}

  my $class = shift;
  my $self  = $class->SUPER::new();
  my %opts  = @_;

  $self->{x_of_map_0     } = delete $opts{x_of_map_0      } // croak 'x_of_map_0      not given';
  $self->{x_of_map_width } = delete $opts{x_of_map_width  } // croak 'x_of_map_width  not given';
  $self->{y_of_map_0     } = delete $opts{y_of_map_0      } // croak 'y_of_map_0      not given';
  $self->{y_of_map_height} = delete $opts{y_of_map_height } // croak 'y_of_map_height not given';

  my $max_width_height     = delete $opts{max_width_height} // croak 'max_width_height not given';

  $self->{diff_width } = $self->{x_of_map_width } - $self->{x_of_map_0};
  $self->{diff_height} = $self->{y_of_map_height} - $self->{y_of_map_0};

  if (abs($self->{diff_width}) > abs($self->{diff_height})) {
    $self->{map_width } = $max_width_height;
    $self->{map_height} = $max_width_height / abs($self->{diff_width}) * abs($self->{diff_height});
  }
  else {
    $self->{map_height} = $max_width_height;
    $self->{map_width } = $max_width_height / abs($self->{diff_height}) * abs($self->{diff_width });
  }


  return $self;

} #_}
sub x_y_to_map_x_y { #_{
#_{ POD

=head2 x_y_to_map_x_y

    my ($map_x, $map_y) = $projection->x_y_to_map_x_y($x, $y);

=cut

#_}

  my $self = shift;
  my $x    = shift;
  my $y    = shift;

  my $map_x = ( $x - $self->{x_of_map_0} ) / $self->{diff_width } * $self->map_width;
  my $map_y = ( $y - $self->{y_of_map_0} ) / $self->{diff_height} * $self->map_height;

  return ($map_x, $map_y);

} #_}
sub map_width { #_{
#_{ POD

=head2 map_width

Returns the width of the map.

=cut

#_}
  my $self = shift;
  return abs($self->{map_width});
} #_}
sub map_height { #_{
#_{ POD

=head2 map_height

Returns the height of the map.

=cut

#_}
  my $self = shift;
  return abs($self->{map_height});
} #_}
#_}
#_{ POD: Author

=head1 AUTHOR

René Nyffenegger <rene.nyffenegger at adp-gmbh.ch>

=cut

#_}
#_{ POD: Copyright and License

=head1 COPYRIGHT AND LICENSE
Copyright © 2017 René Nyffenegger, Switzerland. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at: L<http://www.perlfoundation.org/artistic_license_2_0>
=cut

#_}
#_{ POD: Source Code

=head1 Source Code

The source code is on L<< github|https://github.com/ReneNyffenegger/perl-Geo-OSM-Render >>. Meaningful pull requests are welcome.

=cut

#_}

'tq84';
