#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 1;

diag "Running under perl version $] for $^O",  (chr(65) eq 'A') ? "\n" : " in a non-ASCII world\n";
diag "Win32::BuildNumber ", &Win32::BuildNumber(), "\n" if defined(&Win32::BuildNumber) and defined &Win32::BuildNumber();
diag "MacPerl verison $MacPerl::Version\n" if defined $MacPerl::Version;
diag sprintf "Current time local: %s\n", scalar localtime;
diag sprintf "Current time GMT:   %s\n", scalar gmtime;

pass;
