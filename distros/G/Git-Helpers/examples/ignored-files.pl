#!/usr/bin/env perl

use strict;
use warnings;

use Data::Printer;
use Git::Helpers qw( ignored_files );

my @ignored = ignored_files(@ARGV);
p @ignored;
