#!/usr/bin/perl -w
# $Id: 02_help.t 49328 2008-01-07 16:28:25Z wsnyder $
# DESCRIPTION: Perl ExtUtils: Type 'make test' to test this package
#
# Copyright 2007-2017 by Wilson Snyder.  This program is free software;
# you can redistribute it and/or modify it under the terms of either the GNU
# Lesser General Public License Version 3 or the Perl Artistic License Version 2.0.

use strict;
use Test;

BEGIN { require "./t/test_utils.pl"; }
eval { use ExtUtils::Manifest; };
my $manifest = ExtUtils::Manifest::maniread();
plan tests => (1 + (keys %{$manifest}));
ok(1);

foreach my $filename (keys %{$manifest}) {
    print "Space test of: $filename\n";
    my $wholefile = wholefile($filename);
    if ($wholefile
	&& $wholefile !~ /[ \t]+\n/
	&& $wholefile !~ /^[ \t]*[ ]+\t/) {
	ok(1);
    } elsif ($filename =~ m!META.yml!) {
	skip("File doesn't need check (harmless)",1);
    } elsif (!$ENV{DIRPROJECT_AUTHOR_SITE}) {
	skip("author only test (harmless)",1);
    } else {
	warn "%Error: $filename: Bad indentation\n";
	ok(0);
    }
}
