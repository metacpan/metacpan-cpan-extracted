#!/usr/bin/perl
#
# $Id$
#

#########################
# GtkRecentManager Tests
# 	- ebassi
#########################

#########################

use strict;
use warnings;
use File::Basename qw(basename);
use File::Temp qw(tempdir);
my $dir = tempdir(CLEANUP => 1);

sub on_unthreaded_freebsd {
  if ($^O eq 'freebsd') {
    require Config;
    if ($Config::Config{ldflags} !~ m/-pthread\b/) {
      return 1;
    }
  }
  return 0;
}

use Gtk2::TestHelper tests => 36,
    at_least_version => [2, 10, 0, "GtkRecentManager is new in 2.10"],
    (on_unthreaded_freebsd () ? (skip_all => 'need a perl compiled with "-pthread" on freebsd') : ()),
    ;

my $manager = Gtk2::RecentManager->get_default;
isa_ok($manager, 'Gtk2::RecentManager', 'get_default');

$manager = Gtk2::RecentManager->new;
isa_ok($manager, 'Gtk2::RecentManager', 'new');

$manager = Gtk2::RecentManager->get_for_screen(Gtk2::Gdk::Screen->get_default);
isa_ok($manager, 'Gtk2::RecentManager', 'get_for_screen');

$manager->set_screen(Gtk2::Gdk::Screen->get_default);

# tests should not change or modify the global recently used files
# list, so we use the 'filename' constructor only property of the
# GtkRecentManager object to create our own test storage file.  this
# also gives us a better controlled environment. -- ebassi
$manager = Glib::Object::new('Gtk2::RecentManager', filename => "$dir/test.xbel");
isa_ok($manager, 'Gtk2::RecentManager');

# purge existing items.
$manager->purge_items;

# use this silly trick to get a file
my $icon_theme = Gtk2::IconTheme->get_default;
my $icon_info  = $icon_theme->lookup_icon('stock_edit', 24, 'use-builtin');

SKIP: {
	skip "add_item; theme icon not found", 32
		unless defined $icon_info;

	my $icon_file = $icon_info->get_filename;
	my $icon_uri  = 'file://' . $icon_file;

	$manager->add_item($icon_uri);
	# add_item() is asynchronous, so let the main loop spin for a while
	Gtk2->main_iteration while !$manager->get_items;

	ok($manager->has_item($icon_uri), 'check add item');

	$manager->move_item($icon_uri, $icon_uri . '.bak');
	$manager->move_item($icon_uri . '.bak', $icon_uri,);

	$manager->set_limit(23);
	is ($manager->get_limit, 23, 'limit');

	sleep(1); # gross hack to allow the timestamp to be different

	$manager->add_full($icon_uri, {
			   display_name => 'Stock edit',
			   description  => 'GTK+ stock icon for edit',
			   mime_type    => 'image/png',
			   app_name     => 'Eog',
			   app_exec     => 'eog %u',
			   is_private   => 1,
			   groups       => ['Group I', 'Group II'],
		});
	ok($manager->has_item($icon_uri), 'check add full');

	my $recent_info = $manager->lookup_item($icon_uri);
	isa_ok($recent_info, 'Gtk2::RecentInfo', 'check recent_info');

	is($recent_info->get_uri,          $icon_uri,                  'check URI' );
	is($recent_info->get_display_name, 'Stock edit',               'check name');
	is($recent_info->get_description,  'GTK+ stock icon for edit', 'check description');
	is($recent_info->get_mime_type,    'image/png',                'check MIME');
	is($recent_info->get_short_name,   basename $icon_file,        'check short name');

	ok(defined $recent_info->get_uri_display, 'check display uri');
	ok(defined $recent_info->get_age,         'check age');
	ok($recent_info->is_local,                'check local');
	ok($recent_info->exists,                  'check exists');
	ok($recent_info->match($recent_info),     'check match');

	ok(defined $recent_info->get_added, 'check added stamp');

	ok($recent_info->has_application('Eog'),         'check app/1');
	ok(!$recent_info->has_application('Dummy Test'), 'check app/2');

	ok($recent_info->is_local, 'check is local');

	is($recent_info->last_application, 'Eog', 'check last application');

	my @app_info = $recent_info->get_application_info('Eog');
	is(@app_info, 3, 'check app info');

	my ($exec, $count, $stamp) = @app_info;
	is($exec,  'eog ' . $icon_uri,         'check exec' );
	is($count, 1,                          'check count');
	is($stamp, $recent_info->get_modified, 'check stamp');

	my @apps = $recent_info->get_applications;
	is(scalar @apps, 2, 'check applications'); # $0 + 'Eog'

	is_deeply([$recent_info->get_groups], ['Group I', 'Group II'], 'check groups/1');
	ok($recent_info->has_group('Group I'), 'check groups/2');

	isa_ok($recent_info->get_icon('24'), 'Gtk2::Gdk::Pixbuf');

	is($recent_info->get_private_hint, 1, 'check is private');

	my @items = $manager->get_items;
	is(@items, 1, 'check get_items');
	is($items[0]->get_uri, $icon_uri);

	$manager->remove_item($icon_uri);
	ok(!$manager->has_item($icon_uri), 'check remove item');

	is($manager->purge_items, 0, 'check purge items');
}

__END__

Copyright (C) 2006, 2013 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.
