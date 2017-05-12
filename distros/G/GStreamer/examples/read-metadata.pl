#!/usr/bin/perl

# This is a Perl port of an example found in the gstreamer-0.9.6 tarball.
# Original and current copyright:

# GStreamer
# Copyright (C) 2003 Thomas Vander Stichele <thomas@apestaart.org>
#               2003 Benjamin Otte <in7y118@public.uni-hamburg.de>
#               2005 Andy Wingo <wingo@pobox.com>
#               2005 Jan Schmidt <thaytan@mad.scientist.com>
#
# gst-metadata.c: Use GStreamer to display metadata within files.
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Library General Public
# License as published by the Free Software Foundation; either
# version 2 of the License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Library General Public License for more details.
#
# You should have received a copy of the GNU Library General Public
# License along with this library; if not, write to the
# Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA

use strict;
use warnings;
use Glib qw(TRUE FALSE);
use GStreamer qw(GST_MSECOND);

my ($filename, $pipeline, $source);

sub message_loop {
  my ($element) = @_;

  my $tags = {};
  my $done = FALSE;

  my $bus = $element -> get_bus();

  return undef unless defined $bus;
  return undef unless defined $tags;

  while (!$done) {
    my $message = $bus -> poll("any", 0);
    unless (defined $message) {
      # All messages read, we're done
      last;
    }

    if ($message -> type & "eos") {
      # End of stream, no tags found yet -> return undef
      return undef;
    }

    if ($message -> type & "error") {
      # decodebin complains about not having an element attached to its output.
      # Sometimes this happens even before the "tag" message, so just continue.
      next;
    }

    elsif ($message -> type & "tag") {
      my $new_tags = $message -> tag_list();
      foreach (keys %$new_tags) {
        unless (exists $tags -> { $_ }) {
          $tags -> { $_ } = $new_tags -> { $_ };
        }
      }
    }
  }

  return $tags;
}

sub make_pipeline {
  my $decodebin;

  $pipeline = GStreamer::Pipeline -> new(undef);

  ($source, $decodebin) =
    GStreamer::ElementFactory -> make(filesrc => "source",
                                      decodebin => "decodebin");

  $pipeline -> add($source, $decodebin);
  $source -> link($decodebin);
}

sub print_tag {
  my ($list, $tag) = @_;

  foreach (@{$list -> { $tag }}) {
    if (defined $_) {
      printf "  %15s: %s\n", ucfirst $tag, $_;
    }
  }
}

GStreamer -> init();

if ($#ARGV < 0) {
  print "Please give filenames to read metadata from\n";
  exit 1;
}

make_pipeline();

foreach (@ARGV) {
  $filename = $_;
  $source -> set(location => Glib::filename_to_unicode $filename);

  # Decodebin will only commit to PAUSED if it actually finds a type;
  # otherwise the state change fails
  my $sret = $pipeline -> set_state("paused");

  if ("async" eq $sret) {
    ($sret, undef, undef) = $pipeline -> get_state(500 * GST_MSECOND);
  }

  if ("success" ne $sret) {
    printf "%s - Could not read file\n", $filename;
    next;
  }

  my $tags = message_loop($pipeline);

  unless (defined $tags) {
    printf "No metadata found for %s\n", Glib::filename_display_name $_;
  }

  map { print_tag($tags, $_) } keys %$tags;

  $pipeline -> set_state("null");
}
