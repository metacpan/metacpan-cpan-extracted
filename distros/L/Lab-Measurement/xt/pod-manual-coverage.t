#!/usr/bin/env perl

# Ensure that Lab::Measurement::Manual contains links to all of our modules.
use 5.010;
use warnings;
use strict;
use File::Slurper 'read_binary';
use File::Find;
use Data::Dumper;
use Test::More;

my $manual = read_binary('lib/Lab/Measurement/Manual.pod');

my @module_links = $manual =~ /L<(Lab::.*?)>/g;

# Create lookup table
my %module_links = map { $_ => 1 } @module_links;
# print Dumper \%module_links;
my @source_files;

find(
    {
        wanted => sub {
            my $file = $_;
            if ( $file =~ /\.(pm|pod)$/ ) {
                push @source_files, $file;
            }
        },
        no_chdir => 1,
    },
    'lib'
);

my %source_files = map {
    my $file = $_;
    $file =~ s{^lib/}{};
    $file =~ s{\.(pm|pod)$}{};
    $file =~ s{/}{::}g;
    ( $file => $_ );
} @source_files;

# The following legacy modules are not required in the manual
my @whitelist = qw/
    Lab::Measurement::Manual

    Lab::Moose::Connection::VISA_GPIB
    Lab::Moose::Instrument::OI_IPS::Strunk_3He
    Lab::Moose::Sweep::DataFile
    /;

for my $white (@whitelist) {
    delete $source_files{$white};
}

diag("Checking for dead links in the manual");
for my $link ( keys %module_links ) {
    ok( exists $source_files{$link}, "source file for module $link exists" );
}

diag("Checking for L::M modules missing in the manual");
for my $source ( keys %source_files ) {
    ok( exists $module_links{$source}, "have link to $source" );
}

diag("Checking for modules without pod");
for my $source ( keys %source_files ) {
    my $file     = $source_files{$source};
    my $contents = read_binary($file);
    like( $contents, qr/^=head1/m, "$file contains pod" );
}

done_testing();
