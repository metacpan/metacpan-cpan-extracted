package Lab::Moose::Stabilizer;
$Lab::Moose::Stabilizer::VERSION = '3.682';
#ABSTRACT: Sensor stabilizers role

use 5.010;
use Moose::Role;
use MooseX::Params::Validate 'validated_list';
use Time::HiRes qw/time sleep/;
use Lab::Moose::Countdown;
use Lab::Moose              ();
use Statistics::Descriptive ();
use Scalar::Util 'looks_like_number';
use Carp;
use namespace::autoclean;

# inspired by old Lab::XPRESS stabilization routines


sub stabilize {
    my $self = shift;
    my (
        $setpoint, $getter, $tolerance_setpoint, $tolerance_std_dev,
        $measurement_interval, $observation_time, $max_stabilization_time,
        $verbose
        )
        = validated_list(
        \@_,
        setpoint             => { isa => 'Num' },
        getter               => { isa => 'CodeRef' },
        tolerance_setpoint   => { isa => 'Lab::Moose::PosNum' },
        tolerance_std_dev    => { isa => 'Lab::Moose::PosNum' },
        measurement_interval => { isa => 'Lab::Moose::PosNum' },
        observation_time     => { isa => 'Lab::Moose::PosNum' },
        max_stabilization_time =>
            { isa => 'Maybe[Lab::Moose::PosNum]', optional => 1 },
        verbose => { isa => 'Bool' },
        );

    my @points = ();

    my $num_points = int( $observation_time / $measurement_interval );
    if ( $num_points == 0 ) {
        $num_points = 1;
    }

    # enable autoflush
    my $autoflush  = STDOUT->autoflush();
    my $start_time = time();

    while (1) {
        my $new_value = $self->$getter();
        if ( not looks_like_number($new_value) ) {
            croak "$new_value is not a number";
        }
        push @points, $new_value;
        if ( @points > $num_points ) {
            shift @points;
        }

        if ( @points == $num_points ) {
            my $crit_stddev;
            my $crit_setpoint;

            my $stat = Statistics::Descriptive::Full->new();
            $stat->add_data(@points);

            my $std_dev = $stat->standard_deviation();
            if ( $std_dev < $tolerance_std_dev ) {
                $crit_stddev = 1;
            }

            my $median = $stat->median();
            if ( abs( $setpoint - $median ) < $tolerance_setpoint ) {
                $crit_setpoint = 1;
            }

            if ($verbose) {
                printf(
                    "Setpoint: %.6e, Value: %.6e, std_dev: %.6e, median: %.6e             ",
                    $setpoint, $new_value, $std_dev, $median
                );
            }
            if ( $crit_stddev and $crit_setpoint ) {
                printf("reached stabilization criterion      \n");
                last;
            }
            else {
                printf("\r");
            }

        }
        else {
            if ($verbose) {
                printf(
                    "Setpoint: %.6e, Value: %.6e, need more points...       \r",
                    $setpoint, $new_value
                );
            }
        }
        
        if ($measurement_interval > 5) {
            countdown($measurement_interval, "Measurement interval: Sleeping for ");
        }
        else {
            sleep ($measurement_interval);
        }

        if ( defined $max_stabilization_time ) {
            if ( time() - $start_time > $max_stabilization_time ) {
                printf(
                    "Reached maximum stabilization time                   \n"
                );
                last;
            }
        }
    }

    # reset autoflush to previous value
    STDOUT->autoflush($autoflush);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Moose::Stabilizer - Sensor stabilizers role

=head1 VERSION

version 3.682

=head1 DESCRIPTION

Helper methods for sensor (temperature, magnetic field, ...) stabilization.

=head1 METHODS

=head2 stabilize

 $self->stabilize(
     setpoint => 10,
     getter => sub { ...; return $number},
     tolerance_setpoint => 0.1,     # max. allowed median
     tolerance_std_dev => 0.1,      # max. allowed standard deviation
     measurement_interval => 2,     # time (s) between calls of getter
     observation_time => 20,        # length of window (s) for median/std_dev
     max_stabilization_time => 100, # abort stabilization after (s, optional)
     verbose => 1
 );

Call the C<getter> method repeatedly. As soon as enough points have been measured,
start calculating median and standard deviation and repeat until convergence.
All times are given in seconds. Print status messages if C<verbose> is true.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by the Lab::Measurement team; in detail:

  Copyright 2018       Andreas K. Huettel, Simon Reinhardt


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
