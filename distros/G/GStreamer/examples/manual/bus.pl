#!/usr/bin/perl
use strict;
use warnings;
use Glib qw(TRUE FALSE);
use GStreamer;

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

# init
GStreamer -> init();

# create pipeline, add handler
my $pipeline = GStreamer::Pipeline -> new("my_pipeline");

my $loop = Glib::MainLoop -> new(undef, FALSE);

$pipeline -> get_bus() -> add_watch(\&my_bus_callback, $loop);

# in the mainloop, all messages posted to the bus by the pipeline
# will automatically be sent to our callback.
$loop -> run();
