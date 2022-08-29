package Lab::Moose::Instrument::Keithley2450;
$Lab::Moose::Instrument::Keithley2450::VERSION = '3.822';
#ABSTRACT: Keithley 2450 voltage/current sourcemeter.

use v5.20;

use Moose;
use MooseX::Params::Validate;
use Lab::Moose::Instrument
    qw/validated_getter validated_setter setter_params/;
use Lab::Moose::Instrument::Cache;
use Carp;
use namespace::autoclean;

extends 'Lab::Moose::Instrument';

around default_connection_options => sub {
    my $orig     = shift;
    my $self     = shift;
    my $options  = $self->$orig();
    my $usb_opts = { vid => 0x05e6, pid => 0x2450 };    # FIXME
    $options->{USB} = $usb_opts;
    $options->{'VISA::USB'} = $usb_opts;
    return $options;
};

has [qw/max_units_per_second max_units_per_step min_units max_units/] =>
    ( is => 'ro', isa => 'Num', required => 1 );

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

sub BUILD {
    my $self = shift;

    $self->clear();
    $self->cls();
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


sub get_value {
    my ( $self, %args ) = validated_getter( \@_ );
    return $self->query( command => 'READ?', %args );
}


sub source_limit {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => 'Num' },
    );
    my $func = $self->cached_source_function();
    my $lim_func;

    if ( $func eq 'VOLT' ) {
        $lim_func = 'I';
    }
    elsif ( $func eq 'CURR' ) {
        $lim_func = 'V';
    }
    else {
        croak("unknown source function $func (must one of VOLT or CURR)");
    }
    $self->write( command => "SOUR:${func}:${lim_func}LIM $value", %args );
}

sub source_limit_query {
    my ( $self, %args ) = validated_getter( \@_ );

    my $func = $self->cached_source_function();
    my $lim_func;

    if ( $func eq 'VOLT' ) {
        $lim_func = 'I';
    }
    elsif ( $func eq 'CURR' ) {
        $lim_func = 'V';
    }
    else {
        croak("unknown source function $func (must one of VOLT or CURR)");
    }
    return $self->query( command => "SOUR:${func}:${lim_func}LIM?", %args );
}

#
# Aliases for Lab::XPRESS::Sweep API
#


sub cached_level {
    my $self = shift;
    return $self->cached_source_level(@_);
}


sub get_level {
    my $self = shift;
    return $self->source_level_query(@_);
}


sub set_voltage {
    my $self  = shift;
    my $value = shift;
    return $self->set_level( value => $value );
}

with qw(
    Lab::Moose::Instrument::Common
    Lab::Moose::Instrument::SCPI::Output::State
    Lab::Moose::Instrument::SCPI::Sense::Function
    Lab::Moose::Instrument::SCPI::Sense::Range
    Lab::Moose::Instrument::SCPI::Sense::NPLC
    Lab::Moose::Instrument::SCPI::Source::Function
    Lab::Moose::Instrument::SCPI::Source::Level
    Lab::Moose::Instrument::SCPI::Source::Range
    Lab::Moose::Instrument::LinearStepSweep
);

__PACKAGE__->meta()->make_immutable();

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Moose::Instrument::Keithley2450 - Keithley 2450 voltage/current sourcemeter.

=head1 VERSION

version 3.822

=head1 SYNOPSIS

 use Lab::Moose;

 my $smu = instrument(
     type => 'Keithley2450',
     connection_type => 'LinuxGPIB',
     connection_options => {gpib_address => 15},
     # mandatory protection settings
     max_units_per_step => 0.001, # max step is 1mV/1mA
     max_units_per_second => 0.01,
     min_units => -10,
     max_units => 10,
 );

 ### Sourcing


 # Source voltage
 $smu->source_function(value => 'VOLT');
 $smu->source_range(value => 210);
 
 # Step-sweep to new level.
 # Stepsize and speed is given by (max|min)_units* settings.
 $smu->set_level(value => 9);

 # Get current level from device cache (without sending a query to the
 # instrument):
 my $level = $smu->cached_level();

 ### Measurement 

 # Measure current
 $smu->sense_function(value => 'CURR');
 $smu->sense_nplc(value => 2);

 # Get value of current
 my $current = $smu->get_value();

=head1 METHODS

Used roles:

=over

=item L<Lab::Moose::Instrument::Common>

=item L<Lab::Moose::Instrument::SCPI::Output::State>

=item L<Lab::Moose::Instrument::SCPI::Sense::Range>

=item L<Lab::Moose::Instrument::SCPI::Sense::NPLC>

=item L<Lab::Moose::Instrument::SCPI::Source::Function>

=item L<Lab::Moose::Instrument::SCPI::Source::Level>

=item L<Lab::Moose::Instrument::SCPI::Source::Range>

=item L<Lab::Moose::Instrument::LinearStepSweep>

=back

=head2 set_level

 $smu->set_level(value => $new_level);

Go to new level. Sweep with multiple steps if the distance between current and
new level is larger than C<max_units_per_step>.

=head2 get_value

 my $value = $smu->get_value();

Perform measurement of value defined by C<sense_function>.

=head2 source_limit/source_limit_query

Set current compliance limit of voltage source to 1mA

 $smu->source_function(value => 'VOLT');
 $smu->source_limit(value => 1e-3);

Set voltage compliance limit of current source to 1V

 $smu->source_function(value => 'CURR');
 $smu->source_limit(value => 1);

Get current source limit
 my $limit = $smu->source_limit_query();

=head2 cached_level

 my $current_level = $smu->cached_level();

Get current value from device cache.

=head2 get_level

 my $current_level = $smu->get_level();

Query current level.

=head2 set_voltage

 $smu->set_voltage($value);

For XPRESS voltage sweep. Equivalent to C<< set_level(value => $value) >>.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by the Lab::Measurement team; in detail:

  Copyright 2021       Simon Reinhardt


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
