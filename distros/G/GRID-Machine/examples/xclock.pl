#!/usr/local/bin/perl -w
use strict;
use GRID::Machine qw(is_operative);
use Data::Dumper;

my $host = $ENV{GRID_REMOTE_MACHINE};

my $machine = GRID::Machine->new(host => $host, sshoptions => '-X');

print Dumper($machine->eval(q{ CORE::system('xclock') }));

