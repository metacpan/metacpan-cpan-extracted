package Lab::Moose::Instrument::Yokogawa7651;
$Lab::Moose::Instrument::Yokogawa7651::VERSION = '3.682';
#ABSTRACT: Yokogawa7651 voltage/current source.

use 5.010;

use Moose;
use MooseX::Params::Validate;
use Lab::Moose::Instrument
    qw/validated_getter validated_setter setter_params/;
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

sub BUILD {
    my $self = shift;
}


cache source_level => ( getter => 'source_level_query' );

sub source_level_query {
    my ( $self, %args ) = validated_getter( \@_ );

    my $value = $self->query( command => "OD", %args );

    # FIXME: why do we need this????
    $value = substr( $value, 4 );

    # ????????

    return $self->cached_source_level();
}

sub source_level {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => 'Num' }
    );

    $self->write(

        # Trailing 'e' is trigger.
        command => sprintf( "S%.17ge", $value ),
        %args
    );
    $self->cached_source_level($value);
}


sub set_level {
    my ( $self, $value, %args ) = validated_setter(
        \@_,
        value => { isa => 'Num' },
    );
    return $self->linear_step_sweep( to => $value, %args );
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


sub sweep_to_level {
    my $self = shift;
    return $self->set_voltage(@_);
}

with qw(
    Lab::Moose::Instrument::LinearStepSweep
);

__PACKAGE__->meta()->make_immutable();

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Moose::Instrument::Yokogawa7651 - Yokogawa7651 voltage/current source.

=head1 VERSION

version 3.682

=head1 SYNOPSIS

 use Lab::Moose;

 my $yoko = instrument(
     type => 'Yokogawa7651',
     connection_type => 'LinuxGPIB',
     connection_options => {gpib_address => 15},
     # mandatory protection settings
     max_units_per_step => 0.001, # max step is 1mV/1mA
     max_units_per_second => 0.01,
     min_units => -10,
     max_units => 10,
 );

 # Step-sweep to new level.
 # Stepsize and speed is given by (max|min)_units* settings.
 $yoko->set_level(value => 9);

 # Get current level from device cache (without sending a query to the
 # instrument):
 my $level = $yoko->cached_level();

=head1 METHODS

Used roles:

=over

=item L<Lab::Moose::Instrument::LinearStepSweep>

=back

=head2 set_level

 $yoko->set_level(value => $new_level);

Go to new level. Sweep with multiple steps if the distance between current and
new level is larger than C<max_units_per_step>.

=head2 cached_level

 my $current_level = $yoko->cached_level();

Get current value from device cache.

=head2 get_level

 my $current_level = $yoko->get_level();

Query current level.

=head2 set_voltage

 $yoko->set_voltage($value);

For XPRESS voltage sweep. Equivalent to C<< set_level(value => $value) >>.

=head2 sweep_to_level

 $yoko->sweep_to_level($value);

For XPRESS voltage sweep. Equivalent to C<set_voltage>.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by the Lab::Measurement team; in detail:

  Copyright 2017       Simon Reinhardt


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
