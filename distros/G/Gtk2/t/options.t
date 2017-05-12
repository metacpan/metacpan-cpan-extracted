#!/usr/bin/perl
use strict;
use warnings;
use Gtk2::TestHelper tests => 4, noinit => 1;

SKIP:
{
  @ARGV = qw(--help --name gtk2perl --urgs tree);

  skip 'Gtk2->init_check failed, probably unable to open DISPLAY', 1
    unless (Gtk2->init_check);

  is_deeply (\@ARGV, [qw(--help --urgs tree)]);
}

SKIP: {
  skip "parse_args is new in 2.4.5", 1
    unless Gtk2->CHECK_VERSION (2, 4, 5);

  # we can't do much more than just calling it, since it always
  # immediately returns if init() was called already.
  ok (Gtk2->parse_args);
}

SKIP: {
  skip 'new 2.6 stuff', 1
    unless Gtk2->CHECK_VERSION(2, 6, 0);

  my $foos = 1;
  my $options = [
    [ 'foos', 'f', 'int', \$foos ],
  ];

  my $context = Glib::OptionContext->new ('- urgsify your life');
  $context->add_main_entries ($options, 'C');
  $context->add_group (Gtk2->get_option_group (0));

  @ARGV = qw(--name Foo --foos 23);
  $context->parse ();
  is (@ARGV, 0);
  is ($foos, 23);
}

__END__

Copyright (C) 2003-2013 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.
