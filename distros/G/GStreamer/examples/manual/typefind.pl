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

sub idle_exit_loop {
  my ($loop) = @_;

  $loop -> quit();

  # once
  return FALSE;
}

sub cb_typefound {
  my ($typefind, $probability, $caps, $loop) = @_;
  my $type = $caps -> to_string();

  print "Media type $type found, probability $probability%\n";

  # since we connect to a signal in the pipeline thread context, we need
  # to set an idle handler to exit the main loop in the mainloop context.
  # Normally, your app should not need to worry about such things.
  Glib::Idle -> add(\&idle_exit_loop, $loop);
}

GStreamer -> init();
my $loop = Glib::MainLoop -> new(undef, FALSE);

# check args
unless ($#ARGV == 0) {
  print "Usage: $0 <filename>\n";
  exit -1;
}

# create a new pipeline to hold the elements
my $pipeline = GStreamer::Pipeline -> new("pipe");
$pipeline -> get_bus() -> add_watch(\&my_bus_callback, $loop);

# create file source and typefind element
my ($filesrc, $typefind) =
  GStreamer::ElementFactory -> make(filesrc => "source",
                                    typefind => "typefinder");

$filesrc -> set(location => filename_to_unicode $ARGV[0]);
$typefind -> signal_connect(have_type => \&cb_typefound, $loop);

# setup
$pipeline -> add($filesrc, $typefind);
$filesrc -> link($typefind);
$pipeline -> set_state("playing");
$loop -> run();

# unset
$pipeline -> set_state("null");
