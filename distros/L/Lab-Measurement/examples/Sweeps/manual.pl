#!/usr/bin/env perl
#PODNAME: manual.pl
#ABSTRACT: Example of custom sweep without Sweep framework

use lib '/home/simon/lab-measurement/lib';

use Lab::Moose;               # get instrument, datafolder, datafile, linspace
use Lab::Moose::Countdown;    # get countdown

my $gate_source = instrument(
    type               => 'DummySource',
    connection_type    => 'Debug',
    connection_options => { verbose => 0 },

    # Safety limits:
    max_units          => 10,   min_units            => -10,
    max_units_per_step => 0.11, max_units_per_second => 10
);

my $bias_source = instrument(
    type               => 'DummySource',
    connection_type    => 'Debug',
    connection_options => { verbose => 0 },

    # Safety limits:
    max_units          => 10,   min_units            => -10,
    max_units_per_step => 0.11, max_units_per_second => 10
);

my $folder   = datafolder();
my $datafile = datafile(
    folder  => $folder, filename => 'data.dat',
    columns => [qw/gate bias current/]
);

$datafile->add_plot(
    type => 'pm3d',
    x    => 'gate',
    y    => 'bias',
    z    => 'current'
);

my @gate_values = linspace( from => 0,  to => 1, step => 0.1 );
my @bias_values = linspace( from => -1, to => 1, step => 0.1 );

for my $gate_value (@gate_values) {
    $gate_source->set_level( value => $gate_value );

    # go to bias sweep start point and wait 5 sec
    $bias_source->set_level( value => $bias_values[0] );
    countdown(5);

    for my $bias_value (@bias_values) {
        $bias_source->set_level( value => $bias_value );
        $datafile->log(
            gate    => $gate_value,
            bias    => $bias_value,
            current => $bias_value + $gate_value,
        );
    }
    $datafile->new_block();
    $datafile->refresh_plots();
}

$bias_source->set_level( value => 0 );

__END__

=pod

=encoding UTF-8

=head1 NAME

manual.pl - Example of custom sweep without Sweep framework

=head1 VERSION

version 3.931

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by the Lab::Measurement team; in detail:

  Copyright 2019       Simon Reinhardt


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
