#!/usr/bin/env perl

# Hack the testing framework to install Mash locally

use strict;
use warnings;
use File::Basename qw/basename dirname/;
use FindBin qw/$RealBin/;
use Data::Dumper;
use lib "$RealBin/../lib";
use lib "$RealBin/../lib/perl5"; # compatibility with cpanm --installdeps . -l .

use Test::More tests=>2;

use_ok("File::Find::Fast");

my $thisDir = dirname($0);

subtest 'basic' => sub{
  my $files = File::Find::Fast::find("$thisDir/files");
  is(scalar(@$files), 8, "Found 8 files/folders");
};

