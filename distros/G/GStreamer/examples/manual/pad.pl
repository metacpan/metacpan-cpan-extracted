#!/usr/bin/perl
use strict;
use warnings;
use Glib qw(filename_to_unicode TRUE FALSE);
use GStreamer -init;

# $Id$

sub cb_new_pad {
  my ($element, $pad, $data) = @_;

  printf "A new pad %s was created\n", $pad -> get_name();

  # here, you would setup a new pad link for the newly created pad
}

# create elements
my $pipeline = GStreamer::Pipeline -> new("my_pipeline");
my ($source, $demux) =
  GStreamer::ElementFactory -> make(filesrc => "source",
                                    oggdemux => "demuxer");

$source -> set("location", filename_to_unicode $ARGV[0]);

# you would normally check that the elements were created properly

# put together a pipeline
$pipeline -> add($source, $demux);
$source -> link_pads("src", $demux, "sink");

# listen for newly created pads
$demux -> signal_connect(pad_added => \&cb_new_pad);

# start the pipeline
$pipeline -> set_state("playing");

my $loop = Glib::MainLoop -> new(undef, FALSE);
$loop -> run();
