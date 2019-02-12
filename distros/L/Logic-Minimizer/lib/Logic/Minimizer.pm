package Logic::Minimizer;

use 5.016001;

use Moose;
use namespace::autoclean;

use Carp;

use List::Compare::Functional qw(get_intersection);

our $VERSION = '1.00';


#
# Required attributes to create the object.
#
# 1. 'width' is absolutely required (handled via Moose).
#
# 2. If 'columnstring' is provided, 'minterms', 'maxterms', and
#    'dontcares' can't be used.
#
# 3. Either 'minterms' or 'maxterms' is used, but not both.
#
# 4. 'dontcares' are used with either 'minterms' or 'maxterms', but
#    cannot be used by itself.
#
has 'width' => (
	isa => 'Int', is => 'ro', required => 1,
);

has 'minterms' => (
	isa => 'ArrayRef[Int]', is => 'rw', required => 0,
	predicate => 'has_minterms',
);
has 'maxterms' => (
	isa => 'ArrayRef[Int]', is => 'rw', required => 0,
	predicate => 'has_maxterms',
);
has 'dontcares' => (
	isa => 'ArrayRef[Int]', is => 'rw', required => 0,
	clearer => 'clear_dontcares',
	predicate => 'has_dontcares',
);
has 'columnstring' => (
	isa => 'Str', is => 'ro', required => 0,
	predicate => 'has_columnstring',
	lazy => 1,
	builder => 'to_columnstring',
);
has 'columnlist' => (
	isa => 'ArrayRef[Int]', is => 'ro', required => 0,
	predicate => 'has_columnlist',
	lazy => 1,
	builder => 'to_columnlist',
);

has 'algorithm' => (
	isa => 'Str', is => 'rw',
	builder => 'extract_algorithm',
);

#
# Optional attributes.
#
has 'title'	=> (
	isa => 'Str', is => 'rw', required => 0,
	predicate => 'has_title'
);
has 'dc'	=> (
	isa => 'Str', is => 'rw',
	default => '-'
);
has 'vars'	=> (
	isa => 'ArrayRef[Str]', is => 'rw', required => 0,
	default => sub{['A' .. 'Z']}
);


#
# Prime implicants, essentials, and covers are all "lazy"
# attributes and calculated when asked for in code or by
# the user. All are created via builder functions that
# are provided by the child class.
#

#
# The prime implicants. The hash is of the form
# 'implicant' => [terms that are covered].
#
has 'primes' => (
	isa => 'HashRef', is => 'ro', required => 0,
	init_arg => undef,
	reader => 'get_primes',
	writer => '_set_primes',
	predicate => 'has_primes',
	clearer => 'clear_primes',
	lazy => 1,
	builder => 'generate_primes',
);

#
# The essential prime implicants (for informational
# purposes only, algorithms generally don't need
# it for minimizing).
#
has 'essentials' => (
	isa => 'ArrayRef', is => 'ro', required => 0,
	init_arg => undef,
	reader => 'get_essentials',
	writer => '_set_essentials',
	predicate => 'has_essentials',
	clearer => 'clear_essentials',
	lazy => 1,
	builder => 'generate_essentials',
);

#
# The covers are the building blocks of the final form
# of the solution to the equations and are used to create
# the text form of the equations.
#
# The terms are listed in an array, but as there may be
# more than one way to cover the solution, it is an array
# of cover arrays.
#
has 'covers' => (
	isa => 'ArrayRef[ArrayRef[Str]]', is => 'ro', required => 0,
	init_arg => undef,
	reader => 'get_covers',
	writer => '_set_covers',
	predicate => 'has_covers',
	clearer => 'clear_covers',
	lazy => 1,
	builder => 'generate_covers',
);

#
# The print options.
#
has 'and_symbol' => (
	isa => 'Str', is => 'rw',
	reader => 'get_and_symbol',
	writer => 'set_and_symbol',
	default => ''
);

has 'or_symbol' => (
	isa => 'Str', is => 'rw',
	reader => 'get_or_symbol',
	writer => 'set_or_symbol',
	default => ' + '
);

has 'group_symbols' => (
	isa => 'ArrayRef[Str]', is => 'rw',
	reader => 'get_group_symbols',
	writer => 'set_group_symbols',
	default => sub{['(', ')']}
);

