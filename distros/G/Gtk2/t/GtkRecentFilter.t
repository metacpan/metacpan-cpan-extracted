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
  tests => 13,
  at_least_version => [2, 10, 0, "GtkRecentFilter"],
  (on_unthreaded_freebsd () ? (skip_all => 'need a perl compiled with "-pthread" on freebsd') : ());

# $Id$

my $filter = Gtk2::RecentFilter -> new();
isa_ok($filter, "Gtk2::RecentFilter");

$filter -> set_name("Test");
is($filter -> get_name(), "Test");

$filter -> add_mime_type("image/png");
$filter -> add_pattern("*.png");
$filter -> add_pixbuf_formats();
$filter -> add_group("Images");
$filter -> add_age(23);

sub filter_cb {
  my ($info, $data) = @_;

  return TRUE if ($info -> {age} == 23);
  return TRUE if ($info -> {mime_type} eq "image/png");

  return FALSE;
}

$filter = Gtk2::RecentFilter -> new();
$filter -> add_custom([qw/age mime-type/], \&filter_cb);
ok($filter -> get_needed() >= [qw/age mime-type/]);

ok( $filter -> filter({ contains => [qw/age mime-type/], age => 23, mime_type => "image/jpeg" }));
ok( $filter -> filter({ contains => [qw/age mime-type/], age => 42, mime_type => "image/png" }));
ok(!$filter -> filter({ contains => [qw/age mime-type/], age => 42, mime_type => "image/jpeg" }));

my $stuff = {
  contains     => [qw/display-name mime-type application group age/],
  display_name => "Bla",
  mime_type    => "bla",
  applications => ["bla", "blub"],
  groups       => ["Bla", "Blub"],
  age          => 42,
};

sub test_cb {
  my ($info, $data) = @_;

  is($info -> {display_name}, $stuff -> {display_name});
  is($info -> {mime_type}, $stuff -> {mime_type});
  is_deeply($info -> {applications}, $stuff -> {applications});
  is_deeply($info -> {groups}, $stuff -> {groups});
  is($info -> {age}, $stuff -> {age});

  is($data, "data");

  return TRUE;
}

$filter = Gtk2::RecentFilter -> new();
$filter -> add_custom([qw/display-name mime-type application group age/], \&test_cb, "data");
ok($filter -> filter($stuff));

__END__

Copyright (C) 2006 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.
