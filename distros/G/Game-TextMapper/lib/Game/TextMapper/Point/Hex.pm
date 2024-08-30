# Copyright (C) 2009-2022  Alex Schroeder <alex@gnu.org>
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

Game::TextMapper::Point::Hex - a hex on a map

=head1 SYNOPSIS

    use Modern::Perl;
    use Game::TextMapper::Point::Hex;
    my $hex = Game::TextMapper::Point::Hex->new(x => 1, y => 1, z => 0);
    say $hex->svg_region('', [0]);
    # <polygon id="hex110"  points="50.0,86.6 100.0,173.2 200.0,173.2 250.0,86.6 200.0,0.0 100.0,0.0" />

=head1 DESCRIPTION

This class holds information about a hex region: coordinates, a label, and
types. Types are the kinds of symbols that can be found in the region: a keep, a
tree, a mountain. They correspond to SVG definitions. The class knows how to
draw a SVG polygon at the correct coordinates using these definitions.

For attributes and methods, see L<Game::TextMapper::Point>.

=head2 Additional Methods

=cut

package Game::TextMapper::Point::Hex;

use Game::TextMapper::Constants qw($dx $dy);

use Modern::Perl '2018';
use Mojo::Util qw(url_escape);
use Encode qw(encode_utf8);
use Mojo::Base 'Game::TextMapper::Point';

=head3 corners

Return the relative SVG coordinates of the points making up the shape, i.e. six
for L<Game::TextMapper::Point::Hex> and four for
L<Game::TextMapper::Point::Square>.

The SVG coordinates are arrays with x and y coordinates relative to the center
of the shape.

=cut

my @hex = ([-$dx, 0], [-$dx/2, $dy/2], [$dx/2, $dy/2],
	   [$dx, 0], [$dx/2, -$dy/2], [-$dx/2, -$dy/2]);

sub corners {
  return @hex;
}

sub pixels {
  my ($self, $offset, $add_x, $add_y) = @_;
  my $x = $self->x;
  my $y = $self->y;
  my $z = $self->z;
  $y += $offset->[$z] if defined $offset->[$z];
  $add_x //= 0;
  $add_y //= 0;
  return $x * $dx * 3/2 + $add_x, $y * $dy - $x%2 * $dy/2 + $add_y;
}

sub svg_region {
  my ($self, $attributes, $offset) = @_;
  my $x = $self->x;
  my $y = $self->y;
  my $z = $self->z;
  my $id = "hex";
  if ($x < 100 and $y < 100 and $z < 100) {
    $id .= "$x$y";
    $id .= $z if $z != 0;
  } else {
    $id .= "$x.$y";
    $id .= ".$z" if $z != 0;
  }
  my $points = join(" ", map { sprintf("%.1f,%.1f", $self->pixels($offset, @$_)) } $self->corners());
  return qq{    <polygon id="$id" $attributes points="$points" />\n}
}

sub svg {
  my ($self, $offset) = @_;
  my $data = '';
  for my $type (@{$self->type}) {
    $data .= sprintf(qq{    <use x="%.1f" y="%.1f" xlink:href="#%s" />\n},
		     $self->pixels($offset), $type);
  }
  return $data;
}

sub svg_coordinates {
  my ($self, $offset) = @_;
  my $data = qq{    <text text-anchor="middle"};
  $data .= sprintf(qq{ x="%.1f" y="%.1f"}, $self->pixels($offset, 0, -$dy * 0.4));
  $data .= ' ';
  $data .= $self->map->text_attributes || '';
  $data .= '>';
  $data .= Game::TextMapper::Point::coord($self->x, $self->y, ".");
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
  $url =~ s/\%s/url_escape(encode_utf8($self->label))/e or $url .= url_escape(encode_utf8($self->label)) if $url;
  my $data = sprintf(qq{    <g><text text-anchor="middle" x="%.1f" y="%.1f" %s %s>}
                     . $self->label
                     . qq{</text>},
                     $self->pixels($offset, 0, $dy * 0.4),
                     $attributes ||'',
		     $self->map->glow_attributes ||'');
  $data .= qq{<a xlink:href="$url">} if $url;
  $data .= sprintf(qq{<text text-anchor="middle" x="%.1f" y="%.1f" %s>}
		   . $self->label
		   . qq{</text>},
		   $self->pixels($offset, 0, $dy * 0.4),
		   $attributes ||'');
  $data .= qq{</a>} if $url;
  $data .= qq{</g>\n};
  return $data;
}

=head1 SEE ALSO

This is a specialisation of L<Game::TextMapper::Point>.

The SVG size is determined by C<$dx> and C<$dy> from
L<Game::TextMapper::Constants>.

=cut

1;
