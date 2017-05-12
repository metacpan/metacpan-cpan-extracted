package Karel::Robot::WithGrid;

=head1 NAME

Karel::Robot::WithGrid

=head1 DESCRIPTION

A robot with an associated grid. To create the robot, use

    my $robot = 'Karel::Robot'->new;
    my $grid  = 'Karel::Grid'->new(x => 10, y => 12);
    $robot = $robot->set_grid($grid, 1, 1);

=head1 METHODS

=over 4

=cut

use warnings;
use strict;
use parent 'Karel::Robot';
use Karel::Util qw{ positive_int };
use Carp;
use List::Util qw{ first };
use Clone qw{ clone };
use constant {
    CONTINUE         => 0,
    FINISHED         => 1,
    FINISHED_DELAYED => 2,
    QUIT             => -1,
};
use Moo::Role;
requires qw{ set_grid knows };

=item $robot->x, $robot->y

    my ($x, $y) = map $robot->$_, qw( x y );

Coordinates of the robot in its grid.

=cut

has [qw[ x y ]] => ( is  => 'rwp',
                     isa => \&positive_int,
                   );

=item $robot->grid

    my $grid = $robot->grid;

The associated C<Karel::Grid> object.

=cut

my $grid_type = sub {
    my ($grid) = @_;
    eval { $grid->isa('Karel::Grid') } or croak "Invalid grid type\n";
};


has grid => ( is  => 'rwp',
              isa => $grid_type,
            );

=item $robot->set_grid($grid, $x, $y, $direction);

Initialize the grid. Grid must be an object of the C<Karel::Grid>
type, C<$x> and C<$y> are coordinates of the robot, C<$direction> is
one of C<N E S W> (defaults to C<N>). Dies if the robot's place is
occupied by a wall.

=cut

around set_grid => sub {
    my (undef, $self, $grid, $x, $y, $direction) = @_;
    $self->_set_grid($grid);
    $self->_set_x($x);
    $self->_set_y($y);
    $self->_set_direction($direction) if $direction;
};

=item $robot->drop_mark

Drop mark in the current location. Dies if there are already 9 marks.

=cut

sub drop_mark {
    my ($self) = shift;
    $self->grid->drop_mark($self->coords);
    return 1
}

=item $robot->pick_mark

Picks up one mark from the current location. Dies if there's nothing
to pick.

=cut

sub pick_mark {
    my ($self) = shift;
    $self->grid->pick_mark($self->coords);
    return 1
}

=item $robot->direction

  my $direction = $robot->direction;

Returns the robot's direction: one of C<qw( N W S E )>.

=cut

my $string_list = sub {
    do {
        my %strings = map { $_ => 1 } @_;
        sub { $strings{+shift} or croak "Invalid string" }
    }
};

has direction => ( is      => 'rwp',
                   isa     => $string_list->(qw( N W S E )),
                   default => 'N',
                 );

=item $robot->left

Turn the robot to the left.

=cut

my @directions = qw( N W S E );
sub left {
    my ($self) = @_;
    my $dir = $self->direction;
    my $idx = first { $directions[$_] eq $dir } 0 .. $#directions;
    $self->_set_direction($directions[ ($idx + 1) % @directions ]);
    return FINISHED
}

=item $robot->coords

Returns the robot's coordinates, i.e. C<x> and C<y>.

=cut

sub coords {
    my ($self) = @_;
    return ($self->x, $self->y)
}

=item $robot->cover

Returns the grid element at the robot's coordinates, i.e.

  $r->grid->at($r->coords)

=cut

sub cover {
    my ($self) = @_;
    return $self->grid->at($self->coords)
}

=item $robot->facing_coords

Returns the coordinates of the grid element the robot is facing.

=cut

my %facing = ( N => [0, -1],
               E => [1, 0],
               S => [0, 1],
               W => [-1, 0]
             );

sub facing_coords {
    my ($self) = @_;
    my $direction = $self->direction;
    my @coords = $self->coords;
    $coords[$_] += $facing{$direction}[$_] for 0, 1;
    return @coords
}

=item $robot->facing

Returns the contents of the grid element the robot is facing.

=cut

sub facing {
    my ($self) = @_;
    $self->grid->at($self->facing_coords)
}


has _stack => ( is        => 'rwp',
                predicate => 'is_running',
                clearer   => 'not_running',
                isa       => sub {
                    my $s = shift;
                    'ARRAY' eq ref $s or croak "Invalid stack";
                    ! grep 'ARRAY' ne ref $_, @$s
                        or croak "Invalid stack element";
                }
              );

sub _pop_stack {
    my $self = shift;
    shift @{ $self->_stack };
    $self->not_running unless @{ $self->_stack };
}

sub _push_stack {
    my ($self, $commands, $current) = @_;
    $current = $self->_stack->[1][-1]
        unless $current;
    unshift @{ $self->_stack }, [ clone($commands), 0, $current ];
}


sub _stacked { shift->_stack->[0] }

sub _stack_command {
    my $self = shift;
    my ($commands, $index) = @{ $self->_stacked };
    return $commands->[$index]
}

sub _stack_previous_commands {
    shift->_stack->[1][0]
}

sub _stack_previous_index {
    shift->_stack->[1][1]
}

sub _stack_delay_finish {
    my ($self) = @_;
    $self->_stack_previous_commands
        ->[ $self->_stack_previous_index ][0] = 'x';
}

=item $robot->current

For debugging Karel programs: returns the source of the currently
executed command, current position in the source and the length of the
command.

=cut

