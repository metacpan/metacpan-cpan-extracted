#!/usr/bin/perl

use strict;
use lib 'lib', '../lib';

use File::Stat::Moose;

my $file = shift @ARGV;
-f $file or die "Usage: $0 filename\n";
my $st = File::Stat::Moose->new( file => $file, @ARGV );

print "Size: ", $st->size, "\n";    # named field
print "Blocks: ". $st->[12], "\n";  # numbered field

print $st->dump;
