#!/usr/bin/perl

use strict;
use warnings;
use Gtk2::Ex::Spinner;
use Test::More tests => 9;

SKIP: { eval 'use Test::NoWarnings; 1'
          or skip 'Test::NoWarnings not available', 1; }

my $want_version = 0.21;
ok ($Gtk2::Ex::Spinner::VERSION >= $want_version, 'VERSION variable');
ok (Gtk2::Ex::Spinner->VERSION  >= $want_version, 'VERSION class method');
ok (eval { Gtk2::Ex::Spinner->VERSION($want_version); 1 },
    "VERSION class check $want_version");
{ my $check_version = $want_version + 1000;
  ok (! eval{Gtk2::Ex::Spinner->VERSION($check_version); 1},
      "VERSION class check $check_version");
}

require Gtk2;
diag ("Perl-Gtk2 version ",Gtk2->VERSION);
diag ("Perl-Glib version ",Glib->VERSION);
diag ("Compiled against Glib version ",
      Glib::MAJOR_VERSION(), ".",
      Glib::MINOR_VERSION(), ".",
      Glib::MICRO_VERSION(), ".");
diag ("Running on       Glib version ",
      Glib::major_version(), ".",
      Glib::minor_version(), ".",
      Glib::micro_version(), ".");
diag ("Compiled against Gtk version ",
      Gtk2::MAJOR_VERSION(), ".",
      Gtk2::MINOR_VERSION(), ".",
      Gtk2::MICRO_VERSION(), ".");
diag ("Running on       Gtk version ",
      Gtk2::major_version(), ".",
      Gtk2::minor_version(), ".",
      Gtk2::micro_version(), ".");

#------------------------------------------------------------------------------
# weakening
#
# no circular reference between the datespinner and the spinbuttons
# within it

Gtk2->disable_setlocale;  # leave LC_NUMERIC alone for version nums
my $have_display = Gtk2->init_check;

SKIP: {
  # seem to need a DISPLAY initialized in gtk 2.16 or get a slew of warnings
  # creating a Gtk2::Ex::Spinner
  $have_display
    or skip "due to no DISPLAY available", 4;

  my $datespinner = Gtk2::Ex::Spinner->new;

  ok ($datespinner->VERSION >= $want_version, 'VERSION object method');
  ok (eval { $datespinner->VERSION($want_version); 1 },
      "VERSION object check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { $datespinner->VERSION($check_version); 1 },
      "VERSION object check $check_version");

  require Scalar::Util;
  Scalar::Util::weaken ($datespinner);
  is ($datespinner, undef, 'should be garbage collected when weakened');
}

exit 0;
