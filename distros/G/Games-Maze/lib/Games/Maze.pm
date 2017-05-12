package Games::Maze;
use 5.008003;

use integer;
use strict;
use warnings;
use Carp;

our $VERSION = '1.08';


our $North      = 0x0001;	# 0;
our $NorthWest  = 0x0002;	# 1;
our $West       = 0x0004;	# 2;
our $SouthWest  = 0x0008;	# 3;
our $Ceiling    = 0x0010;	# 4;
our $South      = 0x0020;	# 5;
our $SouthEast  = 0x0040;	# 6;
our $East       = 0x0080;	# 7;
our $NorthEast  = 0x0100;	# 8;
our $Floor      = 0x0200;	# 9;
our $Path_Mark  = 0x8000;	# 15;

#
# So, in bytes, cells are the bit sum of:
#
# 1  0  | 3  2  1  0  | 3  2  1  0
# ------+-------------+-----------
# F  NE | E  SE S  C  | SW W  NW N
#
#
#                200 (down)
#
#       002   001   100
#          \   |   /
#           \  |  /
#            \ | /
#             \|/
#  004 --------+-------- 080
#             /|\
#            / | \
#           /  |  \
#          /   |   \
#      008    020    040
#
#          010 (up)
#
# Path_Mark = 8000
#
# The legal directions (in hexadecimal) for square cells.
#
#
#                North
#                 (1)
#            :------------:   (200) Down
#            |            |
#            |            |
#     West   |     .      | East
#      (4)   |            | (80)
#            |            |
#            :------------:
#                South
#  Up (10)        (20)
#
#
#
# The legal directions (in hexadecimal) for hexagon cells.
#
#                North
#                 (1)
#               ________      (200) Down
#              /        \
# NorthWest   /          \   NorthEast
#     (2)    /     .      \    (100)
#            \            /
# SouthWest   \          /   SouthEast
#     (8)      \________/       (40)
#                South
#  Up (10)        (20)
#
#
# The maze is represented as a matrix, sized 0..lvls+1, 0..cols+1, 0..rows+1.
# To avoid special "are we at the edge" checks, the outer border
# cells of the matrix are pre-marked, which leaves the cells in the
# area of 1..lvls, 1..cols, 1..rows to generate the maze.
#
# The top level upper left hand cell is the 0,0,0 corner of the maze, be
# it a cube or a honeycomb.  This is why they are called "levels" instead
# of "storeys".
#

my($Debug_make_ascii, $Debug_make_vx) = (0, 0);
my($Debug_solve_ascii, $Debug_solve_vx) = (0, 0);
my($Debug_internal) = 0;


#
# Valid options to new().
#

my %valid = (
	dimensions => 'array',
	form => 'scalar',
	cell => 'scalar',
	upcolumn_even => 'scalar',
	generate => 'scalar',
	connect => 'scalar',
	fn_choosedir => 'scalar',
	entry => 'array',
	exit => 'array',
	start => 'array',
);

#
# new
#
# Creates the object with its attributes.  Valid attributes
# are listed in the %valid hash.
#
sub new
{
	my $class = shift;
	my $self = {};

	#
	# We are copying from an existing maze object?
	#
	if (ref $class)
	{
		if ($class->isa("Games::Maze"))
		{
			$class->_copy($self);
			return bless($self, ref $class);
		}

		warn "Attempts to create a Maze object from a '",
			ref $class, "' object fail.\n";
		return undef;
	}

	#
	# Starting from scratch.
	#
	my(%params) = @_;

	while ( my($key, $keyval) = each %params)
	{
		$key = lc $key;
		my $ref_type = $valid{$key};

		unless (defined $ref_type)
		{
			carp "Ignoring unknown parameter '$key'\n";
			next;
		}

		$self->{$key} = $keyval if ($ref_type eq 'scalar');
		push(@{ $self->{$key} }, @{ $keyval }) if ($ref_type eq 'array');
	}


	#
	# Put in defaults for any unnamed but required parameters.
	#
	$self->{dimensions} ||= [3, 3, 1];
	push @{ $self->{dimensions} }, 3 if (@{ $self->{dimensions} } < 1);
	push @{ $self->{dimensions} }, 3 if (@{ $self->{dimensions} } < 2);
	push @{ $self->{dimensions} }, 1 if (@{ $self->{dimensions} } < 3);

	$self->{form} = ucfirst lc($self->{form} || 'Rectangle');
	$self->{cell} = ucfirst lc($self->{cell} || 'Quad');

	unless ($self->{form} =~ /^(?:Rectangle|Hexagon)$/)
	{
		carp "Unknown form type ", $self->{form};
		return undef;
	}
	unless ($self->{cell} =~ /^(?:Quad|Hex)$/)
	{
		carp "Unknown cell type ", $self->{cell};
		return undef;
	}

	bless($self, $class . "::" . $self->{cell});

	return $self->reset();
}


#
# describe
#
# %maze_attr = $obj->describe();
#
# Returns as a hash the attributes of the maze object.
#
# Only keys that don't begin with an underscore
# are allowed to be seen.
#
sub describe()
{
	my $self = shift;

	return map {$_, $self->{$_}} grep(/^[a-z]/, keys %{$self});
}

#
# internals
#
# %maze_attr = $obj->internals();
#
# Returns as a hash the hidden internal attributes of the maze object.
#
# Only keys that begin with an underscore (excepting _corn)
# are allowed to be seen.
#
sub internals()
{
	my $self = shift;

	return map {$_, $self->{$_}} grep(/^_(?!corn)/, keys %{$self});
}

