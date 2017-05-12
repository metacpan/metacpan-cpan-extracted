#!/usr/bin/perl -w
use strict;
use Gtk2::TestHelper tests => 3, noinit => 1;

# $Id$

my $box = Gtk2::HBox -> new();
isa_ok($box, "Gtk2::HBox");

{
  my $label = Gtk2::Label->new ('hello');
  $box->pack_start ($label, 0,0,0);
  $box->remove($label);
  require Scalar::Util;
  Scalar::Util::weaken ($label);
  is ($label, undef, 'child destroyed by weakening after being in box');
}
{
  my $label = Gtk2::Label->new ('hello');
  $box->pack_start ($label, 0,0,0);
  $box->foreach (sub { });
  $box->remove($label);
  require Scalar::Util;
  Scalar::Util::weaken ($label);
  is ($label, undef,
      'child destroyed by weakening after being in box -- and foreach()');
}

__END__

Copyright (C) 2003, 2009 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.
