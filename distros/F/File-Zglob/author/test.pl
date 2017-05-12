#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use 5.010000;
use autodie;

use File::Zglob;

my $pattern = shift or die "Usage: $0 'pattern'";
say $_ for zglob($pattern);