#
# reset
#
# Resets the matrix m. You should not normally need to call this method,
# as the other methods will call it when needed.
#
sub reset
{
	my $self = shift;
	my($l, $c, $r);

	$self->{_corn} = ([]);
	$self->{form} = 'Rectangle' unless (exists $self->{form});
	$self->{generate} = 'Random';
	$self->{connect} = 'Simple';

	return undef unless ($self->_set_internals());

	#
	# Now that we've got one level reset, copy it to the rest.
	#
	my $m = $self->{_corn};

	foreach $l (2..$self->{_lvls})
	{
		foreach $r (0..$self->{_rows} + 1)
		{
			foreach $c (0..$self->{_cols} + 1)
			{
				$$m[$l][$r][$c] = $$m[1][$r][$c];
			}
		}
	}

	#
	# Top and bottom border levels.  Removing the floor is good enough.
	#
	foreach $r (0..$self->{_rows} + 1)
	{
		foreach $c (0..$self->{_cols} + 1)
		{
			$$m[0][$r][$c] =
				$$m[$self->{_lvls} + 1][$r][$c] = $Floor;
		}
	}

	#
	# Now that the internals are set, do the same for
	# the entry, exit coordinates.
	#
	$self->_set_entry_exit();

	$self->{_status} = 'reset';
	return $self;
}

#
# make
#
# $obj->make();
#
# Perform a random walk through the walls of the grid. This creates a
# simply-connected maze.
#
sub make
{
	my $self = shift;
	my(@queue, @dir);

	my($c, $r, $l) = $self->_get_start_point();
	my $choose_dir = $self->{fn_choosedir} || \&_random_dir;

	$self->reset() if ($self->{_status} ne 'reset');

	for (;;)
	{
		@dir = $self->_collect_dirs($c, $r, $l);

		#
		# There is a cell to break into.
		#
		if (@dir > 0)
		{
			#
			# If there were multiple choices, save it
			# for future reference.
			#
			push @queue, ($c, $r, $l) if (@dir > 1);

			#
			# Choose a wall at random and break into the next cell.
			#
			($c, $r, $l) = $self->_break_thru($choose_dir->(\@dir, [$c, $r, $l]),
							$c, $r, $l);

			print STDERR $self->to_hex_dump() if ($Debug_make_vx);
			print STDERR $self->to_ascii() if ($Debug_make_ascii);
		}
		else	# No place to go, back up.
		{
			last if (@queue == 0);	# No place to back up, quit.
			($c, $r, $l) = splice @queue, 0, 3;
		}
	}

	$self->_add_egress();
	$self->{_status} = 'make';
	return $self;
}

#
# solve
#
# $obj->solve();
#
# Finds a solution to the maze by examining a path until a
# dead end is reached.
#
sub solve
{
	my $self = shift;

	$self = $self->make() if ($self->{_status} ne 'make');
	return undef unless ($self);

	my $dir = $North;;
	my($c, $r, $l, $fin_c, $fin_r, $fin_l) = $self->_get_entry_exit();

	$self->_toggle_pathmark($c, $r, $l);

	while ($c != $fin_c or $r != $fin_r or $l != $fin_l)
	{
		my($cc, $rr, $ll);

		#
		# Look around for an open wall (bit == 1).
		#
		while (1)
		{
			$dir = $self->_next_direct($dir);
			last if ($self->_wall_open($dir, $c, $r, $l));
		}

		#
		# Mark (or unmark) the cell we are about to enter (or leave).
		#
		($dir, $cc, $rr, $ll) = $self->_move_thru($dir, $c, $r, $l);

		if ($self->_on_pathmark($cc, $rr, $ll))
		{
			$self->_toggle_pathmark($c, $r, $l);
		}
		else
		{
			$self->_toggle_pathmark($cc, $rr, $ll);
		}

		($c, $r, $l) = ($cc, $rr, $ll);

		print $self->to_hex_dump() if ($Debug_solve_vx);
		print $self->to_ascii() if ($Debug_solve_ascii);
	}

	$self->{_status} = 'solve';
	return $self;
}

#
# unsolve
#
# $obj->unsolve();
#
# Erase the path left by the solve() method.
#
sub unsolve
{
	my $self = shift;

	return $self if ($self->{_status} eq 'make');

	if ($self->{_status} eq 'solve')
	{
		my $m = $self->{_corn};
		my $allwalls = $North|$NorthWest|$West|$SouthWest|$Ceiling|
				$South|$SouthEast|$East|$NorthEast|$Floor;

		foreach my $l (1..$self->{_lvls})
		{
			foreach my $r (1..$self->{_rows})
			{
				foreach my $c (1..$self->{_cols})
				{
					$$m[$l][$r][$c] &= $allwalls;
				}
			}
		}
		$self->{_status} = 'make';
	}
	else
	{
		$self = $self->make();
	}

	return $self;
}

#
# to_hex_dump
#
# @xlvls = $obj->to_hex_dump();
# $xstr = $obj->to_hex_dump();
#
# Returns a formatted hexadecimal string all of the cell values, including
# the border cells, but excluding the all-border 0th and level+1 levels.
#
# If called in a list context, returns a list of strings, each one
# representing a level. If called in a scalar context, returns a single
# string, each level separated by a single newline.
#
sub to_hex_dump
{
	my $self = shift;
	my $m = $self->{_corn};
	my @levels;

	foreach my $l (1..$self->{_lvls})
	{
		my $vxstr = "";
		foreach my $r (0..$self->{_rows} + 1)
		{
			foreach my $c (0..$self->{_cols} + 1)
			{
				$vxstr .= sprintf(" %04x", $$m[$l][$r][$c]);
			}
			$vxstr .= "\n";
		}

		push @levels, $vxstr;
	}

	return wantarray? @levels: join("\n", @levels);
}

#
# $class->_copy($self);
#
# Duplicate the maze object.
#
sub _copy
{
	my($other, $self) = @_;

	#
	# Direct copy of all keys, except for '_corn', which
	# we'll do with a deeper copy.
	#
	foreach my $k (grep($_ !~ /_corn/, keys %{$other}))
	{
		$self->{$k} = $other->{$k};
	}

	$self->{_corn} = ([]);
	my $m = $self->{_corn};
	my $o = $other->{_corn};

	foreach my $l (0..$other->{_lvls} + 1)
	{
		foreach my $r (0..$other->{_rows} + 1)
		{
			foreach my $c (0..$other->{_cols} + 1)
			{
				$$m[$l][$r][$c] = $$o[$l][$r][$c];
			}
		}
	}

	return $self;
}

