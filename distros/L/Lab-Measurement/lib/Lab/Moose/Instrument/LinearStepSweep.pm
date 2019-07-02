package Lab::Moose::Instrument::LinearStepSweep;
$Lab::Moose::Instrument::LinearStepSweep::VERSION = '3.682';
#ABSTRACT: Role for linear step sweeps used by voltage/current sources.
use 5.010;
use Moose::Role;
use MooseX::Params::Validate;
use Lab::Moose::Instrument 'setter_params';

# time() returns floating seconds.
use Time::HiRes qw/time usleep/;
use Lab::Moose 'linspace';
use Carp;

requires qw/max_units_per_second max_units_per_step min_units max_units
    source_level cached_source_level source_level_timestamp/;


# Enforce max_units/min_units.
sub check_max_and_min {
    my $self = shift;
    my $to   = shift;

    my $min = $self->min_units();
    my $max = $self->max_units();
    if ( $to < $min ) {
        croak "target $to is below minimum allowed value $min";
    }
    elsif ( $to > $max ) {
        croak "target $to is above maximum allowed value $max";
    }
}

sub linear_step_sweep {
    my ( $self, %args ) = validated_hash(
        \@_,
        to      => { isa => 'Num' },
        verbose => { isa => 'Bool', default => 1 },
        setter_params(),
    );
    my $to             = delete $args{to};
    my $verbose        = delete $args{verbose};
    my $from           = $self->cached_source_level();
    my $last_timestamp = $self->source_level_timestamp();
    my $distance       = abs( $to - $from );

    $self->check_max_and_min($to);

    if ( not defined $last_timestamp ) {
        $last_timestamp = time();
    }

    # Enforce step size and rate.
    my $step = abs( $self->max_units_per_step() );

    my $rate = abs( $self->max_units_per_second() );
    if ( $step < 1e-9 ) {
        croak "step size must be > 0";
    }

    if ( $rate < 1e-9 ) {
        croak "rate must be > 0";
    }

    my @steps = linspace(
        from         => $from, to => $to, step => $step,
        exclude_from => 1
    );

    my $time_per_step;
    if ( $distance < $step ) {
        $time_per_step = $distance / $rate;
    }
    else {
        $time_per_step = $step / $rate;
    }

    my $time = time();

    if ( $time < $last_timestamp ) {

        # should never happen
        croak "time error";
    }

    # Do we have to wait to enforce the maximum rate or can we start right now?
    my $waiting_time = $time_per_step - ( $time - $last_timestamp );
    if ( $waiting_time > 0 ) {
        usleep( 1e6 * $waiting_time );
    }
    $self->source_level( value => shift @steps, %args );

    # enable autoflush
    my $autoflush = STDOUT->autoflush();
    for my $step (@steps) {
        usleep( 1e6 * $time_per_step );

        #  YokogawaGS200 has 5 + 1/2 digits precision
        if ($verbose) {
            printf(
                "Sweeping to %.5g: Setting level to %.5e          \r", $to,
                $step
            );
        }
        $self->source_level( value => $step, %args );
    }
    if ($verbose) {
        print " " x 70 . "\r";
    }

    # reset autoflush to previous value
    STDOUT->autoflush($autoflush);
    $self->source_level_timestamp( time() );
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Moose::Instrument::LinearStepSweep - Role for linear step sweeps used by voltage/current sources.

=head1 VERSION

version 3.682

=head1 METHODS

=head2 linear_step_sweep

 $source->linear_step_sweep(
     to => $new_level,
     timeout => $timeout # optional
 );

=head1 REQUIRED METHODS

The following methods are required for role consumption:
C<max_units_per_second, max_units_per_step, min_units, max_units,
source_level, cached_source_level, source_level_timestamp > 

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by the Lab::Measurement team; in detail:

  Copyright 2017-2018  Simon Reinhardt


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
