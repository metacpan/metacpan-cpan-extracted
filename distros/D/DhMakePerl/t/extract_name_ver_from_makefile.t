#!/usr/bin/perl -w
use strict;
use Test::More 'no_plan';
use FindBin qw($Bin);

use DhMakePerl::Command::make;
use DhMakePerl::Config;

my $maker
    = DhMakePerl::Command::make->new( { cfg => DhMakePerl::Config->new } );

eval {
    $maker->extract_name_ver_from_makefile("$Bin/makefiles/module-install-autodie.PL");
};

is($@, "", "Calling extract_name_ver_from_makefile should not die on legit file");

is($maker->perlname, "autodie", "Module name should be autodie");
is($maker->version,  "1.994",   "Module version should be 1.994");