#
# Default mechanism to perform the random walk.
#
sub _random_dir
{
	return ${$_[0]}[int(rand(@{$_[0]}))];
}

#
# ($start_c, $start_r, $start_l, $fin_c, $fin_r, $fin_l) = $obj->_get_entry_exit();
#
sub _get_entry_exit
{
	my $self = shift;

	return (@{ $self->{entry} },
		@{ $self->{exit} });
}

#
# Knock down the walls that represent the entrance and exit.
#
sub _add_egress
{
	my $self = shift;
	my $m = $self->{_corn};

	my @egress = $self->_get_entry_exit();

	#
	# This is for the to_ascii() method.
	#
	$$m[$egress[2]][$egress[1] - 1][$egress[0]] |= $South;

	$$m[$egress[2]][$egress[1]][$egress[0]] |= $North;
	$$m[$egress[5]][$egress[4]][$egress[3]] |= $South;

	return $self;
}


#
# $obj->_break_thru($wall, $c, $r, $l)
#
# Mark a wall as broken through.  Go through that wall
# to the next cell.  Mark the equivalent wall in that
# cell as broken through as well.
#
# Return the new column/row/level of the new cell.
#
sub _break_thru
{
	my $self = shift;
	my($wall, $c, $r, $l) = @_;
	my $m = $self->{_corn};

	$$m[$l][$r][$c] |= $wall;
	($wall, $c, $r, $l) = $self->_move_thru($wall, $c, $r, $l);
	$$m[$l][$r][$c] |= $wall;

	return ($c, $r, $l);
}

#
# if ($obj->_wall_open($dir, $c, $r, $l)) {...}
#
sub _wall_open
{
	my $self = shift;
	my($dir, $c, $r, $l) = @_;
	my $m = $self->{_corn};

	return ($$m[$l][$r][$c] & $dir) != 0;
}

#
# $obj->_toggle_pathmark($c, $r, $l)
#
# No return value.
#
sub _toggle_pathmark
{
	my $self = shift;
	my($c, $r, $l) = @_;
	my $m = $self->{_corn};

	$$m[$l][$r][$c] ^= $Path_Mark;
}

#
# if ($obj->_on_pathmark($c, $r, $l)) {...}
#
sub _on_pathmark
{
	my $self = shift;
	my($c, $r, $l) = @_;
	my $m = $self->{_corn};

	return (($$m[$l][$r][$c] & $Path_Mark) == $Path_Mark);
}

#
# Games::Maze::Quad - Create 3-D maze objects.
#
# Maze creation is done through the maze object's methods, listed below:
#
package Games::Maze::Quad;
use parent qw(-norequire Games::Maze);

use integer;
use strict;
use warnings;
use Carp;

our $VERSION = '1.08';

#
# to_ascii
#
# Translate the maze into a string of ascii 7-bit characters. If called in
# a list context, return as a list of levels. Otherwise returned as a
# single string, each level separated by a single newline.
#
sub to_ascii
{
	my $self = shift;
	my $m = $self->{_corn};
	my @levels = ();
	my($c, $r, $l);

	my(%horiz_walls) = (
		(0      , ":--"),
		($South  , ":  ")
	);

	my(%verti_walls) = (
		(0                              , "|  "),
		($West                           , "   "),
		($Path_Mark                      , "| *"),
		($West|$Path_Mark                 , "  *"),
		($Floor                          , "|f "),
		($West|$Floor                     , " f "),
		($Path_Mark|$Floor                , "|f*"),
		($West|$Path_Mark|$Floor           , " f*"),
		($Ceiling                        , "|c "),
		($West|$Ceiling                   , " c "),
		($Path_Mark|$Ceiling              , "|c*"),
		($West|$Path_Mark|$Ceiling         , " c*"),
		($Floor|$Ceiling                  , "|b "),
		($West|$Floor|$Ceiling             , " b "),
		($Path_Mark|$Floor|$Ceiling        , "|b*"),
		($West|$Path_Mark|$Floor|$Ceiling   , " b*")
	);

	foreach $l (1..$self->{_lvls})
	{
		my $lvlstr = "";

		#
		# End of all rows for this level.  Print the closing South walls.
		#
		foreach $c (1..$self->{_cols} + 1)
		{
			$lvlstr .= $horiz_walls{$$m[$l][0][$c] & $South};
		}

		$lvlstr .= "\n";

		foreach $r (1..$self->{_rows})
		{
			foreach $c (1..$self->{_cols} + 1)
			{
				my($v) = $$m[$l][$r][$c] & ($West|$Path_Mark|$Floor|$Ceiling);
				$lvlstr .= $verti_walls{$v};
			}


			$lvlstr .= "\n";

			foreach $c (1..$self->{_cols} + 1)
			{
				$lvlstr .= $horiz_walls{$$m[$l][$r][$c] & $South};
			}

			$lvlstr .= "\n";
		}

		push @levels, $lvlstr;
	}

	return wantarray? @levels: join("\n", @levels);
}