sub current {
    my ($self) = @_;
    my $command = (first { 'x' ne $_->[0][0][0] } @{ $self->_stack })
               // $self->_stacked;
    my $current = $command->[-1];
    my ($from, $length) = @{ $command->[0][ $command->[-2] ][-1] };
    my $known = $self->knowledge->{ $current // q() };
    my $src = ref $current ? $current->[0] : $known->[1];
    return $src, $from, $length
}

sub _run {
    my ($self, $prog, $current) = @_;
    $self->_set__stack([ [ $prog, 0, $current ] ]);
}

=item $robot->run($command_name)

Run the given command.

=cut

sub run {
    my ($self, $command) = @_;
    my $parsed = $self->parser->parse("run $command");
    $self->_run($$parsed, [$command]);
}

=item $robot->forward

Moves the robot one cell forward in its direction.

=cut

sub forward {
    my ($self) = @_;
    croak "Can't walk through walls" if $self->facing =~ /w/i;
    my ($x, $y) = $self->facing_coords;
    $self->_set_x($x);
    $self->_set_y($y);
    return FINISHED
}

=item $robot->repeat($count, $commands)

Runs the C<repeat> command: decreases the counter, and if it's
non-zero, pushes the body to the stack. Returns 0 (CONTINUE) when it
should stay in the stack, 1 (FINISHED) otherwise.

=cut

sub repeat {
    my ($self, $count, $commands) = @_;
    if ($count) {
        $self->_stack_command->[1] = $count - 1;
        $self->_push_stack($commands);#, $self->_stack->[1][-1]);
        return CONTINUE

    } else {
        return FINISHED
    }
}

=item $isnot_south = $robot->condition('!S')

Solve the given condition. Supported parameters are:

=over 4

=item * N E S W

Facing North, East, South, West

=item * m

Covering mark(s).

=item * w

Facing a wall.

=item * !

Negates the condition.

=back

Returns true or false, dies on invalid condition.

=cut

sub condition {
    my ($self, $condition) = @_;
    my $negation = $condition =~ s/!//;
    my $result;

    if ($condition =~ /^[NESW]$/) {
        $result = $self->direction eq $condition;

    } elsif ($condition eq 'w') {
        $result = $self->facing =~ /w/i;

    } elsif ($condition eq 'm') {
        $result = $self->cover =~ /^[1-9]$/;

    } else {
        croak "Invalid condition '$condition'"
    }

    $result = ! $result if $negation;
    return $result
}

=item $robot->If($condition, $commands, $else)

If $condition is true, puts $commands to the stack, otherwise puts
$else to the stack. Returns 2 (FINISH_DELAYED) in the former case, 1
(FINISHED) in the latter one.

=cut

sub If {
    my ($self, $condition, $commands, $else) = @_;
    if ($self->condition($condition)) {
        $self->_push_stack($commands);
    } elsif ($else) {
        $self->_push_stack($else);
    } else {
        return FINISHED
    }
    return FINISHED_DELAYED
}

=item $robot->While($condition, $commands)

Similar to C<If>, but returns 0 (CONTINUE) if the condition is true,
i.e. it stays in the stack.

=cut

sub While {
    my ($self, $condition, $commands) = @_;
    if ($self->condition($condition)) {
        $self->_push_stack($commands);
        return CONTINUE

    } else {
        return FINISHED
    }
}

=item $robot->call($command)

Checks whether the robot knows the command, and if so, pushes its
definition to the stack. Dies otherwise. Returns 2 (FINISH_DELAYED).

=cut

sub call {
    my ($self, $command_name) = @_;
    my $commands = $self->knows($command_name);
    if ($commands) {
        $self->_push_stack($commands, $command_name);
    } else {
        croak "Unknown command $command_name.";
    }
    return FINISHED_DELAYED
}

=item $robot->stop

Stops execution of the current program and clears the stack. Returns
-1 (QUIT).

=cut

sub stop { shift->not_running; QUIT }

=item $robot->step

Makes one step in the currently running program.

=cut

sub step {
    my ($self) = @_;
    croak 'Not running!' unless $self->is_running;

    my ($commands, $index) = @{ $self->_stacked };

    my $command;
    $command = defined $index ? $commands->[$index] : ['x'];
    my $action = { f   => 'forward',
                   l   => 'left',
                   p   => 'pick_mark',
                   d   => 'drop_mark',
                   r   => 'repeat',
                   i   => 'If',
                   w   => 'While',
                   q   => 'stop',
                   c   => 'call',
                   x   => sub { FINISHED },
                 }->{ $command->[0] };
    croak "Unknown action " . $command->[0] unless $action;

    my $finished = $self->$action(@{ $command }[ 1 .. $#$command ]);
    # warn "$command->[0], $finished.\n";
    # use Data::Dump; warn Data::Dump::dump($self->_stack);

    { FINISHED, sub {
          if (++$index > $#$commands) {
              $self->_pop_stack;

          } else {
              $self->_stacked->[1] = $index;
          }
      },
      CONTINUE, sub { @_ = ($self); goto &step },
      FINISHED_DELAYED, sub { $self->_stack_delay_finish },
      QUIT, sub { },
    }->{$finished}->();
}

=back

=head1 RETURN VALUES

There are three special return values corresponding to the stack handling:

 0 CONTINUE
 1 FINISHED
 2 FINISHED_DELAYED

If a command returns C<CONTINUE>, the stack doesn't change. If it
returns C<FINISHED>, the following command in the stack is executed.
If it returns C<FINISHED_DELAYED>, new commands are put in the stack,
but once they're finished, the command behaves as if finished, too.

=cut

__PACKAGE__
