#!/usr/bin/env perl

use strict;
use warnings;
use lib './lib';
use File::Basename qw/dirname/;
use FindBin qw/$RealBin/;
use Data::Dumper;

use lib '$RealBin/../lib';

use Test::More tests => 2;

use File::MagicPP qw/file/;

$ENV{PATH} = "$RealBin/../scripts:".$ENV{PATH};

diag `file-pp.pl -h`;
my $exit_code = $? << 8;
is($exit_code, 0, "exit code");

subtest 'sub file' => sub {
  is(file($0), "script", "Detected this script as a script");
};

