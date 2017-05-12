#!/usr/bin/perl -w
# DESCRIPTION: Perl ExtUtils: Type 'make test' to test this package
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'
#
# Copyright 2007-2017 by Wilson Snyder.  This program is free software;
# you can redistribute it and/or modify it under the terms of either the GNU
# Lesser General Public License Version 3 or the Perl Artistic License Version 2.0.

use Test::More;
use strict;

BEGIN { plan tests => 2 }
BEGIN { require "./t/test_utils.pl"; }

#########################

my $cmd = `$PERL script/uriexec echo %27Hello+%57orld%21%27`;
ok(1, "uriexec ran");
like($cmd, qr/Hello World!/, "uriexec result for: $cmd");

