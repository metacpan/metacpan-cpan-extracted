#!/usr/bin/perl
use strict;
use warnings;
use Glib qw(TRUE FALSE filename_to_unicode);
use GStreamer;

# $Id$

sub my_bus_callback {
  my ($bus, $message, $loop) = @_;

  if ($message -> type & "error") {
    warn $message -> error;
    $loop -> quit();
  }

  elsif ($message -> type & "eos") {
    $loop -> quit();
  }

  # remove message from the queue
  return TRUE;
}

my ($pipeline, $audio);

sub cb_newpad {
  my ($decodebin, $pad, $last, $data) = @_;

  my $audiopad = $audio -> get_pad("sink");

  # only link audio; only link once
  return if ($audiopad -> is_linked());

  # check media type
  my $caps = $pad -> get_caps();
  my $str = $caps -> get_structure(0);

  return if (index($str -> { name }, "audio") == -1);

  # link'n'play
  $pad -> link($audiopad);
}

GStreamer -> init();
my $loop = Glib::MainLoop -> new(undef, FALSE);

# make sure we have input
unless ($#ARGV == 0) {
  print "Usage: $0 <filename>\n";
  exit -1;
}

# setup
$pipeline = GStreamer::Pipeline -> new("pipeline");
$pipeline -> get_bus() -> add_watch(\&my_bus_callback, $loop);

$audio = GStreamer::Bin -> new("audiobin");

my ($src, $dec, $conv, $sink) =
  GStreamer::ElementFactory -> make(filesrc => "source",
                                    decodebin => "decoder",
                                    audioconvert => "aconv",
                                    alsasink => "sink");

my $audiopad = $conv -> get_pad("sink");

$src -> set(location => filename_to_unicode $ARGV[0]);
$dec -> signal_connect(new_decoded_pad => \&cb_newpad);

$audio -> add($conv, $sink);
$conv -> link($sink);
$pipeline -> add($src, $dec);
$src -> link($dec);

$audio -> add_pad(GStreamer::GhostPad -> new("sink", $audiopad));
$pipeline -> add($audio);

# run
$pipeline -> set_state("playing");
$loop -> run();

# cleanup
$pipeline -> set_state("null");
