package Lab::Moose::Sweep::Continuous::Time;
$Lab::Moose::Sweep::Continuous::Time::VERSION = '3.621';
#ABSTRACT: Time sweep


use 5.010;
use Moose;
use Time::HiRes qw/time sleep/;

extends 'Lab::Moose::Sweep::Continuous';

#
# Public attributes
#

has [qw/+from +to +rate +instrument/] => ( required => 0 );
has interval => ( is => 'ro', isa => 'Num', default => 0 );
has duration => ( is => 'ro', isa => 'Num' );

# use go_to_next_point from parent

sub go_to_sweep_start {
    my $self = shift;
    $self->_index(0);
}

sub start_sweep {
    my $self = shift;
    $self->_start_time( time() );
}

sub sweep_finished {
    my $self     = shift;
    my $duration = $self->duration;
    if ( defined $duration ) {
        my $start_time = $self->start_time;
        if ( time() - $start_time > $duration ) {
            return 1;
        }
    }
    return 0;
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

version 3.621

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
