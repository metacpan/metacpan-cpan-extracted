#!/usr/bin/perl
use strict;
use warnings;
use 5.010;

use Data::Dumper;
use MetaCPAN::API;

my $name = shift or die "Usage: $0 Module::Name\n";

my %data;

my $mcpan = MetaCPAN::API->new;
process_module($name);
say Dumper \%data;

sub process_distro {
    my ($name) = @_;

    return if exists $data{distros}{$name};
    say STDERR "Processing distro $name";

    $data{distros}{$name} = undef;
    my $dist  = eval { $mcpan->release( distribution => $name ) };
    if ($@) {
        warn "Exception: $@";
        return;
    }
    $data{distros}{$name} = $dist;

    foreach my $dep (@{ $dist->{dependency} }) {
        process_module($dep->{module});
    }

    return;
}

sub process_module {
    my ($name) = @_;

    return if exists $data{modules}{ $name };
    say STDERR "Processing module $name";

    $data{modules}{ $name } = undef;
    my $module   = eval { $mcpan->module( $name ) };
    if ($@) {
        warn "Exception: $@";
        return;
    }
    $data{modules}{ $name } = $module;
    process_distro($module->{distribution});

    return;
}

