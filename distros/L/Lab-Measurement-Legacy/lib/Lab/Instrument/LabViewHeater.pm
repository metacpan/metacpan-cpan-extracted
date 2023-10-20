package Lab::Instrument::LabViewHeater;
#ABSTRACT: ?????
$Lab::Instrument::LabViewHeater::VERSION = '3.899';
use v5.20;

use strict;
use warnings;
use Lab::Instrument;
use IO::File;
use Time::HiRes qw/usleep/;
use Time::HiRes qw/sleep/;

our @ISA = ("Lab::Instrument");

our %fields = ( supported_connections => ['Socket'], );

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self  = $class->SUPER::new(@_);
    $self->${ \( __PACKAGE__ . '::_construct' ) }(__PACKAGE__);

    return $self;
}

sub set_T {
    my $self    = shift;
    my $set_T   = shift;
    my $command = sprintf( "SET_T %f", $set_T );
    my $result  = $self->query($command);
    return $result;
}

sub get_T0 {
    my $self   = shift;
    my $result = $self->query("GET_T0");
    return $result;
}

sub get_T {
    my $self   = shift;
    my $result = $self->query("GET_T");
    return $result;
}

sub get_mean_T {
    my $self   = shift;
    my $result = $self->query("GET_MEAN_T");
    return $result;
}

sub get_sigma_T {
    my $self   = shift;
    my $result = $self->query("GET_SIGMA_T");
    return $result;
}

sub get_max_dT {
    my $self   = shift;
    my $result = $self->query("GET_MAX_dT");
    return $result;
}

# returns two boolean bits: first bit is SETPOINT_REMOTE, second bit is PID_ON
sub get_mode {
    my $self   = shift;
    my $result = $self->query("GET_MODE");
    return $result;
}

sub set_mode {
    my $self   = shift;
    my $remote = shift;
    my $pid    = shift;
    my $result = $self->query("SET_MODE $remote,$pid");
    return $result;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Instrument::LabViewHeater - ????? (deprecated)

=head1 VERSION

version 3.899

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by the Lab::Measurement team; in detail:

  Copyright 2012       David Kalok
            2016       Simon Reinhardt
            2017       Andreas K. Huettel
            2020       Andreas K. Huettel


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
