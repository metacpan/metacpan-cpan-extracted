#!/usr/bin/perl -w
use strict;
use Gtk2::TestHelper
  tests => 4,
  at_least_version => [2, 10, 0, "GtkPrintOperationPreview is new in 2.10"];

# $Id$

my $op = Gtk2::PrintOperation -> new();
$op -> signal_connect(preview => sub {
  my ($op, $preview, $context, $window) = @_;

  isa_ok($op, "Gtk2::PrintOperation");
  isa_ok($preview, "Gtk2::PrintOperationPreview");
  isa_ok($context, "Gtk2::PrintContext");
  is($window, undef);

  my $surf = Cairo::ImageSurface -> create("rgb24", 1, 1);
  my $cr = Cairo::Context -> create($surf);
  $context -> set_cairo_context($cr, 72, 72);

  # This is not nice at all, but I know of no other way to convince the op that
  # now's a good time to stop blocking.
  exit;

  return TRUE;
});

$op -> run("preview", undef);

__END__

Copyright (C) 2006 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.
