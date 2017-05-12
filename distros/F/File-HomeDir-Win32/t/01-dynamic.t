#!/usr/bin/perl

use strict;

use Test::More;

BEGIN {
  eval {
    require File::HomeDir;
    File::HomeDir->import();
  };
  plan skip_all => "File::HomeDir not installed" if ($@);
}

plan tests => 5;

BEGIN {
  if ($^O eq "MSWin32") {
    eval {
      require File::HomeDir::Win32;
      File::HomeDir::Win32->import();
    };
    die "$@" if ($@); 
  }
}

ok( defined home(), "home defined");
is( home(), home($ENV{USERNAME}), "home = home(username)");
ok( -d home(), "home exists");

{
  is( $~{''}, home(), "\$~{} = home(username)");
  is( $~{$ENV{USERNAME}}, home(), "\$~{} = home(username)");
}