#
# _set_internals
#
# Sets the internal values of the maze, and resets the first level of the maze.
#
sub _set_internals
{
	my $self = shift;
	my($c, $r);

	#
	# Check the dimensions for correctness.
	#
	my($cols, $rows, $lvls) = @{ $self->{dimensions} };

	if ($self->{form} eq 'Rectangle')
	{
		if ($cols < 2 or $rows < 2 or $lvls < 1)
		{
			carp "Minimum column, row, and level dimensions are 2, 2, 1";
			return undef;
		}
		$self->{_rows} = $rows;
		$self->{_cols} = $cols;
		$self->{_lvls} = $lvls;
	}
	else
	{
		carp "Unknown form requested for ", __PACKAGE__, ".\n";
		return undef;
	}

	#
	# Ensure that the starting point is set correctly.
	#
	if (defined $self->{start})
	{
		my @start = @{ $self->{start} };

		if ((not defined $start[0]) or
			$start[0] < 1 or $start[0] > $self->{_cols})
		{
			$start[0] = int(rand($self->{_cols})) + 1;
			carp "Start column $start[0] is out of range.\n";
		}
		if ((not defined $start[1]) or
			$start[1] < 1 or $start[1] > $self->{_rows})
		{
			$start[1] = int(rand($self->{_rows})) + 1;
			carp "Start row $start[1] is out of range.\n";
		}
		if ((not defined $start[2])
			or $start[2] < 1 or $start[2] > $self->{_rows})
		{
			$start[2] = int(rand($self->{_lvls})) + 1;
		}

		$self->{start} = \@start;
	}

	my $m = $self->{_corn};
	my $allwalls = $North | $West | $South | $East;

	#
	# Reset the center cells to unbroken.
	#
	foreach $r (1..$self->{_rows})
	{
		foreach $c (1..$self->{_cols})
		{
			$$m[1][$r][$c] = 0;
		}
	}

	#
	# Set the border cells.
	#
	foreach $r (0..$self->{_rows} + 1)
	{
		$$m[1][$r][$self->{_cols} + 1] = $North | $South | $East;
		$$m[1][$r][0] = $allwalls;
	}
	foreach $c (0..$self->{_cols} + 1)
	{
		$$m[1][$self->{_rows} + 1][$c] = $allwalls;
		$$m[1][0][$c] = $North | $West | $East;
	}

	$$m[1][0][$self->{_cols} + 1] |= $South;

	return $self;
}

#
# $obj->_set_entry_exit
#
# Pick the start and final points on the maze. These will become
# user-settable choices in the future.
#
sub _set_entry_exit
{
	my $self = shift;
	my $m = $self->{_corn};

	if (defined $self->{entry})
	{
		my @entry = @{ $self->{entry} };

		if ($entry[0] < 1 or $entry[0] > $self->{_cols})
		{
			$entry[0] = int(rand($self->{_cols})) + 1;
			carp "Entry column $entry[0] is out of range.\n";
		}

		$entry[1] = 1;
		$entry[2] = 1;

		$self->{entry} = \@entry;
	}
	else
	{
		$self->{entry} = [int(rand($self->{_cols})) + 1, 1, 1];
	}

	if (defined $self->{exit})
	{
		my @exit = @{ $self->{exit} };

		if ($exit[0] < 1 or $exit[0] > $self->{_cols})
		{
			$exit[0] = int(rand($self->{_cols})) + 1;
			carp "Exit column $exit[0] is out of range.\n";
		}
	
		$exit[1] = $self->{_rows};
		$exit[2] = $self->{_lvls};
		$self->{exit} = \@exit;
	}
	else
	{
		$self->{exit} = [int(rand($self->{_cols})) + 1,
					$self->{_rows},
					$self->{_lvls}];
	}

	return $self;
}

#
# $obj->_get_start_point
#
# Return the (or pick a) starting point in the maze.
#
sub _get_start_point
{
	my $self = shift;

	return @{ $self->{start} } if (defined $self->{start});

	return (
		int(rand($self->{_cols})) + 1,
		int(rand($self->{_rows})) + 1,
		int(rand($self->{_lvls})) + 1
	);
}

#
# ($dir, $c, $r, $l) = $obj->_move_thru($dir, $c, $r, $l)
#
# Move from the current cell to the next by going in the direction
# of $dir.  The function will return your new coordinates, and the
# number of the wall you just came through, from the point of view
# of your new position.
#
sub _move_thru
{
	my $self = shift;
	my($dir, $c, $r, $l) = @_;

	print STDERR "_move_thru: [$c, $r, $l] to $dir\n" if ($Debug_internal);

	if ($dir == $North or $dir == $South)
	{
		$r += ($dir == $North)? -1: 1;
	}
	elsif ($dir == $East or $dir == $West)
	{
		$c += ($dir == $West)? -1: 1;
	}
	else
	{
		$l += ($dir == $Ceiling)? -1: 1;
	}

	$dir = ($dir <= $Ceiling)? ($dir << 5): ($dir >> 5);

	print STDERR "_move_thru: [$c, $r, $l] from $dir\n" if ($Debug_internal);
	return ($dir, $c, $r, $l);
}

#
# @directions = $obj->_collect_dirs($c, $r, $l);
#
# Find all of our possible directions to wander when creating the maze.
# You are only allowed to go into not-yet-broken cells.  The directions
# are deliberately accumulated in a counter-clockwise fashion.
#
sub _collect_dirs
{
	my $self = shift;
	my $m = $self->{_corn};
	my @dir;
	my($c, $r, $l) = @_;

	#
	# Search for enclosed cells.
	#
	push(@dir, $North)    if ($$m[$l][$r - 1][$c] == 0);
	push(@dir, $West)     if ($$m[$l][$r][$c - 1] == 0);
	push(@dir, $South)    if ($$m[$l][$r + 1][$c] == 0);
	push(@dir, $East)     if ($$m[$l][$r][$c + 1] == 0);
	push(@dir, $Ceiling)  if ($$m[$l - 1][$r][$c] == 0);
	push(@dir, $Floor)    if ($$m[$l + 1][$r][$c] == 0);

	print STDERR "_collect_dirs($c, $r, $l) returns (", join(", ", @dir), ")\n" if ($Debug_internal);
	return @dir;
}

#
# $dir = $obj->_next_direct($dir)
#
# Returns the next direction to move to when checking walls.
#
sub _next_direct
{
	my $self = shift;
	my($dir) = @_;

	print STDERR "_next_direct: start with ", $dir, "\n" if ($Debug_internal);
	if ($dir == $Floor)
	{
		$dir = $North;
	}
	elsif ($dir == $Ceiling)
	{
		$dir = $South;
	}
	else
	{
		$dir <<= 2;
	}
	print STDERR "_next_direct: return ", $dir, "\n" if ($Debug_internal);
	return $dir;
}

#
# NAME
#
# Games::Maze::Hex - Create 3-D hexagon maze objects.
#
# Maze creation is done through the maze object's methods, listed below:
#
package Games::Maze::Hex;
use parent qw(-norequire Games::Maze);

use integer;
use strict;
use warnings;
use Carp;

our $VERSION = '1.08';

