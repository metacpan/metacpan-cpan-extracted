package Lab::Moose::Sweep::Continuous;
$Lab::Moose::Sweep::Continuous::VERSION = '3.682';
#ABSTRACT: Base class for continuous sweeps (time, temperature, magnetic field)


use 5.010;
use Moose;
use MooseX::Params::Validate;

# Do not import all functions as they clash with the attribute methods.
use Lab::Moose 'linspace';
use Time::HiRes qw/time sleep/;

use Carp;

extends 'Lab::Moose::Sweep';

#
# Public attributes set by the user
#

has instrument =>
    ( is => 'ro', isa => 'Lab::Moose::Instrument', required => 1 );

has from       => ( is => 'ro', isa => 'Num' );
has to         => ( is => 'ro', isa => 'Num' );
has rate       => ( is => 'ro', isa => 'Lab::Moose::PosNum' );
has start_rate => ( is => 'ro', isa => 'Lab::Moose::PosNum' );
has interval   => ( is => 'ro', isa => 'Lab::Moose::PosNum' );

has points => (
    is      => 'ro', isa => 'ArrayRef[Num]', traits => ['Array'],
    handles => {
        shift_points => 'shift', num_points => 'count',
        points_array => 'elements'
    },
    writer => '_points',
);

has intervals => (
    is      => 'ro',
    isa     => 'ArrayRef[Num]',
    traits  => ['Array'],
    handles => {
        shift_intervals => 'shift', get_interval    => 'get',
        num_intervals   => 'count', intervals_array => 'elements',
    },
    writer => '_intervals',
);

has rates => (
    is      => 'ro', isa => 'ArrayRef[Num]', traits => ['Array'],
    handles => {
        shift_rates => 'shift', num_rates => 'count',
        rates_array => 'elements'
    },
    writer => '_rates',
);

has backsweep => ( is => 'ro', isa => 'Bool', default => 0 );

#
# Private attributes used internally
#

has index => (
    is => 'ro', isa => 'Num', default => 0, init_arg => undef, default => 0,
    traits  => ['Counter'],
    handles => { inc_index => 'inc', reset_index => 'reset' }
);

has start_time =>
    ( is => 'ro', isa => 'Num', init_arg => undef, writer => '_start_time' );

# has in_backsweep => (
#     is     => 'ro', isa => 'Bool', init_arg => undef,
#     writer => '_in_backsweep'
# );

sub _validate_points_attributes {
    my $self = shift;

    my $error_str
        = "use either (points, rates, [intervals]) or (from, to, rate, [interval], [start_rate]) attributes";
    if ( defined $self->points ) {
        if ( not defined $self->rates ) {
            croak "missing 'rates' attribute";
        }

        if (   defined $self->from
            or defined $self->to
            or defined $self->rate
            or defined $self->start_rate
            or $self->interval ) {
            croak $error_str;
        }

    }
    elsif ( defined $self->from ) {
        if ( not defined $self->to ) {
            croak "missing 'to' attribute";
        }
        if ( not defined $self->rate ) {
            croak "missing 'rate' attribute";
        }
        if (   defined $self->points
            or defined $self->rates
            or defined $self->intervals ) {
            croak $error_str;
        }
    }
}

sub BUILD {
    my $self = shift;

    $self->_validate_points_attributes();

    # Time subclass uses neither points/rates nor from/to
    if ( not defined $self->points and not defined $self->from ) {
        return;
    }

    my @points;
    my @rates;
    my @intervals;

    if ( defined $self->points ) {
        my $num_points = $self->num_points;
        my $num_rates  = $self->num_rates;
        my $num_intervals;
        @points = $self->points_array;
        @rates  = $self->rates_array;

        if ( $num_points < 2 ) {
            croak "need at least two points";
        }

        if ( $num_rates > $num_points ) {
            croak "rates array exceeds points array";
        }
        if ( $num_rates < 1 ) {
            croak "need at least one element in rates array";
        }
        if ( $num_rates < $num_points ) {
            push @rates, map { $rates[-1] } ( 1 .. $num_points - $num_rates );
        }

        if ( not defined $self->intervals ) {
            @intervals = map {0} ( 1 .. $num_points - 1 );
        }
        else {
            @intervals     = $self->intervals_array;
            $num_intervals = $self->num_intervals;
            if ( $num_intervals > $num_points - 1 ) {
                croak "intervals array exceeds points array";
            }
            if ( $num_intervals < 1 ) {
                croak "need at least one element in intervals array";
            }
            if ( $num_intervals < $num_points - 1 ) {
                push @intervals,
                    map { $intervals[-1] }
                    ( 1 .. $num_points - 1 - $num_intervals );
            }
        }

    }
    elsif ( defined $self->from ) {
        @points = ( $self->from, $self->to );
        my $rate       = $self->rate;
        my $start_rate = $self->start_rate;

        if ( not defined $self->start_rate ) {
            $start_rate = $rate;
        }

        @rates = ( $start_rate, $rate );

        my $interval = $self->interval;

        if ( not defined $self->interval ) {
            $interval = 0;
        }
        @intervals = ($interval);
    }

    if ( $self->backsweep ) {
        my @bs_points = @points;

        # Do not perform sweep of zero length in the middle
        pop @bs_points;
        push @points, reverse @bs_points;

        my @bs_rates = @rates;

        # Do not need start rate
        shift @bs_rates;
        push @rates, reverse @bs_rates;

        push @intervals, reverse @intervals;
    }

    $self->_points( \@points );
    $self->_rates( \@rates );
    $self->_intervals( \@intervals );

}

