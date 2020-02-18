#!/usr/bin/perl

# $Id$
#
# Basic test for Glib fundamentals.  make sure that the smoke does't get out,
# and test most of the procedural things in Glib's toplevel namespace.

use strict;
use warnings;

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

use Test::More tests => 28;
BEGIN { use_ok('Glib') };

#########################

ok (defined (Glib::major_version), 'major_version');
ok (defined (Glib::minor_version), 'minor_version');
ok (defined (Glib::micro_version), 'micro_version');
ok (Glib->CHECK_VERSION(0,0,0), 'CHECK_VERSION pass');
ok (!Glib->CHECK_VERSION(50,0,0), 'CHECK_VERSION fail');
my @version = Glib->GET_VERSION_INFO;
print "Glib was compiled for glib version ".join(".",@version)."\n";
is (scalar (@version), 3, 'version info list is 3 items long');
is (Glib::MAJOR_VERSION, $version[0], 'MAJOR_VERSION');
is (Glib::MINOR_VERSION, $version[1], 'MINOR_VERSION');
is (Glib::MICRO_VERSION, $version[2], 'MICRO_VERSION');

ok (defined (Glib::get_user_name), "Glib::get_user_name");
ok (defined (Glib::get_real_name), "Glib::get_real_name");
ok (defined (Glib::get_home_dir), "Glib::get_home_dir");
ok (defined (Glib::get_tmp_dir), "Glib::get_tmp_dir");

SKIP: {
  skip "set_application_name is new in glib 2.2.0", 2
    unless Glib->CHECK_VERSION (2,2,0);

  SKIP: {
    skip 'no undef on win32', 1
      if $^O eq 'MSWin32';
    # this will not hold after Gtk2::init, since gtk_init() calls
    # gdk_parse_args() which calls g_set_prgname(argv[0]).
    is (Glib::get_application_name (), undef, 'before any calls to anything');
  }

  my $appname = 'Flurble Foo 2, Electric Boogaloo';
  Glib::set_application_name ($appname);
  is (Glib::get_application_name (), $appname);
}

is (Glib::get_prgname (), undef, 'before any calls to anything');
Glib::set_prgname ('my_prgname');
is (Glib::get_prgname (), 'my_prgname');

SKIP: {
  skip "new 2.6 stuff", 6
    unless Glib->CHECK_VERSION (2,6,0);

  ok (defined Glib::get_user_data_dir ());
  ok (defined Glib::get_user_config_dir ());
  ok (defined Glib::get_user_cache_dir ());

  ok (defined Glib::get_system_data_dirs ());
  ok (defined Glib::get_system_config_dirs ());
  ok (defined Glib::get_language_names ());
}

SKIP: {
  skip 'new 2.14 stuff', 1
    unless Glib->CHECK_VERSION (2, 14, 0);

  # qw/desktop documents download music pictures public-share templates videos/
  ok (defined Glib::get_user_special_dir ('desktop'));
}

is (Glib::Markup::escape_text ("<gtk2-perl>"), "&lt;gtk2-perl&gt;");

ok (defined Glib::strerror (2));
ok (defined Glib::strsignal (11));

__END__

Copyright (C) 2003-2005 by the gtk2-perl team (see the file AUTHORS for the
full list)

This library is free software; you can redistribute it and/or modify it under
the terms of the GNU Library General Public License as published by the Free
Software Foundation; either version 2.1 of the License, or (at your option) any
later version.

This library is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.  See the GNU Library General Public License for more
details.

You should have received a copy of the GNU Library General Public License along
with this library; if not, write to the Free Software Foundation, Inc., 
51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
