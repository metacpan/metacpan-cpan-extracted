#!/usr/bin/perl

use strict;

use Test::More tests => 6;

use_ok('File::HomeDir::Win32');

ok( defined home(), "home defined");
ok( home() eq home($ENV{USERNAME}), "home = home(username)");
ok( -d home(), "home exists");

{
  ok( !defined $~{''}, "\$~{}");
  ok( !defined $~{$ENV{USERNAME}}, "\$~{username}");
}

