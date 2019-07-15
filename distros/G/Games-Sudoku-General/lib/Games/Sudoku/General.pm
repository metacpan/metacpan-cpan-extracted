=head1 NAME

Games::Sudoku::General - Solve sudoku-like puzzles.

=head1 SYNOPSIS

 $su = Games::Sudoku::General->new ();
 print $su->problem(<<eod)->solution();
 3 . . . . 8 . 2 .
 . . . . . 9 . . .
 . . 2 7 . 5 . . .
 2 4 . 5 . . 8 . .
 . 8 5 . 7 4 . . 6
 . 3 . . . . 9 4 .
 1 . 4 . . . . 7 2
 . . 6 9 . . . 5 .
 . 7 . 6 1 2 . . 9
 eod

=head1 DESCRIPTION

This package solves puzzles that involve the allocation of symbols
among a number of sets, such that no set contains more than one of
any symbol. This class of problem includes the puzzles known as
'Sudoku', 'Number Place', and 'Wasabi'.

Each Sudoku puzzle is considered to be made up of a number of cells,
each of which is a member of one or more sets, and each of which may
contain exactly one symbol. The contents of some of the cells are
given, and the problem is to deduce the contents of the rest of the
cells.

Although such puzzles as Sudoku are presented on a square grid, this
package does not assume any particular geometry. Instead, the topology
of the puzzle is defined by the user in terms of a list of the sets
to which each cell belongs. Some topology generators are provided, but
the user has the option of hand-specifying an arbitrary topology.

Even on the standard 9 x 9 Sudoku topology there are variants in which
unspecified cells are constrained in various ways (odd/even, high/low).
Such variants are accommodated by defining named sets of allowed
symbols, and then giving the set name for each unoccupied cell to which
it applies. See the C<allowed_symbols> attribute for more
information and an example.

This module is able not only to solve a variety of Sudoku-like
puzzles, but to 'explain' how it arrived at its solution. The
steps() method, called after a solution is generated, lists in order
what solution constraints were applied, what cell each constraint
is applied to, and what symbol the cell was constrained to.

Test script t/sudoku.t demonstrates these features. ActivePerl users
will have to download the kit from L<http://www.cpan.org/>  or
L<https://metacpan.org/release/Games-Sudoku-General> to get this
file.

=head2 Exported symbols

No symbols are exported by default, but the following things are
available for export:

  Status values exported by the :status tag
    SUDOKU_SUCCESS
      This means what you think it does.
    SUDOKU_NO_SOLUTION
      This means the method exhausted all possible
      soltions without finding one
    SUDOKU_TOO_HARD
      This means the iteration_limit attribute was
      set to a positive number and the solution()
      method hit the limit without finding a solution.

The :all tag is provided for convenience, but it exports the same
symbols as :status.

=head2 Attributes

Games::Sudoku::General objects have the following attributes, which may
normally be accessed by the get() method, and changed by the set()
method.

In parentheses after the name of the attribute is the word "boolean",
"number" or "string", giving the data type of the attribute. Booleans
are interpreted in the Perl sense: undef, 0, and '' are false, and
anything else is true. The parentheses may also contain the words
"read-only" to denote a read-only attribute or "write-only" to denote
a write-only attribute.

In general, the write-only attributes exist as a convenience to the
user, and provide a shorthand way to set a cluster of attributes at
the same time. At the moment all of them are concerned with generating
problem topologies, which are a real pain to specify by hand.

=over

=item allowed_symbols (string)

This attribute names and defines sets of allowed symbols which may
appear in empty cells. The set definitions are whitespace-delimited
and each consists of a string of the form 'name=symbol,symbol...'
where the 'name' is the name of the set, and the symbols are a list
of the symbols valid in a cell to which that set applies.

For example, if you have an odd/even puzzle (i.e. you are given that
at least some of the unoccupied cells are even or odd but not both),
you might want to

 $su->set (allowed_symbols => <<eod);
 o=1,3,5,7,9
 e=2,4,6,8
 eod

and then define the problem like this:

 $su->problem (<<eod);
 1 o e o e e o e 3
 o o e o 6 e o o e
 e e 3 o o 1 o e e
 e 7 o 1 o e e o e
 o e 8 e e o 5 o o
 o e o o e 3 e 4 o
 e o o 8 o o 6 o e
 o o o e 1 e e e o
 6 e e e o o o o 7
 eod

To eliminate an individual allowed symbol set, set it to an empty
string (e.g. $su->set (allowed_symbols => 'o=');). To eliminate all
symbol sets, set the entire attribute to the empty string.

Allowed symbol set names may not conflict with symbol names. If you set
the symbol attribute, all allowed symbol sets are deleted, because
that seemed to be the most expeditious way to enforce this restriction
across a symbol set change.

Because symbol set names must be parsed like symbol names when a
problem is defined, they also affect the need for whitespace on
problem input. See the L<problem()|/problem> documentation for
full details.

=item autocopy (boolean)

If true, this attribute causes the generate() method to implicitly call
copy() to copy the generated problem to the clipboard.

This attribute is false by default.

=item brick (string, write-only)

This "virtual" attribute is a convenience, which causes the object to be
configured with a topology of rows, columns, and rectangles. The value
set must be either a comma-separated list of two numbers (e.g.  '3,2')
or a reference to a list containing two numbers (e.g. [3, 2]). Either
way, the numbers represent the horizontal dimension of the rectangle (in
columns) and the vertical dimension of the rectangle (in rows). The
overall size of the puzzle square is the product of these.  For example,

 $su->set( brick => [ 3, 2 ] )

generates a topology that looks like this

 +-------+-------+
 | x x x | x x x |
 | x x x | x x x |
 +-------+-------+
 | x x x | x x x |
 | x x x | x x x |
 +-------+-------+
 | x x x | x x x |
 | x x x | x x x |
 +-------+-------+


Originally there was a third argument giving the total size of the
puzzle. Beginning with version 0.006 this was deprecated, since it
appeared to me to be redundant. As of version 0.021, all uses of this
argument resulted in a warning. As of version 0.022, use of the third
argument will become fatal.

Setting this attribute modifies the following "real" attributes:

 columns is set to the size of the big square;
 symbols is set to "." and the numbers "1", "2",
   and so on, up to the size of the big square;
 topology is set to represent the rows,  columns,
   and small rectangles in the big square, with row
   sets named "r0", "r1", and so on, column sets
   named "c0", "c1", and so on, and small
   rectangle sets named "s0", "s1", and so on for
   historical reasons.

=item columns (number)

This attribute defines the number of columns of data to present in a
line of output when formatting the topology attribute, or the solution
to a puzzle.

=item corresponding (number, write-only)

This "virtual" attribute is a convenience, which causes the object
to be configured for "corresponding-cell" Sudoku. The topology is
the same as C<set( sudoku => ... )>, but in addition corresponding
cells in the small squares must have different values. The extra set
names are "u0", "u1", and so on.

This kind of puzzle is also called "disjoint groups."

=item cube (string, write-only)

This "virtual" attribute is a convenience, which causes the object to
be configured for cubical sudoku. The string is either a number, or
'full', or 'half'.

* a number sets the topology to a Dion cube of the given order.
That is,

 sudokug> set cube 3

generates a 9 x 9 x 9 Dion cube, with the small squares being 3 x 3.
The problem is entered in plane, row, and column order, as though you
were entering the required number of normal Sudoku puzzles
back-to-back.

* 'full' generates a topology that includes all faces of the cube. The
sets are the faces of the cube, and the rows, columns, and (for lack
of a better word) planes of cells that circle the cube.

To enter the problem, imagine the cube unfolded to make a Latin cross.
Then, enter the problem in order by faces, rows, and columns, top to
bottom and left to right. The order of entry is actually by cell
number, as given below.

               +-------------+
               |  0  1  2  3 |
               |  4  5  6  7 |
               |  8  9 10 11 |
               | 12 13 14 15 |
 +-------------+-------------+-------------+
 | 16 17 18 19 | 32 33 34 35 | 48 49 50 51 |
 | 20 21 22 23 | 36 37 38 39 | 52 53 54 55 |
 | 24 25 26 27 | 40 41 42 43 | 56 57 58 59 |
 | 28 29 30 31 | 44 45 46 47 | 60 61 62 63 |
 +-------------+-------------+-------------+
               | 64 65 66 67 |
               | 68 69 70 71 |
               | 72 73 74 75 |
               | 76 77 78 79 |
               +-------------+
               | 80 81 82 83 |
               | 84 85 86 87 |
               | 88 89 90 91 |
               | 92 93 94 95 |
               +-------------+

The solution will be displayed in order by cell number, with line
breaks controlled by the C<columns> attribute, just
like any other solution presented by this package.

I have seen such puzzles presented with the bottom square placed to the
right and rotated counterclockwise 90 degrees. You will need to perform
the opposite rotation when you enter the problem.

* 'half' generates a topology that looks like an isometric view of a
cube, with the puzzle on the visible faces. The faces are divided in
half, since the set size here is 8, not 16. Imagine the isometric
unfolded to make an L-shape. Then, enter the problem in order by faces,
rows, and columns, top to bottom and left to right. The order of entry
is actually in order by cell number, as given below.

 +-------------------+
 |  0    1    2    3 |
 |                   |
 |  4    5    6    7 |
 +-------------------+
 |  8    9   10   11 |
 |                   |
 | 12   13   14   15 |
 +---------+---------+-------------------+
 | 16   17 | 18   19 | 32   33   34   35 |
 |         |         |                   |
 | 20   21 | 22   23 | 36   37   38   39 |
 |         |         +-------------------+
 | 24   25 | 26   27 | 40   41   42   43 |
 |         |         |                   |
 | 28   29 | 30   31 | 44   45   46   47 |
 +---------+---------+-------------------+

The solution will be displayed in order by cell number, with line
breaks controlled by the C<columns> attribute, just
like any other solution presented by this package.

For the 'full' and 'half' cube puzzles, the C<columns> attribute is
set to 4, and the C<symbols> attribute to the numbers 1
to the size of the largest set (16 for the full cube, 8 for the half
or isometric cube). I have seen full cube puzzles done with hex digits
0 to F; these are handled most easily by setting the
C<symbols> attribute appropriately:

 $su->set (cube => 'full', symbols => <<eod);
 . 0 1 2 3 4 5 6 7 8 9 A B C D E F
 eod

=item debug (number)

This attribute, if not 0, causes debugging information to be displayed.
Values other than 0 are not supported, in the sense that the author
makes no commitment what will happen when a non-zero value is set, and
further reserves the right to change this behavior without notice of
any sort, and without documenting the changes.

=item generation_limit (number)

This attribute governs how hard the generate() method tries to generate
a problem. If generate() cannot generate a problem after this number of
tries, it gives up.

The default is 30.

=item iteration_limit (number)

This attribute governs how hard the solution() method tries to solve
a problem. An iteration is an attempt to use the backtrack constraint.
Since what this really counts is the number of times we place a
backtrack constraint on the stack, not the number of values generated
from that constraint, I suspect 10 to 20 is reasonable for a "normal"
sudoku problem.

The default is 0, which imposes no limit.

=item largest_set (number, read-only)

This read-only attribute returns the size of the largest set defined by
the current topology.

=item latin (number, write-only)

