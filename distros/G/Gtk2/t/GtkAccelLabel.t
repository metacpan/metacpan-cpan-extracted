#!/usr/bin/perl -w
use strict;
use Gtk2::TestHelper tests => 5;

# $Id$

my $button = Gtk2::Button -> new("Blub");

my $label = Gtk2::AccelLabel -> new("Bla");
isa_ok($label, "Gtk2::AccelLabel");

# undef for no accel-widget
$label -> set_accel_widget(undef);
is($label -> get_accel_widget(), undef);

$label -> set_accel_widget($button);
is($label -> get_accel_widget(), $button);

like($label -> get_accel_width(), qr/^\d+$/);
ok(! $label -> refetch());

__END__

Copyright (C) 2003, 2010 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.
