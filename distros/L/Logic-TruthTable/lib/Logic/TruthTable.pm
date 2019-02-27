package Logic::TruthTable;

use 5.016001;
use strict;
use warnings;

use Moose;
use Moose::Util::TypeConstraints;
use namespace::autoclean;

use Carp;
use Module::Runtime qw(is_module_name use_module);
use Text::CSV;
use JSON;

use Logic::Minimizer;
use Logic::TruthTable::Convert81 qw(:all);


#
#use Devel::Timer;
# TBD: Parallelize the column-solving. Some
# recommended modules below, choose later.
#
#use Parallel::ForkManager;
# or
#use Parallel::Loops;
# or
#use MCE;
#use Smart::Comments ('###'); 
#

#
# Base class of the Algorithm::<minimizer_name> modules
# which will become the columns' array type.
#
class_type 'ColumnMinimizer',
	{class => 'Logic::Minimizer'};

#
# Define types of 'array of column' and 'array of hashref',
# used to define our table's function columns.
#
subtype 'ArrayRefOfColumnMinimizer',
	as 'ArrayRef[ColumnMinimizer]';

subtype 'ArrayRefOfHashRef',
	as 'ArrayRef[HashRef]';

#
# The width attribute is fed into the
# minimizer object; it cannot be overridden
# by the minimizer's attributes.
#
has 'width' => (
	isa => 'Int', is => 'ro', required => 1
);

#
# The don't-care character, vars, and functions attributes on the
# other hand, are merely defaults and *can* be overridden
# by the object.
#
has 'dc' => (
	isa => 'Str', is => 'rw',
	default => '-'
);

has 'vars' => (
	isa => 'ArrayRef[Str]', is => 'rw', required => 0,
	default => sub{['A' .. 'Z'];},
);

has 'functions' => (
	isa => 'ArrayRef[Str]', is => 'rw', required => 0,
	default => sub{['F0' .. 'F9', 'F10' .. 'F31'];},
);

#
# Used to determine which minimizer object type will be
# created by default for the columns. As of this release,
# only Algorithm::QuineMcCluskey is available, so that is
# the default.
#
has 'algorithm' => (
	isa => 'Str', is => 'ro', required => 0,
	default => 'QuineMcCluskey',
);

#
# The column objects. Either the array ref of hash refs (i.e., the plain
# text), or the algorithm object.
#
has 'columns' => (
	isa => 'ArrayRefOfHashRef|ArrayRefOfColumnMinimizer',
	is => 'ro', required => 1,
	reader => '_get_columns',
	writer => '_set_columns',
	predicate => 'has_columns'
);

#
# The title of the truth table.
#
has 'title' => (
	isa => 'Str', is => 'rw', required => 0,
	predicate => 'has_title'
);

#
# Number of columns (functions). Stored so that we don't have to
# go nuts with array sizing an array reference in an object.
#
has '_fn_width' => (
	isa => 'Int', is => 'rw', required => 0
);

#
# Hash look-up by name instead of by index for column (function)
# or var column.
#
has ['_fn_lookup', '_var_lookup'] => (
	isa => 'HashRef', is => 'rw', required => 0,
);

=head1 NAME

Logic::TruthTable - Create and solve sets of boolean equations.

=head1 VERSION

Version 1.02

=cut

our $VERSION = '1.02';


=head1 SYNOPSIS

Create a truth table.

    #
    # Create a truth table for converting zero to nine (binary)
    # to a 2-4-2-1 code.
    #
    my $tt_2421 = Logic::TruthTable->new(
        width => 4,
        algorithm => 'QuineMcCluskey',
        title => "A four-bit binary to 2-4-2-1 converter",
        vars => ['w' .. 'z'],
        functions => [qw(a3 a2 a1 a0)],
        columns => [
            {
                title => "Column a3",
                minterms => [ 5 .. 9 ],
                dontcares => [ 10 .. 15 ],
            },
            {
                title => "Column a2",
                minterms => [ 4, 6 .. 9 ],
                dontcares => [ 10 .. 15 ],
            },
            {
                title => "Column a1",
                minterms => [ 2, 3, 5, 8, 9 ],
                dontcares => [ 10 .. 15 ],
            },
            {
                title => "Column a0",
                minterms => [ 1, 3, 5, 7, 9 ],
                dontcares => [ 10 .. 15 ],
            },
        ],
    );

    #
    # Get and print the results.
    #
    my @solns = $tt_2421 ->solve();
    print join("\n\n", @solns), "\n";

    #
    # Save the truth table values as a CSV file.
    #
    open my $fh_csv, ">", "twofourtwoone.csv" or die "Error opening CSV file.";
    $tt_2421 ->export_csv(write_handle => \$fh_csv);
    close $fh_csv or warn "Error closing CSV file: $!";

    #
    # Or save the truth table values as a JSON file.
    #
    open my $fh_json, ">", "twofourtwoone.json" or die "Error opening JSON file.";
    $tt_2421 ->export_json(write_handle => \$fh_json);
    close $fh_json or warn "Error closing JSON file: $!";


