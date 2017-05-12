#!/usr/bin/perl
use strict;
use warnings;
use Glib qw(filename_to_unicode TRUE FALSE);
use GStreamer qw(GST_SECOND GST_TIME_FORMAT GST_TIME_ARGS);

# $Id$

# Turn off perl's output buffering.
$|++;

sub my_bus_message_callback {
  my ($bus, $message, $loop) = @_;

  if ($message -> type & "error") {
    warn $message -> error;
    $loop -> quit();
  }

  elsif ($message -> type & "eos") {
    $loop -> quit();
  }
}

sub cb_print_position {
  my ($pipeline) = @_;

  my $pos_query = GStreamer::Query::Position -> new("time");
  my $dur_query = GStreamer::Query::Duration -> new("time");

  if ($pipeline -> query($pos_query) &&
      $pipeline -> query($dur_query)) {
    printf "Time: %" . GST_TIME_FORMAT . " / %" . GST_TIME_FORMAT . "\r",
           GST_TIME_ARGS(($pos_query -> position)[1]),
           GST_TIME_ARGS(($dur_query -> duration)[1]);
  }

  # call me again
  return TRUE;
}

GStreamer -> init();

# args
if ($#ARGV != 0) {
  print "Usage: $0 <filename>\n";
  exit -1;
}

my $loop = Glib::MainLoop -> new(undef, FALSE);

my $file = filename_to_unicode $ARGV[0];

# build pipeline, the easy way
my $pipeline;
eval {
  $pipeline = GStreamer::parse_launch(
                "filesrc location=\"$file\" ! " .
                "oggdemux ! " .
                "vorbisdec ! " .
                "audioconvert ! " .
                "audioresample ! " .
                "alsasink");
};

if ($@) {
  warn "Cannot build pipeline: ", $@;
  exit -1;
}

my $bus = $pipeline -> get_bus();
$bus -> add_signal_watch();
$bus -> signal_connect(message => \&my_bus_message_callback, $loop);

# play
my $ret = $pipeline -> set_state("playing");
if ($ret eq "failure") {
  die "Failed to set pipeline to PLAYING.\n";
}

# run pipeline
Glib::Timeout -> add(200, \&cb_print_position, $pipeline);
$loop -> run();

# clean up
$pipeline -> set_state("null");
