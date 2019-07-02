package Lab::Moose::Instrument::KeysightE3633E;
$Lab::Moose::Instrument::KeysightE3633E::VERSION = '3.682';
#ABSTRACT: Keysight E3633E voltage/current source.

use 5.010;

use Moose;
use MooseX::Params::Validate;
use Moose::Util::TypeConstraints qw(enum);
use Lab::Moose::Instrument
    qw/validated_getter validated_setter setter_params/;
use Lab::Moose::Instrument::Cache;
use Carp;
use namespace::autoclean;

extends 'Lab::Moose::Instrument';

around default_connection_options => sub {
    my $orig    = shift;
    my $self    = shift;
    my $options = $self->$orig();

    #my $usb_opts = { vid => 0x0b21, pid => 0x0039 };
    #$options->{USB} = $usb_opts;
    #$options->{'VISA::USB'} = $usb_opts;
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

has mode => (
    is       => 'ro',
    isa      => enum( [ 'CURR', 'VOLT' ] ),
    required => 1,
);

sub BUILD {
    my $self = shift;
    $self->clear();
    $self->cls();
}



cache source_level => ( getter => 'source_level_query' );

sub source_level_query {
    my ( $self, %args ) = validated_getter( \@_ );
    my $mode = $self->mode();

    return $self->cached_source_level(
        $self->query( command => "$mode?", %args ) );
}

sub source_level {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => 'Num' }
    );
    my $mode = $self->mode();
    $self->write(
        command => sprintf( "$mode %.15g", $value ),
        %args
    );
    $self->cached_source_level($value);
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
    return $self->cached_source_level(@_);
}


sub get_level {
    my $self = shift;
    return $self->source_level_query(@_);
}


sub get_voltage {
    my ( $self, %args ) = validated_getter( \@_ );
    return $self->query( command => "VOLT?", %args );
}


sub get_current {
    my ( $self, %args ) = validated_getter( \@_ );
    return $self->query( command => "CURR?", %args );
}


sub set_voltage {
    my $self  = shift;
    my $value = shift;
    return $self->set_level( value => $value );
}


sub sweep_to_level {
    my $self   = shift;
    my $target = shift;
    return $self->set_level( value => $target );
}

with qw(
    Lab::Moose::Instrument::Common
    Lab::Moose::Instrument::LinearStepSweep
);

__PACKAGE__->meta()->make_immutable();

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Moose::Instrument::KeysightE3633E - Keysight E3633E voltage/current source.

=head1 VERSION

version 3.682

=head1 SYNOPSIS

 use Lab::Moose;

 my $source = instrument(
     type => 'KeysightE3633E',
     connection_type => 'LinuxGPIB',
     connection_options => {gpib_address => 15},
     # mandatory protection settings
     max_units_per_step => 0.001, # max step is 1mV/1mA
     max_units_per_second => 0.01,
     min_units => -10,
     max_units => 10,

     mode => 'CURR', # or 'VOLT'

 );

 # The source is either in 'CURR' or 'VOLT' mode.

 # Step-sweep to new level.
 # Stepsize and speed is given by (max|min)_units* settings.
 $source->set_level(value => 9);

 # Get level from device cache (without sending a query to the
 # instrument):
 my $level = $source->cached_level();

 # Measure voltage and current (independent of used mode).
 my $current = $source->get_current();
 my $voltage = $source->get_voltage();

=head1 METHODS

Used roles:

=over

=item L<Lab::Moose::Instrument::Common>

=item L<Lab::Moose::Instrument::LinearStepSweep>

=back

=head2 source_range/source_range_query

Set/Get the output source range.

=head2 set_level

 $source->set_level(value => $new_level);

Go to new level. Sweep with multiple steps if the distance between current and
new level is larger than C<max_units_per_step>.

=head2 cached_level

 my $current_level = $source->cached_level();

Get current value from device cache.

=head2 get_level

 my $current_level = $source->get_level();

Query current level.

=head2 get_voltage

 my $voltage = $source->get_voltage();

=head2 get_current

 my $current = $source->get_current();

=head2 set_voltage

 $source->set_voltage($value);

For XPRESS voltage sweep. Equivalent to C<< set_level(value => $value) >>.

=head2 sweep_to_level

Use rate limits (max_units_per_second, max_units_per_step) for sweep steps.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by the Lab::Measurement team; in detail:

  Copyright 2019       Simon Reinhardt


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
