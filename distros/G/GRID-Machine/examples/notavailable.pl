#!/usr/local/bin/perl -w
use strict;
use GRID::Machine qw(is_operative);

my $host = shift || 'casiano@miranda.pcg.ull.es';
my $command = shift || 'perl -v';
my $delay = shift || 1;

die "$host is not operative\n" unless is_operative('ssh', $host, $command, $delay);
print "host is operative\n";
