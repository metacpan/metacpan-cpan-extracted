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

  my $class  = shift;
  my $V_or_H = shift;

  my $self = {};
  bless $self, $class;
  return $self;

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