#
# to_ascii
#
# Translate the maze into a string of ascii 7-bit characters. If called in
# a list context, return as a list of levels. Otherwise returned as a
# single string, each level separated by a single newline.
#
sub to_ascii
{
	my $self = shift;
	my $m = $self->{_corn};
	my($c, $r, $l, @levels);

	my(%upper_west) = (
		(0                                      , '/  '),
		($NorthWest                              , '   '),
		($Floor                                  , '/f '),
		($NorthWest | $Floor                      , ' f '),
		($Ceiling                                , '/c '),
		($NorthWest | $Ceiling                    , ' c '),
		($Floor | $Ceiling                        , '/b '),
		($NorthWest | $Floor | $Ceiling            , ' b '),
		($Path_Mark                              , '/ *'),
		($NorthWest | $Path_Mark                  , '  *'),
		($Floor | $Path_Mark                      , '/f*'),
		($NorthWest | $Floor | $Path_Mark          , ' f*'),
		($Ceiling | $Path_Mark                    , '/c*'),
		($NorthWest | $Ceiling | $Path_Mark        , ' c*'),
		($Floor | $Ceiling | $Path_Mark            , '/b*'),
		($NorthWest | $Floor | $Ceiling | $Path_Mark, ' b*'),
	);
	my(%lower_west) = (
		(0                  , '\__'),
		($South             , '\  '),
		($SouthWest         , ' __'),
		($SouthWest | $South, '   '),
	);

	my $rlim = $self->{_rows} + 1;

	foreach $l (1..$self->{_lvls})
	{
		#
		# Print the top line of the border (the underscores on the
		# 'up' columns).
		#
		my $lvlstr = "";

		foreach $c (1..$self->{_cols})
		{
			if ($self->_up_column($c))
			{
				$lvlstr .= $lower_west{$$m[$l][0][$c] & ($SouthWest|$South)};
			}
			else
			{
				$lvlstr .= $lower_west{($SouthWest|$South)};
			}
		}

		$lvlstr .= "\n";

		#
		# Now print the rows.
		#
		foreach $r (1..$rlim)
		{
#			my($clim1, $clim2) = $self->_first_last_col($r);
			my($clim2) = $self->{_cols};

			#
			# It takes two lines to print out the hexagon, or parts of the
			# hexagon.  First, the top half.
			#
			foreach $c (1..$clim2 + 1)
			{
				if ($self->_up_column($c))
				{
					$lvlstr .= $upper_west{$$m[$l][$r][$c] & ($NorthWest|$Floor|$Ceiling|$Path_Mark)};
				}
				else
				{
					$lvlstr .= $lower_west{$$m[$l][$r - 1][$c] & ($SouthWest|$South)};
				}
			}

			$lvlstr .= "\n";

			#
			# Now, the lower half.
			#
			foreach $c (1..$clim2 + 1)
			{
				if ($self->_up_column($c))
				{
					$lvlstr .= $lower_west{$$m[$l][$r][$c] & ($SouthWest|$South)};
				}
				else
				{
					$lvlstr .= $upper_west{$$m[$l][$r][$c] & ($NorthWest|$Floor|$Ceiling|$Path_Mark)};
				}
			}

			$lvlstr .= "\n";
		}

		push @levels, $lvlstr;
	}

	return wantarray? @levels: join("\n", @levels);
}

