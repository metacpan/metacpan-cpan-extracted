package Lab::Moose::Instrument::DummySource;
$Lab::Moose::Instrument::DummySource::VERSION = '3.822';
#ABSTRACT: Dummy YokogawaGS200 source for use with 'Debug' connection

use v5.20;


use Moose;
use MooseX::Params::Validate;
use Lab::Moose::Instrument
    qw/validated_getter validated_setter setter_params/;
use Carp;
use Lab::Moose::Instrument::Cache;
use Time::HiRes qw/time sleep/;

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

#
# Internal variables for continous sweep
#

has _sweep_start_time => (
    is  => 'rw',
    isa => 'Lab::Moose::PosNum',
);

has _active => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0
);

has _sweep_target_level => (
    is  => 'rw',
    isa => 'Num',
);

has _sweep_start_level => (
    is  => 'rw',
    isa => 'Num',
);

has _sweep_rate => (
    is  => 'rw',
    isa => 'Num',
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

sub cached_level {
    my $self = shift;
    return $self->get_level(@_);
}

# return negative if sweep is done
sub _remaining_sweep_time {
    my $self = shift;
    if ( not $self->_active ) {
        croak "no sweep";
    }
    my $start_time   = $self->_sweep_start_time();
    my $rate         = $self->_sweep_rate;
    my $target_level = $self->_sweep_target_level;
    my $start_level  = $self->_sweep_start_level;

    my $sgn = $target_level >= $start_level ? 1 : -1;
    my $duration = abs( ( $target_level - $start_level ) / $rate );
    return $duration - ( time() - $start_time );
}

sub get_level {
    my ( $self, %args ) = validated_getter( \@_ );

    if ( $self->_active() ) {

        # in sweep

        my $remaining_time = $self->_remaining_sweep_time();

        my $start_time   = $self->_sweep_start_time();
        my $rate         = $self->_sweep_rate;
        my $target_level = $self->_sweep_target_level;
        my $start_level  = $self->_sweep_start_level;

        my $sgn = $target_level >= $start_level ? 1 : -1;
        my $duration = abs( ( $target_level - $start_level ) / $rate );
        if ( $remaining_time < 0 ) {
            $self->_active(0);
            $self->source_level( value => $target_level );
            return $target_level;
        }
        else {
            return $start_level + $sgn * $rate * ( time - $start_time );
        }
    }
    else {
        return $self->cached_source_level();
    }
}

sub config_sweep {
    my $self = shift;
    my %args = @_;
    if ( $self->_active ) {
        croak("config_sweep called while instrument is active");
    }
    my $target = $args{point};
    my $rate   = abs( $args{rate} );
    $self->_sweep_start_level( $self->cached_level );
    $self->_sweep_target_level($target);
    $self->_sweep_rate($rate);
}

sub trg {
    my $self = shift;
    $self->_active(1);
    $self->_sweep_start_time( time() );
}

sub wait {
    my $self         = shift;
    my $start_time   = $self->_sweep_start_time();
    my $rate         = $self->_sweep_rate;
    my $target_level = $self->_sweep_target_level;
    my $start_level  = $self->_sweep_start_level;
    my $duration     = abs( ( $target_level - $start_level ) / $rate );

    if ( $start_time + $duration > time() ) {
        sleep( $start_time + $duration - time() );
    }

    # Sweep done
    $self->_active(0);
    $self->source_level( value => $target_level );
}

sub active {
    my $self = shift;
    if ( not $self->_active ) {
        return 0;
    }
    if ( $self->_remaining_sweep_time > 0 ) {
        return 1;
    }
    return 0;
}

__PACKAGE__->meta()->make_immutable();

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Moose::Instrument::DummySource - Dummy YokogawaGS200 source for use with 'Debug' connection

=head1 VERSION

version 3.822

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

This software is copyright (c) 2022 by the Lab::Measurement team; in detail:

  Copyright 2017       Simon Reinhardt
            2020       Andreas K. Huettel, Simon Reinhardt


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
