#!/usr/bin/perl;

use Test::More tests => 2;

use File::Path::Stderr qw(make_path remove_tree);
ok(defined(&make_path), "make_path exported");
ok(defined(&remove_tree), "remove_tree exported");