#
# _set_internals
#
# Sets the internal values of the maze, and resets the first level of the maze.
#
sub _set_internals
{
	my $self = shift;
	my($c, $r);

	#
	# Check the dimensions for correctness.
	#
	my($cols, $rows, $lvls) = @{ $self->{dimensions} };

	if ($self->{form} eq 'Rectangle')
	{
		if ($cols < 2 or $rows < 2 or $lvls < 1)
		{
			carp "Minimum column, row, and level dimensions are 2, 2, 1";
			return undef;
		}

		$self->{upcolumn_even} = 0 unless (defined $self->{upcolumn_even});
		$self->{_rows} = $rows;
		$self->{_cols} = $cols;
		$self->{_lvls} = $lvls;
	}
	elsif ($self->{form} eq 'Hexagon')
	{
		if ($cols < 2 or $rows < 1 or $lvls < 1)
		{
			carp "Minimum column, row, and level dimensions are 1, 2, 1";
			return undef;
		}

		$self->{upcolumn_even} = 1 - ($cols & 1);
		$self->{_rows} = $rows + $cols - 1;
		$self->{_cols} = $cols * 2 - 1;
		$self->{_lvls} = $lvls;
	}
	else
	{
		carp "Unknown form requested for ", __PACKAGE__, ".\n";
		return undef;
	}

	#
	# Ensure that the starting point is set correctly.
	#
	if (defined $self->{start})
	{
		my @start = @{ $self->{start} };

		if ((not defined $start[0]) or
			$start[0] < 1 or $start[0] > $self->{_cols})
		{
			$start[0] = int(rand($self->{_cols})) + 1;
			carp "Start column $start[0] is out of range.\n";
		}
		if ((not defined $start[1]) or
			$start[1] < 1 or $start[1] > $self->{_rows})
		{
			my($row_start, $row_end) = $self->_first_last_row($start[0]);
			$start[1] = int(rand($row_end - $row_start + 1)) + $row_start;
			carp "Start row $start[1] is out of range.\n";
		}

		if ((not defined $start[2])
			or $start[2] < 1 or $start[2] > $self->{_rows})
		{
			$start[2] = int(rand($self->{_lvls})) + 1;
		}

		$self->{start} = \@start;
	}

	my $m = $self->{_corn};

	#
	# Reset the center cells to unbroken.
	#
	foreach $r (1..$self->{_rows})
	{
		foreach $c (1..$self->{_cols})
		{
			$$m[1][$r][$c] = 0;
		}
	}

	#
	# Set the border cells.
	#
	if ($self->{form} eq 'Rectangle')
	{
		#
		# North and South boundry.
		#
		foreach $c (1..$self->{_cols})
		{
			$$m[1][0][$c] = $NorthWest;
			$$m[1][$self->{_rows} + 1][$c] = $SouthWest;

			if ($self->_up_column($c))
			{
				$$m[1][0][$c] |= $SouthWest;
				$$m[1][$self->{_rows} + 1][$c] |= $South;
			}
			else
			{
				$$m[1][$self->{_rows} + 1][$c] |= $NorthWest;
			}
		}

		#
		# East and West boundry.
		#
		foreach $r (0..$self->{_rows} + 1)
		{
			$$m[1][$r][0] = $South | $SouthWest;
			$$m[1][$r][$self->{_cols} + 1] = $South;
		}

		#
		# We use some of the boundry cells to print the top and bottom walls.
		# Make sure that some of those walls don't print.
		#
		if ($self->_up_column(1))
		{
			$$m[1][$self->{_rows} + 1][1] |= $NorthWest;
		}
		else
		{
			$$m[1][0][1] |= $SouthWest;
		}

		#
		# Eliminate some corner-border walls.
		#
		if ($self->_up_column($self->{_cols} + 1))
		{
			$$m[1][1][$self->{_cols} + 1] |= $NorthWest;
			$$m[1][$self->{_rows} + 1][$self->{_cols} + 1] |= $SouthWest;
		}
		else
		{
			$$m[1][$self->{_rows}][$self->{_cols} + 1] |= $SouthWest;
			$$m[1][$self->{_rows} + 1][$self->{_cols} + 1] |= $NorthWest;
		}
	}
	elsif ($self->{form} eq 'Hexagon')
	{
		my $allwalls = $North|$NorthWest|$SouthWest|$South|$SouthEast|$NorthEast;

		#
		# Set up the East-West boundries.
		#
		foreach $r (0..$self->{_rows} + 1)
		{
			$$m[1][$r][0] = $$m[1][$r][$self->{_cols} + 1] = $allwalls;
		}

		if ($self->_up_column($self->{_cols} + 1))
		{
			my($rlim1, $rlim2) = $self->_first_last_row($self->{_cols});
			for ($r = $rlim1; $r <= $rlim2; $r++)
			{
				$$m[1][$r + 1][1 + $self->{_cols}] ^= $NorthWest;
				$$m[1][$r][1 + $self->{_cols}] ^= $SouthWest;
			}
		}
		else
		{
			my($rlim1, $rlim2) = $self->_first_last_row($self->{_cols});
			for ($r = $rlim1; $r <= $rlim2; $r++)
			{
				$$m[1][$r][1 + $self->{_cols}] ^= $NorthWest;
				$$m[1][$r - 1][1 + $self->{_cols}] ^= $SouthWest;
			}
		}

		#
		# Extend the North and South boundries inward to create
		# the hexagonal form.
		#
		# In the Hexagon form, the columns dimension is the
		# midpoint of '_cols'.
		#
		for ($c = 1; $c <= $cols; $c++)
		{
			my($rlim1, $rlim2) = $self->_first_last_row($c);

			for ($r = 0; $r < $rlim1; $r++)
			{
				$$m[1][$r][$c] = $allwalls;
			}

			for ($r = $self->{_rows} + 1; $r > $rlim2; $r--)
			{
				$$m[1][$r][$c] = $allwalls;
			}

			$$m[1][$rlim1 - 1][$c] ^= $South;
		}

		for ($c = 1 + $cols; $c <= $self->{_cols}; $c++)
		{
			my($rlim1, $rlim2) = $self->_first_last_row($c);

			for ($r = 0; $r < $rlim1; $r++)
			{
				$$m[1][$r][$c] = $allwalls;
			}

			for ($r = $self->{_rows} + 1; $r > $rlim2; $r--)
			{
				$$m[1][$r][$c] = $allwalls;
			}

			$$m[1][$rlim1 - 1][$c] ^= $SouthWest|$South;
			$$m[1][$rlim2 + 1][$c] ^= $NorthWest;
		}
	}

	return $self;
}

#
# $obj->_set_entry_exit
#
# Pick the start and final points on the maze. This will become a
# user-settable choice in the future.
#
sub _set_entry_exit
{
	my $self = shift;
	my $m = $self->{_corn};

	if (defined $self->{entry})
	{
		my @entry = @{ $self->{entry} };

		if ($entry[0] < 1 or $entry[0] > $self->{_cols})
		{
			$entry[0] = int(rand($self->{_cols})) + 1;
			carp "Entry column $entry[0] is out of range.\n";
		}

		($entry[1], undef) = $self->_first_last_row($entry[0]);
		$entry[2] = 1;

		$self->{entry} = \@entry;
	}
	else
	{
		my @entry = (int(rand($self->{_cols})) + 1);

		($entry[1], undef) = $self->_first_last_row($entry[0]);
		$entry[2] = 1;

		$self->{entry} = \@entry;
	}

	if (defined $self->{exit})
	{
		my @exit = @{ $self->{exit} };

		if ($exit[0] < 1 or $exit[0] > $self->{_cols})
		{
			$exit[0] = int(rand($self->{_cols})) + 1;
			carp "Exit column $exit[0] is out of range.\n";
		}

		(undef, $exit[1]) = $self->_first_last_row($exit[0]);
		$exit[2] = $self->{_lvls};

		$self->{exit} = \@exit;
	}
	else
	{
		my @exit = (int(rand($self->{_cols})) + 1);

		(undef, $exit[1]) = $self->_first_last_row($exit[0]);
		$exit[2] = $self->{_lvls};

		$self->{exit} = \@exit;
	}

	return $self;
}

#
# $obj->_get_start_point
#
# Return the (or pick a) starting point in the maze.
#
sub _get_start_point
{
	my $self = shift;

	return @{ $self->{start} } if (defined $self->{start});

	my $c = int(rand($self->{_cols})) + 1;
	my($row_start, $row_end) = $self->_first_last_row($c);

	return (
		$c,
		int(rand($row_end - $row_start + 1)) + $row_start,
		int(rand($self->{_lvls})) + 1
	);
}

