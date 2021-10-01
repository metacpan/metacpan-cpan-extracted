#!/usr/bin/env perl

# Copyright (C) 2015-2018 Alex Schroeder <alex@gnu.org>

# This program is free software: you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software
# Foundation, either version 3 of the License, or (at your option) any later
# version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with
# this program. If not, see <http://www.gnu.org/licenses/>.

=encoding utf8

=head1 NAME

Game::FaceGenerator::Core - support for the Face Generator application

=head1 DESCRIPTION

Face Generator is a web application which uses random images to create faces.
This module provides the subroutines that L<Game::FaceGenerator> needs.

=cut

package Game::FaceGenerator::Core;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(dir no_flip all_artists random_components all_components all_elements render_components move);

use Modern::Perl;
use File::ShareDir qw(dist_dir);
use File::Slurper qw(read_dir read_text read_binary write_binary);
use List::Util 'any';
use Cwd;
use GD;

sub member {
  my $element = shift;
  foreach (@_) {
    return 1 if $element eq $_;
  }
}

sub one {
  my $i = int(rand(scalar @_));
  return $_[$i];
}

my $dir;

sub dir {
  $dir = shift;
}

my $no_flip;

sub no_flip {
  my $arg = shift;
  if (ref $arg) {
    $no_flip = $arg;
   } elsif ($arg and $no_flip->{$arg}) {
    @{$no_flip->{$arg}};
  } else {
    ();
  }
}

=head1 ARTISTS

The F<contrib> directory contains background images like F<empty.png> (default
human), F<elf.png> (narrower), F<dwarf.png> (rounder), F<demon.png> (looking
half left, with horns), F<dragon.png> (looking left), and the artist
directories.

Each artist directory must contain a F<README.md> file. The first Markdown link
of the form C<[name](URL)> is used to name the artist and link to their presence
on the web. The first Markdown emphasized text of the form C<*title*> is used as
the title for the collection. This can be useful if an artist has two different
collections. Take Alex Schroeder, who started out as “alex”. Then a second
collection is added, and called “alex2”. It’s still the same person, so the two
F<README.md> files both contain the link C<[Alex
Schroeder](https://alexschroeder.ch/)>, and the first one contains the title
C<*Blau*> and the second one contains the title C<*Tablet*>.

=cut

my %artists;

=head1 METHODS

=head2 all_artists

Return a hash referefence of all the artists and their types. This scans the
entire F<contrib> directory, so the result is cached.

=cut

sub all_artists {
  return \%artists if %artists;
  my @dirs = grep {
    !/\.png$/ # ignore images
	&& -d "$dir/$_"
	&& -f "$dir/$_/README.md"
  } read_dir($dir);
  for my $artist (@dirs) {
    # Determine name and url from the README file.
    $artists{$artist}{name} = $artist; # default
    my $text = read_text("$dir/$artist/README.md");
    if ($text =~ /\[([^]]*)\]\((https?:.*)\)/) {
      $artists{$artist} = {};
      $artists{$artist}{name} = $1;
      $artists{$artist}{url}  = $2;
    }
    if ($text =~ /\*([^* ][^*]*)\*/) {
      $artists{$artist}{title}  = $1;
    }
    # Find available types from the filenames.
    my %types;
    for (read_dir("$dir/$artist")) {
      $types{$1} = 1 if /_([a-z]+)/;
    }
    delete $types{all} if $types{all} and keys %types > 1;
    $artists{$artist}{types}  = [sort keys %types];
  }
  return \%artists;
}

=head2 all_components

Returns all the elements for an C<$artist>, optionally with prefix c<$element>,
followed by the C<$empty> image (defaulting to F<empty.png>), and possibly
filtered by last modification time in C<$days>. Each element is an array of
C<$empty> and the actual file name.

=cut

sub all_components {
  my ($artist, $element, $empty, $days) = @_;
  $empty ||= 'empty.png';
  my @files = grep {
    /$element.*\.png$/
	and (not $days or (stat("$dir/$artist/$_"))[9] >= (time - $days*24*60*60))
  } read_dir("$dir/$artist");
  my @components = map { [$empty, $_] } @files;
  return @components;
}

=head2 all_elements

The elements are drawn in a default order over one another: C<face> C<eyes>
C<brows> C<mouth> C<chin> C<ears> C<nose> C<extra> C<horns> C<bangs> C<hair>
C<hat>.

