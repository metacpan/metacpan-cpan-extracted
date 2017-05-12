#!/usr/bin/perl

use strict;
use warnings;
use Gtk2::Ex::Spinner::CellRenderer;
use Test::More tests => 11;

SKIP: { eval 'use Test::NoWarnings; 1'
          or skip 'Test::NoWarnings not available', 1; }

my $want_version = 5.1;
ok ($Gtk2::Ex::Spinner::CellRenderer::VERSION >= $want_version,
    'VERSION variable');
ok (Gtk2::Ex::Spinner::CellRenderer->VERSION  >= $want_version,
    'VERSION class method');
ok (eval { Gtk2::Ex::Spinner::CellRenderer->VERSION($want_version); 1 },
    "VERSION class check $want_version");
{ my $check_version = $want_version + 1000;
  ok (! eval{Gtk2::Ex::Spinner::CellRenderer->VERSION($check_version); 1},
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

sub main_iterations {
  my $count = 0;
  while (Gtk2->events_pending) {
    $count++;
    Gtk2->main_iteration_do (0);
  }
  diag "main_iterations(): ran $count events/iterations\n";
}


#-----------------------------------------------------------------------------
# plain creation

{
  my $renderer = Gtk2::Ex::Spinner::CellRenderer->new;

  ok ($renderer->VERSION >= $want_version, 'VERSION object method');
  ok (eval { $renderer->VERSION($want_version); 1 },
      "VERSION object check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { $renderer->VERSION($check_version); 1 },
      "VERSION object check $check_version");

  require Scalar::Util;
  Scalar::Util::weaken ($renderer);
  is ($renderer, undef, 'should be garbage collected when weakened');
}

#-----------------------------------------------------------------------------
# start_editing return object

Gtk2->disable_setlocale;  # leave LC_NUMERIC alone for version nums
my $have_display = Gtk2->init_check;

SKIP: {
  $have_display or skip 'no DISPLAY available', 2;

  my $toplevel = Gtk2::Window->new ('toplevel');

  my $renderer = Gtk2::Ex::Spinner::CellRenderer->new (editable => 1);
  my $event = Gtk2::Gdk::Event->new ('button-press');
  my $rect = Gtk2::Gdk::Rectangle->new (0, 0, 100, 100);
  my $editable = $renderer->start_editing
    ($event, $toplevel, "0", $rect, $rect, ['selected']);
  isa_ok ($editable, 'Gtk2::CellEditable',
          'start_editing return');
  $toplevel->add ($editable);
  $toplevel->remove ($editable);
  main_iterations (); # for idle handler hack

  require Scalar::Util;
  Scalar::Util::weaken ($editable);
  is ($editable, undef, 'editable should be garbage collected when weakened');

  $toplevel->destroy;
}

exit 0;
