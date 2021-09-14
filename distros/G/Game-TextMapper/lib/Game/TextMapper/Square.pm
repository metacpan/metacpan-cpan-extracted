# Copyright (C) 2009-2021  Alex Schroeder <alex@gnu.org>
#
# This program is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, either version 3 of the License, or (at your option) any
# later version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

=encoding utf8

=head1 NAME

Game::TextMapper::Square - a square on a map

=head1 SYNOPSIS

    use Modern::Perl;
    use Game::TextMapper::Square;
    my $square = Game::TextMapper::Square->new(x => 1, y => 1, z => 0);
    say $square->svg_region('', [0]);
    # <rect id="square110"  x="86.6025403784439" y="86.6025403784439" width="173.205080756888" height="173.205080756888" />

=head1 DESCRIPTION

This class holds information about a square region: coordinates, a label, and
types. Types are the kinds of symbols that can be found in the region: a keep, a
tree, a mountain. They correspond to SVG definitions. The class knows how to
draw a SVG rectangle at the correct coordinates using these definitions.

=head1 SEE ALSO

L<Game::TextMapper::Constants>

=cut

package Game::TextMapper::Square;

use Game::TextMapper::Constants qw($dx $dy);

use Game::TextMapper::Point;
use Modern::Perl '2018';
use Mojo::Util qw(url_escape);
use Mojo::Base -base;

has 'x';
has 'y';
has 'z';
has 'type';
has 'label';
has 'size';
has 'map';

sub str {
  my $self = shift;
  return '(' . $self->x . ',' . $self->y . ')';
}

sub svg_region {
  my ($self, $attributes, $offset) = @_;
  my $x = $self->x;
  my $y = $self->y;
  my $z = $self->z;
  my $id = "square$x$y$z";
  $y += $offset->[$z];
  $x = ($x - 0.5) * $dy;
  $y = ($y - 0.5) * $dy; # square!
  return qq{    <rect id="$id" $attributes x="$x" y="$y" width="$dy" height="$dy" />\n}
}

sub svg {
  my ($self, $offset) = @_;
  my $x = $self->x;
  my $y = $self->y;
  my $z = $self->z;
  $y += $offset->[$z];
  my $data = '';
  for my $type (@{$self->type}) {
    $data .= sprintf(qq{    <use x="%d" y="%d" xlink:href="#%s" />\n},
		     $x * $dy,
		     $y * $dy, # square
		     $type);
  }
  return $data;
}

sub svg_coordinates {
  my ($self, $offset) = @_;
  my $x = $self->x;
  my $y = $self->y;
  my $z = $self->z;
  $y += $offset->[$z];
  my $data = '';
  $data .= qq{    <text text-anchor="middle"};
  $data .= sprintf(qq{ x="%d" y="%d"},
		   $x * $dy,
		   ($y - 0.4) * $dy); # square
  $data .= ' ';
  $data .= $self->map->text_attributes || '';
  $data .= '>';
  $data .= Game::TextMapper::Point::coord($self->x, $self->y, "."); # original
  $data .= qq{</text>\n};
  return $data;
}

sub svg_label {
  my ($self, $url, $offset) = @_;
  return '' unless defined $self->label;
  my $attributes = $self->map->label_attributes;
  if ($self->size) {
    if (not $attributes =~ s/\bfont-size="\d+pt"/'font-size="' . $self->size . 'pt"'/e) {
      $attributes .= ' font-size="' . $self->size . '"';
    }
  }
  $url =~ s/\%s/url_escape($self->label)/e or $url .= url_escape($self->label) if $url;
  my $x = $self->x;
  my $y = $self->y;
  my $z = $self->z;
  $y += $offset->[$z];
  my $data = sprintf(qq{    <g><text text-anchor="middle" x="%d" y="%d" %s %s>}
                     . $self->label
                     . qq{</text>},
                     $x  * $dy,
		     ($y + 0.4) * $dy, # square
                     $attributes ||'',
		     $self->map->glow_attributes ||'');
  $data .= qq{<a xlink:href="$url">} if $url;
  $data .= sprintf(qq{<text text-anchor="middle" x="%d" y="%d" %s>}
		   . $self->label
		   . qq{</text>},
		   $x * $dy,
		   ($y + 0.4) * $dy, # square
		   $attributes ||'');
  $data .= qq{</a>} if $url;
  $data .= qq{</g>\n};
  return $data;
}

1;
