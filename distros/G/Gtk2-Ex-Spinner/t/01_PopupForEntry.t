#!/usr/bin/perl

use strict;
use warnings;
use Gtk2::Ex::Spinner::PopupForEntry;
use Test::More tests => 5;

SKIP: { eval 'use Test::NoWarnings; 1'
          or skip 'Test::NoWarnings not available', 1; }

my $want_version = 5.1;
ok ($Gtk2::Ex::Spinner::PopupForEntry::VERSION >= $want_version,
    'VERSION variable');
ok (Gtk2::Ex::Spinner::PopupForEntry->VERSION >= $want_version,
    'VERSION class method');
ok (eval { Gtk2::Ex::Spinner::PopupForEntry->VERSION($want_version); 1 },
    "VERSION class check $want_version");
{ my $check_version = $want_version + 1000;
  ok (! eval{Gtk2::Ex::Spinner::PopupForEntry->VERSION($check_version); 1},
      "VERSION class check $check_version");
}

exit 0;
