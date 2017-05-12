#!/usr/bin/perl
# $Id: 09-packages-reqd.t 19 2012-08-29 06:19:44Z andrew $

use strict;
use warnings;

use Test::More tests => 3;

use blib;
use LaTeX::Encode;


my $packages = {};

my $string = latex_encode(chr(0x20a4) . chr(0x263f), { packages => $packages });

is($string, '{\\textlira}{\\Mercury}', 'translation ok');
ok(exists $packages->{'textcomp'},     'required package indicated');
ok(exists $packages->{'marvosym'},     'required package indicated');
