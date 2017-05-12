#!/usr/bin/perl
use strict;
use warnings;
use Glib qw(TRUE FALSE filename_to_unicode);
use GStreamer qw(-init GST_RANK_MARGINAL);

# $Id$

my ($pipeline, @factories);

# This function is called by the registry loader. Its return value
# (TRUE or FALSE) decides whether the given feature will be included
# in the list that we're generating further down.
sub cb_feature_filter {
  my ($feature, $data) = @_;

  # we only care about element factories
  return FALSE unless ($feature -> isa("GStreamer::ElementFactory"));

  # only parsers, demuxers and decoders
  my $klass = $feature -> get_klass();
  return FALSE if (index($klass, "Demux") == -1 &&
                   index($klass, "Decoder") == -1 &&
                   index($klass, "Parse") == -1);

  # only select elements with autoplugging rank
  my $rank = $feature -> get_rank();
  return FALSE if ($rank < GST_RANK_MARGINAL);

  return TRUE;
}

# This function is called to sort features by rank.
sub cb_compare_ranks {
  return $b -> get_rank() - $a -> get_rank();
}

sub init_factories {
  # first filter out the interesting element factories
  @factories = GStreamer::RegistryPool -> feature_filter(
                 \&cb_feature_filter, FALSE);

  # sort them according to their ranks
  @factories = sort cb_compare_ranks @factories;
}

my ($converter, $scale, $audiosink);

sub cb_newpad {
  my ($element, $pad, $data) = @_;
  try_to_plug($pad, $pad -> get_caps());
}

sub close_link {
  my ($srcpad, $sinkelement, $padname, @templlist) = @_;
  my $has_dynamic_pads = FALSE;

  printf "Plugging pad %s:%s to newly created %s:%s\n",
         $srcpad -> get_parent() -> get_name(),
	 $srcpad -> get_name(),
         $sinkelement -> get_name(),
         $padname;

  # add the element to the pipeline and set correct state
  $sinkelement -> set_state("paused");
  $pipeline -> add($sinkelement);
  $srcpad -> link($sinkelement -> get_pad($padname));
  $pipeline -> sync_children_state();

  # if we have static source pads, link those. If we have dynamic
  # source pads, listen for new-pad signals on the element
  foreach my $templ (@templlist) {
    my $direction = $templ -> get_direction();
    my $presence = $templ -> get_presence();
    # only sourcepads, no request pads
    next if ($direction ne "src" || $presence eq "request");

    if ($presence eq "always") {
      my $pad = $sinkelement -> get_pad($templ -> get_name_template());
      my $caps = $pad -> get_caps();

      # link
      try_to_plug($pad, $caps);
    } elsif ($presence eq "sometimes") {
      $has_dynamic_pads = TRUE;
    }
  }

  # listen for newly created pads if this element supports that
  if ($has_dynamic_pads) {
    $sinkelement -> signal_connect(new_pad => \&cb_newpad);
  }
}

sub try_to_plug {
  my ($pad, $caps) = @_;
  my $parent = $pad -> get_parent();

  # don't plug if we're already plugged
  if ($audiosink -> get_pad("sink") -> is_linked()) {
    printf "Omitting link for pad %s:%s because we're already linked\n",
           $parent -> get_name(),
           $pad -> get_name();
    return;
  }

  # as said above, we only try to plug audio... Omit video
  my $mime = $caps -> get_structure(0) -> { name };
  if (index($mime, "video") > -1) {
    printf "Omitting link for pad %s:%s because mimetype %s is non-audio\n",
           $parent -> get_name(),
           $pad -> get_name(),
           $mime;
    return;
  }

  # can it link to the audiopad?
  my $audiocaps = $audiosink -> get_pad("sink") -> get_caps();
  my $res = $caps -> intersect($audiocaps);
  if ($res && !$res -> is_empty()) {
    print "Found pad to link to audiosink - plugging is now done\n";
    close_link($pad, $converter, "sink", ());
    close_link($converter -> get_pad("src"), $scale, "sink", ());
    close_link($scale -> get_pad("src"), $audiosink, "sink", ());
    return;
  }

  # try to plug from our list
  foreach my $factory (@factories) {
    foreach my $templ ($factory -> get_pad_templates()) {
      # find the sink template - need an always pad
      next if ($templ -> get_direction() ne "sink" ||
               $templ -> get_presence() ne "always");

      # can it link?
      my $res = $caps -> intersect($templ -> get_caps());
      if ($res && !$res -> is_empty()) {
        # close link and return
        my $element = $factory -> create(undef);
        close_link($pad, $element, $templ -> get_name_template(),
                   $factory -> get_pad_templates());
        return;
      }

      # we only check one sink template per factory, so move on to the
      # next factory now
      last;
    }
  }

  # if we get here, no item was found
  printf "No compatible pad found to decode %s on %s:%s\n",
         $mime,
         $parent -> get_name(),
         $pad -> get_name();
}

sub cb_typefound {
  my ($typefind, $probability, $caps, $data) = @_;

  printf "Detected media type %s\n", $caps -> to_string();

  # actually plug now
  try_to_plug($typefind -> get_pad("src"), $caps);
}

sub cb_error {
  my ($pipeline, $source, $error, $debug, $data) = @_;

  printf "Error: %s\n", $error -> message();
}

# init ourselves
init_factories();

# args
unless ($#ARGV == 0) {
  print "Usage: $0 <filename>\n";
  exit -1;
}

# pipeline
$pipeline = GStreamer::parse_launch(
  sprintf qq(filesrc location="%s" ! typefind name=tf), filename_to_unicode $ARGV[0]);
$pipeline -> signal_connect(error => \&cb_error);

my $typefind = $pipeline -> get_by_name("tf");
$typefind -> signal_connect(have_type => \&cb_typefound);

($converter, $scale, $audiosink) =
  GStreamer::ElementFactory -> make(audioconvert => "audio-converter",
                                    audioscale => "audio-scale",
                                    alsasink => "audiosink");

$audiosink -> set_state("paused");
$pipeline -> set_state("playing");

# run
while ($pipeline -> iterate()) { }

# exit
$pipeline -> set_state("null");
