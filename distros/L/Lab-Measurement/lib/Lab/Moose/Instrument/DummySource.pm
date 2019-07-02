package Lab::Moose::Instrument::DummySource;
$Lab::Moose::Instrument::DummySource::VERSION = '3.682';
#ABSTRACT: Dummy YokogawaGS200 source for use with 'Debug' connection

use 5.010;

use Moose;
use MooseX::Params::Validate;
use Lab::Moose::Instrument
    qw/validated_getter validated_setter setter_params/;
use Carp;
use Lab::Moose::Instrument::Cache;

use namespace::autoclean;

extends 'Lab::Moose::Instrument';

has [
    qw/
        max_units_per_second
        max_units_per_step
        min_units
        max_units
        /
] => ( is => 'ro', isa => 'Num', required => 1 );

has source_level_timestamp => (
    is       => 'rw',
    isa      => 'Num',
    init_arg => undef,
);

has verbose => (
    is      => 'ro',
    isa     => 'Bool',
    default => 1
);

with qw(
    Lab::Moose::Instrument::Common
    Lab::Moose::Instrument::LinearStepSweep
    Lab::Moose::Instrument::SCPI::Source::Function
    Lab::Moose::Instrument::SCPI::Source::Level
    Lab::Moose::Instrument::SCPI::Source::Range
);

sub BUILD {
    my $self = shift;
    $self->clear();
    $self->cached_source_level(0);
    $self->cached_source_function('VOLT');

    #    $self->cls();

    # FIXME: check protect params
}


sub set_level {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => 'Num' },
    );

    return $self->linear_step_sweep(
        to => $value, verbose => $self->verbose,
        %args
    );
}

#
# Aliases for Lab::XPRESS::Sweep API
#

sub cached_level {
    my $self = shift;
    return $self->get_level(@_);
}

sub get_level {
    my $self = shift;

    # Dummy Source: do not query!
    return $self->cached_source_level();
}

sub set_voltage {
    my $self  = shift;
    my $value = shift;
    return $self->set_level( value => $value );
}

sub sweep_to_level {
    my $self = shift;
    return $self->set_voltage(@_);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Moose::Instrument::DummySource - Dummy YokogawaGS200 source for use with 'Debug' connection

=head1 VERSION

version 3.682

=head1 SYNOPSIS

 use Lab::Moose;

 my $source = instrument(
     type => 'DummySource',
     connection_type => 'Debug',
     connection_options => {verbose => 0},
     # mandatory protection settings
     max_units_per_step => 0.001, # max step is 1mV/1mA
     max_units_per_second => 0.01,
     min_units => -10,
     max_units => 10,
 );

 # Step-sweep to new level.
 # Stepsize and speed is given by (max|min)_units* settings.
 $source->set_level(value => 9);

 # Get current level from device cache (without sending a query to the
 # instrument):
 my $level = $source->cached_level();

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by the Lab::Measurement team; in detail:

  Copyright 2017       Simon Reinhardt


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
