#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use 5.018;
use Mojo::Util qw(dumper);
use DBI;

my @driver_names = DBI->available_drivers;
my %drivers      = DBI->installed_drivers;
say dumper \@driver_names;
say dumper \%drivers;