sub go_to_next_point {
    my $self  = shift;
    my $index = $self->index;
    if ( $self->num_intervals < 1 ) {
        croak "num_intervals error";
    }
    my $interval = $self->get_interval(0);
    if ( $index == 0 or $interval == 0 ) {

        # first point is special
        # don't have to sleep until the level is reached
    }
    else {
        my $t           = time();
        my $target_time = $self->start_time + $index * $interval;
        if ( $t < $target_time ) {
            sleep( $target_time - $t );
        }
        else {
            my $prev_target_time
                = $self->start_time + ( $index - 1 ) * $interval;
            my $required = $t - $prev_target_time;
            carp <<"EOF";
WARNING: Measurement function takes too much time:
required time: $required
interval: $interval
EOF
        }

    }
    $self->inc_index();
}

sub go_to_sweep_start {
    my $self = shift;
    $self->reset_index();
    my $point = $self->shift_points();
    my $rate  = $self->shift_rates();
    carp <<"EOF";
Going to sweep start:
Setpoint: $point
Rate: $rate
EOF
    my $instrument = $self->instrument();
    $instrument->config_sweep(
        point => $point,
        rate  => $rate
    );
    $instrument->trg();
    $instrument->wait();
}

sub start_sweep {
    my $self       = shift;
    my $instrument = $self->instrument();
    my $to         = $self->shift_points();
    my $rate       = $self->shift_rates();
    carp <<"EOF";
Starting sweep
Setpoint: $to
Rate: $rate
EOF
    $instrument->config_sweep(
        point => $to,
        rate  => $rate,
    );
    $instrument->trg();
    $self->_start_time( time() );
    $self->reset_index();
}

sub sweep_finished {
    my $self = shift;
    if ( $self->instrument->active() ) {
        return 0;
    }

    # finished one segment of the sweep

    if ( $self->num_points > 0 ) {

        # continue with next point
        $self->start_sweep();
        $self->shift_intervals();
        return 0;
    }
    else {
        # finished all points!
        return 1;
    }
}

# implement get_value in subclasses.

__PACKAGE__->meta->make_immutable();
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Moose::Sweep::Continuous - Base class for continuous sweeps (time, temperature, magnetic field)

=head1 VERSION

version 3.682

=head1 SYNOPSIS

 use Lab::Moose;

 #
 # 1D sweep of magnetic field
 #
 
 my $ips = instrument(
     type => 'OI_Mercury::Magnet'
     connection_type => ...,
     connection_options => {...}
 );

 my $multimeter = instrument(...);
 
 my $sweep = sweep(
     type => 'Continuous::Magnet',
     instrument => $ips,
     from => -1, # Tesla
     to => 1,
     rate => 0.1, (Tesla/min, always positive)
     start_rate => 1, (optional) rate to approach start point
     interval => 0.5, # one measurement every 0.5 seconds
 );


 # alternative: points/rates
 # my $sweep = sweep(
 #     type => 'Continuous::Magnet',
 #     instrument => $ips,
 #     points => [-1, -0.1, 0.1, 1],
 #     # start rate: 1
 #     # use slow rate 0.01 between points -0.1 and 0.1
 #     rates => [1, 0.1, 0.01, 0.1], 
 #     intervals => [0.5], # one measurement every 0.5 seconds
 # );
 

 my $datafile = sweep_datafile(columns => ['B-field', 'current']);
 $datafile->add_plot(x => 'B-field', y => 'current');
 
 my $meas = sub {
     my $sweep = shift;
     my $field = $ips->get_field();
     my $current = $multimeter->get_value();
     $sweep->log('B-field' => $field, current => $current);
 };

 $sweep->start(
     datafiles => [$datafile],
     measurement => $meas,
 );

=head1 DESCRIPTION

Continuous sweep constructure. The sweep can be configured with either

=over

=item * from/to

=item * rate

=item * interval (default: 0)

=back

or by providing the arrayrefs

=over

=item * points

=item * rates

=item * intervals (default: [0])

=item

=back

If an interval is C<0>, do as much measurements as possible.
Otherwise, warn if measurement requires more time than C<interval>.

Do backsweep if C<backsweep> attribute is set to 1.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by the Lab::Measurement team; in detail:

  Copyright 2018       Simon Reinhardt


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
