#!/usr/bin/perl -w
use strict;
use Gtk2::TestHelper
  tests => 23,
  at_least_version => [2, 10, 0, 'GtkPrintSettings: it is new in 2.10'];

# $Id$

use File::Temp qw(tempdir);
my $dir = tempdir(CLEANUP => 1);

my $settings = Gtk2::PrintSettings -> new();
isa_ok($settings, 'Gtk2::PrintSettings');

my $key = 'printer';
my $value = 'Bla DeskJet';

$settings -> set($key, $value);
is($settings -> get($key), $value);

ok($settings -> has_key($key));

$settings -> set($key, undef);
is($settings -> get($key), undef);

$settings -> unset($key);
is($settings -> get($key), undef);

my $i_know_you = 0;
my $callback = sub {
  my ($c_key, $c_value, $data) = @_;
  return if $i_know_you++;
  is($c_key, $key);
  is($c_value, $value);
  is($data, 'blub');
};

$settings -> set($key, $value);
$settings -> foreach($callback, 'blub');

SKIP: {
  skip 'new 2.12 stuff', 7
    unless Gtk2->CHECK_VERSION (2, 12, 0);

  $settings -> set($key, $value);

  my $new_settings;
  my $file = "$dir/tmp.settings";

  eval {
    $settings -> to_file($file);
  };
  is($@, '');

  eval {
    $new_settings = Gtk2::PrintSettings -> new_from_file($file);
  };
  is($@, '');
  isa_ok($new_settings, 'Gtk2::PrintSettings');
  is($new_settings -> get($key), $value);

  my $key_file = Glib::KeyFile -> new();
  my $group = undef;
  $settings -> to_key_file($key_file, $group);
  open my $fh, '>', $file or skip 'key file tests', 3;
  print $fh $key_file -> to_data();
  close $fh;

  $key_file = Glib::KeyFile -> new();
  eval {
    $key_file -> load_from_file($file, 'none');
    $new_settings = Gtk2::PrintSettings -> new_from_key_file($key_file, $group);
  };
  is($@, '');
  isa_ok($new_settings, 'Gtk2::PrintSettings');
  is($new_settings -> get($key), $value);
}

SKIP: {
  skip 'new 2.14 stuff', 5
    unless Gtk2->CHECK_VERSION(2, 14, 0);

  my $file = "$dir/tmp.settings2";

  my $settings = Gtk2::PrintSettings -> new();
  $settings -> set($key, $value);

  $settings -> to_file($file);

  my $key_file = Glib::KeyFile -> new();
  my $group = undef;
  $settings -> to_key_file($key_file, $group);

  my $copy = Gtk2::PrintSettings -> new();
  eval {
    $copy -> load_file($file);
  };
  is($@, '');
  is($copy -> get($key), $value);

  eval {
    $copy -> load_file('asdf');
  };
  ok(defined $@);

  $copy = Gtk2::PrintSettings -> new();
  eval {
    $copy -> load_key_file($key_file, $group);
  };
  is($@, '');
  is($copy -> get($key), $value);
}

SKIP: {
  skip 'new 2.16 stuff', 3
    unless Gtk2->CHECK_VERSION(2, 16, 0);

  my $settings = Gtk2::PrintSettings -> new();

  $settings -> set_printer_lpi(3.1416);
  delta_ok($settings -> get_printer_lpi(), 3.1416);

  $settings -> set_resolution_xy(10, 20);
  is($settings -> get_resolution_x(), 10);
  is($settings -> get_resolution_y(), 20);
}

__END__

Copyright (C) 2006, 2013 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.
