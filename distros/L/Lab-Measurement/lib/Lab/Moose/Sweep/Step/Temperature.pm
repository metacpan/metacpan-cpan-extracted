package Lab::Moose::Sweep::Step::Temperature;
$Lab::Moose::Sweep::Step::Temperature::VERSION = '3.682';
#ABSTRACT: Step/list sweep of temperature


use 5.010;
use Moose;

extends 'Lab::Moose::Sweep::Step';

with 'Lab::Moose::Stabilizer';

has instrument =>
    ( is => 'ro', isa => 'Lab::Moose::Instrument', required => 1 );

has filename_extension => ( is => 'ro', isa => 'Str', default => 'T=' );

has setter => ( is => 'ro', isa => 'CodeRef', builder => '_build_setter' );
has tolerance_setpoint   => ( is => 'ro', isa => 'Num', default => 0.2 );
has tolerance_std_dev    => ( is => 'ro', isa => 'Num', default => 0.15 );
has observation_time     => ( is => 'ro', isa => 'Num', default => 3 * 60 );
has measurement_interval => ( is => 'ro', isa => 'Num', default => 1 );
has max_stabilization_time => ( is => 'ro', isa => 'Maybe[Num]' );

sub _build_setter {
    return \&_temp_setter;
}

sub _getter {
    my $self = shift;
    return $self->instrument()->get_T();
}

sub _temp_setter {
    my $self  = shift;
    my $value = shift;
    $self->instrument->set_T( value => $value );
    $self->stabilize(
        setpoint               => $value,
        getter                 => \&_getter,
        tolerance_setpoint     => $self->tolerance_setpoint,
        tolerance_std_dev      => $self->tolerance_std_dev,
        measurement_interval   => $self->measurement_interval,
        observation_time       => $self->observation_time,
        max_stabilization_time => $self->max_stabilization_time,
        verbose                => 1,
    );

}

__PACKAGE__->meta->make_immutable();
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Moose::Sweep::Step::Temperature - Step/list sweep of temperature

=head1 VERSION

version 3.682

=head1 SYNOPSIS

 my $sweep = sweep(
     type => 'Step::Temperature',
     instrument => $oi_triton,
     from => 0.010, # K
     to => 0.5,
     step => 0.05, # K

     # stabilizer options (details in Lab::Moose::Stabilizer)
     tolerance_setpoint => 0.01,
     tolerance_std_dev => 0.01,
     measurement_interval => 1,
     observation_time => 10,
     ...
 );

=head1 Description

Step sweep of temperature. 

Set the temperature with instrument's C<set_T> method; use 
L<Lab::Moose::Stabilizer> to wait until temperature has converged to the
setpoint.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by the Lab::Measurement team; in detail:

  Copyright 2018       Andreas K. Huettel, Simon Reinhardt


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
