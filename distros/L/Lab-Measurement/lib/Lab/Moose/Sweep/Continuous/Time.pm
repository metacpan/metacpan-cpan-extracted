package Lab::Moose::Sweep::Continuous::Time;
$Lab::Moose::Sweep::Continuous::Time::VERSION = '3.682';
#ABSTRACT: Time sweep


use 5.010;
use Moose;
use Time::HiRes qw/time sleep/;
use Carp;

extends 'Lab::Moose::Sweep::Continuous';

#
# Public attributes
#

has [qw/ +instrument +points +rates/] => ( required => 0 );

has duration => ( is => 'ro', isa => 'Lab::Moose::PosNum' );

has durations => (
    is      => 'ro',
    isa     => 'ArrayRef[Lab::Moose::PosNum]',
    traits  => ['Array'],
    handles => {
        get_duration  => 'get',   shift_durations => 'shift',
        num_durations => 'count', durations_array => 'elements',
    },
    writer => '_durations'
);

# TODO: make duration optional => infinite

sub BUILD {
    my $self = shift;

    # Do not mess with intervals/durations attribute arrays. Make copies of them.
    my @intervals;
    my @durations;

    if ( defined $self->interval ) {
        if ( defined $self->intervals ) {
            croak "Use either interval or intervals attribute";
        }
        @intervals = ( $self->interval );
    }
    elsif ( defined $self->intervals ) {
        @intervals = $self->intervals_array;
    }
    else {
        # default interval
        @intervals = (0);
    }

    if ( defined $self->duration ) {
        if ( defined $self->durations ) {
            croak "Use either duration or durations attribute";
        }
        @durations = ( $self->duration );
    }
    elsif ( defined $self->durations ) {
        @durations = $self->durations_array;
    }
    else {
        croak "Missing mandatory duration or durations argument";
    }

    $self->_intervals( \@intervals );
    $self->_durations( \@durations );

    if ( $self->num_intervals < 1 ) {
        croak "need at least one interval";
    }

    if ( $self->num_intervals != $self->num_durations ) {
        croak "need same number of intervals and durations";
    }
}

sub go_to_sweep_start {
    my $self = shift;
    $self->reset_index();
}

sub start_sweep {
    my $self = shift;
    $self->_start_time( time() );
}

sub sweep_finished {
    my $self     = shift;
    my $duration = $self->get_duration(0);
    if ( not defined $duration ) {
        return 0;
    }

    my $start_time = $self->start_time;
    if ( time() - $start_time < $duration ) {
        return 0;
    }
    if ( $self->num_durations > 1 ) {
        $self->shift_intervals();
        $self->shift_durations();
        $self->reset_index();
        $self->start_sweep();
        return 0;
    }
    else {
        return 1;
    }
}

sub get_value {
    my $self = shift;
    return time();
}

__PACKAGE__->meta->make_immutable();
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Moose::Sweep::Continuous::Time - Time sweep

=head1 VERSION

version 3.682

=head1 SYNOPSIS

 use Lab::Moose;

 my $sweep = sweep(
     type => 'Continuous::Time',
     interval => 0.5, # optional, default is 0 (no delay)
     duration => 60
 );

 # Multiple segments with different intervals
 my $sweep = sweep(
     type => 'Continuous::Time',
     # 60s with 0.5s interval followed by 120s with 1s interval
     durations => [60, 120],
     intervals => [0.5, 1],
 );

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by the Lab::Measurement team; in detail:

  Copyright 2018       Simon Reinhardt


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
