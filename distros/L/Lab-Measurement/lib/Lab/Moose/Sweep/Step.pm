package Lab::Moose::Sweep::Step;
$Lab::Moose::Sweep::Step::VERSION = '3.682';
#ABSTRACT: Base class for step/list sweeps


use 5.010;
use Moose;
use Moose::Util::TypeConstraints 'enum';
use MooseX::Params::Validate;
use Data::Dumper;

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

has points =>
    ( is => 'ro', isa => 'ArrayRef[Num]', predicate => 'has_points' );
has steps => ( is => 'ro', isa => 'ArrayRef[Num]', predicate => 'has_steps' );

has list => (
    is     => 'ro', isa => 'ArrayRef[Num]', predicate => 'has_list',
    writer => '_list'
);
has backsweep => ( is => 'ro', isa => 'Bool', default => 0 );

has setter => ( is => 'ro', isa => 'CodeRef', required => 1 );

#
# Private attributes used internally
#

has _points => (
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
or (points => [...], steps => [....])
or (points => [...], step => )

EOF

sub _build_points {
    my $self = shift;
    my $has_from_to_step
        = $self->has_from && $self->has_to && $self->has_step;
    my $has_list         = $self->has_list;
    my $has_points_steps = $self->has_points && $self->has_steps;
    my $has_points_step  = $self->has_points && $self->has_step;
    if ( $has_from_to_step + $has_list + $has_points_steps + $has_points_step
        != 1 ) {
        croak $error_msg;
    }

    my @points;

    if ($has_list) {
        @points = @{ $self->list() };
        if ( @points < 1 ) {
            croak "list needs at least 1 point";
        }
    }
    elsif ($has_from_to_step) {
        @points = linspace(
            from => $self->from,
            to   => $self->to,
            step => $self->step
        );
    }
    else {
        # points_steps or points_step
        my @steps;
        my @corner_points = @{ $self->points };
        if ( @corner_points < 2 ) {
            croak "points array needs at least two elements";
        }

        if ($has_points_steps) {
            @steps = @{ $self->steps };
        }
        else {
            @steps = ( $self->step );
        }
        if ( @steps >= @corner_points ) {
            croak "steps array exceeds points array";
        }
        push @steps, map { $steps[-1] } ( 1 .. @corner_points - @steps - 1 );
        my ( $p1, $p2 );
        $p1 = shift @corner_points;
        while (@corner_points) {
            my $p2   = shift @corner_points;
            my $step = shift @steps;
            push @points, linspace( from => $p1, to => $p2, step => $step );
            $p1 = $p2;
        }
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

version 3.682

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

=item * points/steps

alternative to from/to/step. Lets define multiple segments with different steps, e.g.

 points => [0,1,2],
 steps => [0.5, 0.2],

is equivalent to

 list => [0, 0.5, 1, 1, 1.2, 1.4, 1.6, 1.8, 2]

If C<steps> has fewer elements than segments provided in C<points>, reuse the last value in C<steps>.

=item * points/step

 points => [...],
 step => $x, # equivalent to steps => [$x]

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

This software is copyright (c) 2019 by the Lab::Measurement team; in detail:

  Copyright 2017-2018  Simon Reinhardt


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