=head1 Description

This module minimizes tables of 
L<Boolean expressions|https://en.wikipedia.org/wiki/Boolean_algebra> using the
algorithms available on CPAN.

It lets you contain related sets of problems (represented by their columns) in
a single object, along with the variable names, function names, and title.
Methods exist to import from and export to CSV and JSON files.

=head2 Object Methods

=head3 new()

Create the truth table object. The attributes are:

=over 4

=item 'width'

The number of variables (input columns) in the Boolean expressions.

This is a required attribute.

=item 'title'

A title for the problem you are solving.

=item 'dc'

I<Default value: '-'>

Change the representation of the don't-care character. The don't-care
character is used in the columnstring, as character in exported
CSV files, and internally as a place holder for eliminated variables
in the equation, which may be examined with other methods.

This becomes the I<default> value of the function columns; it may be
individually overridden in each C<columns> attribute.

=item 'vars'

I<Default value: ['A' .. 'Z']>

The variable names used to form the equation. The names will be taken from
the leftmost first.

This becomes the I<default> names of the C<vars> attribute of the function
columns; it may be individually overridden in each C<columns> attribute.

=item 'functions'

I<Default value: ['F0' .. 'F9', 'F10' .. 'F31']>

The function names of each equation.

The function name becomes the I<default> title of the individual column
if the column doesn't set a title.

=item 'algorithm'

The default algorithm that will be used to minimize each column.

Currently, there is only one minimizer algorithm (L</Algorithm::QuineMcCluskey>)
available on CPAN, and it is the default.

The name will come from the package name, e.g., having an attribute
C<algorithm =E<gt> 'QuineMcCluskey'> means that the column will be minimized
using the package Algorithm::QuineMcCluskey.

The algorithm module must be installed and be of the form
C<Algorithm::Name>. The module must also have Logic::Minimizer as its
parent class. This ensures that it will have the methods needed by
Logic::TruthTable to create and solve the Boolean expressions.

This becomes the I<default> value of the function columns; it may be
individually overridden in each C<columns>'s attribute.

=item 'columns'

An array of hash references. Each hash reference contains the key/value
pairs used to define the Boolean expression. These are used to create
a minimizer object, which in turn solves the expression.

=item 'minterms'

An array reference of terms representing the 1-values of the
Boolean expression.

=item 'maxterms'

An array reference of terms representing the 0-values of the
Boolean expression. This will also indicate that you want the
expression in product-of-sum form, instead of the default
sum-of-product form.

=item 'dontcares'

An array reference of terms representing the don't-care-values of the
Boolean expression. These represent inputs that simply shouldn't happen
(e.g., numbers 11 through 15 in a base 10 system), and therefore don't
matter to the result.

=item 'columnstring'

Present the entire list of values of the boolean expression as a single
string. The values are ordered from left to right in the string. For example,
a simple two-variable AND equation would have a string "0001".

=back

You can use only one of C<minterms>, C<maxterms>, or C<columnstring>.

The minterms or maxterms do not have to be created by hand; there are
functions in L</Logic::TruthTable::Util> to help create the terms.

=over 4

=item 'dc'

Change the representation of the don't-care character. The don't-care character
is used both in the columnstring, and internally as a place holder for
eliminated variables in the equation. Defaults to the character
defined in the C<Logic::TruthTable> object.

=item 'title'

A title for the expression you are solving. Defaults to the function
name defined in the C<Logic::TruthTable> object.

=item 'vars'

I<Default value: ['A' .. 'Z']>

