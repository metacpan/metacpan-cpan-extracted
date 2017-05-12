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

GStreamer -> init();
my $loop = Glib::MainLoop -> new(undef, FALSE);

# make sure we have a URI
unless ($#ARGV == 0) {
  print "Usage: $0 <URI>\n";
  exit -1;
}

# set up
my $play = GStreamer::ElementFactory -> make("playbin", "play");
$play -> set(uri => filename_to_unicode $ARGV[0]);
$play -> get_bus() -> add_watch(\&my_bus_callback, $loop);
$play -> set_state("playing");

# now run
$loop -> run();

# also clean up
$play -> set_state("null");
