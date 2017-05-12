#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

eval "use YAML";

plan 'skip_all', "Can't check prerequisites in META.yml - YAML not installed"
    if $@;

my @modules = qw();

eval {
    my $meta = YAML::LoadFile('META.yml');
    my $prereqs = $meta->{'requires'};
    push @modules, keys %$prereqs
        if ref($prereqs) eq 'HASH';
};

plan 'tests' => 1;

if ($@) {
    fail( "An error occurred while fetching prerequisites from META.yml: $@" )
}

print STDERR "\n# Reporting module versions in case there are test failures\n"
    if scalar @modules;

foreach (@modules) {
    no strict 'refs';
    eval "require $_";
    my $version = $@ ? 'not installed' : ${ "${_}::VERSION" } || 'unknown';
    print STDERR sprintf("#   %s - %s\n", $_, $version);
}

ok( 1, 'report versions' );