The variable names used to form the equation. Defaults to the variable
names defined in the C<Logic::TruthTable> object.
 
    #
    # Create a "Rock-Paper-Scissors winners" truth table, using
    # the following values:
    #
    # Columns represent (in two bits) the winner of Rock (01)
    # vs. Paper (10), or vs. Scissors (11). A tie is 00.
    #
    # 
    #        a1 a0 b1 b0 ||  w1 w0
    #       -----------------------
    #  0     0  0  0  0  ||  -  -
    #  1     0  0  0  1  ||  -  -
    #  2     0  0  1  0  ||  -  -
    #  3     0  0  1  1  ||  -  -
    #  4     0  1  0  0  ||  -  -
    #  5     0  1  0  1  ||  0  0    (tie)
    #  6     0  1  1  0  ||  1  0    (paper)
    #  7     0  1  1  1  ||  0  1    (rock)
    #  8     1  0  0  0  ||  -  -
    #  9     1  0  0  1  ||  1  0    (paper)
    # 10     1  0  1  0  ||  0  0    (tie)
    # 11     1  0  1  1  ||  1  1    (scissors)
    # 12     1  1  0  0  ||  -  -
    # 13     1  1  0  1  ||  0  1    (rock)
    # 14     1  1  1  0  ||  1  1    (scissors)
    # 15     1  1  1  1  ||  0  0    (tie)
    #

    use Logic::TruthTable;

    my $ttbl = Logic::TruthTable->new(
        width => 4,
        algorithm => 'QuineMcCluskey',
        title => 'Rock Paper Scissors Winner Results',
        vars => ['a1', 'a0', 'b1', 'b0'],
        functions => ['w1', 'w0'],
        columns => [
            {
                title => 'Bit 1 of the result.',
                minterms => [6, 9, 11, 14],
                dontcares => [0 .. 4, 8, 12],
            },
            {
                title => 'Bit 0 of the result.',
                minterms => [7, 11, 13, 14],
                dontcares => [0 .. 4, 8, 12],
            },
        ],
    );


=back

Alternatively, it is possible to pre-create the algorithm minimizer objects,
and use them directly in the C<columns> array, although it does result in
a lot of duplicated code:

    my $q1 = Algorithm::QuineMcCluskey->new(
        title => "Column 1 of RPS winner results";
        width => 4,
        minterms => [ 2, 3, 5, 8, 9 ],
        dontcares => [ 10 .. 15 ],
        vars => ['w' .. 'z'],
    );
    my $q0 = Algorithm::QuineMcCluskey->new(
        title => "Column 0 of RPS winner results";
        width => 4,
        minterms => [ 1, 3, 5, 7, 9 ],
        dontcares => [ 10 .. 15 ],
        vars => ['w' .. 'z'],
    );

    #
    # Create the truth table using the above
    # Algorithm::QuineMcCluskey objects.
    #
    my $tt_rps = Logic::TruthTable->new(
        width => 4,
        title => 'Rock Paper Scissors Winner Results',
        functions => [qw(w1 w0)],
        columns => [$q1, $q0],
    );

=cut