#
# ($dir, $c, $r, $l) = $obj->_move_thru($dir, $c, $r, $l)
#
# Move from the current cell to the next by going in the direction
# of $dir.  The function will return your new coordinates, and the
# number of the wall you just came through, from the point of view
# of your new position.
#
sub _move_thru
{
	my $self = shift;
	my($dir, $c, $r, $l) = @_;

	print STDERR "_move_thru: [$c, $r, $l] to $dir\n" if ($Debug_internal);
	if ($dir == $North or $dir == $South)
	{
		$r += ($dir == $North)? -1: 1;
	}
	elsif ($dir == $Ceiling or $dir == $Floor)
	{
		$l += ($dir == $Ceiling)? -1: 1;
	}
	else
	{
		if ($self->_up_column($c))
		{
			$r -= 1 if ($dir == $NorthWest or $dir == $NorthEast);
		}
		else
		{
			$r += 1 if ($dir == $SouthWest or $dir == $SouthEast);
		}

		if ($dir == $NorthWest or $dir == $SouthWest)
		{
			$c -= 1;
		}
		elsif ($dir == $NorthEast or $dir == $SouthEast)
		{
			$c += 1;
		}
	}

	$dir = ($dir <= $Ceiling)? ($dir << 5): ($dir >> 5);

	print STDERR "_move_thru: [$c, $r, $l] from $dir\n" if ($Debug_internal);
	return ($dir, $c, $r, $l);
}

#
# @directions = $obj->_collect_dirs($c, $r, $l);
#
# Find all of our possible directions to wander when creating the maze.
# You are only allowed to go into not-yet-broken cells.  The directions
# are deliberately accumulated in a counter-clockwise fashion.
#
sub _collect_dirs
{
	my $self = shift;
	my($c, $r, $l) = @_;
	my $m = $self->{_corn};
	my @dir;

	#
	# Search for enclosed cells.
	#
	push(@dir, $North) if ($$m[$l][$r - 1][$c] == 0);

	if ($self->_up_column($c))
	{
		push(@dir, $NorthWest) if ($$m[$l][$r - 1][$c - 1] == 0);
		push(@dir, $SouthWest) if ($$m[$l][$r][$c - 1] == 0);

		push(@dir, $South) if ($$m[$l][$r + 1][$c] == 0);

		push(@dir, $SouthEast) if ($$m[$l][$r][$c + 1] == 0);
		push(@dir, $NorthEast) if ($$m[$l][$r - 1][$c + 1] == 0);
	}
	else
	{
		push(@dir, $NorthWest) if ($$m[$l][$r][$c - 1] == 0);
		push(@dir, $SouthWest) if ($$m[$l][$r + 1][$c - 1] == 0);

		push(@dir, $South) if ($$m[$l][$r + 1][$c] == 0);

		push(@dir, $SouthEast) if ($$m[$l][$r + 1][$c + 1] == 0);
		push(@dir, $NorthEast) if ($$m[$l][$r][$c + 1] == 0);
	}

	push(@dir, $Ceiling) if ($$m[$l - 1][$r][$c] == 0);
	push(@dir, $Floor) if ($$m[$l + 1][$r][$c] == 0);

	print STDERR "_collect_dirs($c, $r, $l) returns (", join(", ", @dir), ")\n" if ($Debug_internal);
	return @dir;
}

#
# $dir = $obj->_next_direct($dir)
#
# Returns the next direction to move to when checking walls.
#
sub _next_direct
{
	my $self = shift;
	my($dir) = @_;

	print STDERR "_next_direct: start with ", $dir, "\n" if ($Debug_internal);
	if ($dir == $Floor)
	{
		$dir = $North;
	}
	elsif ($dir == $NorthWest)
	{
		$dir = $SouthWest;
	}
	elsif ($dir == $SouthEast)
	{
		$dir = $NorthEast;
	}
	else
	{
		$dir <<= 1;
	}
	print STDERR "_next_direct: return ", $dir, "\n" if ($Debug_internal);
	return $dir;
}

#
# if ($obj->_up_column($c)) {...}
#
# Which columns are high due to hexagonal drift?
#
sub _up_column
{
	my $self = shift;
	my($c) = @_;
	return 1 & ($c ^ $self->{upcolumn_even});
}

#
# ($first_col, $last_col) = $obj->_first_last_col($r)
#
# Given a row, what columns have the first and last non-border cells
# in the hexagon-formed grid?
#
sub _first_last_col
{
	my $self = shift;
	my($r) = @_;

	if ($self->{form} eq 'Hexagon')
	{
		my $mid_c = ($self->{_cols} + 1)/2;
		my $ante_r = $self->{_cols}/4;
		my $post_r = $self->{_rows} - ($self->{_cols} + 1)/4;

		if ($r <= $ante_r)
		{
			my $offset = (2 * $r - 1);
			return ($mid_c - $offset, 
				$mid_c + $offset);
		}
		elsif ($r > $post_r)
		{
			my $offset = (2 * ($self->{_rows} - $r));
			return ($mid_c - $offset, 
				$mid_c + $offset);
		}
		else
		{
			return (1, 
				$self->{_cols});
		}
	}
	else
	{
		return (1, 
			$self->{_cols});
	}
}

#
# ($first_row, $last_row) = $obj->_first_last_row($c)
#
# Given a column, what rows have the first and last non-border cells
# in the hexagon-formed grid?
#
sub _first_last_row
{
	my $self = shift;
	my $c = $_[0];

	if ($self->{form} eq 'Hexagon')
	{
		#
		# Find how far off $c is from the midpoint (in the
		# Hexagon form, the columns dimension is the midpoint of
		# '_cols').
		#
		my $offset_c = abs(${ $self->{dimensions} }[0] - $c);

		return ($offset_c/2 + 1,
			$self->{_rows} - ($offset_c + 1)/2);
	}
	else
	{
		return (1, 
			$self->{_rows});
	}
}
1;
__END__

=head1 NAME

Games::Maze - Create Mazes as Objects.

=head1 SYNOPSIS

 use Games::Maze;

 $m1 = Games::Maze->new();
 $m2 = Games::Maze->new(dimensions => [12,7,2]);
 $m3 = Games::Maze->new(dimensions => [12,7,2],
                        cell => 'Hex');

 $m1->make();
 $m1->solve();
 print $m1->to_ascii();
 print $m1->to_hex_dump();

 %maze_attr = $m1->describe();

