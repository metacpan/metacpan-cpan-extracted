#!/usr/bin/perl -w
use strict;
use Gtk2::TestHelper tests => 24;

# $Id$

use Gtk2::Gdk::Keysyms;

my $key = $Gtk2::Gdk::Keysyms{ KP_Enter };
my $mask = [qw(shift-mask)];

Gtk2::AccelMap -> add_entry("<gtk2-perl-tests>/Bla/Blub", $key, $mask);

my @test = Gtk2::AccelMap -> lookup_entry("<gtk2-perl-tests>/Bla/Blub");
is($test[0], $key);
is_deeply(\@{ $test[1] }, $mask);
is($test[2], 0);

is(Gtk2::AccelMap -> change_entry("<gtk2-perl-tests>/Bla/Blub", $key + 1, $mask, 0), 1);

@test = Gtk2::AccelMap -> lookup_entry("<gtk2-perl-tests>/Bla/Blub");
is($test[0], $key + 1);
is_deeply(\@{ $test[1] }, $mask);
is($test[2], 0);

# Gtk2::AccelMap -> save(...);
# Gtk2::AccelMap -> load(...);

Gtk2::AccelMap -> add_filter("<gtk2-perl-tests>/Ble");

Gtk2::AccelMap -> add_entry("<gtk2-perl-tests>/Ble", $key, $mask);
is(Gtk2::AccelMap -> change_entry("<gtk2-perl-tests>/Ble", $key + 1, $mask, 0), 1);

Gtk2::AccelMap -> foreach("bla", sub {
  is($_[0], "<gtk2-perl-tests>/Bla/Blub");
  is($_[1], $key + 1);
  is_deeply(\@{ $_[2] }, $mask);
  is($_[3], 1);
  is($_[4], "bla");
});

Gtk2::AccelMap -> foreach_unfiltered("bla", sub {
  my $path = shift();

  ok($path eq "<gtk2-perl-tests>/Bla/Blub" || $path eq "<gtk2-perl-tests>/Ble");
  ok(shift() - $key <= 1);
  is_deeply(\@{ shift() }, $mask);
  is(shift(), 1);
  is(shift(), "bla");
});

SKIP: {
  skip "new stuff", 1
    unless Gtk2 -> CHECK_VERSION(2, 4, 0);

  isa_ok(Gtk2::AccelMap -> get(), "Gtk2::AccelMap");

  Gtk2::AccelMap -> lock_path("<gtk2-perl-tests>/Bla/Blub");
  Gtk2::AccelMap -> unlock_path("<gtk2-perl-tests>/Bla/Blub");
}

__END__

Copyright (C) 2003-2005 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.
