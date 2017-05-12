#!/usr/bin/perl -w
use strict;

sub on_unthreaded_freebsd {
  if ($^O eq 'freebsd') {
    require Config;
    if ($Config::Config{ldflags} !~ m/-pthread\b/) {
      return 1;
    }
  }
  return 0;
}

use Gtk2::TestHelper
  tests => 15,
  at_least_version => [2, 10, 0, "GtkRecentChooser"],
  (on_unthreaded_freebsd () ? (skip_all => 'need a perl compiled with "-pthread" on freebsd') : ());

# $Id$

use File::Temp qw(tempdir);
my $dir = tempdir(CLEANUP => 1);

my $manager = Glib::Object::new("Gtk2::RecentManager", filename => "$dir/test.xbel");

my $chooser = Gtk2::RecentChooserWidget -> new_for_manager($manager);
isa_ok($chooser, "Gtk2::RecentChooser");

$chooser -> set_show_private(TRUE);
ok($chooser -> get_show_private());

$chooser -> set_show_not_found(TRUE);
ok($chooser -> get_show_not_found());

$chooser -> set_select_multiple(TRUE);
ok($chooser -> get_select_multiple());

$chooser -> set_limit(23);
is($chooser -> get_limit(), 23);

$chooser -> set_local_only(TRUE);
ok($chooser -> get_local_only());

$chooser -> set_show_tips(TRUE);
ok($chooser -> get_show_tips());

$chooser -> set_show_icons(TRUE);
ok($chooser -> get_show_icons());

$chooser -> set_sort_type("mru");
is($chooser -> get_sort_type(), "mru");

$chooser -> set_sort_func(sub { warn join ", ", @_; }, "data");
$chooser -> set_sort_func(sub { warn join ", ", @_; });

# --------------------------------------------------------------------------- #

use Cwd qw(cwd);
my $uri_one = Glib::filename_to_uri(cwd() . "/" . $0, undef);
my $uri_two = Glib::filename_to_uri($^X, undef);

$manager -> purge_items();
$manager -> add_item($uri_one);
$manager -> add_item($uri_two);

# add_item() is asynchronous, so let the main loop spin for a while
Gtk2->main_iteration while scalar (my @items = $manager->get_items) < 2;
$manager->signal_emit("changed");

$chooser -> set_select_multiple(FALSE);

run_main(sub {
  $chooser -> set_current_uri($uri_one);
});

run_main(sub {
  is($chooser -> get_current_uri(), $uri_one);
  is($chooser -> get_current_item() -> get_uri(), $uri_one);
});

$chooser -> select_uri($uri_two);
$chooser -> unselect_uri($uri_two);

$chooser -> set_select_multiple(TRUE);

$chooser -> select_all();
$chooser -> unselect_all();

my @expected_uris = sort ($uri_two, $uri_one);
is_deeply([sort $chooser -> get_uris()], \@expected_uris);
is_deeply([sort map { $_ -> get_uri() } $chooser -> get_items()], \@expected_uris);

my $filter_one = Gtk2::RecentFilter -> new();
my $filter_two = Gtk2::RecentFilter -> new();

$chooser -> add_filter($filter_one);
$chooser -> add_filter($filter_two);
is_deeply([$chooser -> list_filters()], [$filter_one, $filter_two]);
$chooser -> remove_filter($filter_two);
$chooser -> remove_filter($filter_one);

$chooser -> set_filter($filter_one);
is($chooser -> get_filter(), $filter_one);

__END__

Copyright (C) 2006, 2013 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.
