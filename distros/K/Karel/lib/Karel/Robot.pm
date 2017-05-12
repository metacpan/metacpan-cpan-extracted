package Karel::Robot;

=head1 NAME

Karel::Robot

=head1 DESCRIPTION

Basic robot class. It represents a robot wihtout a grid.

=head1 METHODS

=over 4

=cut

use warnings;
use strict;

use Karel::Grid;
use Karel::Parser;
use Carp;
use Module::Load qw{ load };
use Moo;
use Syntax::Construct qw{ // };
use namespace::clean;

=item my $robot = 'Karel::Robot'->new

The constructor. It can take one parameter: C<parser>. Its value
should be a parser object, by default an instance of C<Karel::Parser>.

=item $robot->set_grid($grid, $x, $y, $direction)

Applies the L<Karel::Robot::WithGrid> role to the $robot. C<$grid>
must be a C<Karel::Grid> instance, $x and $y denote the position of
the robot in the grid. Optional $direction is one of C<N E S W> (for
North, East, South, and West), defaults to C<N>.

=cut

sub set_grid {
    my ($self, $grid, $x, $y, $direction) = @_;
    $direction //= 'N';
    my $with_grid_class = $self->class_with_grid;
    if (! $self->does($with_grid_class)) {
        load($with_grid_class);
        'Moo::Role'->apply_roles_to_object($self, $with_grid_class);
        $self->set_grid($grid, $x, $y, $direction);
    }
}

=item class_with_grid

The class to which the robot is reblessed after obraining the grid. By
default, it's the robot's class plus C<::WithGrid>.

=cut

sub class_with_grid { ref(shift) . '::WithGrid' }


=item $robot->load_grid( [ file | handle ] => '...' )

Loads grid from the given source. You can specify a scalar reference
as C<file>, too. The format of the input is as follows:

 # karel 4 2
 WWWWWW
 W   v W
 W1w  W
 WWWWWW

The first line specifies width and height of the grid. An ASCII map of
the grid follows with the following symbols:

 W      outer wall
 w      inner wall
 space  blank
 1 .. 9 marks

The robot's position and direction is denoted by either of C<< ^ > v <
>> B<preceding> the cell in which the robot should start. In the
example above, the robots starts at coordinates 4, 1 and faces South.

=cut

my %faces = ( '^' => 'N',
              '>' => 'E',
              'v' => 'S',
              '<' => 'W' );

sub load_grid {
    my ($self, $type, $that) = @_;

    my %backup;
    if ($self->can('grid')) {
        @backup{qw{ grid x y direction }} = map $self->$_,
                qw( grid x y direction );
    }

    my $IN;
    my $open = { file   => sub { open $IN, '<', $that or croak "$that: $!" },
                 string => sub { open $IN, '<', \$that or croak "'$that': $!" },
                 handle => sub { $IN = $that },
               }->{$type};
    croak "Unknown type $type" unless $open;
    $open->();

    local $/ = "\n";
    my $header = <$IN>;
    croak 'Invalid format'
        unless $header =~ /^\# \s* karel \s+ (v[0-9]+\.[0-9]{2}) \s+ ([0-9]+) \s+ ([0-9]+)/x;
    my ($version, $x, $y) = ($1, $2, $3);
    my $grid = 'Karel::Grid'->new( x => $x,
                                   y => $y,
                                 );

    my $r = 0;
    my (@pos, $direction);
    while (<$IN>) {
        chomp;
        my @chars = split //;
        my $c = 0;
        while ($c != $#chars) {
            next if 'W' eq $chars[$c]
                 && (   $r == 0 || $r == $y + 1
                     || $c == 0 || $c == $x + 1);
            my $build = { w   => 'build_wall',
                          ' ' => 'clear',
                          # marks
                          ( map {
                              my $x = $_;
                              $x => sub {
                                  $_[0]->drop_mark(@_[1, 2]) for 1 .. $x
                              }
                          } 1 .. 9 ),
                          # robot
                          ( map {
                              my $f = $_;
                              $f => sub {
                                  croak 'Two robots in a grid' if $direction;
                                  $direction = $faces{$f};
                                  @pos = ($c, $r);
                                  splice @chars, $c, 1;
                                  no warnings 'exiting';
                                  redo
                              }
                          } keys %faces )
                        }->{ $chars[$c] };
            croak "Unknown or invalid grid character '$chars[$c]' at $c, $.."
                unless $build;
            $grid->$build($c, $r);
        } continue {
            ++$c;
        }
    } continue {
        ++$r;
    }

    croak 'Wall at starting position' if 'w' eq lc $grid->at(@pos);

    eval {
        $_[0]->set_grid($grid, @pos, $direction);
    1 } or do {
        $_[0]->set_grid(@backup{qw{ grid x y direction }});
        croak $@
    };
}

has parser => ( is      => 'ro',
                default => sub { 'Karel::Parser'->new },
);


=item $commands = $robot->knows($command_name)

If the robot knows the command, returns its definition; dies
otherwise.

=cut

sub knows {
    my ($self, $command) = @_;
    $self->knowledge->{$command}[0]
}

sub _learn {
    my ($self, $command, $parsed, $code) = @_;
    my ($prog, $from, $to) = @$parsed;
    my $knowledge = $self->knowledge;
    $knowledge->{$command} = [ $prog, $code ]; # TODO: No leaks!
    $self->_set_knowledge($knowledge);
}

=item $robot->learn($program)

Teaches the robot new commands. Dies if the definitions contain
unknown commands.

=cut

sub learn {
    my ($self, $prog) = @_;
    my ($commands, $unknown) = $self->parser->parse($prog);
    $self->_learn($_, $commands->{$_}, $prog) for keys %$commands;
    for my $command (keys %$unknown) {
        croak "Dont' know $command" unless $self->knows($command);
    }
}

has knowledge => ( is => 'rwp' );

=back

=cut


__PACKAGE__
