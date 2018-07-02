package Lab::Moose::Sweep::Step;
$Lab::Moose::Sweep::Step::VERSION = '3.653';
#ABSTRACT: Base class for step/list sweeps


use 5.010;
use Moose;
use Moose::Util::TypeConstraints 'enum';
use MooseX::Params::Validate;

# Do not import all functions as they clash with the attribute methods.
use Lab::Moose 'linspace';

use Carp;

extends 'Lab::Moose::Sweep';

#
# Public attributes set by the user
#

has from => ( is => 'ro', isa => 'Num', predicate => 'has_from' );
has to   => ( is => 'ro', isa => 'Num', predicate => 'has_to' );
has step =>
    ( is => 'ro', isa => 'Lab::Moose::PosNum', predicate => 'has_step' );

has list => (
    is     => 'ro', isa => 'ArrayRef[Num]', predicate => 'has_list',
    writer => '_list'
);
has backsweep => ( is => 'ro', isa => 'Bool', default => 0 );

has setter => ( is => 'ro', isa => 'CodeRef', required => 1 );

#
# Private attributes used internally
#

has points => (
    is => 'ro', isa => 'ArrayRef[Num]', lazy => 1, init_arg => undef,
    builder => '_build_points', traits => ['Array'],
    handles => { get_point => 'get', num_points => 'count' },
);

has index => (
    is     => 'ro', isa => 'Int', default => 0, init_arg => undef,
    writer => '_index'
);

has current_value => (
    is     => 'ro', isa => 'Num', init_arg => undef,
    writer => '_current_value'
);

my $error_msg = <<"EOF";
give either (from => ..., to => ..., step => ...)
or (list => [...])
EOF

sub _build_points {
    my $self = shift;
    my $has_from_to_step
        = $self->has_from
        and $self->has_to
        and $self->has_step;
    my $has_list = $self->has_list;
    if ( $has_from_to_step and $has_list ) {
        croak $error_msg;
    }
    if ( not $has_list and not $has_from_to_step ) {
        croak $error_msg;
    }

    my @points;

    if ($has_list) {
        @points = @{ $self->list() };
        if ( @points < 1 ) {
            croak "list needs at least 1 point";
        }
    }
    else {
        @points = linspace(
            from => $self->from,
            to   => $self->to,
            step => $self->step
        );
    }

    if ( $self->backsweep ) {
        my @backsweep_points = reverse @points;
        push @points, @backsweep_points;
    }

    return \@points;
}

sub start_sweep {

    # do nothing
}

sub go_to_next_point {
    my $self   = shift;
    my $index  = $self->index();
    my $point  = $self->get_point($index);
    my $setter = $self->setter();
    $self->$setter($point);
    $self->_current_value($point);
    $self->_index( ++$index );
}

sub go_to_sweep_start {
    my $self   = shift;
    my $point  = $self->get_point(0);
    my $setter = $self->setter();
    $self->$setter($point);
    $self->_current_value($point);
    $self->_index(0);
}

sub sweep_finished {
    my $self  = shift;
    my $index = $self->index();
    if ( $index >= $self->num_points ) {
        return 1;
    }
    return 0;
}

sub _in_backsweep {
    my $self = shift;
    if ( $self->backsweep ) {
        if ( $self->index > $self->num_points / 2 ) {
            return 1;
        }
    }
    else {
        return 0;
    }
}

sub get_value {
    my $self = shift;
    if ( not defined $self->current_value() ) {
        croak "sweep not yet started";
    }
    my $value = sprintf( "%.14g", $self->current_value );
    if ( $self->_in_backsweep ) {
        $value .= '_backsweep';
    }
    return $value;
}

__PACKAGE__->meta->make_immutable();
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Moose::Sweep::Step - Base class for step/list sweeps

=head1 VERSION

version 3.653

=head1 SYNOPSIS

 use Lab::Moose;

 #
 # basic 1D sweep (e.g. IV curve)
 #
 
 my $source = instrument(
     type => ...,
     connection_type => ...,
     connection_options => {...}
 );
 my $multimeter = instrument(...);
 
 my $sweep = sweep(
     type => 'Step::Voltage',
     instrument => $instrument,
     from => -1,
     to => 1,
     step => 0.1,
     backsweep => 1, # points: -1, -0.9, ..., 0.9, 1, 0.9, ..., -1
 );

 my $datafile = sweep_datafile(columns => ['volt', 'current']);
 $datafile->add_plot(x => 'volt', y => 'current');
 
 my $meas = sub {
     my $sweep = shift;
     my $volt = $source->cached_level();
     my $current = $multimeter->get_value();
     $sweep->log(volt => $volt, current => $current);
 };

 $sweep->start(
     datafiles => [$datafile],
     measurement => $meas,
 );

 #
 # 2D sweep (quantum dot stability diagram)
 #
 
 my $gate = instrument(...);
 my $bias = instrument(...);
 my $multimeter = instrument(...);

 # master sweep
 my $gate_sweep = sweep(
     type => 'Step::Voltage',
     instrument => $gate,
     from => -5,
     to => 5,
     step => 0.01
 );

 # slave sweep
 my $bias_sweep = sweep(
     type => 'Step::Voltage',
     instrument => $bias,
     from => -1,
     to => 1,
     step => 0.01
 );

 my $datafile = sweep_datafile(columns => [qw/gate bias current/]);
 $datafile->add_plot(
     type => 'pm3d',
     x => 'gate',
     y => 'bias',
     z => 'current'
 );
 
 my $meas = sub {
     my $sweep = shift;
     my $gate_v = $gate->cached_level();
     my $bias_v = $bias->cached_level();
     my $current = $multimeter->get_value();
     $sweep->log(gate => $gate_v, bias => $bias_v, current => $current);
 };

 $gate_sweep->start(
     slaves => [$bias_sweep],
     datafiles => [$datafile],
     measurement => $meas
 );

=head1 DESCRIPTION

This C<sweep> constructor defines the following arguments

=over

=item * from/to/step

define a linear range of points.

=item * list

alternative to from/to/step, give an arbitrary arrayref of points.

=item * backsweep

Include a backsweep: After finishing the sweep, go through all points in
reverse.

=item * setter

A coderef which will be called to change the source level.
Use this if you do some arcane type of sweep which does not justify its own
sweep subclass.
Sweep subclasses like L<Lab::Moose::Sweep::Step::Voltage> will
define defaults for this. E.g. for the Voltage sweep:

 sub {
     my $sweep = shift;
     my $value = shift;
     $sweep->instrument->set_level(value => $value);
 };

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by the Lab::Measurement team; in detail:

  Copyright 2017-2018  Simon Reinhardt


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
