#!/usr/bin/perl
use strict;
use warnings;
use Glib qw(TRUE FALSE);
use GStreamer;

# $Id$

sub cb_handoff {
  my ($fakesrc, $buffer, $pad, $user_data) = @_;
  my $white = FALSE if (0);

  # this makes the image black/white
  $buffer -> set_data($white ?
                        0xff x $buffer -> size() :
                        0x0 x $buffer -> size());
  $white = !$white;
}

GStreamer -> init();
my $loop = Glib::MainLoop -> new(undef, FALSE);

# setup pipeline
my $pipeline = GStreamer::Pipeline -> new("pipeline");
my ($fakesrc, $flt, $conv, $videosink) =
  GStreamer::ElementFactory -> make(fakesrc => "source",
                                    capsfilter => "flt",
                                    ffmpegcolorspace => "conv",
                                    ximagesink => "videosink");

# setup
$flt -> set(caps => GStreamer::Caps::Simple -> new(
                       "video/x-raw-rgb",
                       width => "Glib::Int" => 384,
                       height => "Glib::Int" => 288,
                       framerate => "Glib::Double" => 1.0,
                       bpp => "Glib::Int" => 16,
                       depth => "Glib::Int" => 16,
                       endianness => "Glib::Int" => 1234));

$pipeline -> add($fakesrc, $flt, $conv, $videosink);
$fakesrc -> link($flt, $conv, $videosink);

# setup fake source
$fakesrc -> set(signal_handoffs => TRUE,
                sizemax => 384 * 288 * 2,
                sizetype => "fixed");
$fakesrc -> signal_connect(handoff => \&cb_handoff);

# play
$pipeline -> set_state("playing");
$loop -> run();

# clean up
$pipeline -> set_state("null");
