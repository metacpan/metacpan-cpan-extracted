#!/usr/bin/perl -w

use strict;
use warnings;
use diagnostics;
use blib;
use IO::All;

die "please give two URIs, filenames, or somethings\n" unless (@ARGV >= 2);
io(shift) > io(shift);

