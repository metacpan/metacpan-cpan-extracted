#!/usr/bin/perl

use strict;
use warnings;

use File::Spec;
use FindBin qw($Bin);
use LaTeX::TOM;
use Test::More tests => 2;

my $parser = LaTeX::TOM->new;
ok($parser->isa('LaTeX::TOM::Parser'), 'Parser object is-a LaTeX::TOM::Parser object');
my $tree = $parser->parseFile(File::Spec->catfile($Bin, 'data', 'tex.in'));
ok($tree, 'Parser returned a defined tree');
