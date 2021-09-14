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

Game::TextMapper::Archipelago - work in progress

=head1 DESCRIPTION

This is an unfinished idea.

=cut

package Game::TextMapper::Schroeder::Archipelago;
use Game::TextMapper::Log;
use Modern::Perl '2018';
use Mojo::Base -base;
use Role::Tiny::With;
with 'Game::TextMapper::Schroeder::Base';
use List::Util qw'shuffle min max';

my $log = Game::TextMapper::Log->get;

has 'bottom' => 0;
has 'top' => 10;
has 'radius' => 5;
has 'width' => 30;
has 'height' => 10;
has 'concentration' => 0.1;
has 'eruptions' => 0.03;
has 'world' => sub { { } };
has 'altitude' => sub { {} };

sub flat {
  my $self = shift;
  $log->debug("initializing altitude map");
  # initialize the altitude map; this is required so that we have a list of
  # legal hex coordinates somewhere
  for my $y (1 .. $self->height) {
    for my $x (1 .. $self->width) {
      my $coordinates = coordinates($x, $y);
      $self->altitude->{$coordinates} = 0;
      $self->world->{$coordinates} = "height0";
    }
  }
}

sub ocean {
  my $self = shift;
  $log->debug("placing ocean and water");
  for my $coordinates (sort keys %{$self->altitude}) {
    if ($self->altitude->{$coordinates} <= $self->bottom) {
      my $ocean = 1;
      for my $i ($self->neighbors()) {
	my ($x, $y) = $self->neighbor($coordinates, $i);
	my $legal = $self->legal($x, $y);
	my $other = coordinates($x, $y);
	next if not $legal or $self->altitude->{$other} <= $self->bottom;
	$ocean = 0;
      }
      $self->world->{$coordinates} = $ocean ? "ocean" : "water";
    }
  }
}

sub eruption {
  my $self = shift;
  my $cx = int $self->width * rand();
  my $cy = int $self->height * (rand() + rand()) / 2;
  $log->debug("eruption at " . $self->coordinates($cx, $cy));
  my $top = 1 + int($self->top * $cx / $self->width);
  $top-- if $top > 2 and rand() < 0.6;
  for my $coordinates (keys %{$self->altitude}) {
    my $d = $self->distance($self->xy($coordinates), $cx, $cy);
    if ($d <= $top) {
      my $h = $top - $d;
      $self->altitude->{$coordinates} = $h if $h > $self->altitude->{$coordinates};
      $self->world->{$coordinates} = "height" . $self->altitude->{$coordinates};
    }
  }
}

sub generate {
  my $self = shift;
  my $step = shift;
  my @code = (sub { $self->flat() });
  for (1 .. $self->width * $self->height * $self->eruptions) {
    push(@code, sub { $self->eruption() });
  }
  push(@code, sub { $self->ocean() });

  # $step 0 runs all the code; note that we can't simply cache those results
  # because we need to start over with the same seed!
  my $i = 1;
  while (@code) {
    shift(@code)->();
    return if $step == $i++;
  }
}

sub generate_map {
  my $self = shift;
  # If provided, the arguments override the defaults
  $self->width(shift // $self->width);
  $self->height(shift // $self->height);
  $self->concentration(shift // $self->concentration);
  $self->eruptions(shift // $self->eruptions);
  $self->top(shift // $self->top);
  $self->bottom(shift // $self->bottom);
  my $seed = shift||time;
  my $url = shift;
  my $step = shift||0;

  # For documentation purposes, I want to be able to set the pseudo-random
  # number seed using srand and rely on rand to reproduce the same sequence of
  # pseudo-random numbers for the same seed. The key point to remember is that
  # the keys function will return keys in random order. So if we loop over the
  # result of keys, we need to look at the code in the loop: If order is
  # important, that wont do. We need to sort the keys. If we want the keys to be
  # pseudo-shuffled, use shuffle sort keys.
  srand($seed);

  # keys for all hashes are coordinates such as "0101".
  $self->generate($step);

  # when documenting or debugging, do this before collecting lines
  if ($step > 0) {
    # add a height label at the very end
    if ($step) {
      for my $coordinates (keys %{$self->altitude}) {
	$self->world->{$coordinates} .= ' "' . $self->altitude->{$coordinates} . '"';
      }
    }
  }

  local $" = "-"; # list items separated by -
  my @lines;
  push(@lines, map { $_ . " " . $self->world->{$_} } sort keys %{$self->world});
  # push(@lines, map { "$_ trail" } @$trails);
  push(@lines, "include gnomeyland.txt");

  # when documenting or debugging, add some more lines at the end
  if ($step > 0) {
    # visualize height
    push(@lines,
	 map {
	   my $n = int(255 / $self->top * $_);
	   qq{height$_ attributes fill="rgb($n,$n,$n)"};
	 } (0 .. $self->top));
    # visualize water flow
    push(@lines, $self->arrows());
  }

  push(@lines, "# Seed: $seed");
  push(@lines, "# Documentation: " . $url) if $url;
  my $map = join("\n", @lines);
  return $map;
}

1;