has 'var_formats' => (
	isa => 'ArrayRef[Str]', is => 'rw',
	reader => 'get_var_formats',
	writer => 'set_var_formats',
	default => sub{["%s", "%s'"]}
);

#
# Change behavior.
#
has 'order_by' => (
	isa => 'Str', is => 'rw',
	reader => 'get_order_by',
	writer => 'set_order_by',
	default => 'none',
);

has 'minonly' => (
	isa => 'Bool', is => 'rw',
	default => 1
);

#
# $self->catch_errors();
#
# Sanity checking for parameters that contradict each other
# or which aren't sufficient to create the object.
#
# These are fatal errors. No return value needs to be checked,
# because any error results in a using croak().
#
sub catch_errors
{
	my $self = shift;
	my $w = $self->width;

	#
	# Catch errors involving minterms, maxterms, and don't-cares.
	#
	croak "Mixing minterms and maxterms not allowed"
		if ($self->has_minterms and $self->has_maxterms);

	#
	# Does the width make sense?
	#
	croak "'width' must be at least 1" if ($w < 1);

	my $wp2 = 1 << $w;

	if ($self->has_columnstring or $self->has_columnlist)
	{
		croak "Other terms are redundant when using the columnstring or columnlist attributes"
			if ($self->has_minterms or $self->has_maxterms or $self->has_dontcares);
		croak "Use only one of the columnstring or columnlist attributes"
			if ($self->has_columnstring and $self->has_columnlist);

		my $cl = $wp2 - (($self->has_columnstring)?
					length $self->columnstring:
					$#{$self->columnlist});

		if ($cl != 0)
		{
			my $attr = ($self->has_columnlist)? "Columnlist": "Columnstring";

			croak "$attr length is too short by ", $cl if ($cl > 0);
			croak "$attr length is too long by ", -$cl;
		}
	}
	else
	{
		my @terms;

		if ($self->has_minterms)
		{
			@terms = @{ $self->minterms };
			croak "Empty 'minterm' array reference." unless (scalar @terms);
		}
		elsif ($self->has_maxterms)
		{
			@terms = @{ $self->maxterms };
			croak "Empty 'maxterm' array reference" unless (scalar @terms);
		}
		else
		{
			croak "Must supply either minterms or maxterms";
		}

		if ($self->has_dontcares)
		{
			my @dcs = @{ $self->dontcares };
			unless (scalar @dcs)
			{
				carp "Empty 'dontcare' array reference";
				$self->clear_dontcares();
			}
			else
			{
				my @intersect = get_intersection([\@dcs, \@terms]);
				if (scalar @intersect != 0)
				{
					croak "Term(s) ", join(", ", @intersect),
						" are in both the don't-care list and the term list.";
				}

				push @terms, @dcs;
			}
		}

		#
		# Can those terms be expressed in 'width' bits?
		#
		my @outside = grep {$_ >= $wp2 or $_ <= -1} @terms;

		if (scalar @outside)
		{
			croak "Terms (" . join(", ", @outside) . ") are larger than $w bits";
		}
	}

	#
	# Do we really need to check if they've set the
	# don't-care character to '0' or '1'? Oh well...
	#
	croak "Don't-care must be a single character" if (length $self->dc != 1);
	croak "The don't-care character cannot be '0' or '1'" if ($self->dc =~ qr([01]));

	#
	# Make sure we have enough variable names.
	#
	croak "Not enough variable names for your width" if (scalar @{$self->vars} < $w);

	return 1;
}

#
# Return an array reference made up of the function column.
# Position 0 in the array is the 0th row of the column, and so on.
#
sub to_columnlist
{
	my $self = shift;
	my ($dfltbit, $setbit) = ($self->has_min_bits)? qw(0 1): qw(1 0);
	my @bitlist = ($dfltbit) x (1 << $self->width);

	my @terms;

	push @terms, @{$self->minterms} if ($self->has_minterms);
	push @terms, @{$self->maxterms} if ($self->has_maxterms);

	map {$bitlist[$_] = $setbit} @terms;

	if ($self->has_dontcares)
	{
		map {$bitlist[$_] = $self->dc} (@{ $self->dontcares});
	}

	return \@bitlist;
}

#
# Return a string made up of the function column. Position 0 in the string is
# the 0th row of the column, and so on.
#
sub to_columnstring
{
	my $self = shift;

	return join "", @{ $self->to_columnlist };
}

#
# Take a column list and return array refs usable as parameters for
# minterm, maxterm, and don't-care attributes.
#
sub list_to_terms
{
	my $self = shift;
	my(@bitlist) = @_;
	my $x = 0;

	my(@maxterms, @minterms, @dontcares);

	for (@bitlist)
	{
		if ($_ eq '1')
		{
			push @minterms, $x;
		}
		elsif ($_ eq '0')
		{
			push @maxterms, $x;
		}
		else
		{
			push @dontcares, $x;
		}
		$x++;
	}

	return (\@minterms, \@maxterms, \@dontcares);
}

#
# Get the algorithm name from the algorithm package name, suitable for
# using in the 'algorithm' parameter of Logic::TruthTable->new().
#
sub extract_algorithm
{
	my $self = shift;
	my $al =  ref $self;

	#
	# There is probably a better way to do this.
	#
	$al=~ s/^Algorithm:://;
	$al =~ s/::/-/g;
	return $al;
}

sub to_boolean
{
	my $self = shift;
	my($cref) = @_;
	my $is_sop = $self->has_min_bits;
	my $w = $self->width;

	#
	# Group separators, and the group joiner string (set according
	# to whether this is a sum-of-products or product-of-sums).
	#
	my($gsb, $gse) = @{$self->get_group_symbols()};
	my $gj = $is_sop ? $self->get_or_symbol() : $self->get_and_symbol();

	my @covers = @$cref;

	#
	# Check for the special case where the covers are reduced to
	# a single expression of nothing but dc characters
	# (e.g., "----"). This happens when all of the terms are
	# covered, resulting in an equation that would be simply
	# "(1)" (or "(0)" if using maxterms). Since the normal
	# translation will return "()", this has to checked.
	#
	if ($#covers == 0)
	{
		if ($covers[0] =~ /[^01]{$w}/)
		{
			return $gsb . (($is_sop)? "1": "0") . $gse;
		}
		else
		{
			return $gsb . $self->to_boolean_term($covers[0], $is_sop) . $gse;
		}
	}

	@covers = sort @covers if ($self->get_order_by eq 'covers');

	my @exprns = map {$gsb . $self->to_boolean_term($_, $is_sop) . $gse} @covers;
	@exprns = sort @exprns if ($self->get_order_by eq 'vars');

	return join $gj, @exprns;
}

#
# Convert an individual term or prime implicant to a boolean variable string.
#
sub to_boolean_term
{
	my $self = shift;
	my($term, $is_sop) = @_;

	#
	# The variable and complemented variable formats.
	#
	my($vf, $nvf) = @{$self->get_var_formats()};

	#
	# Element joiner and match condition
	#
	my($ej, $cond) =
		$is_sop ? ($self->get_and_symbol(), 1):
			($self->get_or_symbol(), 0);

	my @trits = split //, $term;
	my @indices = grep{$trits[$_] ne $self->dc} (0 .. $#trits);

	my @vars = @{$self->vars};

	return join $ej, map {
		sprintf(($trits[$_] == $cond ? $vf: $nvf), $vars[$_])
	} @indices;
}

=head1 NAME

Logic::Minimizer - The parent class of Boolean minimizers.

=head1 SYNOPSIS

This is the base class for logic minimizers that are used by
L<Logic::TruthTable>. You do not need to use this class (or
indeed read any further) unless you are creating a logic
minimizer package.

    package Algorithm::SomethingNiftyLikeEspresso;
    extends 'Logic::Minimizer';

(C<Algorithm::SomethingNiftyLikeEspresso> has C<Logic::Minimizer>
as its base class, which is required if C<Logic::TruthTable> is to
use it.)

Then, either use the package directly in your program:

    my $fn = Algorithm::SomethingNiftyLikeEspresso->new(
        width => 4,
        minterms => [1, 8, 9, 14, 15],
        dontcares => [2, 3, 11, 12]
    );
    ...

or as a algorithm choice in C<Logic::TruthTable>:

    my $tt = Logic::TruthTable->new(
        width => 4,
        algorithm => 'SomethingNiftyLikeEspresso',
        columns => [
            {
                minterms => [1, 8, 9, 14, 15],
                dontcares => [2, 3, 11, 12],
            }
            {
                minterms => [4, 5, 6, 10, 13],
                dontcares => [2, 3, 11, 12],
            }
        ],
    );

This class provides the attributes and some of the methods for your
minimizer class.

=head3 Minimizer Attributes

These are the attributes provided by C<Logic::Minimizer> to
create and reduce the object. Some attributes are required
to be set from the program, some are optional, and others are
generated internally.

The attributes required to create the object are:

=over 4

=item 'width'

C<width> is absolutely required -- it tells the object how many
variables are used in the Boolean equation.

=item 'minterms'

=item 'maxterms'

The set (if using minterms) or unset (if using maxterms) terms in
the Boolean equation. The choice affects the output of the equation:
using minterms results in a sum-of-products form of the equation, while
using maxterms results in a product-of-sums form.

=item 'dontcares'

The terms that don't affect the output of the equation at all; that
one literally doesn't care about.

=item 'columnstring'

=item 'columnlist'

Alternate ways of providing minterms, maxterms, and don't-care terms.
Position 0 in the string or list represents the 0th row of the column,
position 1 represents the next row, and so on. In either case, the
output is in sum-of-product form.

=back

Some common sense rules apply. If 'columnstring' or 'columnlist' is
provided, 'minterms', 'maxterms', and 'dontcares' can't be used.

Likewise, 'minterms' and 'maxterms' can not be used together, and
'dontcares' can't be used by itself.

Some attributes are optional, and are used to changed the look
of the output.

=over 4

=item 'title'

A name or description of the problem. Useful for tracking
which object one is working with, if there's more than one.

=item 'dc'

The don't-care character. May be changed for both aesthetic
and inter-program communication purposes. Used in columnstring
or columnlist attributes. Also used in output files by
C<Logic::TruthTable>, and in 'covers' output (see below).
Defaults to the character '-'.

=item 'vars'

The variable names used to output the Boolean equation. By default,
uses 'A' to 'Z'. The names do not have to be single characters, e.g.:
C<vars => ['a1', 'a0', 'b1', 'b0']>

=back

The attributes that are set during the minimizing process.

These are all "lazy" attributes, and calculated when asked
for in code or by the user. All are created by builder
functions that the child class needs to provide.

=over 4

=item 'primes'

The prime implicants. A hash in the form
C<'implicant' => [covered terms]>.

=item 'covers'

The covers are the building blocks of the final form
of the solution to the equation, and are used to create
the text form of the equation.

The terms are listed in an array, but as there may be
more than one way to cover the solution, it is an array
of cover arrays.

=item 'essentials'

The essential prime implicants (for informational purposes
only, algorithms generally don't need it for minimizing).

=item 'algorithm'

The class of the child object. for example, if the
class used to solve the set of terms is Algorithm::QuineMcCluskey,
then 'algorithm' would be set to 'QuineMcCluskey'.

=back

=head3 Minimizer Methods

These are the methods needed for error checking, or to read from or
write to the attributes.

Some are provided by C<Logic::Minimizer>, while others (the builder
methods of the attributes 'primes', 'covers', and 'essentials') are
merely method definitions, and are expected to be provided by the
child class.

=over 4

=item to_columnstring

Provided by this module. Converts the column into a single string.

=item to_columnlist

Provided by this module. Converts the column into an array reference.

=item catch_errors

Provided by this module. Finds basic errors such as empty term arrays,
insufficient variables for the width, terms that don't fit within the
table size, and so forth.

=item to_boolean

Provided by this module. Converts a set of covers to a boolean equation.

=item to_boolean_term

Provided by this module. Converts a cover term into a boolean expression.
Called by C<to_boolean()>.

=item generate_primes

=item generate_covers

=item generate_essentials

The primes, covers, and essentials attributes need methods to create
those attributes. The child module of C<Logic::Minimizer> should provide these.

=back


=head1 AUTHOR

John M. Gamble, C<< <jgamble at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-logic-minimizer at rt.cpan.org>,
or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Logic-Minimizer>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Logic::Minimizer

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Logic-Minimizer>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Logic-Minimizer>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Logic-Minimizer>

=item * Search CPAN

L<http://search.cpan.org/dist/Logic-Minimizer/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2015 John M. Gamble.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.


=cut

1;
