#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 3;
use Glib ':constants';

BEGIN { use_ok('Glib::MakeHelper'); }

my $configure_requires =
  Glib::MakeHelper->get_configure_requires_yaml(Bla => 0.1, Foo => 0.006);
like($configure_requires, qr/Bla/);
like($configure_requires, qr/Foo/);
