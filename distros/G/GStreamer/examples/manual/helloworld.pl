#!/usr/bin/perl
use strict;
use warnings;
use Glib qw(TRUE FALSE filename_to_unicode);
use GStreamer;

# $Id$

# Global objects are usually a bad thing. For the purpose of this
# example, we will use them, however.

my ($pipeline, $source, $parser, $decoder, $conv, $sink);

sub bus_call {
  my ($bus, $message, $loop) = @_;

  if ($message -> type & "eos") {
    print "End of stream\n";
    $loop -> quit();
  }

  elsif ($message -> type & "error") {
    warn $message -> error;
    $loop -> quit();
  }

  # remove message from the queue
  return TRUE;
}

sub new_pad {
  my ($element, $pad, $data) = @_;

  # We can now link this pad with the audio decoder.
  print "Dynamic pad created, linking parser/decoder\n";
  $pad -> link($decoder -> get_pad("sink"));
}

GStreamer -> init();
my $loop = Glib::MainLoop -> new(undef, FALSE);

# check input arguments
if ($#ARGV != 0) {
  print "Usage: $0 <Ogg/Vorbis filename>\n";
  exit -1;
}

# create elements
$pipeline = GStreamer::Pipeline -> new("audio-player");
($source, $parser, $decoder, $conv, $sink) =
  GStreamer::ElementFactory -> make(filesrc => "file-source",
                                    oggdemux => "ogg-parser",
                                    vorbisdec => "vorbis-decoder",
                                    audioconvert => "audio-converter",
                                    alsasink => "alsa-output");

# set filename property on the file source. Also add a message handler.
$source -> set(location => filename_to_unicode $ARGV[0]);
$pipeline -> get_bus() -> add_watch(\&bus_call, $loop);

# put all elements in a bin
$pipeline -> add($source, $parser, $decoder, $conv, $sink);

# link together - note that we cannot link the parser and
# decoder yet, becuse the parser uses dynamic pads. For that,
# we set a pad-added signal handler.
$source -> link($parser);
$decoder -> link($conv, $sink);
$parser -> signal_connect(pad_added => \&new_pad);

# Now set to playing and iterate.
print "Setting to PLAYING\n";
$pipeline -> set_state("playing");
print "Running\n";
$loop -> run();

# clean up nicely
print "Returned, stopping playback\n";
$pipeline -> set_state("null");
