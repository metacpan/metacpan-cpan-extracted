#!/usr/bin/perl;

use Test::More tests => 3;

use_ok("File::Path::Stderr");
ok(defined(&mkpath), "mkpath exported");
ok(defined(&rmpath), "rmpath exported");