sub BUILD
{
	my $self = shift;
	my $w = $self->width;
	my @cols = @{$self->_get_columns};
	my @fn_names = @{$self->functions};
	my @vars = @{$self->vars};
	my $dc = $self->dc;

	#
	# Make sure the number of function names and variables
	# get set correctly.
	#
	croak "Not enough function names for your columns" if ($#fn_names < $#cols);

	$#fn_names = $#cols;
	$self->functions(\@fn_names);
	$self->_fn_width($#cols);

	$#vars = $w - 1;
	$self->vars(\@vars);
	$self->title("$w-variable truth table in $#cols columns") unless ($self->has_title);

	#
	# Set up the look-up-by-name hashes.
	#
	$self->_fn_lookup({ map{ $fn_names[$_], $_} (0 .. $#fn_names) });
	$self->_var_lookup({ map{ $vars[$_], $_} (0 .. $#vars) });

	#
	# Set up the individual columns, using defaults
	# from the truth table object, if present.
	#
	for my $idx (0 .. $#cols)
	{
		my %tcol = %{ $cols[$idx] };
		$tcol{width} //= $w;

		croak "Column $idx: width => " . $tcol{width} .
			" doesn't match table's width $w" if ($tcol{width} != $w);
		$tcol{dc} //= $dc;
		$tcol{algorithm} //= $self->algorithm;
		$tcol{vars} //= [@vars];
		$tcol{title} //= $fn_names[$idx];

		${$self->_get_columns}[$idx] = new_minimizer_obj(\%tcol);
	}

	return $self;
}

#
# new_minimizer_obj(%algorithm_options)
#
# Creates a column's object (e.g. an Algorithm::QuineMcCluskey object)
# from the options provided.
#
sub new_minimizer_obj
{
	my($href) = @_;
	my %args = %{$href};
	my $al;

	#
	# Find out which object we're creating.
	#
	($al = $args{algorithm}) =~ s/-/::/;
	$al = "Algorithm::" . $al;

	croak "Invalid module name '$al'" unless (is_module_name($al));

	my $obj = use_module($al)->new(%args);
	croak "Couldn't create '$al' object" unless defined $obj;

	return $obj;
}

=head3 solve()

Run the columns of the truth table through their solving methods. Each column's
solution is returned in a list.

A way to view the solutions would be:

    my @equations = $tt->solve();

    print join("\n", @equations), "\n";

=cut

sub solve
{
	my $self = shift;

	return map {$_->solve()} @{$self->_get_columns};
}

=head3 fnsolve()

Like C<solve()>, run the columns of the truth table through their solving
methods, but store the solutions in a hash table using each column's 
function name as a key.

=cut

sub fnsolve
{
	my $self = shift;
	my(@f) = @{ $self->functions() };
	my %fn;

	$fn{shift @f} = $_ for ($self->solve());

	return %fn;
}


=head3 all_solutions()

It is possible that there's more than one equation that solves a
column's boolean expression. Therefore solve() can return a different
(but equally valid) equation on separate runs.

If you wish to examine all the possible equations that solve an
individual column, you may call all_solutions using the columns name.

    print "All possible equations for column F0:\n";
    print join("\n\t", $tt->all_solutions("F0")), "\n";

=cut

sub all_solutions
{
	my $self = shift;

	if (@_ == 0)
	{
		carp "No column name provided to all_solutions().";
		return ();
	}

	my $col = $self->fncolumn(@_);
	return $col->all_solutions() if (defined $col);
	return ();
}

=head3 fncolumn()

Return a column object by name.

The columns of a C<Logic::TruthTable> object are themselves
objects, of types C<Algorithm::Name>, where I<Name> is the
algorithm, and which may be set using the C<algorithm> parameter
in C<new()>. (As of this writing, the only algorithm availble
in the CPAN ecosystem is C<Algorithm::QuineMcCluseky>.)

Each column is named via the C<functions> attribute in C<new()>, and
a column can be retrieved using its name.

    my $ttable = Logic::TruthTable->new(
        title => "An Example",
        width => 5,
        functions => ['F1', 'F0'],
        columns => [
            {
                minterms => [6, 9, 23, 27],
                dontcares => [0, 2, 4, 16, 24],
            },
            {
                minterms => [7, 11, 19, 23, 29, 30],
                dontcares => [0, 2, 4, 16, 24],
            },
        ],
    );

    my $col_f0 = $ttable->fncolumn('F0');

C<$col_f0> will be an Algorithm::QuineMcCluskey object with minterms
(7, 11, 19, 23, 29, 30).

=cut

sub fncolumn
{
	my $self = shift;
	my($fn_name) = @_;
	my $idx;

	#
	#### Let's look at the key: $fn_name
	#### Let's look at the hash: %{$self->_fn_lookup()}
	#### Let's look an an element: $self->_fn_lookup()->{$fn_name}
	#

	#$idx = %{$self->_fn_lookup()}{$fn_name};
	$idx = $self->_fn_lookup()->{$fn_name};

	return undef unless (defined $idx);
	return ${$self->_get_columns}[$idx];

}

=head3 export_csv()

=head3 export_json()

Write the truth table out as either a CSV file or a JSON file.

In either case, the calling code opens the file and provides the file
handle:

    open my $fh_nq, ">:encoding(utf8)", "nq_6.json"
        or die "Can't open export file: $!";

    $tt->export_json(write_handle => $fh_nq);

    close $fh_nq or warn "Error closing JSON file: $!";

Making your code handle the opening and closing of the file may
seem like an unnecessary inconvenience, but one benefit is that it
allows you to make use of STDOUT:

    $tt->export_csv(write_handle => \*STDOUT, dc => 'X');

A CSV file can store the varible names, function names, minterms,
maxterms, and don't-care terms. The don't-care character of the object
may be overridden with your own choice by using the C<dc> parameter.
Whether the truth table uses minterms or maxterms will have to be a
choice made when importing the file (see L</import_csv()>).

CSV is a suitable format for reading by other programs, such as spreadsheets,
or the program L<Logic Friday|http://sontrak.com/>, a tool for working with
logic functions.

In the example below, a file is being written out for reading
by Logic Friday. Note that Logic Friday insists on its own
don't-care character, which we can set with the 'dc' option:

    if (open my $fh_mwc, ">", "ttmwc.csv")
    {
        #
        # Override the don't-care character, as Logic Friday
        # insists on it being an 'X'.
        #
        $truthtable->export_csv(write_handle => $fh_mwc, dc => 'X');

        close $fh_mwc or warn "Error closing CSV file: $!";
    }
    else
    {
        warn "Error opening CSV file: $!";
    }


The JSON file will store all of the attributes that were in the
truth table, except for the algorithm, which will have to be
set when importing the file.

The options are:

=over 2

=item write_handle

The opened file handle for writing.

=item dc

The don't-care symbol to use in the file. In the case of the CSV file,
becomes the character to write out. In the case of the JSON file, will
become the truth table's default character.

=back

The method returns undef if an error is encountered. On
success it returns the truth table object.

=cut

sub export_csv
{
	my $self = shift;
	my(%opts) = @_;

	my $handle = $opts{write_handle};

	### handle: $handle

	unless (defined $handle)
	{
		carp "export_csv(): no file opened for export.";
		return undef;
	}

	my $w = $self->width;
	my $dc = $opts{dc} // $self->dc;
	my $fmt = "%0${w}b";
	my $lastrow = (1 << $w) - 1;
	my @columns;

	#
	# Set up the array of column strings.
	#
	# If the don't-care character is different from the
	# don't-care character of the columns, convert them.
	#
	### dc: $dc
	#
	for my $c_idx (0 .. $self->_fn_width)
	{
		my $obj = ${$self->_get_columns}[$c_idx];
		my @c = @{$obj->to_columnlist};

		if ($dc ne $obj->dc)
		{
			$_ =~ s/[^01]/$dc/ for (@c);
		}

		push @columns, [@c];
	}

	#
	# Open the CSV file, print out the header, then each row.
	#
	my $csv = Text::CSV->new( {binary => 1, eol => "\012"} );

	unless ($csv)
	{
		carp "Cannot use Text::CSV: " . Text::CSV->error_diag();
		return undef;
	}

	$csv->print($handle, [@{$self->vars}, '', @{$self->functions}]);

	for my $r_idx (0 .. $lastrow)
	{
		my @row = (split(//, sprintf($fmt, $r_idx)), '');

		push @row, shift @{ $columns[$_] } for (0 .. $self->_fn_width);

		$csv->print($handle, [@row]);
	}

	return $self;
}

sub export_json
{
	my $self = shift;
	my(%opts) = @_;

	my $handle = $opts{write_handle};
	my %jhash;
	my @columns;

	$jhash{title} = $self->title;
	$jhash{vars} = $self->vars;
	$jhash{functions} = $self->functions;
	$jhash{width} = $self->width;
	$jhash{dc} = $opts{dc} // $self->dc;
	for my $f (@{ $self->functions })
	{
		my %colhash;
		my $col = $self->fncolumn($f);
		my $isminterms = $col->has_minterms;
		my $terms = $isminterms? $col->minterms: $col->maxterms;

		$colhash{dc} = $col->dc if ($col->dc ne $self->dc and $col->dc ne $jhash{dc});

		$colhash{title} = $col->title;
		$colhash{pack81} =
			terms_to_base81($self->width, $isminterms,
				$terms, $col->dontcares);
		push @columns, {%colhash};
	}
	$jhash{columns} = \@columns;
	my $jstr = encode_json(\%jhash);
	print $handle $jstr;
	return $self;
}

=head3 import_csv()

=head3 import_json()

Read a previously written CSV or JSON file and create a Logic::TruthTable
object from it.

    #
    # Read in a JSON file.
    #
    if (open my $fh_x3, "<:encoding(utf8)", "excess_3.json")
    {
        $truthtable = Logic::TruthTable->import_json(
            read_handle => $fh_x3,
            algorithm => $algorithm,
        );
        close $fh_x3 or warn "Error closing JSON file: $!";
    }


    #
    # Read in a CSV file.
    #
    if (open my $lf, "<", "excess_3.csv")
    {
        $truthtable = Logic::TruthTable->import_csv(
            read_handle => $lf,
            dc => '-',
            algorithm => $algorithm,
            title => 'Four bit Excess-3 table',
            termtype => 'minterms',
        );
        close $lf or warn "Error closing CSV file: $!";
    }

Making your code handle the opening and closing of the file may
seem like an unnecessary inconvenience, but one benefit is that it
allows you to make use of STDIN or the __DATA__ section:

    my $ttable = Logic::TruthTable->import_csv(
        title => "Table created from __DATA__ section.",
        read_handle => \*DATA,
    );
    print $ttable->fnsolve();
    exit(0);
    __DATA__
    c2,c1,c0,,w1,w0
    0,0,0,,X,0
    0,0,1,,X,X
    0,1,0,,X,X
    0,1,1,,X,1
    1,0,0,,X,X
    1,0,1,,0,X
    1,1,0,,1,1
    1,1,1,,0,1

The attributes read in may be set or overridden, as the file may not
have the attributes that you want. CSV files in particular do not have a
title or termtype, and without the C<dc> option the truth table's
don't-care character will be the object's default character, not what was
stored in the file.

You can set whether the truth table object is created using its
minterms or its maxterms by using the C<termtype> attribute:

    $truthtable = Logic::TruthTable->import_csv(
        read_handle => $lf,
        termtype => 'maxterms',        # or 'minterms'.
    );

By default the truth table is created with minterms.

In addition to the termtype, you may also set the title, don't-care character,
and algorithm attributes. Width, variable names, and function names cannot be
set as these are read from the file.

    $truthtable = Logic::TruthTable->import_json(
        read_handle => $fh_x3,
        title => "Excess-3 multiplier",
        dc => '.',
        algorithm => 'QuineMcCluskey'
    );

The options are:

=over 2

=item read_handle

The opened file handle for reading.

=item dc

The don't-care symbol to use in the truth table. In the case of the CSV
file, becomes the default character of the table and its columns. In the
case of the JSON file, becomes the truth table's default character, but may
not be an individual column's character if it already has a value set.

=item algorithm

The truth table's algorithm of choice. The algorthm's module must be one
that is intalled, or the truth table object will fail to build.

=item title

The title of the truth table.

=item termtype

The terms to use when creating the columns. May be either C<minterms>
(the default) or C<maxterms>.

=back

The method returns undef if an error is encountered.

=cut

sub import_csv
{
	my $self = shift;
	my(%opts) = @_;

	my $handle = $opts{read_handle};
	my $termtype = $opts{termtype} // 'minterms';

	my @vars;
	my @functions;
	my $width = 0;

	unless (defined $handle)
	{
		carp "import_csv(): no file opened.";
		return undef;
	}
	unless ($termtype =~ /minterms|maxterms/)
	{
		carp "Incorrect value for termtype ('minterms' or 'maxterms')";
		return undef;
	}

	my $csv = Text::CSV->new( {binary => 1} );

	unless ($csv)
	{
		carp "Cannot use Text::CSV: " . Text::CSV->error_diag();
		return undef;
	}

	#
	# Parse the first line of the file, which is the header,
	# and which will have the variable and function names, which
	# in turn will let us deduce the width.
	#
	my $header = $csv->getline($handle);

	#
	### The header is: $header
	#
	for (@$header)
	{
		#
		### Examining: $_
		#
		if ($_ eq '')
		{
			if ($width != 0)
			{
				carp "File is not in the correct format";
				return undef;
			}

			$width = scalar @vars;
		}
		elsif ($width == 0)
		{
			push @vars, $_;
		}
		else
		{
			push @functions, $_;
		}
	}

	#
	# Now that we've got our width, var names, and
	# function names, collect the terms.
	#
	### width: $width
	### termtype: $termtype
	### functions: @functions
	### vars: @vars
	#
	my($termrefs, $dcrefs);

	my $idx = 0;
	while (my $row = $csv->getline($handle))
	{
		for my $c (0 .. $#functions)
		{
			my $field = 1 + $c + $width;

			if ($row->[$field] !~ /[01]/)
			{
				push @{ $dcrefs->[$c] }, $idx;
			}
			elsif (($termtype eq 'minterms' and $row->[$field] eq '1') or
				($termtype eq 'maxterms' and $row->[$field] eq '0'))
			{
				push @{ $termrefs->[$c] }, $idx;
			}
		}
		$idx++;
	}

	#
	# We've collected our variable names, function names, and terms.
	# Let's make an object.
	#
	### dcrefs: $dcrefs
	### termrefs: $termrefs
	#
	my $title = $opts{title} // "$width-input table created from import file";
	my $algorithm = $opts{algorithm} // 'QuineMcCluskey';
	my $dc = $opts{dc} // '-';
	my @columns;

	for my $c (0 .. $#functions)
	{
		push @columns, {
			dontcares => $dcrefs->[$c],
			$termtype, $termrefs->[$c]
		};
	}

	return Logic::TruthTable->new(
		width => $width,
		title => $title,
		dc => $dc,
		vars => [@vars],
		functions => [@functions],
		columns => [@columns],
		algorithm => $algorithm,
	);
}

sub import_json
{
	my $self = shift;
	my(%opts) = @_;

	my $handle = $opts{read_handle};
	my $termtype = $opts{termtype} // 'minterms';

	unless (defined $handle)
	{
		carp "import_json(): no file opened.";
		return undef;
	}

	#
	# The attributes that may be overridden by the function's caller.
	#
	my @opt_atts = qw(algorithm title dc);

	#
	# Slurp in the entire JSON string.
	#
	my $jstr = do {
		local $/ = undef;
		<$handle>;
	};

	#
	# Take the JSON string and parse it.
	#
	### JSON string read in: $jstr
	#
	my %jhash = %{ decode_json($jstr) };

	my $width = $jhash{width};
	my @vars = @{ $jhash{vars} };
	my @functions = @{ $jhash{functions} };
	my @jcols = @{ $jhash{columns} };

	#
	# Use JSON, or passed-in, or default attributes?
	#
	map{$jhash{$_} = $opts{$_}} grep{exists $opts{$_}} @opt_atts;

	my %other = map{$_, $jhash{$_}} grep{exists $jhash{$_}} @opt_atts;

	my @columns;
	#
	# Go through the columns array of the JSON import.
	#
	### columns : @jcols
	#
	for my $c (0 .. $#functions)
	{
		my $base81str = $jcols[$c]->{pack81};
		my($minref, $maxref, $dontcaresref) =
			terms_from_base81($width, $base81str);

		my %colhash = map{$_, $jcols[$c]->{$_}}
			grep{exists $jcols[$c]->{$_}} @opt_atts;

		if (exists $jcols[$c]->{termtype} and
			$jcols[$c]->{termtype} eq 'maxterms')
		{
			$colhash{maxterms} = $maxref;
		}
		else
		{
			$colhash{minterms} = $minref;
		}
		$colhash{dontcares} = $dontcaresref if (scalar @{$dontcaresref} > 0);

		push @columns, {%colhash};
	}

	return Logic::TruthTable->new(
		width => $width,
		%other,
		vars => [@vars],
		functions => [@functions],
		columns => [@columns],
	);
}


=head1 AUTHOR

John M. Gamble, C<< <jgamble at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-logic-truthtable at rt.cpan.org>,
or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Logic-TruthTable>. I will
be notified, and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

This module is on Github at L<https://github.com/jgamble/Logic-TruthTable>

You can also look for information on L<MetaCPAN|https://metacpan.org/release/Logic-TruthTable>

=head1 SEE ALSO

=over 3

=item

Introduction To Logic Design, by Sajjan G. Shiva, 1998.

=item

Discrete Mathematics and its Applications, by Kenneth H. Rosen, 1995

=item

L<Logic Friday|https://web.archive.org/web/20180204131842/http://sontrak.com/>
("Free software for boolean logic optimization, analysis, and synthesis.")
was located on its website until some time after 4 February 2018, at which
point it shut down. It was enormously useful, and can still be found on
The Wayback Machine.

It has two forms of its export format, a standard CSV file, and a minimized
version of the CSV file that unfortunately was not documented. This is
why only the standard CSV file can be read or written.

=back

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2019 John M. Gamble. All rights reserved. This program is
free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

See L<http://dev.perl.org/licenses/> for more information.

=cut

1;

__END__
