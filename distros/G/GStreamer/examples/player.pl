#!/usr/bin/perl
use strict;
use warnings;
use Glib qw(TRUE FALSE);
use GStreamer -init;

sub my_bus_callback {
  my ($bus, $message, $loop) = @_;

  if ($message -> type & "tag") {
    my $tags = $message -> tag_list;
    foreach (qw(artist title album track-number)) {
      if (exists $tags -> { $_ }) {
        printf "  %12s: %s\n", ucfirst GStreamer::Tag::get_nick($_),
                               $tags -> { $_ } -> [0];
      }
    }
  }

  elsif ($message -> type & "error") {
    warn $message -> error;
    $loop -> quit();
  }

  elsif ($message -> type & "eos") {
    $loop -> quit();
  }

  # remove message from the queue
  return TRUE;
}

foreach my $file (@ARGV) {
  my $loop = Glib::MainLoop -> new(undef, FALSE);

  my $player = GStreamer::ElementFactory -> make(playbin => "player");

  $player -> set(uri => Glib::filename_to_uri $file, "localhost");
  $player -> get_bus() -> add_watch(\&my_bus_callback, $loop);

  print "Playing: $file\n";

  $player -> set_state("playing") or die "Could not start playing";
  $loop -> run();
  $player -> set_state("null");
}