Thus, a mustache (as part of the C<chin>) covers a mouth; C<hair> covers the
face; C<hat> cover C<hair>, and so on.

=cut

sub all_elements {
  # face is the background, if any (mostly to support photos)
  # chin after mouth (mustache hides mouth)
  # nose after chin (mustache!)
  # hair after ears
  # ears after chin (if you're fat)
  # chin after ears (for your beard) – damn!
  return qw(face eyes brows mouth chin ears nose extra horns bangs hair hat);
}

=head2 random_components

The random components of C<$type> for C<$artist>. If C<$debug> is true,
F<empty.png> is added to the list of components.

=cut

sub random_components {
  my ($type, $artist, $debug) = @_;
  %artists = %{all_artists()} unless keys %artists;
  $type = one(@{$artists{$artist}->{types}}) if $type eq 'random';
  my @elements = all_elements();
  @elements = grep(!/^extra/, @elements) if rand(1) >= 0.1; # 10% chance
  @elements = grep(!/^hat/, @elements) if rand(1) >= 0.1; # 10% chance
  my @files = grep { /\.png$/ } read_dir("$dir/$artist");
  my @components;
  for my $element (@elements) {
    my @candidates1 = grep(/^${element}_/, @files);
    my @candidates2 = grep(/_$type/, @candidates1);
    @candidates2 = grep(/_all/, @candidates1) unless @candidates2;
    my $candidate = one(@candidates2) || '';
    unless (any { $type eq $_ } no_flip($artist)) {
      $candidate .= '_' if $candidate and rand >= 0.5; # invert it!
    }
    push(@components, $candidate) if $candidate;
  }
  unshift(@components, 'empty.png') if $debug;
  return @components;
}

=head2 render_components

Renders the components for C<$artist>. The C<@components> are probably the
result of a call to C<random_components>.

=cut

sub render_components {
  my ($artist, @components) = @_;
  my $image;
  for my $component (@components) {
    next unless $component;
    my $layer;
    if (-f "$dir/$component") {
      $layer = GD::Image->newFromPng("$dir/$component", 1);
    } elsif (substr($component, -1) eq '_') {
      $component = substr($component, 0, -1);
      $layer = GD::Image->newFromPng("$dir/$artist/$component", 1);
      $layer->flipHorizontal();
    } else {
      $layer = GD::Image->newFromPng("$dir/$artist/$component", 1);
    }
    # scanned images with a white background: make white transparent unless this
    # is the first image
    if ($layer->isTrueColor == 0 and $layer->transparent == -1 and $image) {
      my $white = $layer->colorClosest(255,255,255);
      $layer->transparent($white);
    }
    # if we already have an image, combine them
    if ($image) {
      $image->copy($layer, 0, 0, 0, 0, $layer->getBounds());
    } else {
      $image = $layer;
      $image->alphaBlending(1);
      $image->saveAlpha(1);
    }
  }
  return $image->png();
}

=head2 move

This is the subroutine called to edit the images.

=cut

sub move {
  my ($artist, $element, $direction, $step) = @_;
  my $file = "$dir/$artist/$element";
  my $original = GD::Image->new($file);
  my $image = GD::Image->new(450, 600);
  my $white = $image->colorAllocate(255,255,255); # find white
  $image->rectangle(0, 0, $image->getBounds(), $white);
  if ($direction eq 'up') {
    $image->copy($original, 0, 0, 0, $step, $image->width, $image->height - $step);
  } elsif ($direction eq 'down') {
    $image->copy($original, 0, $step, 0, 0, $image->width, $image->height - $step);
  } elsif ($direction eq 'left') {
    $image->copy($original, 0, 0, $step, 0, $image->width - $step, $image->height);
  } elsif ($direction eq 'right') {
    $image->copy($original, $step, 0, 0, 0, $image->width - $step, $image->height);
  } elsif ($direction eq 'appart') {
    $image->copy($original, $image->width/2 + $step/2, 0, $image->width/2, 0, $image->width/2 - $step/2, $image->height);
    $image->copy($original, 0, 0, $step/2, 0, $image->width/2 - $step/2, $image->height);
  } elsif ($direction eq 'closer') {
    $image->copy($original, $step/2, 0, 0, 0, $image->width/2 - $step/2, $image->height);
    $image->copy($original, $image->width/2, 0, $image->width/2 + $step/2, 0, $image->width/2 - $step/2, $image->height);
  } else {
    die "Unknown direction: $direction\n";
  }
  write_binary($file, $image->png);
}

1;
