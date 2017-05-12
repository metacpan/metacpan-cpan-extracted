#!/usr/bin/perl

use strict;

use Test::More;

plan skip_all => "Need Perl 5.7.3 or greater" if ($] < 5.007003);

plan tests => 7;

use_ok("File::HomeDir");
use_ok("if", ($^O eq "MSWin32"), "File::HomeDir::Win32");

ok( defined home(), "home defined");
ok( home() eq home($ENV{USERNAME}), "home = home(username)");
ok( -d home(), "home exists");

{
  ok( $~{''} eq home(), "\$~{} = home(username)");
  ok( $~{$ENV{USERNAME}} eq home(), "\$~{} = home(username)");
}


