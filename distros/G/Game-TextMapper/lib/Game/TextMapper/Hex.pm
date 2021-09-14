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

Game::TextMapper::Hex - a hex on a map

=head1 SYNOPSIS

    use Modern::Perl;
    use Game::TextMapper::Hex;
    my $hex = Game::TextMapper::Hex->new(x => 1, y => 1, z => 0);
    say $hex->svg_region('', [0]);
    # <polygon id="hex110"  points="50.0,86.6 100.0,173.2 200.0,173.2 250.0,86.6 200.0,0.0 100.0,0.0" />

=head1 DESCRIPTION

This class holds information about a hex region: coordinates, a label, and
types. Types are the kinds of symbols that can be found in the region: a keep, a
tree, a mountain. They correspond to SVG definitions. The class knows how to
draw a SVG polygon at the correct coordinates using these definitions.

=cut

package Game::TextMapper::Hex;

use Game::TextMapper::Constants qw($dx $dy);
use Game::TextMapper::Point;

use Modern::Perl '2018';
use Mojo::Util qw(url_escape);
use Encode qw(encode_utf8);
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

my @hex = ([-$dx, 0], [-$dx/2, $dy/2], [$dx/2, $dy/2],
	   [$dx, 0], [$dx/2, -$dy/2], [-$dx/2, -$dy/2]);

sub corners {
  return @hex;
}

sub svg_region {
  my ($self, $attributes, $offset) = @_;
  my $x = $self->x;
  my $y = $self->y;
  my $z = $self->z;
  my $id = "hex$x$y$z";
  $y += $offset->[$z];
  my $points = join(" ", map {
    sprintf("%.1f,%.1f",
	    $x * $dx * 3/2 + $_->[0],
	    $y * $dy - $self->x % 2 * $dy/2 + $_->[1]) } $self->corners());
  return qq{    <polygon id="$id" $attributes points="$points" />\n}
}

sub svg {
  my ($self, $offset) = @_;
  my $x = $self->x;
  my $y = $self->y;
  my $z = $self->z;
  $y += $offset->[$z];
  my $data = '';
  for my $type (@{$self->type}) {
    $data .= sprintf(qq{    <use x="%.1f" y="%.1f" xlink:href="#%s" />\n},
		     $x * $dx * 3/2, $y * $dy - $x%2 * $dy/2, $type);
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
  $data .= sprintf(qq{ x="%.1f" y="%.1f"},
		   $x * $dx * 3/2,
		   $y * $dy - $x%2 * $dy/2 - $dy * 0.4);
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
  my $x = $self->x;
  my $y = $self->y;
  my $z = $self->z;
  $y += $offset->[$z];
  my $data = sprintf(qq{    <g><text text-anchor="middle" x="%.1f" y="%.1f" %s %s>}
                     . $self->label
                     . qq{</text>},
                     $x * $dx * 3/2, $y * $dy - $x%2 * $dy/2 + $dy * 0.4,
                     $attributes ||'',
		     $self->map->glow_attributes ||'');
  $data .= qq{<a xlink:href="$url">} if $url;
  $data .= sprintf(qq{<text text-anchor="middle" x="%.1f" y="%.1f" %s>}
		   . $self->label
		   . qq{</text>},
		   $x * $dx * 3/2, $y * $dy - $x%2 * $dy/2 + $dy * 0.4,
		   $attributes ||'');
  $data .= qq{</a>} if $url;
  $data .= qq{</g>\n};
  return $data;
}

1;