This "virtual" attribute is a convenience, which causes the object to
be configured to handle a Latin square. The value gives the size of
the square. Setting this modifies the following "real" attributes:

 columns is set to the size of the square;
 symbols is set to "." and the letters "A", "B",
   and so on, up to the size of the square;
 topology is set to represent the rows and columns
   of a square, with row sets named "r0", "r1",
   and so on, and the column sets named "c0",
   "c1", and so on.

=item max_tuple (number)

This attribute represents the maximum-sized tuple to consider for the
tuple constraint. It is possible that one might want to modify this
upward for large puzzles, or downward for small ones.

The default is 4, meaning that the solution considers doubles, triples,
and quads only.

=item name (string)

This attribute is for information, and is not used by the class.

=item null (string, write-only)

This "virtual" attribute is a convenience, which causes the object to
be configured with the given number of cells, but no topology. The
topology must be added later using the add_set method once for each
set of cells to be created.

The value must be either a comma-separated list of one to three numbers
(e.g. '81,9,9') or a reference to a list containing one to three
numbers (e.g. [81, 9, 9]). The first (and only required) number gives the
number of cells. The second, if supplied, sets the 'columns' attribute,
and the third, if supplied, sets the 'rows' attribute. For example,

 $su->set (null => [36, 6]);
 $su->add_set (r0 => 0, 1, 2, 3, 4, 5);
 $su->add_set (r1 => 6, 7, 8, 9, 10, 11);
 ...
 $su->add_set (c0 => 0, 6, 12, 18, 24, 30);
 $su->add_set (c1 => 1, 7, 13, 19, 25, 31);
 ...
 $su->add_set (s0 => 0, 1, 2, 6, 7, 8);
 $su->add_set (s1 => 3, 4, 5, 9, 10, 11);
 ...

Generates the topology equivalent to

 $su->set (brick => [3, 2])

=item output_delimiter (string)

This attribute specifies the delimiter to be used between cell values
on output. The default is a single space.

=item quincunx (text, write-only)

