package Lab::Moose::Sweep::Continuous::Time;
$Lab::Moose::Sweep::Continuous::Time::VERSION = '3.651';
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

#has interval => ( is => 'ro', isa => 'Num', default => 0 );
has durations => (
    is      => 'ro',
    isa     => 'ArrayRef[Lab::Moose::PosNum]',
    traits  => ['Array'],
    handles => {
        get_duration  => 'get', shift_durations => 'shift',
        num_durations => 'count'
    },
    required => 1
);

# FIXME: make copy of original arrays.
# TODO: interval/duration scalars
# TODO: make duration optional => infinite
# use go_to_next_point from Continuous.pm

sub BUILD {
    my $self = shift;
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

version 3.651

=head1 SYNOPSIS

 use Lab::Moose;

 my $sweep = sweep(
     type => 'Continuous::Time',
     interval => 0.5,
     duration => 60
 );

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by the Lab::Measurement team; in detail:

  Copyright 2018       Simon Reinhardt


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
