package Lab::Moose::Instrument::Keithley2400;
$Lab::Moose::Instrument::Keithley2400::VERSION = '3.682';
#ABSTRACT: Keithley 2400 voltage/current sourcemeter.

use 5.010;

use Moose;
use MooseX::Params::Validate;
use Lab::Moose::Instrument
    qw/validated_getter validated_setter setter_params/;
use Lab::Moose::Instrument::Cache;
use Carp;
use namespace::autoclean;

extends 'Lab::Moose::Instrument';

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


sub get_measurement {
    my ( $self, %args ) = validated_getter( \@_ );
    my $meas = $self->query( command => ':MEAS:CURR?', %args );
    my $elements = $self->query( command => ':FORM:ELEM?' );
    my @elements    = split /,/, $elements;
    my @meas_values = split /,/, $meas;
    my %result = map { $_ => shift @meas_values } @elements;
    return \%result;
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
    Lab::Moose::Instrument::SCPI::Sense::Function::Concurrent
    Lab::Moose::Instrument::SCPI::Sense::Protection
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

Lab::Moose::Instrument::Keithley2400 - Keithley 2400 voltage/current sourcemeter.

=head1 VERSION

version 3.682

=head1 SYNOPSIS

 use Lab::Moose;

 my $source = instrument(
     type => 'Keithley2400',
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
 $source->source_function(value => 'VOLT');
 $source->source_range(value => 210);
 
 # Step-sweep to new level.
 # Stepsize and speed is given by (max|min)_units* settings.
 $source->set_level(value => 9);

 # Get current level from device cache (without sending a query to the
 # instrument):
 my $level = $source->cached_level();

 ### Measurement 

 # Measure current
 $source->sense_function_on(value => ['CURR']);
 # Use measurement integration time of 2 NPLC
 $source->sense_function(value => 'CURR');
 $source->sense_nplc(value => 2);

 # Get measurement sample
 my $sample = $source->get_measurement();
 my $current = $sample->{CURR};
 # print all entries in sample (Voltage, Current, Resistance, Timestamp):
 use Data::Dumper;
 print Dumper $sample;

=head1 METHODS

Used roles:

=over

=item L<Lab::Moose::Instrument::Common>

=item L<Lab::Moose::Instrument::SCPI::Sense::Protection>

=item L<Lab::Moose::Instrument::SCPI::Sense::Range>

=item L<Lab::Moose::Instrument::SCPI::Sense::NPLC>

=item L<Lab::Moose::Instrument::SCPI::Source::Function::Concurrent>

=item L<Lab::Moose::Instrument::SCPI::Source::Level>

=item L<Lab::Moose::Instrument::SCPI::Source::Range>

=item L<Lab::Moose::Instrument::LinearStepSweep>

=back

=head2 set_level

 $source->set_level(value => $new_level);

Go to new level. Sweep with multiple steps if the distance between current and
new level is larger than C<max_units_per_step>.

=head2 get_measurement

 my $sample = $source->get_measurement();
 my $current = $sample->{CURR};

Do new measurement and return sample hashref of measured elements.

=head2 cached_level

 my $current_level = $source->cached_level();

Get current value from device cache.

=head2 get_level

 my $current_level = $source->get_level();

Query current level.

=head2 set_voltage

 $source->set_voltage($value);

For XPRESS voltage sweep. Equivalent to C<< set_level(value => $value) >>.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by the Lab::Measurement team; in detail:

  Copyright 2018       Simon Reinhardt


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