=head1 DESCRIPTION

Simply put, this package create mazes. You may use the Games::Maze
package to create 3-dimensional rectangular or hexagonal mazes. Mazes
are objects that you can manipulate using the available methods.

=head2 Maze Object Methods

=head3 new([<attribute> => value, ...])

Creates the object with its attributes. Current attributes are:

=over 4

=item 'form'

I<Default value: 'Rectangle'.> The shape of the entire maze. Currently
'Rectangle' is the valid for all mazes, 'Hexagon' is valid
for the {cell => 'Hex'} class of mazes.

=item 'cell'

I<Default value: 'Quad'.> The shape of the maze's cells. Valid values
are 'Quad' and 'Hex'.

=item 'dimensions'

I<Default value: [3, 3, 1].> The number of columns, rows, and levels in
the maze. The minimum values for mazes of form 'Rectangle' are S<[2, 2, 1]>.

The minimum values for mazes of form 'Hexagon' are S<[2, 1, 1]> because
the columns and rows values represent slightly different things. The
hexagon form is shaped with the the 'points' North and South, and the
vertical sides East and West.  The rows count represents the size of the
vertical sides, and the columns count represents the length of the
diagonal sides.

=item 'entry'

I<default value: [rand(), 1, 1].> The entry point S<[column, row, level]>
of the maze. Columns, rows, and levels all start at 1. Currently only
the column value is used, the other values are set to 1.

=item 'exit'

I<default value: [rand(), rows, levels].> The exit point S<[column, row, level]>
of the maze. Columns, rows, and levels all start at 1. Currently only
the column value is used, the row value is either calculated if form =>
'Hexagon' or set to the last row number, and the level value is set to
the last level number.

=item 'upcolumn_even'

I<Default value: 0.> Determines whether, in a {cell => 'Hex', form =>
'Rectangle'} maze, the first (and third and fifth..) column is the
upwards column, or if the second (and fourth and sixth...) column is
upwards. By default, the odd number columns are the ones shifted
upwards.

This parameter will be ignored for the {cell => 'Quad'} mazes, and is
set automatically for the {form => 'Hexagon'} mazes, as the center
column is always the 'up' column for such mazes.

=item 'start'

I<default value: [rand(), rand(), rand()].> The random walk's starting
point S<[column, row, level]> when making the maze. Columns, rows, and
levels all start at 1.

=item 'fn_choosedir'

I<Default value: internal function>. Reference to a function that
selects a single direction from a list, which is used to create the
maze. The function expects a reference to an array of directions, and a
reference to a three-element array that holds the column, row, and level
number. A simple example would be

	sub first_dir
	{
		return ${$_[0]}[0];
	}

which would simply return the first direction in the array of
directions, ignoring all else.  If that's a little cryptic, it could
also be written as

	sub first_dir
	{
		my($direction_ref, $position_ref) = @_;

		return ${$direction_ref}[0];
	}

If all directions were available, they would be passed in almost-sorted
order: [North, West, South, East, Ceiling, Floor] for cell =>'Quad'
mazes, [North, NorthWest, SouthWest, South, SouthEast, NorthEast,
Ceiling, Floor] for cell => 'Hex' mazes.  This would mean that first_dir()
would always return North unless it wasn't on the list, whereupon the next
available direction would be tried.

The direction values are available by using their variable names:
C<$Games::Maze::North>, C<$Games::Maze::NorthWest>, C<$Games::Maze::West>, et cetera.

=item 'generate'

I<Default value: 'Random'.> Currently read-only. The method used to
generate the paths of the maze.

=item 'connect'

I<Default value: 'Simple'.> Currently read-only. The path connections. A
simply-connected maze has only one path between any two points; a
multiply-connected maze has one or more paths.

=back

=head3 make

 $obj->make();

Perform a random walk through the walls of the grid. This creates a
simply-connected maze.

=head3 solve

 $obj->solve();

Finds a solution to the maze by examining a path until a
dead end is reached.

=head3 unsolve

 $obj->unsolve();

Erase the path from the maze that was created by the solve() method.

=head3 reset

Resets the maze cells to their clean, unbroken state. You should not
normally need to call this method, as the other methods will call it
when needed.

=head3 describe

 %maze_attributes = $obj->describe();

Returns as a hash the attributes of the maze object.

=head3 internals

 %maze_internals = $obj->internals();

Returns as a hash the 'hidden' internal values of the maze object,
excepting the maze cell values, which can be retrieved via the
to_hex_dump method.

=head3 to_ascii

Translate the maze into a string of ascii 7-bit characters. If called in
a list context, return as a list of levels. Otherwise returned as a
single string, each level separated by a single newline.

Currently, this is the only method available to view the maze. It uses
underscores, both slash characters, and vertical bars to represent the
walls of the maze. The letters 'c', 'f', and 'b' represent passages
through the ceiling, floor, or both, respectively. The asterisk
represents the path, which will only be present after invoking the
solve() method.

=head3 to_hex_dump

Returns a formatted hexadecimal string all of the cell values, including
the border cells.

If called in a list context, returns a list of strings, each one
representing a level. If called in a scalar context, returns a single
string, each level separated by a single newline.

=head1 EXAMPLES

 use Games::Maze;

 #
 # Create and print the maze and the solution to the maze.
 #
 my $minos = Games::Maze->new(dimensions => [15, 15, 3]);
 $minos->make();
 print "\n\nThe Maze...\n", scalar($minos->to_ascii());
 $minos->solve();
 print "\n\nThe Solution...\n", scalar($minos->to_ascii()), "\n";

 #
 # We're curious about the maze properties.
 #
 my %p = $minos->describe();

 foreach (sort keys %p)
 {
    if (ref $p{$_} eq "ARRAY")
    {
        print "$_ => [", join(", ", @{$p{$_}}), "]\n";
    }
    else
    {
        print "$_ => ", $p{$_}, "\n";
    }
 }

 exit(0);

=head1 AUTHOR

John M. Gamble may be found at B<jgamble@cpan.org>

=cut