This "virtual" attribute is a convenience, which causes the object to be
configured as a quincunx (a. k. a. 'Samurai Sudoku' at
L<http://www.samurai-sudoku.com/>). The value must be
either a comma-separated list of one to two numbers (e.g. '3,1') or a
reference to a list of one to two numbers (e.g. [3, 1]). In either case,
the numbers are the order of the quincunx (3 corresponding to the usual
'Samurai Sudoku' configuration), and the gap between the arms of the
quincunx, in small squares. The gap must be strictly less than the
order, and the same parity (odd or even) as the order. If the gap is not
specified, it defaults to the smallest possible.

To be specific,

 $su->set(quincunx => 3)

is equivalent to

 $su->set(quincunx => [3, 1])

and both specify the 'Samurai Sudoku' configuration.

The actual topology is set up as a square of (2 * order + gap) * order
cells on a side, with the cells in the gap being unused. The sets used
are the same as for sudoku of the same order, but with 'g0' through 'g4'
prepended to their names, with g0 being the top left sudoku grid, g1 the
top right, g2 the middle, g3 the bottom left, and g4 the bottom right.

In the case of the 's' sets, this would result in duplicate sets being
generated in the overlap area, so the 's' set from the higher-numbered
grid is suppressed. For example, in the 'Samurai Sudoku' configuration,
sets g0s8, g1s6, g2s6, and g2s8 contain exactly the same cells as g2s0,
g2s2, g3s2, and g4s0 respectively, so the latter are suppressed, and
only the former appear in the topology.

Problems are specified left-to-right by rows. The cells in the gaps are
unused, and are not specified. For example, the May 2, 2008 'Samurai
Sudoku' problem could be specified as

 . . .  . . 1  . . .         . . .  4 . .  . . .
 . . .  . 3 .  6 . .         . . 7  . 2 .  . . .
 . . .  7 . .  . 5 .         . 4 .  . . 5  . . .

 . . 6  9 . .  . . 7         6 . .  . . 9  1 . .
 . 5 .  . 2 .  . 4 .         . 2 .  . 5 .  . 9 .
 4 . .  . . 5  2 . .         . . 8  1 . .  . . 7

 . 2 .  . . 4  . . .  . 8 .  . . .  3 . .  . 2 .
 . . 5  . 6 .  . . .  4 . 5  . . .  . 8 .  4 . .
 . . .  1 . .  . . .  . 7 .  . . .  . . 7  . . .

               . 4 .  . 6 .  . 2 .
               6 . 7  8 . 9  4 . 1
               . 1 .  . 4 .  . 3 .

 . . .  7 . .  . . .  . 9 .  . . .  . . 6  . . .
 . . 8  . 2 .  . . .  2 . 8  . . .  . 8 .  5 . .
 . 4 .  . . 3  . . .  . 5 .  . . .  3 . .  . 2 .

 2 . .  . . 7  8 . .         . . 4  1 . .  . . 6
 . 3 .  . 5 .  . 4 .         . 3 .  . 2 .  . 4 .
 . . 4  8 . .  . . 7         2 . .  . . 3  1 . .

 . . .  9 . .  . 1 .         . 5 .  . . 8  . . .
 . . .  . 6 .  9 . .         . . 7  . 4 .  . . .
 . . .  . . 4  . . .         . . .  2 . .  . . .


Setting this attribute causes the rows and columns attributes to be set
to (2 * order + gap) * order. The symbols attribute is set to '.' and
the numbers 1, 2, ... up to order * order.

=item rows (number)

This attribute defines the number of lines of output to present before
inserting a blank line (for readability) when formatting the topology
attribute, or the solution to a puzzle.

=item status_text (text, read-only)

This attribute is a short piece of text corresponding to the
status_value.

=item status_value (number)

The solution() method sets a status, which can be retrieved via this
attribute. The retrieved value is one of

    SUDOKU_SUCCESS
      This means what you think it does.
    SUDOKU_NO_SOLUTION
      This means the method exhausted all possible
      soltions without finding one
    SUDOKU_TOO_HARD
      This means the iteration_limit attribute was
      set to a positive number and the solution()
      method hit the limit without finding a solution.

=item sudoku (number, write-only)

This attribute is a convenience, which causes the object to be
configured to handle a standard Sudoku square. The value gives the size
of the small squares into which the big square is divided. The big
square's side is the square of the value.

For example, the customary Sudoku topology is set by

 $su->set (sudoku => 3);

This attribute is implemented in terms of C<set( brick => ... )>,
and modifies the same "real" attributes. See the C<brick> attribute for
the details.

=item sudokux (number, write-only)

This attribute is a convenience. It is similar to the 'sudoku'
attribute, but the topology includes both main diagonals (set names
'd0' and 'd1') in addition to the standard sets. See the
C<brick> attribute for the details, since that's ultimately how this
attribute is implemented.

=item symbols (string)

This attribute defines the symbols to be used in the puzzle. Any
printing characters may be used except ",". Multi-character symbols
are supported. The value of the attribute is a whitespace-delimited
list of the symbols, though the whitespace is optional if all symbols
(and symbol constraints if any) are a single character. See the
L<problem()|/problem> documentation for full details.

The first symbol in the list is the one that represents an empty cell.
Except for this, the order of the symbols is immaterial.

The symbols defined here are used only for input or output. It is
perfectly legitimate to set symbols, call the problem() method, and
then change the symbols. The solution() method will return solutions
in the new symbol set. I have no idea why you would want to do this.

=item topology (string)

This attribute defines the topology of the puzzle, in terms of what
sets each cell belongs to. Each cell is defined in terms of a
comma-delimited list of the names of the sets it belongs to, and
the string is a whitespace-delimited list of cell definitions. For
example, a three-by-three grid with diagonals can be defined as
follows in terms of sets r1, r2, and r3 for the rows, c1, c2, and
c3 for the columns, and d1 and d2 for the diagonals:

 r1,c1,d1 r1,c2       r1,c3,d2
 r2,c1    r2,c2,d1,d2 r2,c3
 r3,c1,d2 r3,c2       r3,c3,d1

The parser treats line breaks as whitespace. That is to say, the
above definition would be the same if it were all on one line.

You do not need to define the sets themselves anywhere. The
package defines each set as it encounters it in the topology
definition.

For certain topologies (e.g. the London Times Quincunx) it may be
convenient to include in the definition cells that are not part of the
puzzle. Such unused cells are defined by specifying just a comma,
without any set names.

Setting the topology invalidates any currently-set-up problem.

=back

=head2 Methods

This package provides the following public methods:

=cut

package Games::Sudoku::General;

use 5.006002;	# For 'our', at least.

use strict;
use warnings;

use Exporter qw{ import };

our $VERSION = '0.023';
our @EXPORT_OK = qw{
    SUDOKU_SUCCESS
    SUDOKU_NO_SOLUTION
    SUDOKU_TOO_HARD
    SUDOKU_MULTIPLE_SOLUTIONS
};
our %EXPORT_TAGS = (
    all => \@EXPORT_OK,
    status => \@EXPORT_OK,
);
use Carp;
use Data::Dumper;
use List::Util qw{first max reduce};
use POSIX qw{floor};

use constant SUDOKU_SUCCESS => 0;
use constant SUDOKU_NO_SOLUTION => 1;
use constant SUDOKU_TOO_HARD => 2;
use constant SUDOKU_MULTIPLE_SOLUTIONS => 3;

my @status_values = (
    'Success',
    'No solution found',
    'No solution found before exceeding iteration limit',
    'Multiple solutions found',
);

use constant HASH_REF	=> ref {};

=head2 new

 $su = Games::Sudoku::General->new ()

This method instantiates a new Games::Sudoku::General object. Any
arguments are passed to the set() method. If, after processing
the arguments, the object does not have a topology,

  $self->set (sudoku => 3)

is called. If there is no symbols setting (which could happen
if the user passed an explicit topology),

  $self->set (symbols => join ' ', '.',
    1 .. $self->get ('largest_set'))

is called. If, after all this, there is still no columns setting,
the number of columns is set to the number of symbols, excluding
the "empty cell" symbol.

The newly-instantiated object is returned.

=cut

sub new {
    my ($class, @args) = @_;
    ref $class and $class = ref $class;
    my $self = bless {
	debug => 0,
	generation_limit => 30,
	iteration_limit => 0,
	output_delimiter => ' ',
    }, $class;
    @args and $self->set (@args);
    $self->{cell} or $self->set (sudoku => 3);
    $self->{symbol_list}
	or $self->set (symbols => join ' ', '.', 1 .. $self->{largest_set});
    defined $self->{columns}
	or $self->set (columns => @{$self->{symbol_list}} - 1);
    defined $self->{status_value}
	or $self->set (status_value => SUDOKU_SUCCESS);
    defined $self->{max_tuple}
	or $self->set (max_tuple => 4);
    return $self;
}

=head2 add_set

 $su->add_set ($name => $cell ...)

This method adds to the current topology a new set with the given name,
and consisting of the given cells. The set name must not already
exist, but the cells must already exist. In other words, you can't
modify an existing set with this method, nor can you add new cells.

=cut

sub add_set {
    my ($self, $name, @cells) = @_;
    $self->{set}{$name} and croak <<eod;
Error - Set '$name' already exists.
eod
    foreach my $inx (@cells) {
	$self->{cell}[$inx] or croak <<eod
Error - Cell $inx does not exist.
eod
    }
    foreach my $inx (@cells) {
	my $cell = $self->{cell}[$inx];
	@{$cell->{membership}} or --$self->{cells_unused};
	foreach my $other (@{$cell->{membership}}) {
	    my $int = join ',', sort $other, $name;
	    $self->{intersection}{$int} ||= [];
	    push @{$self->{intersection}{$int}}, $inx;
	}
	@{$cell->{membership}} = sort $name, @{$cell->{membership}};
    }
    $self->{set}{$name} = {
	name => $name,
	membership => [sort @cells],
    };
    $self->{largest_set} = max ($self->{largest_set},
	scalar @{$self->{set}{$name}{membership}});
    delete $self->{backtrack_stack};	# Force setting of new problem.
    return $self;
}


=head2 constraints_used

 %constraints_used = $su->constraints_used;

This method returns a hash containing the constraints used in the most
recent call to solution(), and the number of times each was used. The
constraint codes are the same as for the steps() method. If called in
scalar context it returns a string representing the constraints used
at least once, in canonical order (i.e. in the order documented in the
steps() method).

B<Note:> As of version 0.002, the string returned by the scalar has
spaces delimiting the constraint names. They were not delimited in
version 0.001

=cut

sub constraints_used {
    my ( $self ) = @_;
    return unless $self->{constraints_used} && defined wantarray;
    return %{$self->{constraints_used}} if wantarray;
    my $rslt = join ' ', grep {
	$self->{constraints_used}{$_}} qw{F N B T X Y W ?};
    return $rslt;
}


=head2 copy

 $su->copy ()

This method copies the current problem to the clipboard. If solution()
has been called, the current solution goes on the clipboard.

See L<CLIPBOARD SUPPORT|/CLIPBOARD SUPPORT> for what is needed for this
to work.

=cut

{	# Local symbol block.
    my $copier;
    sub copy {
	my ( $self ) = @_;
	( $copier ||= eval {
		require Clipboard;
		Clipboard->import();
		sub {
		    Clipboard->copy( join '', @_ );
		    return;
		};
	    }
	) or croak 'copy() unavailable; can not load Clipboard';
	$copier->( $self->_unload() );
	return $self;
    }
}

=head2 drop_set

 $su->drop_set( $name )

This method removes from the current topology the set with the given
name. The set must exist, or an exception is raised.

=cut

sub drop_set {
    my ($self, $name) = @_;
    $self->{set}{$name} or croak <<eod;
Error - Set '$name' not defined.
eod
    foreach my $inx (@{$self->{set}{$name}{membership}}) {
	my $cell = $self->{cell}[$inx];
	my @mbr;
	foreach my $other (@{$cell->{membership}}) {
	    if ($other ne $name) {
		push @mbr, $other;
		my $int = join ',', sort $other, $name;
		delete $self->{intersection}{$int};
	    }
	}
	if (@mbr) {
	    @{$cell->{membership}} = sort @mbr;
	} else {
	    @{$cell->{membership}} = ();
	    $self->{cells_unused}++;
	}
    }
    delete $self->{set}{$name};
    $self->{largest_set} = 0;
    foreach (keys %{$self->{set}}) {
	$self->{largest_set} = max ($self->{largest_set},
	    scalar @{$self->{set}{$_}{membership}});
    }
    delete $self->{backtrack_stack};	# Force setting of new problem.
    return $self;
}


=head2 generate

 $problem = $su->generate( $min, $max, $const );

This method generates a problem and returns it.

The $min argument is the minimum number of givens in the puzzle. You
may (and probably will) get more. The default is the number of cells
in the puzzle divided by the number of sets a cell belongs to.

The value of this argument is critical to getting a puzzle: too large
and you generate puzzles with no solution; too small and you spend all
your time backtracking. There is no science behind the default, just an
attempt to make a rational heuristic based on the number of degrees of
freedom and the observation that about a third of the cells are given
in a typical Sudoku puzzle. My experience with the default is:

 topology        comment
 brick 3,2       default is OK
 corresponding 3 default is OK
 cube 3          default is too large
 cube half       default is OK
 cube full       default is OK
 quincunx 3      default is too large
 sudoku 3        default is OK
 sudoku 4        default is OK
 sudokux 3       default is OK

Typically when I take the defaults I get a puzzle in anywhere from
a few seconds (most of the listed topologies) to a couple minutes
(sudoku 4) on an 800 Mhz G4. But I have never successfully generated
a Dion cube (cube 3). C<Caveat user.>

The $max argument is the maximum number of givens in the puzzle. You
may get less. The default is 1.5 times the minimum.

The $const argument specifies the constraints to be used in the
generated puzzle. This may be specified either as a string or as a hash
reference. If specified as a string, it is a whitespace-delimited list,
with each constraint name possibly followed by an equals sign and a
number to specify that that constraint can be used only a certain
number of times. For example, 'F N ?=1' specifies a puzzle to be
solved by use of any number of applications of the F and N constraints,
and at most one guessed cell. If specified as a hash reference, the
keys are the constraint names, and the values are the usage counts,
with undef meaning no limit. The hash reference corresponding to
'F N ?=1' is {F => undef, N => undef, '?' => 1}. The default for this
argument is to allow all known constraints except '?'.

In practice, the generator usually generates puzzles solvable using
only the F constraint, or the F and N constraints.

The algorithm used is to generate a puzzle with the minimum number of
cells selected at random, and then solve it. If a solution does not
exist, we try again until we have tried
C<generation_limit> times, then we return undef.
B<This means generate() is not guaranteed to generate a puzzle.>

If we get a solution, we remove allowed constraints. If we run into
a constraint that is not allowed, we either stop (if we're below the
maximum number of givens) or turn it into a given value (if we're
above the maximum). We stop unconditionally if we get down to the
minimum number of givens. As a side effect, the generated puzzle is
set up as a problem.

Note that if you allow guesses you may get puzzles with more than
one solution.

=cut

sub generate {
    my ( $self, $min, $max, $const ) = @_;
    my $size = @{$self->{cell}} - $self->{cells_unused};
    $min ||= do {
	floor( $size * $size /
	    ( $self->{largest_set} * keys %{ $self->{set} } ) );
    };
    $max ||= floor( $min * 1.5 );
    $const ||= 'F N B T';
    croak <<"EOD" if ref $const && HASH_REF ne ref $const;
Error - The constraints argument must be a string or a hash reference,
    not a @{[ref $const]} reference.
EOD
    $const = {map {my @ret; $_ and do {
	    @ret = split '=', $_, 2; push @ret, undef while @ret < 2}; @ret}
	    split '\s+', $const}
	unless HASH_REF eq ref $const;
    $self->{debug} and do {
	local $Data::Dumper::Terse = 1;
	print <<eod;
Debug generate ($min, $max, @{[Dumper $const]})
eod
    };
    my $syms = @{$self->{symbol_list}} - 1;
    croak <<eod if $min > $size;
Error - You specified a minimum of $min given values, but the puzzle
        only contains $size cells.
eod
    my $tries = $self->{generation_limit};
    $size = @{$self->{cell}};	# Note equivocation on $size.
    local $Data::Dumper::Terse = 1;
    my @universe = $self->{cells_unused} ?
	grep {@{$self->{cell}[$_]{membership}}} (0 .. @{$self->{cell}} - 1) :
	(0 .. @{$self->{cell}} - 1);
    while (--$tries >= 0) {
	$self->problem ();	# We rely on this specifying an empty problem.
##	my @ix = (0 .. $size - 1);
	my @ix = @universe;
	my $gen = 0;
	while ($gen++ < $min) {
	    my ($inx) = splice @ix, floor (rand scalar @ix), 1;
	    my $cell = $self->{cell}[$inx];
##	    @{$cell->{membership}} or redo;	# Ignore unused cells.
	    my @pos = grep {!$cell->{possible}{$_}} 1 .. $syms or next;
	    my $val = $pos[floor (rand scalar @pos)];
	    defined $val or confess <<eod, Dumper ($cell->{possible});
Programming error  - generate() selected an undefined value for cell $inx.
        Possible values hash is:
eod
	    $self->_try ($cell, $val)
		and confess <<eod, Dumper ($cell->{possible});
Programming error - generate() tried to assign $val to cell $inx,
         but it was rejected. Possible values hash is:
eod
	}
	$self->solution () or next;
	$self->_constraint_remove ($min, $max, $const);
	my $prob = $self->_unload ('', SUDOKU_SUCCESS);
	$self->problem ($prob);
	$self->copy ($prob) if $self->{autocopy};
	return $prob;
    }
    return;
}

my %accessor = (
    allowed_symbols => \&_get_allowed_symbols,
    autocopy => \&_get_value,
    columns => \&_get_value,
    debug => \&_get_value,
    generation_limit => \&_get_value,
##    ignore_unused => \&_get_value,
    iteration_limit => \&_get_value,
    largest_set => \&_get_value,
    name => \&_get_value,
    output_delimiter => \&_get_value,
    rows => \&_get_value,
    status_text => \&_get_value,
    status_value => \&_get_value,
    symbols => \&_get_symbols,
    topology => \&_get_topology,
);

=head2 get

 $value = $su->get( $name );

This method returns the value of the named attribute. An exception
is thrown if the given name does not correspond to an attribute that
can be read. That is, the given name must appear on the list of
attributes above, and not be marked "write-only".

If called in list context, you can pass multiple attribute names,
and get back a list of their values. If called in scalar context,
attribute names after the first are ignored.

=cut

sub get {
    my ($self, @args) = @_;
    my @rslt;
    wantarray or @args = ($args[0]);
    foreach my $name (@args) {
	exists $accessor{$name} or croak <<eod;
Error - Attribute $name does not exist, or is write-only.
eod
	push @rslt, $accessor{$name}->($self, $name);
    }
    return wantarray ? @rslt : $rslt[0];
}

sub _get_allowed_symbols {
    my ( $self ) = @_;
    my $rslt = '';
    my $syms = @{$self->{symbol_list}};
    foreach (sort keys %{$self->{allowed_symbols}}) {
	my @symlst;
	for (my $val = 1; $val < $syms; $val++) {
	    push @symlst, $self->{symbol_list}[$val]
		if $self->{allowed_symbols}{$_}[$val];
	}
	$rslt .= "$_=@{[join ',', @symlst]}\n";
    }
    return $rslt;
}

sub _get_symbols {
    my ( $self ) = @_;
    return join ' ', @{$self->{symbol_list}};
}

sub _get_topology {
    my ( $self ) = @_;
    my $rslt = '';
    my $col = $self->{columns};
    my $row = $self->{rows} ||= floor (@{$self->{cell}} / $col);
    foreach (map {join (',', @{$_->{membership}}) || ','} @{$self->{cell}}) {
	$rslt .= $_;
	if (--$col > 0) {
	    $rslt .= ' '
	} else {
	    $rslt .= "\n";
	    $col = $self->{columns};
	    if (--$row <= 0) {
		$rslt .= "\n";
		$row = $self->{rows};
	    }
	}
    }
    0 while chomp $rslt;
    $rslt .= "\n";
    return $rslt;
}

sub _get_value {return $_[0]->{$_[1]}}


=head2 paste

 $su->paste()

This method pastes a problem from the clipboard.

See L<CLIPBOARD SUPPORT|/CLIPBOARD SUPPORT> for what is needed for this
to work.

=cut

{	#	Begin local symbol block

    my $paster;
    sub paste {
	my ( $self ) = @_;
	( $paster ||= eval {
		require Clipboard;
		Clipboard->import();
		return sub {
		    return Clipboard->paste();
		};
	    }
	) or croak 'paste() unavailable; can not load Clipboard';

	$self->problem( $paster->() );
	$self->_unload();
	return $self;
    }


}	#	End local symbol block

=head2 problem

 $su->problem( $string );

This method specifies the problem to be solved, and sets the object
up to solve the problem.

The problem is specified by a whitespace-delimited list of the symbols
contained by each cell. You can format the puzzle definition into a
square grid (e.g. the SYNOPSIS section), but to the parser a  line
break is no different than spaces. If you pass an empty string, an
empty problem will be set up - that is, one in which all cells are
empty.

An exception will be thrown if:

 * The puzzle definition uses an unknown symbol;
 * The puzzle definition has a different number
   of cells from the topology definition;
 * There exists a set with more members than the
   number of symbols, excluding the "empty"
   symbol.

The whitespace delimiter is optional, provided that all symbol names
are exactly one character long, B<and> that you have not defined any
symbol constraint names more than one character long since the last
time you set the symbol names.

=cut

sub problem {
    my ( $self, $val ) = @_;
    $val ||= '';
    $val =~ m/\S/ or
	$val = "$self->{symbol_list}[0] " x
	(scalar @{$self->{cell}} - $self->{cells_unused});
    $val =~ s/\s+//g unless $self->{biggest_spec} > 1;
    $val =~ s/^\s+//;
    $val =~ s/\s+$//;
    $self->{debug} and print <<eod;
Debug problem - Called with $val
eod

    local $Data::Dumper::Terse = 1;
    $self->{largest_set} >= @{$self->{symbol_list}} and croak <<eod;
Error - The largest set has $self->{largest_set} cells, but there are only @{[
		@{$self->{symbol_list}} - 1]} symbols.
        Either the set definition is in error or the list of symbols is
        incomplete.
eod

    my $syms = @{$self->{symbol_list}};
    foreach (@{$self->{cell}}) {
	$_->{content} = $_->{chosen} = 0;
	$_->{possible} = {map {$_ => 0} (1 .. $syms - 1)};
    }
    foreach (values %{$self->{set}}) {
	$_->{free} = @{$_->{membership}};
	$_->{content} = [$_->{free}];
    }
    $self->{cells_unassigned} = scalar @{$self->{cell}} - $self->{cells_unused};

    my $hash = $self->{symbol_hash};
    my $inx = 0;
    my $max = @{$self->{cell}};
    foreach (split (($self->{biggest_spec} > 1 ? '\s+' : ''), $val)) {
	$inx >= $max and croak <<eod;
Error - Too many cell specifications. The topology allows only $max.
eod
	next unless defined $_;
	# was $self->{ignore_unused}
	($self->{cells_unused} && !@{$self->{cell}[$inx]{membership}})
	    and do {$inx++; redo};
	$self->{allowed_symbols}{$_} and do {
	    $self->{debug} > 1 and print <<eod;
Debug problem - Cell $inx allows symbol set $_
eod
	    my $cell = $self->{cell}[$inx];
	    @{$cell->{membership}} or croak <<eod;
Error - Cell $inx is unused, and must be specified as empty.
eod
	    for (my $val = 1; $val < $syms; $val++) {
		next if $self->{allowed_symbols}{$_}[$val];
		$cell->{possible}{$val} = 1;
	    }
	};
	defined $hash->{$_} or $_ = $self->{symbol_list}[0];
	(@{$self->{cell}[$inx]{membership}} ||
	    $_ eq $self->{symbol_list}[0])
	    or croak <<eod;
Error - Cell $inx is unused, and must be specified as empty.
eod
	$self->{debug} > 1 and print <<eod;
Debug problem - Cell $inx specifies symbol $_
eod
	$self->_try ($inx, $hash->{$_}) and croak <<eod;
Error - Symbol '$_' appears more than once in a set.
        The problem loaded thus far is:
@{[$self->_unload ('        ')]}
eod
	$self->{cell}[$inx]{chosen} = $hash->{$_} ? 1 : 0;
    } continue {
	$inx++;
    }

    unless ($inx == $max) {
	# was $self->{ignore_unused}
	$self->{cells_unused} and do {
	    $inx -= $self->{cells_unused};
	    $max -= $self->{cells_unused};
	};
	croak <<eod;
Error - Not enough cell specifications. you gave $inx but the topology
        defined $max.
eod
    }

    $self->{constraints_used} = {};

    $self->{debug} and print <<eod;
Debug problem - problem loaded.
eod

    $self->{backtrack_stack} = [];
    $self->{cell_order} = [];
    delete $self->{no_more_solutions};

    $self->{debug} > 1 and print "         object = ", Dumper ($self);

    return $self;
}

my %mutator = (
    allowed_symbols => \&_set_allowed_symbols,
    autocopy => \&_set_value,
    brick => \&_set_brick,
    columns => \&_set_number,
    debug => \&_set_number,
    corresponding => \&_set_corresponding,
    cube => \&_set_cube,
    generation_limit => \&_set_number,
##    ignore_unused => \&_set_value,
    iteration_limit => \&_set_number,
    latin => \&_set_latin,
    max_tuple => \&_set_number,
    name => \&_set_value,
    null => \&_set_null,
    output_delimiter => \&_set_value,
    quincunx => \&_set_quincunx,
    rows => \&_set_number,
    status_value => \&_set_status_value,
    sudoku => \&_set_sudoku,
    sudokux => \&_set_sudokux,
    symbols => \&_set_symbols,
    topology => \&_set_topology,
);

=head2 set

 $su->set( $name => $value );

This method sets the value of the named attribute. An exception
is thrown if the given name does not correspond to an attribute that
can be written. That is, the given name must appear on the list of
attributes above, and not be marked "read-only". An exception is
also thrown if the value is invalid, e.g. a non-numeric value for
an attribute marked "number".

You can pass multiple name-value pairs. If an exception is thrown,
all settings before the exception will be made, and all settings
after the exception will not be made.

The object itself is returned.

=cut

sub set {
    my ( $self, @args ) = @_;
    while ( @args ) {
	my ( $name, $val ) = splice @args, 0, 2;
	exists $mutator{$name} or croak <<eod;
Error - Attribute $name does not exist, or is read-only.
eod
	$mutator{$name}->($self, $name, $val );
    }
    return $self;
}

sub _set_allowed_symbols {
##  my ( $self, $name, $value ) = @_;
    my ( $self, undef, $value ) = @_;	# Name unused
    defined $value or $value = '';
    my $maxlen = 0;
    $self->{debug} and print <<eod;
Debug allowed_symbols being set to '$value'
eod
    if ($value) {
	foreach (split '\s+', $value) {
	    my ($name, $value) = split '=', $_, 2;
	    croak <<eod if $self->{symbol_hash}{$name};
Error - You can not use '$name' as a symbol constraint name, because
        it is a valid symbol name.
eod
	    $value or do {delete $self->{allowed_symbols}{$name}; next};
	    $maxlen = max ($maxlen, length ($name));
	    $self->{debug} > 1 and print <<eod;
Debug allowed_symbols - $_
        set name '$name' has length @{[length ($name)]}. Maxlen now $maxlen.
eod
	    my $const = $self->{allowed_symbols}{$name} = [];
	    foreach (split ',', $value) {
		$self->{debug} > 1 and print <<eod;
Debug allowed_symbols - Adding symbol '$_' to set '$name'.
eod
		$self->{symbol_hash}{$_} or croak <<eod;
Error - '$_' is not a valid symbol.
eod
		$const->[$self->{symbol_hash}{$_}] = 1;
	    }
	}
    } else {
	$self->{allowed_symbols} = {};
    }
    $self->{biggest_spec} = $maxlen if $maxlen > $self->{biggest_spec};
    return;
}

sub _set_brick {
    my ( $self, undef, $value ) = @_;	# $name unused
    my ($horiz, $vert, $size) = ref $value ? @$value : split ',', $value;
    defined $size
	and $self->_deprecation_notice( 'brick_third_argument' );
    $size ||= $horiz * $vert;
    ($size % $horiz || $size % $vert) and croak <<eod;
Error - The puzzle size $size must be a multiple of both the horizontal
        brick size $horiz and the vertical brick size $vert.
eod
    my $rowmul = floor ($size / $horiz);
    my $syms = '.';
    my $topo = '';
    for (my $row = 0; $row < $size; $row++) {
	$syms .= " @{[$row + 1]}";
	for (my $col = 0; $col < $size; $col++) {
	    $topo .= sprintf ' r%d,c%d,s%d', $row, $col,
		    floor ($row / $vert) * $rowmul + floor ($col / $horiz);
	}
    }
    substr ($topo, 0, 1, '');
    $self->set (columns => $size,  rows => $size, symbols => $syms,
	topology => $topo);
    return;
}

sub _set_corresponding {
##  my ( $self, $name, $order ) = @_;
    my ( $self, undef, $order ) = @_;	# Name unused
    my $size = $order * $order;
    $self->set (sudoku => $order);
    my $order_minus_1 = $order - 1;
    my $offset = $size * $order;
    for (my $inx = 0; $inx < $size; $inx++) {
	my $base = floor ($inx / $order) * $size + $inx % $order;
	$self->add_set ("u$inx", map {
	    my $g = $_ * $offset + $base;
	    (map {$_ * $order + $g} 0 .. $order_minus_1)} 0 .. $order_minus_1);
    }
    return;
}

my %cube = (
    full => <<eod,
c0,r0,s0 c1,r0,s0 c2,r0,s0 c3,r0,s0
c0,r1,s0 c1,r1,s0 c2,r1,s0 c3,r1,s0
c0,r2,s0 c1,r2,s0 c2,r2,s0 c3,r2,s0
c0,r3,s0 c1,r3,s0 c2,r3,s0 c3,r3,s0
p0,r0,s1 p0,r1,s1 p0,r2,s1 p0,r3,s1
p1,r0,s1 p1,r1,s1 p1,r2,s1 p1,r3,s1
p2,r0,s1 p2,r1,s1 p2,r2,s1 p2,r3,s1
p3,r0,s1 p3,r1,s1 p3,r2,s1 p3,r3,s1
c0,p0,s2 c1,p0,s2 c2,p0,s2 c3,p0,s2
c0,p1,s2 c1,p1,s2 c2,p1,s2 c3,p1,s2
c0,p2,s2 c1,p2,s2 c2,p2,s2 c3,p2,s2
c0,p3,s2 c1,p3,s2 c2,p3,s2 c3,p3,s2
p0,r3,s3 p0,r2,s3 p0,r1,s3 p0,r0,s3
p1,r3,s3 p1,r2,s3 p1,r1,s3 p1,r0,s3
p2,r3,s3 p2,r2,s3 p2,r1,s3 p2,r0,s3
p3,r3,s3 p3,r2,s3 p3,r1,s3 p3,r0,s3
c0,r3,s4 c1,r3,s4 c2,r3,s4 c3,r3,s4
c0,r2,s4 c1,r2,s4 c2,r2,s4 c3,r2,s4
c0,r1,s4 c1,r1,s4 c2,r1,s4 c3,r1,s4
c0,r0,s4 c1,r0,s4 c2,r0,s4 c3,r0,s4
c0,p3,s5 c1,p3,s5 c2,p3,s5 c3,p3,s5
c0,p2,s5 c1,p2,s5 c2,p2,s5 c3,p2,s5
c0,p1,s5 c1,p1,s5 c2,p1,s5 c3,p1,s5
c0,p0,s5 c1,p0,s5 c2,p0,s5 c3,p0,s5
eod
    half => <<eod,
r0,c0,s0 r0,c1,s0 r0,c2,s0 r0,c3,s0
r1,c0,s0 r1,c1,s0 r1,c2,s0 r1,c3,s0
r2,c0,s1 r2,c1,s1 r2,c2,s1 r2,c3,s1
r3,c0,s1 r3,c1,s1 r3,c2,s1 r3,c3,s1
p0,c0,s2 p0,c1,s2 p0,c2,s3 p0,c3,s3
p1,c0,s2 p1,c1,s2 p1,c2,s3 p1,c3,s3
p2,c0,s2 p2,c1,s2 p2,c2,s3 p2,c3,s3
p3,c0,s2 p3,c1,s2 p3,c2,s3 p3,c3,s3
p0,r3,s4 p0,r2,s4 p0,r1,s4 p0,r0,s4
p1,r3,s4 p1,r2,s4 p1,r1,s4 p1,r0,s4
p2,r3,s5 p2,r2,s5 p2,r1,s5 p2,r0,s5
p3,r3,s5 p3,r2,s5 p3,r1,s5 p3,r0,s5
eod
);

sub _set_cube {
##  my ( $self, $name, $type ) = @_;
    my ( $self, undef, $type ) = @_;	# Name unused
    if ($type =~ m/\D/) {
	$cube{$type} or croak <<eod;
Error - Cube type '$type' is not defined. Legal values are numeric (for
        Dion cube), or one of @{[join ', ', map {"'$_'"} sort keys %cube]}
eod
	$self->set (topology => $cube{$type}, columns => 4, rows => 4);
    } else {
	my $size = $type * $type;
	my $topo = '';
	for (my $x = 0; $x < $size; $x++) {
	    for (my $y = 0; $y < $size; $y++) {
		for (my $z = 0; $z < $size; $z++) {
		    $topo .= join (',',
			    _cube_set_names ($type, x => $x, $y, $z),
			    _cube_set_names ($type, y => $y, $z, $x),
			    _cube_set_names ($type, z => $z, $x, $y)) . ' ';
		}
	    }
	}
	$self->set (topology => $topo, columns => $size, rows => $size);
    }
    $self->set (symbols => join ' ', '.', 1 .. $self->{largest_set});
    return;
}

sub _cube_set_names {
    my ( $order, $name, $x, $y, $z ) = @_;
    my $tplt = sprintf '%s%d%%s%%d', $name, $x;
    return map {sprintf $tplt, @$_} [r => $y], [c => $z],
	[s => floor ($y / $order) * $order + floor ($z / $order)]
}

sub _set_latin {
##  my ( $self, $name, $size ) = @_;
    my ( $self, undef, $size ) = @_;	# Name unused
    my $syms = '.';
    my $topo = '';
    my $letter = 'A';
    for (my $row = 0; $row < $size; $row++) {
	$syms .= " @{[$letter++]}";
	for (my $col = 0; $col < $size; $col++) {
	    $topo .= sprintf ' r%d,c%d', $row, $col;
	}
    }
    substr ($topo, 0, 1, '');
    $self->set (columns => $size, rows => $size, symbols => $syms,
	topology => $topo);
    return;
}

sub _set_null {
##  my ( $self, $name, $value ) = @_;
    my ( $self, undef, $value ) = @_;	# Name unused
    my ($size, $columns, $rows) = ref $value ? @$value : split ',', $value;
    $self->{cell} = [];		# The cells themselves.
    $self->{set} = {};		# The sets themselves.
    $self->{largest_set} = 0;
    $self->{intersection} = {};
    $self->{cells_unused} = $size;
    foreach my $cell_inx (0 .. $size - 1) {
	my $cell = {membership => [], index => $cell_inx};
	push @{$self->{cell}}, $cell;
    }
    delete $self->{backtrack_stack};	# Force setting of new problem.
    defined $columns and $self->set (columns => $columns);
    defined $rows and $self->set (rows => $rows);
    return;
}

sub _set_number {
    my ( $self, $name, $value ) = @_;
    _looks_like_number ($value) or croak <<eod;
Error - Attribute $name must be numeric.
eod
    $self->{$name} = $value;
    return;
}

sub _set_quincunx {
##  my ( $self, $name, $value ) = @_;
    my ( $self, undef, $value ) = @_;	# Name unused
    my ($order, $gap) = ref $value ? @$value : split ',', $value;
    $order =~ m/\D/ and croak <<eod;
Error - The quincunx order must be an integer.
eod
    if (defined $gap) {
	$gap =~ m/\D/ and croak <<eod;
Error - The quincunx gap must be an integer.
eod
	$gap > $order - 2 and croak <<eod;
Error - The quincunx gap must not be greater than the order ($order) - 2.
eod
	$gap % 2 == $order % 2 or croak <<eod;
Error - The gap must be the same parity (odd or even) as the order.
eod
    } else {
	$gap = $order % 2;
    }
    my $cols = ($order * 2 + $gap) * $order;
    $self->set(null => [$cols * $cols, $cols, $cols]);
    my $osq = $order * $order;
    $self->set(symbols => join (' ', '.', 1 .. $osq));
    my @squares = do {	# Squares in terms of index of top left corner
	my $offset = ($order + $gap) * $order;
	my $inset = ($order - ($order - $gap) / 2) * $order;
	(
	    0,					# Top left square
	    $offset,				# Top right square
	    $inset * $cols + $inset,		# Middle square
	    $offset * $cols,			# Bottom left square
	    $offset * ($cols + 1),		# Bottom right square
	)
    };
    my $limit = $osq - 1;
    my @colinx = map {$_ * $cols} 0 .. $limit;
    my @sqinx = map {$_ .. $_ + $order - 1} map {$_ * $cols} 0 .. $order - 1;
    my @sqloc = map {$_ * $order} @sqinx;
    my @sqgened;	# 's' sets generated, by origin cell.
    # Crete the row, column, and square sets. These have the same names
    # as those created by the corresponding 'sudoku' topology, but with
    # 'g0' .. 'g4' prepended, representing the five individual
    # 'standard' sudoku grids. For topology 'quincunx 3', the top left
    # cell is in sets g0c0,g0r0,g0s0, the top right in g1c8,g1r0,g1s2,
    # and so on. Because some of the 's' sets are duplicates, the
    # higher-numbered ones are supressed. In topology 'quincunx 3', set
    # g0s8 is the same as g2s0, so the latter is supressed.
    foreach my $grid (0 .. $#squares) {
	my $sqr = $squares[$grid];
	foreach my $inx (0 .. $limit) {
	    my $offset = $inx * $cols;
	    my $o1 = $offset + $sqr;
	    $self->add_set("g${grid}r$inx" => $o1 .. $o1 + $limit);
	    $self->add_set("g${grid}c$inx" => map {$_ + $inx + $sqr}
		@colinx);
	    $o1 = $sqloc[$inx] + $sqr;
	    $sqgened[$o1]++
		or $self->add_set("g${grid}s$inx" => map {$_ + $o1}
		@sqinx);
	}
    }
    return;
}

sub _set_status_value {
    my ( $self, $name, $value ) = @_;
    _looks_like_number ($value) or croak <<eod;
Error - Attribute $name must be numeric.
eod
    ($value < 0 || $value >= @status_values) and croak <<eod;
Error - Attribute $name must be greater than or equal to 0 and
        less than @{[scalar @status_values]}
eod
    $self->{status_value} = $value;
    $self->{status_text} = $status_values[$value];
    return;
}

sub _set_sudoku {
##  my ( $self, $name, $order ) = @_;
    my ( $self, undef, $order ) = @_;	# Name unused
    $self->set( brick => [ $order, $order ] );
    return;
}

sub _set_sudokux {
##  my ( $self, $name, $order ) = @_;
    my ( $self, undef, $order ) = @_;	# Name unused
    $self->set (sudoku => $order);
    my $size = $order * $order;
    my $size_minus_1 = $size - 1;
    my $size_plus_1 = $size + 1;
    $self->add_set (d0 => map {$_ * $size_plus_1} 0 .. $size_minus_1);
    $self->add_set (d1 => map {$_ * $size_minus_1} 1 .. $size);
    return;
}

sub _set_symbols {
##  my ( $self, $name, $value ) = @_;
    my ( $self, undef, $value ) = @_;	# Name unused
    my @lst = split '\s+', $value;
    my %hsh;
    my $inx = 0;
    my $maxlen = 0;
    foreach (@lst) {
	defined $_ or next;
	m/,/ and croak <<eod;
Error - Symbols may not contain commas.
eod
	exists $hsh{$_} and croak <<eod;
Error - Symbol '$_' specified more than once.
eod
	$hsh{$_} = $inx++;
	$maxlen = max ($maxlen, length ($_));
    }
    $self->{symbol_list} = \@lst;
    $self->{symbol_hash} = \%hsh;
    $self->{symbol_number} = scalar @lst;
    $self->{biggest_spec} = $self->{biggest_symbol} = $maxlen;
    $self->{allowed_symbols} = {};
    return;
}

sub _set_topology {
##  my ( $self, $name, @args ) = @_;
    my ( $self, undef, @args ) = @_;	# Name unused
    $self->{cell} = [];		# The cells themselves.
    $self->{set} = {};		# The sets themselves.
    $self->{largest_set} = 0;
    $self->{intersection} = {};
    $self->{cells_unused} = 0;
    my $cell_inx = 0;
    foreach my $cell_def (map {split '\s+', $_} @args) {
	my $cell = {membership => [], index => $cell_inx};
	push @{$self->{cell}}, $cell;
	foreach my $name (sort grep {$_ ne ''} split ',', $cell_def) {
	    foreach my $other (@{$cell->{membership}}) {
		my $int = "$other,$name";
		$self->{intersection}{$int} ||= [];
		push @{$self->{intersection}{$int}}, $cell_inx;
	    }
	    push @{$cell->{membership}}, $name;
	    my $set = $self->{set}{$name} ||=
		    {name => $name, membership => []};
	    push @{$set->{membership}}, $cell_inx;
	    $self->{largest_set} = max ($self->{largest_set},
		scalar @{$set->{membership}});
	}
	@{$cell->{membership}} or $self->{cells_unused}++;
	$cell_inx++;
    }
    delete $self->{backtrack_stack};	# Force setting of new problem.
    return;
}

sub _set_value {$_[0]->{$_[1]} = $_[2]; return;}


=head2 solution

 $string = $su->solution();

This method returns the next solution to the problem, or undef if there
are no further solutions. The solution is a blank-delimited list of the
symbols each cell contains, with line breaks as specified by the
'columns' attribute. If the problem() method has not been called,
an exception is thrown.

Status values set:

  SUDOKU_SUCCESS
  SUDOKU_NO_SOLUTION
  SUDOKU_TOO_HARD

=cut

sub solution {
    my ( $self ) = @_;

    $self->{backtrack_stack} or croak <<eod;
Error - You cannot call the solution() method unless you have specified
        the problem via the problem() method.
eod

    $self->{debug} and print <<eod;
Debug solution - entering method. Stack depth = @{[
	scalar @{$self->{backtrack_stack}}]}
eod

    return $self->_constrain ();
}


=head2 steps

 $string = $su->steps();

=for comment help syntax-highlighting editor "

This method returns the steps taken to solve the problem. If no
solution was found, it returns the steps taken to determine this. If
called in list context, you get an actual copy of the list. The first
element is the name of the constraint applied:

 F = forced: only one value works in this cell;
 N = numeration or necessary: this is the only cell
     that can supply the given value;
 B = box claim: if a candidate number appears in only
     one row or column of a given box, it can be
     eliminated as a candidate in that row or column
     but outside that box;
 T = tuple, which is a generalization of the concept
     pair, triple, and so on. These come in two
     varieties for a given size of the tuple N:
   naked: N cells contain among them N values, so
     no cells outside the tuple can supply those
     values.
   hidden: N cells contain N values which do not
     occur outside those cells, so any other values
     in the tuple are supressed.
 ? = no constraint: generated in backtrack mode.

See L<http://www.research.att.com/~gsf/sudoku/> and
L<http://www.angusj.com/sudoku/hints.php> for fuller
definitions of the constraints and how they are applied.

The second value is the cell number, as defined by the topology
setting. For the 'sudoku' and 'latin' settings, the cells are
numbered from zero, row-by-row. If you did your own topology, the
first cell you defined is 0, the second is 1, and so on.

The third value is the value assigned to the cell. If returned in
list context, it is the number assigned to the cell's symbol. If
in scalar context, it is the symbol itself.

=for comment help syntax-highlighting editor "

=cut

sub steps {
    my ( $self ) = @_;
    return wantarray ? (@{$self->{backtrack_stack}}) :
	defined wantarray ?
	    $self->_format_constraint (@{$self->{backtrack_stack}}) :
	undef;
}

=head2 unload

 $string = $su->unload();

This method returns either the current puzzle or the current solution,
depending on whether the solution() method has been called since the
puzzle was loaded.

=cut

sub unload {
    my ( $self ) = @_;
    return $self->_unload ()
}

########################################################################

#	Private methods and subroutines.


#	$status_value = $su->_constrain ();

#	This method applies all possible constraints to the current
#	problem, placing them on the backtrack stack. The backtrack
#	algorithm needs to remove these when backtracking. The return
#	is false if we ran out of constraints, or true if we found
#	a constraint that could not be satisfied.

my %constraint_method = (
    '?' => '_constraint_backtrack',
);

sub _constrain {
    my ( $self ) = @_;
    my $stack = $self->{backtrack_stack} ||= [];	# May hit this
							# when initializing.
    my $used = $self->{constraints_used} ||= {};
    my $iterations;
    $iterations = $self->{iteration_limit}
	if $self->{iteration_limit} > 0;

    $self->{no_more_solutions} and
	return $self->_unload (undef, SUDOKU_NO_SOLUTION);

    @{$self->{backtrack_stack}} and do {
	$self->_constraint_remove and
	    return $self->_unload (undef, SUDOKU_NO_SOLUTION);
    };

    $self->{cells_unassigned} or do {
	$self->{no_more_solutions} = 1;
	return $self->_unload ('', SUDOKU_SUCCESS);
    };

    my $number_of_cells = @{$self->{cell}};

constraint_loop:
    {	# Begin outer constraint loop.

	foreach my $constraint (qw{F N B T ?}) {
	    confess <<eod if @{$self->{cell}} != $number_of_cells;
Programming error - Before trying $constraint constraint.
        We started with $number_of_cells cells, but now have @{[
	scalar @{$self->{cell}}]}.
eod
	    my $method = $constraint_method{$constraint} ||
		    "_constraint_$constraint";
	    my $rslt = $self->$method () or next;
	    @$rslt or next;
	    foreach my $constr (@$rslt) {
		if (ref $constr) {
		    push @$stack, $constr;
		    $used->{$constr->[0]}++
		} else {
		    my $rslt = $self->_constraint_remove or
			redo constraint_loop;
		    return $self->_unload ('', $rslt);
	        }
	    }
	    $self->{cells_unassigned} or
		return $self->_unload ('', SUDOKU_SUCCESS);
	    redo constraint_loop;
	}

    }	# end outer constraint loop.

    $self->set (status_value => SUDOKU_TOO_HARD);
    return;
}

#	Constraint executors:
#	These all return a reference to the constraints to be stacked,
#	provided progress was made. Otherwise they return 0. At the
#	point a contradiction is found, they push 'backtrack' on the
#	end of the list to be returned, and return immediately.


#	F constraint - only one value possible. Unlike the other
#	constraints, we keep iterating this one until we make no
#	progress.

sub _constraint_F {
    my ( $self ) = @_;
    my @stack;
    my $done = 1;

    while ($done) {
	$done = 0;
	my $inx = 0;				# Cell index.
	foreach my $cell (@{$self->{cell}}) {
	    next if $cell->{content};		# Skip already-assigned cells.
	    next unless @{$cell->{membership}};	# Skip unused cells.
	    my $pos = 0;
	    foreach (values %{$cell->{possible}}) {$_ or $pos++};
	    if ($pos > 1) {			# > 1 possibility. Can't apply.
	    } elsif ($pos == 1) {		# Exactly 1 possibility. Apply.
		my $val;
		foreach (keys %{$cell->{possible}}) {
		    next if $cell->{possible}{$_};
		    $val = $_;
		    last;
		}
		$self->_try ($cell, $val) and confess <<eod;
Programming error - Passed 'F' constraint but _try failed.
eod
		my $constraint = [F => [$inx, $val]];
		$self->{debug} and
		    print '#    ', $self->_format_constraint ($constraint);
		$done++;
		push @stack, $constraint;
		$self->{cells_unassigned} or do {$done = 0; last};
	    } else {				# No possibilities. Backtrack.
		$self->{debug} and print <<eod;
Debug - Cell $inx has no possible values. Backtracking.
eod
		$self->{debug} > 1 and do {
		    local $Data::Dumper::Terse = 1;
		    print Dumper $cell;
		};
		push @stack, 'backtrack';
		$done = 0;
		last;
	    }
	} continue {
	    $inx++;
	}
    }
    return \@stack;
}


#	N constraint - the only cell which supplies a necessary value.

sub _constraint_N {
    my ( $self ) = @_;
    while (my ($name, $set) = each %{$self->{set}}) {
	my @suppliers;
	foreach my $inx (@{$set->{membership}}) {
	    my $cell  = $self->{cell}[$inx];
	    next if $cell->{content};
	    # No need to check @{$cell->{membership}}, since the cell is
	    # known to be a member of set $name.
	    while (my ($val, $count) = each %{$cell->{possible}}) {
		next if $count;
		$suppliers[$val] ||= [];
		push @{$suppliers[$val]}, $inx;
	    }
	}
	my $limit = @suppliers;
	for (my $val = 1; $val < $limit; $val++) {
	    next unless $suppliers[$val] && @{$suppliers[$val]} == 1;
	    my $inx = $suppliers[$val][0];
	    $self->_try ($inx, $val) and confess <<eod, $self->{debug} ? <<eod : ();
Programming error - Cell $inx passed 'N' constraint but try of
        $self->{symbol_list}[$val] failed.
eod
@{[$self->_unload
]}         set: $name
        cell: @{[Dumper ($self->{cell}[$inx])]}
eod
	    my $constraint = [N => [$inx, $val]];
	    $self->{debug} and
		print '#    ', $self->_format_constraint ($constraint);
	    keys %{$self->{set}};	# Reset iterator.
	    return [$constraint];
	}
    }
    return [];
}

#	B constraint - "box claim". Given two sets whose intersection
#	contains more than one cell, if all cells which can contribute
#	a given value to one set are in the intersection, no cell in
#	the second set can contribute that value. Note that this
#	constraint does NOT actually assign a value to a cell, it just
#	eliminates possible values. The name is because on the
#	"standard" sudoku layout one of the sets is always a box; the
#	other can be a row or a column.

sub _constraint_B {
    my ( $self ) = @_;
    my $done = 0;
    while (my ($int, $cells) = each %{$self->{intersection}}) {
	next unless @$cells > 1;
	my @int_supplies;	# Values supplied by the intersection
	my %int_cells;	# Cells in the intersection
	foreach my $inx (@$cells) {
	    next if $self->{cell}[$inx]{content};
	    # No need to check @{$cell->{membership}}, since the cell is
	    # known to be a member of at least two sets.
	    $int_cells{$inx} = 1;
	    while (my ($val, $imposs) = each %{
		    $self->{cell}[$inx]{possible}}) {
		$int_supplies[$val] = 1 unless $imposs;
	    }
	}
	my %ext_supplies;	# Intersection values also supplied outside.
	my %ext_cells;	# Cells not in the intersection.
	my @set_names = split ',', $int;
	foreach my $set (@set_names) {
	    $ext_supplies{$set} = [];
	    $ext_cells{$set} = [];
	    foreach my $inx (@{$self->{set}{$set}{membership}}) {
		next if $int_cells{$inx};	# Skip cells in intersection.
		next if $self->{cell}[$inx]{content};
		push @{$ext_cells{$set}}, $inx;
		while (my ($val, $imposs) = each %{
			$self->{cell}[$inx]{possible}}) {
		    $ext_supplies{$set}[$val] = 1
			if !$imposs && $int_supplies[$val];
		}
	    }
	}
	for (my $val = 1; $val < @int_supplies; $val++) {
	    next unless $int_supplies[$val];
	    my @occurs_in = grep {$ext_supplies{$_}[$val]} @set_names;
	    next unless @occurs_in && @occurs_in < @set_names;
	    my %cells_claimed;
	    foreach my $set (@occurs_in) {
		foreach my $inx (@{$ext_cells{$set}}) {
		    next if $self->{cell}[$inx]{possible}{$val};
		    $cells_claimed{$inx} = 1;
		    $self->{cell}[$inx]{possible}{$val} = 1;
		    $done++;
		}
	    }
	    next unless $done;
	    my $constraint = [B => [[sort keys %cells_claimed], $val]];
	    $self->{debug} and
		print '#    ', $self->_format_constraint ($constraint);
	    keys %{$self->{intersection}};	# Reset iterator.
	    return [$constraint];
	}
    }
    return []
}

#	T constraint - "tuple" (double, triple, quad). These come in
#	two flavors, "naked" and "hidden". Considering only pairs for
#	the moment:
#   A "naked pair" is two cells in the same set which contain the same
#	pair of possibilities, and only those possibilities. These
#	possibilities are then excluded from other cells in the set.
#   A "hidden pair" is when there is a pair of values which can only
#	be contributed to the set by one or the other of a pair of
#	cells. These cells then must supply these values, and any other
#	values supplied by cells in the pair can be eliminated.
#    For higher groups (triples, quads ...) the rules generalize, except
#	that all of the candidate values need not be present in all of
#	the cells under consideration; it is only necessary that none
#	of the candidate values appears outside the cells under
#	consideration.
#
#	Glenn Fowler of AT&T (http://www.research.att.com/~gsf/sudoku/)
#	lumps all these together. But he refers to Angus Johnson
#	(http://www.angusj.com/sudoku/hints.php) for the details, and
#	Angus separates naked and hidden tuples.

sub _constraint_T {
    my ( $self ) = @_;
    my @tuple;		# Tuple indices
    my %vacant;		# Empty cells by set. $vacant{$set} = [$cell ...]
    my %contributors;	# Number of cells which can contrib value, by set.
    my $syms = @{$self->{symbol_list}};

    while (my ($name, $set) = each %{$self->{set}}) {
	my @open = grep {!$_->{content}}
	map {$self->{cell}[$_]} @{$set->{membership}}
	    or next;
	# No need to check @{$_->{membership}} in the grep, since cell
	# $_ is known to be a member of set $name.
	foreach my $cell (@open) {
	    for (my $val = 1; $val < $syms; $val++) {
		$cell->{possible}{$val} and next;
		$contributors{$name} ||= [];
		$contributors{$name}[$val]++;
	    }
	}
	@{$contributors{$name}} = map {$_ || 0} @{$contributors{$name}};
	$vacant{$name} = \@open;
	$tuple[scalar @open] ||= [map {[$_]} 0 .. $#open];
    }

    for (my $order = 2; $order <= $self->{max_tuple}; $order++) {
	for (my $inx = 1; $inx < @tuple; $inx++) {
	    next unless $tuple[$inx];
	    my $max = $inx - 1;
	    $tuple[$inx] = [map {my @tpl = @$_;
		map {[@tpl, $_]} $tpl[-1] + 1 .. $max}
		grep {$_->[-1] < $max} @{$tuple[$inx]}];
	    $tuple[$inx] = undef unless @{$tuple[$inx]};
	}

#	Okay, I have generated the blasted tuples. Now I need to take
#	the union of all values provided by the tuple of cells. If the
#	number of values in this union is equal to the current order, I
#	have potentially found a naked tuple, and if this lets me
#	eliminate any values outside the tuple I can apply the
#	constraint. If the number of values inside the union is greater
#	than the current order, I need to consider whether any tuple of
#	supplied values is not represented outside the cell tuple; if
#	so, I have a hidden tuple and can eliminate the superfluous
#	values.

	foreach my $name (keys %vacant) {
	    my $open = $vacant{$name};
	    next unless $tuple[@$open];
	    my $contributed = $contributors{$name};
	    foreach my $tuple (@{$tuple[@$open]}) {
		my @tcontr;	# number of times each value
				# contributed by the tuple.
		foreach my $inx (@$tuple) {
		    my $cell = $open->[$inx];
		    for (my $val = 1; $val < $syms; $val++) {
			next if $cell->{possible}{$val};
			$tcontr[$val]++;
		    }
		}
		@tcontr = map {$_ || 0} @tcontr;


#	At this point, @tcontr contains how many cells in the tuple
#	contribute each value. Calculate the number of discrete values
#	the tuple can contribute.

#	If the number of discrete values contributed by the tuple is
#	equal to the current order, we have a naked tuple. We have an
#	"effective" naked tuple if at least one of the values
#	contributed by the tuple occurs outside the tuple. We can
#	determine this by subtracting the values in @tcontr from the
#	corresponding values in @$contributed; if we get a positive
#	result for any cell, we have an "effective" naked tuple.

		my $discrete = grep {$_} @tcontr;
		my $constraint;
		my @tuple_member;
		if ($discrete == $order) {
		    for (my $val = 1; $val < @tcontr; $val++) {
			next unless $tcontr[$val] &&
			    $contributed->[$val] > $tcontr[$val];

#	At this point we know we have an "effective" naked tuple.

			$constraint ||= ['T', 'naked', $order];
			@tuple_member or map {$tuple_member[$_] = 1} @$tuple;
			my @ccl;
			for (my $inx = 0; $inx < @$open; $inx++) {
			    next if $tuple_member[$inx] ||
				$open->[$inx]{possible}{$val};
			    $open->[$inx]{possible}{$val} = 1;
			    --$contributed->[$val];
			    push @ccl, $open->[$inx]{index};
			}
			push @$constraint, [\@ccl, $val] if @ccl;
		    }

#	If the number of discrete values is greater than the current
#	order, we may have a hidden tuple. The test for an "effective"
#	hidden tuple involves massaging @tcontr against @$contributed in
#	some way to find a tuple of values within the tuple of cells
#	which do not occur outside it.

		} elsif ($discrete > $order) {
		    my $within = 0;	# Number of values occuring only
					# within tuple.
		    for (my $val = 1; $val < @tcontr; $val++) {
			$within++ if $tcontr[$val] &&
			    $contributed->[$val] == $tcontr[$val];
		    }
		    next unless $within >= $order;
		    $constraint = ['T', 'hidden', $order];
		    map {$tuple_member[$_] = 1} @$tuple;
		    for (my $val = 1; $val < @tcontr; $val++) {
			next unless $tcontr[$val] &&
			    $contributed->[$val] > $tcontr[$val];
			my @ccl;
			for (my $inx = 0; $inx < @$open; $inx++) {
			    next unless $tuple_member[$inx]
				&& !$open->[$inx]{possible}{$val}
				;
			    $open->[$inx]{possible}{$val} = 1;
			    --$contributed->[$val];
			    --$tcontr[$val];
			    push @ccl, $open->[$inx]{index};
			}

			push @$constraint, [\@ccl, $val] if @ccl;
		    }
		}

		next unless $constraint;
		$self->{debug} and
		    print '#    ', $self->_format_constraint ($constraint);
		return [$constraint];
	    }	# Next tuple
	}	# Next set containing vacant cells
    }	# Next order

    return [];
}

# ? constraint - initiate backtracking.

sub _constraint_backtrack {
    my ( $self ) = @_;
##  --$iterations >= 0 or return $self->_unload ('', SUDOKU_TOO_HARD)
##	if defined $iterations;
    my @try;
    my $syms = @{$self->{symbol_list}};
    foreach my $cell (@{$self->{cell}}) {
	next if $cell->{content};
	next unless @{$cell->{membership}};
	my $possible = 0;
	for (my $val = 1; $val < $syms; $val++) {
	    $possible++ unless $cell->{possible}{$val};
	}
	$possible or return ['backtrack'];
	push @try, [$cell, $possible];
    }
    @try = map {$_->[0]} sort {
	$a->[1] <=> $b->[1] || $a->[0]{index} <=> $b->[0]{index}} @try;
    my $cell = $try[0];
    for (my $val = 1; $val < $syms; $val++) {
	next if $cell->{possible}{$val};
	$self->_try ($cell, $val) and confess <<eod;
Programming error - Value $val illegal in cell $cell->{index} for ? constraint, but
        \$self->{possible}{$val} = $self->{possible}{$val}
eod
	my $constraint = ['?' => [$cell->{index}, $val]];
	$self->{debug}
	    and print '#    ', $self->_format_constraint ($constraint);
	return [$constraint];
    }
    return [];
}

#	$status_value = $su->_constraint_remove ();

#	This method removes the topmost constraints from the backtrack
#	stack. It continues until the next item is a backtrack item or
#	the stack is empty. It returns true (SUDOKU_NO_SOLUTION,
#	actually) if the stack is emptied, or false (SUDOKU_SUCCESS,
#	actually) if it stops because it found a backtrack item.

#	The following arguments may be passed, for use in preparing
#	a generated problem:
#	    - minimum number of cells to leave occupied (no lower limit
#		if this is undefined);
#	    - maximum number of cells to leave occupied (no upper limit
#		if this is undefined);
#	    - a reference to a hash of constraints that it is legal to
#		remove. The hash value is the number of times it is
#		legal to remove that constraint, or undef if it can
#		be removed any number of times.

sub _constraint_remove {
    my ( $self, $min, $max, $removal_ok ) = @_;
    $min and $min = @{$self->{cell}} - $min;
    $max and $max = @{$self->{cell}} - $max;
    $self->{no_more_solutions} and return SUDOKU_NO_SOLUTION;
    my $stack = $self->{backtrack_stack} or return SUDOKU_NO_SOLUTION;
    my $used = $self->{constraints_used} ||= {};
    my $inx = @$stack;
    my $syms = @{$self->{symbol_list}};
    ($self->{debug} && $inx) and print <<eod;
# Debug - Backtracking
eod
    my $old = $inx;
    while (--$inx >= 0) {
	($min && $self->{cells_unassigned} >= $min) and do {
	    $self->{debug} and print <<eod;
Debug - Hit minimum occupied cells - returning.
eod
	    return SUDOKU_SUCCESS;
	};
	my $constraint = $stack->[$inx][0];
	if ($removal_ok) {
	    ($max && $self->{cells_unassigned} <= $max &&
##		!$removal_ok->{$constraint} and next;
		!exists $removal_ok->{$constraint}) and next;

	    if (!exists $removal_ok->{$constraint}) {
		$self->{debug} and print <<eod;
Debug - Encountered constraint $constraint - returning.
eod
		return SUDOKU_SUCCESS;
	    } elsif (defined $removal_ok->{$constraint} &&
		    --$removal_ok->{$constraint}) {
		$self->{debug} and print <<eod;
Debug - Reached usage limit on $constraint - returning.
eod
		return SUDOKU_SUCCESS;
	    }
	} else {
	    ($max && $self->{cells_unassigned} <= $max &&
		$constraint eq '?')
		and next;
	}
	--$used->{$constraint};
	if ($constraint eq 'F' || $constraint eq 'N') {
	    foreach my $ref (reverse @{$stack->[$inx]}) {
		$self->_try ($ref->[0], 0) if ref $ref;
	    }
	} elsif ($constraint eq 'B' || $constraint eq 'T') {
	    foreach my $ref (reverse @{$stack->[$inx]}) {
		next unless ref $ref;
		my $val = $ref->[1];
		foreach my $inx (@{$ref->[0]}) {
		    $self->{cell}[$inx]{possible}{$val} = 0;
		}
	    }
	} elsif ($constraint eq '?') {
	    my $start = $stack->[$inx][1][1] + 1;
	    my $cell = $self->{cell}[$stack->[$inx][1][0]];
	    $self->_try ($cell, 0);
	    next if $removal_ok;
	    for (my $val = $start; $val < $syms; $val++) {
		next if $cell->{possible}{$val};
		    $self->_try ($cell, $val) and confess <<eod;
Programming error - Try of $val in cell $cell->{index} failed, but
        \$cell->{possible}[$inx] = $cell->{possible}[$inx]
eod
		$used->{$constraint}++;
		$stack->[$inx][1][0] = $cell->{index};
		$stack->[$inx][1][1] = $val;
		$self->{debug} and do {
		    my $x = $self->_format_constraint ($stack->[$inx]);
		    chomp $x;
		    print <<eod;
# Debug - Backtrack complete. @{[$old - @$stack]} constraints removed.
#         Resuming puzzle at stack depth @{[$inx + 1]} with
#         $self->{cells_unassigned} unassigned cells, guessing
#         $x
eod
		};
		return SUDOKU_SUCCESS;
	    }
	} else {confess <<eod
Programming Error - No code provided to remove constraint '$constraint' from stack.
eod
	}
	pop @$stack;
    }
    $self->{debug} and print <<eod;
# Debug - Backtrack complete. @{[$old - @$stack]} constraints removed.
#         No more solutions to the puzzle exist.
eod
    $self->{no_more_solutions} = 1;
    return SUDOKU_NO_SOLUTION;
}

#	$self->_deprecation_notice( $name );
#
#	This method centralizes deprecation. Deprecation is driven of
#	the %deprecate hash. Level values are:
#	    false - no warning
#	    1 - warn on first use
#	    2 - warn on each use
#	    3 - die on each use.

{

    my %deprecate = (
	brick_third_argument	=> {
	    message	=> 'Specifying 3 values for set( brick => ... ) is no longer allowed',
	    level	=> 3,
	},
    );

    sub _deprecation_notice {
	my ( undef, $name ) = @_;	# Invocant unused
	my $info = $deprecate{$name}
	    or return;
	$info->{level}
	    or return;
	$info->{level} >= 3
	    and croak $info->{message};
	warnings::enabled( 'deprecated' )
	    and carp $info->{message};
	$info->{level} == 1
	    and $info->{level} = 0;
	return;
    }

}

#	_format_constraint formats the given constraint for output.

sub _format_constraint {
    my ($self, @args) = @_;
    my @steps;
    foreach (@args) {
	my @stuff;
	foreach (@$_) {
	    last unless $_;
	    push @stuff, ref $_ ?
		'[' . join (' ',
		    ref $_->[0] ? '[' . join (', ', @{$_->[0]}) . ']' : $_->[0],
		    ref $_->[1] ? '[' . join (', ',
			map {$self->{symbol_list}[$_]} @{$_->[1]}) . ']' :
			$self->{symbol_list}[$_->[1]],
			) . ']' :
		$_;
	}
	push @steps, join (' ', @stuff) . "\n";
    }
    return join '', @steps;
}

#	_looks_like_number is cribbed heavily from
#	Scalar::Util::looks_like_number by Graham Barr. This version
#	only accepts integers, but it is really here because
#	ActivePerl's Scalar::Util is too ancient to export
#	looks_like_number.

sub _looks_like_number {
    ( local $_ ) = @_;
    return 0 if !defined ($_) || ref ($_);
    return 1 if m/^[+-]?\d+$/;
    return 0;
}


#	_set_* subroutines are found right after the set() method.


#	$su->_try ($cell, $value)

#	This method inserts the given value in the given cell,
#	replacing the previous value if any, and doing all the
#	bookkeeping. If the given value is legal (meaning, if
#	it is zero or if it is unique in all sets the cell
#	belongs to), it returns 0. If not, it returns 1, but
#	does not undo the trial.

sub _try {
    my ( $self, $cell, $new ) = @_;
    $cell = $self->{cell}[$cell] unless ref $cell;
    defined $new
	or _fatal (
	"_try called for cell $cell->{index} with new value undefined");
    defined (my $old = $cell->{content}) or _fatal (
	"_try called with old cell $cell->{index} value undefined");
    my $rslt = eval {
	return 0 if $old == $new;
	if ($new) {
	    foreach my $set (@{$cell->{membership}}) {
		return 1 if $self->{set}{$set}{content}[$new];
	    }
	}
	$cell->{content} = $new;
	$old and $self->{cells_unassigned}++;
	$new and --$self->{cells_unassigned};
	foreach my $name (@{$cell->{membership}}) {
	    my $set = $self->{set}{$name};
	    --$set->{content}[$old];
	    $old and do {
		$set->{free}++;
		foreach (@{$set->{membership}}) {
		    --$self->{cell}[$_]{possible}{$old};
		}
	    };
	    $set->{content}[$new]++;
	    $new and do {
		--$set->{free};
		foreach (@{$set->{membership}}) {
		    $self->{cell}[$_]{possible}{$new}++;
		}
	    };
	}
	return 0;
    };
    $@ and _fatal ("Eval failed in _try", $@);
    return $rslt;
}


#	$string = $self->_unload (prefix, status_value)

#	This method unloads the current cell contents into a string.
#	The prefix is prefixed to the string, and defaults to ''.
#	If status_value is specified, it is set. If status_value is
#	specified and it is a failure status, undef is returned, and
#	the current cell contents are ignored.

sub _unload {
    my ($self, $prefix, @args) = @_;
    defined $prefix or $prefix = '';
    @args and do {
	$self->set (status_value => $args[0]);
	$args[0] and return;
    };
    my $rslt = '';
    my $col = $self->{columns};
    my $row = $self->{rows} ||= floor (@{$self->{cell}} / $col);
    my $fmt = "%$self->{biggest_symbol}s";
    foreach (@{$self->{cell}}) {
	$col == $self->{columns} and $rslt .= $prefix;
	# was $self->{ignore_unused}
	$rslt .= ($self->{cells_unused} && !@{$_->{membership}}) ?
	    sprintf ($fmt, ' ') :
	    sprintf ($fmt, $self->{symbol_list}[$_->{content} || 0]);
	if (--$col > 0) {
	    $rslt .= $self->{output_delimiter}
	} else {
	    # was $self->{ignore_unused}
	    $self->{cells_unused} and $rslt =~ s/\s+$//m;
	    $rslt .= "\n";
	    $col = $self->{columns};
	    if (--$row <= 0) {
		$rslt .= "\n";
		$row = $self->{rows};
	    }
	}
    }
    0 while chomp $rslt;
    $rslt .= "\n";
    return $rslt;
}

1;

__END__

=head1 EXECUTABLES

The distribution for this module also contains the script 'sudokug',
which is a command-driven interface to this module.

=head1 CLIPBOARD SUPPORT

Clipboard support is via the L<Clipboard|Clipboard> module. If this is
not installed, the C<copy()> and C<paste()> methods will throw
exceptions.

=head1 BUGS

The X, Y, and W constraints (to use Glenn Fowler's terminology) are
not yet handled. The package can solve puzzles that need these
constraints, but it does so by backtracking.

Please report bugs either through L<http://rt.cpan.org/> or by
mail to the author.

=head1 ACKNOWLEDGMENTS

The author would like to acknowledge the following, without whom this
module would not exist:

Glenn Fowler of AT&T, whose L<http://www.research.att.com/~gsf/sudoku/>
provided the methodological starting point and basic terminology, whose
'sudoku' executable provided a reference implementation for checking
the solutions of standard Sudoku puzzles, and whose constraint taxonomy
data set provided invaluable test data.

Angus Johnson, whose fulsome explanation at
L<http://www.angusj.com/sudoku/hints.php> was a great help
in understanding the mechanics of solving Sudoku puzzles.

Ed Pegg, Jr, whose Mathematical Association of America C<Math Games>
column number 41 for September 5 2005 ("Sudoku Variations",
L<http://mathpuzzle.com/MAA/41-Sudoku%20Variations/mathgames_09_05_05.html>)
provided a treasure trove of 'non-standard' Sudoku puzzles.

=head1 SEE ALSO

The C<Games-LogicPuzzle> package by Andy Adler (see
L<http://metacpan.org/release/Games-LogicPuzzle/>) solves all sorts of
combinatorial puzzles, by backtracking through the puzzle space and
applying a user-supplied function to see whether it has a valid
solution. The examples include a couple Sudoku puzzles.

The C<Games-Sudoku> package by Eugene Kulesha (see
C<http://metacpan.org/release/Games-Sudoku/>) solves the standard 9x9
version of the puzzle. As of June 15 2019 this appears to have been
retracted.

The C<Games-Sudoku-Component> package by Kenichi Ishigaki (see
L<http://metacpan.org/release/Games-Sudoku-Component/>) both
generates and solves the standard 9x9 version of the puzzle.

The C<Games-Sudoku-Component-TkPlayer> by Kenichi Ishigaki (see
L<http://metacpan.org/release/Games-Sudoku-Component-TkPlayer/>). Tk
front end for his Games-Sudoku-Component.

The C<Games-Sudoku-CPSearch> package by Martin-Louis Bright (see
L<https://metacpan.org/release/Games-Sudoku-CPSearch>). Solves 9x9
Sudoku by use of "F" and "N" constraints and backtracking.

The C<Games-Sudoku-Lite package> by Bob O'Neill (see
L<http://metacpan.org/release/Games-Sudoku-Lite/>) solves the standard
9x9 version of the puzzle.

The C<Games-Sudoku-OO> package by Michael Cope (see
L<http://metacpan.org/release/Games-Sudoku-OO/>) also solves the
standard 9x9 version of the puzzle, with an option to solve (to the
extent possible) a single row, column, or square. The implementation may
be extensible to other topologies than the standard one.

The C<Games-Sudoku-Solver> package by Fritz Mehner (see
L<http://metacpan.org/release/Games-Sudoku-Solver/>) solves 9x9 Sudoku
puzzles by recursion and backtracking.

The C<Games-Sudoku-SudokuTk> package by Christian Guine (see
L<http://metacpan.org/release/Games-Sudoku-SudokuTk/> claims to
implement a Tk-based Sudoku solver.

The C<Games-YASudoku> package by Andrew Wyllie (see
L<http://metacpan.org/release/Games-YASudoku/>) also solves the standard
9x9 version of the puzzle. In contrast to the other packages, this one
represents the board as a list of cell/value pairs.

=head1 AUTHOR

Thomas R. Wyant, III (F<wyant at cpan dot org>)

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005-2006, 2008, 2011-2019 by Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

#	Guide to attributes:
#  The following indicators say how each attribute is used:
#    T - The attribute is used to define the topology. It is set by
#        set (topology => string).
#    A - The attribute is set by some setting other than topology.
#    P - The attribute is used to define the problem. It is set by
#        problem();
#    S - The attribute is used to solve the problem.
#
#  T {cell} = []		# A list of the cell definitions.
#  P {cell}[$inx]{content}	# The symbol the cell contains.
#  T {cell}[$inx]{index} = $inx	# The index number of the cell.
#  T {cell}[$inx]{membership} = [] # A list of the names of the sets
#				   # the cell is a member of.
#  P {cell}[$inx]{possible} = {}   # A list of the possible values of
#				   # the cell. Each element is false if
#				   # the value is possible.
#  P {cells_unassigned}		# Number of empty cells remaining
#  T {cells_unused}		# Number of cells which are not members
#				# of any set.
#  S {constraints_used} = {}	# The number of times each constraint
#				# was applied.
#  T {intersection}{$name} = []	# The indices of the cells in the named
#				# intersection. The name is the alpha-
#				# betized set names, comma-separated.
#  T {largest_set}		# The size of the largest set.
#  S {no_more_solutions}	# Cleared when problem set up, set when
#				# we run out of backtrack.
#  T {set} = {}			# A hash of all the set definitions.
#  T {set}{$set}{content} = []	# The contents of the set.
#  T {set}{$set}{membership} = []  # A list of the numbers of the cells
#				   # that are members of the set.
#  T {set}{$set}{name} = $set	# The name of the set.
#  A {allowed_symbols}{$name} = [] # The list contains a 1 if the
#				# symbol's value is allowed under the
#				# named symbol set.
#  A {biggest_spec}		# Number of characters in biggest
#				# symbol or allowed value set name.
#  A {biggest_symbol}		# Number of characters in biggest
#				# symbol.
#  A {symbol_hash} = {}		# A hash of symbols, giving the internal
#				# value for each.
#  A {symbol_list} = []		# A list of the symbols used, in order
#				# by the values used internally.
#  A {symbol_number}		# Number of symbols defined.

# ex: set textwidth=72 :
