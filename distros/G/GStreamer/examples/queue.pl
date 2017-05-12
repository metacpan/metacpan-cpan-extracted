#!/usr/bin/perl
use strict;
use warnings;
use Glib qw(TRUE FALSE);
use GStreamer;

# This is a Perl port of the queue example found in gstreamer-0.9.6.

# This example uses the queue element to create a buffer between 2 elements.
# The scheduler automatically uses 2 threads, 1 to feed and another to consume
# data from the queue buffer

# Event loop to listen to events posted on the GstBus from the pipeline. Exits
# on EOS or ERROR events
sub event_loop {
  my ($pipe) = @_;

  my $bus = $pipe -> get_bus();

  while (TRUE) {
    my $message = $bus -> poll("any", -1);

    if ($message -> type & "eos") {
      return;
    }

    elsif ($message -> type & "warning" or
           $message -> type & "error") {
      die $message -> error;
    }
  }
}

GStreamer -> init();

if ($#ARGV != 0) {
  printf "usage: %s <filename>\n", $0;
  exit -1;
}

# create a new pipeline to hold the elements
my $pipeline = GStreamer::Pipeline -> new("pipeline");

# create a disk reader
my $filesrc = GStreamer::ElementFactory -> make(filesrc => "disk_source");
$filesrc -> set(location => Glib::filename_to_unicode $ARGV[0]);

my $decode = GStreamer::ElementFactory -> make(mad => "decode");

my $queue = GStreamer::ElementFactory -> make(queue => "queue");

# and an audio sink
my $audiosink = GStreamer::ElementFactory -> make(alsasink => "play_audio");

# add objects to the main pipeline
$pipeline -> add($filesrc, $decode, $queue, $audiosink);
$filesrc -> link($decode, $queue, $audiosink);

# start playing
$pipeline -> set_state("playing");

# Listen for EOS
event_loop($pipeline);

$pipeline -> set_state("null");
