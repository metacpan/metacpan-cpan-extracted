package Lab::Moose::Sweep::Step::Repeat;
$Lab::Moose::Sweep::Step::Repeat::VERSION = '3.682';
#ABSTRACT: Repeat something (e.g. some sweep) N times


use 5.010;
use Moose;
use Carp;
extends 'Lab::Moose::Sweep::Step';

has filename_extension => ( is => 'ro', isa => 'Str', default => 'Repeat=' );
has count => (is => 'ro', isa => 'Lab::Moose::PosInt', required => 1);
has setter => (is => 'ro', isa => 'CodeRef', builder => '_build_setter');

sub _build_setter {
    return sub {};
}

sub BUILD {
    my $self = shift;
    my $count = $self->count;
    if ($count < 1) {
        croak "count must be a positive integer";
    }
    my @list = (1..$self->count);
    $self->_list(\@list);
}

__PACKAGE__->meta->make_immutable();
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Moose::Sweep::Step::Repeat - Repeat something (e.g. some sweep) N times

=head1 VERSION

version 3.682

=head1 SYNOPSIS

 # Repeat voltage sweep 10 times
 
 my $repeat = sweep(
     type => 'Step::Repeat',
     count => 10
 );

 my $voltage_sweep = sweep(...);
 my $meas = ...;
 my $datafile = sweep_datafile(...);
 
 $repeat->start(
     slave => $voltage_sweep,
     measurement => $meas,
     datafile => $datafile
 );

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by the Lab::Measurement team; in detail:

  Copyright 2018       Andreas K. Huettel, Simon Reinhardt


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
