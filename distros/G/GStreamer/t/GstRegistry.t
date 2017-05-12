#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 21;

# $Id$

use Glib qw(TRUE FALSE);
use GStreamer -init;

my $registry = GStreamer::Registry -> get_default();
isa_ok($registry, "GStreamer::Registry");

$registry -> scan_path("~/.gstreamer-0.10");
is_deeply([$registry -> get_path_list()], []);

isa_ok(($registry -> get_plugin_list())[0], "GStreamer::Plugin");

sub plugin_filter {
  my ($plugin, $data) = @_;

  isa_ok($plugin, "GStreamer::Plugin");
  is($data, "bla");

  return TRUE;
}

my @plugins = $registry -> plugin_filter(\&plugin_filter, TRUE, "bla");
is($#plugins, 0);
isa_ok($plugins[0], "GStreamer::Plugin");

sub feature_filter {
  my ($feature, $data) = @_;

  isa_ok($feature, "GStreamer::PluginFeature");
  is($data, "bla");

  return TRUE;
}

my @features = $registry -> feature_filter(\&feature_filter, TRUE, "bla");
is($#features, 0);
isa_ok($features[0], "GStreamer::PluginFeature");

isa_ok(($registry -> get_feature_list("GStreamer::ElementFactory"))[0], "GStreamer::PluginFeature");

my $plugin_feature = ($registry -> get_feature_list_by_plugin("alsa"))[0];
SKIP: {
  skip 'no alsa plugin found', 1
    unless defined $plugin_feature;

  isa_ok($plugin_feature, "GStreamer::PluginFeature");
}

SKIP: {
  my $plugin = $registry -> find_plugin("volume");
  skip 'could not find "volume" plugin', 2
    unless defined $plugin;
  isa_ok($plugin, "GStreamer::Plugin");
  isa_ok($registry -> find_feature("volume", "GStreamer::ElementFactory"), "GStreamer::PluginFeature");
}

is($registry -> lookup("..."), undef);
is($registry -> lookup_feature("..."), undef);

# These can fail, so just test for definedness.
ok(defined $registry -> xml_write_cache("tmp"));
ok(defined $registry -> xml_read_cache("tmp"));
unlink "tmp";

my $plugin = GStreamer::Plugin::load_by_name("alsa");
SKIP: {
  skip 'failed to load alsa plugin', 2
    unless defined $plugin;

  ok($registry -> add_plugin($plugin));

  my $feature = GStreamer::ElementFactory -> find("alsasink");
  ok($registry -> add_feature($feature));

  $registry -> remove_feature($feature);
  $registry -> remove_plugin($plugin);
}
