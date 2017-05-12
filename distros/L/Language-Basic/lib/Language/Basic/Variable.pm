package Language::Basic::Variable;

# Part of Language::Basic by Amir Karger (See Basic.pm for details)

=pod

=head1 NAME

Language::Basic::Variable - Module to handle parsing and implementing
BASIC variables.

=head1 SYNOPSIS

See L<Language::Basic> for the overview of how the Language::Basic module
works. This pod page is more technical.

There are two sorts of variables: Arrays and Scalars. Each of those
classes has a subclass for Numeric or String variables.

=head1 DESCRIPTION

An Array needs to have full LBV::Scalar objects in it, rather than just
having an array of values. The reason is that, for example, you might
use ARR(3) as the variable in a FOR loop. Also, the "set" and "value"
methods apply to a LBV::Scalar (since you can't set an array to a value
(in BASIC :)) so in order to be handle A(3)=3, A(3) needs to be an LBV::Scalar.

The lookup method looks up a variable in the Array or Scalar lookup
table (depending on whether there were parentheses after the variable
name). BASIC allows undeclared variables, so if the variable name hasn't
been seen before, a new variable is created.

=cut

use strict;

# sub-packages
{
package Language::Basic::Variable;
package Language::Basic::Variable::Numeric;
package Language::Basic::Variable::String;
package Language::Basic::Variable::Scalar;
package Language::Basic::Variable::Array;
}
# Hash storing the program's variables
my %Scalars;
my %Arrays;

# Look up a variable based on its name.
# Create a new Variable (Scalar or Array) if it doesn't yet exist.
# Arg0 is the name for the variable, Arg1 is defined if there were () after
# the name, i.e., if it's an array. For now, we don't care what's in the 
# parens.
# Returns the Variable ref, whether or not it had to create a new one.
sub lookup {
    my $name = shift;
    my $arglist = shift;
    if (defined($arglist)) {
        unless (exists $Arrays{$name}) {
	    $Arrays{$name} = new Language::Basic::Variable::Array $name;
	}
	return $Arrays{$name};
    } else {
	unless (exists $Scalars{$name}) {
	    $Scalars{$name} = new Language::Basic::Variable::Scalar $name;
	}
	return $Scalars{$name};
    }
} # end sub Language::Basic::Variable::lookup

######################################################################
# package Language::Basic::Variable::Scalar
#
# Fields:
#    value - the current value of the variable
#

=head2 Language::Basic::Variable::Scalar class

This class handles a variable or one cell in an array.

Methods include "value", which gets the variable's value, and "set",
which sets it.

=cut

{
package Language::Basic::Variable::Scalar;
@Language::Basic::Variable::Scalar::ISA = qw(Language::Basic::Variable);

sub new {
    my ($class, $name) = @_;
    my $type = ($name =~ /\$$/) ? "String" : "Numeric";
    # Create a new subclass object, & return it
    my $subclass = $class . "::$type";
    return (new $subclass);
} # end sub Language::Basic::Variable::new

# Set the variable to value arg1
sub set {
    my ($self, $value) = @_;
    $self->{"value"} = $value;
}

sub value {return shift->{"value"} }

package Language::Basic::Variable::Scalar::String;
@Language::Basic::Variable::Scalar::String::ISA = 
    qw (Language::Basic::Variable::Scalar Language::Basic::Variable::String);

sub new {
    my $class = shift;
    my $value = "";
    my $self = {
        "value" => $value,
    };
    bless $self, $class;
} # end sub Language::Basic::Variable::Scalar::String::new

package Language::Basic::Variable::Scalar::Numeric;
@Language::Basic::Variable::Scalar::Numeric::ISA = 
    qw (Language::Basic::Variable::Scalar Language::Basic::Variable::Numeric);

sub new {
    my $class = shift;
    my $value = 0;
    my $self = {
        "value" => $value,
    };
    bless $self, $class;
} # end sub Language::Basic::Variable::Scalar::Numeric::new

} # end package Language::Basic::Variable::Scalar

######################################################################
#
# Fields:
#     cells - list (of lists, for 2- or more dimensional arrays) of
#         Language::Basic::Variable::Scalar objects holding the actual values
#         for each index

=head2 Language::Basic::Variable::Array class

This class handles a BASIC array. Each cell in the array is a LBV::Scalar
object.

Methods include "dimension", which dimensions the array to a given size (or
a default size) and get_cell, which returns the LBV::Scalar object in a
given array location.

Note that BASIC arrays start from 0!

=cut

{
package Language::Basic::Variable::Array;
@Language::Basic::Variable::Array::ISA = qw(Language::Basic::Variable);
use Language::Basic::Common;

# Fields:
#     cells - holds the LBV::Scalar::* objects in the array

# Note that this returns subclasses of LBVA (String or Numeric)
sub new {
    my ($class, $name) = @_;
    my $self = {
        "cells" => [],
    };

    my $type = ($name =~ /\$$/) ? "String" : "Numeric";
    my $subclass = $class . "::$type";
    bless $self, $subclass;

    # Dimension the array to its default size
    $self->dimension;
    return $self;
} # end sub Language::Basic::Variable::Array::new

# Make room in the array
# Input: Optionally, a list of sizes for each dimension. Otherwise, a
#     one-dimensional array of default size is dimensioned.
# Error: Exit with error if the array will be too big.
sub dimension {
    my $MAXDIM = 100000;
    my $self = shift;
    my @Default = (10);

    # TODO multi-dim arrays
    my @sizes = @_ ? @_ : @Default;
    my $size = 1;
    for (@sizes) {$size *= ($_+1)}
    if ($size > $MAXDIM) 
        {&Exit_Error("Array size may not be greater than $MAXDIM")}

    my $subclass = ref($self);
    $subclass =~ s/Array/Scalar/;
    $self->{"cells"} = &lol($subclass, @sizes);
    $self->{"dimensions"} = \@sizes;
} # end sub Language::Basic::Variable::Array::dimension

sub lol {
# create a list of lists of arg0 objects, dimensions arg1-n
    my ($subclass, @sizes) = @_;
    if (@sizes) {
        #recurse
	my $size = shift(@sizes);
        my @arr = map {&lol($subclass, @sizes)} (0 .. $size);
	return \@arr;
    } else {
	# end recursion
        # '$subclass->new' because 'new $subclass' calls LBVA::new!
        my $ret = $subclass->new;
	return $ret;
    }
} # end sub Language::Basic::Variable::Array::lol

# Get one cell of an array
# Input: a list of array indices
# Output: the Language::Basic::Variable::Scalar at that location in the array
sub get_cell {
    my $self = shift;
    my @indices = @_;
    my @sizes = @{$self->{"dimensions"}};
    unless (@sizes == @indices) {Exit_Error("Wrong number of indices!")}

    my $ptr = $self->{"cells"};
    foreach my $index (@indices) {
        my $size = shift(@sizes);
	# index can't be negative or greater than the array size
	if ($index !~ /^\d+$/ || $index > $size) {
	    &Exit_Error ("Illegal array indexing '@indices'")
	}
	$ptr = $ptr->[$index];
    }

    my $c = ref($ptr);
    warn "Weird class $c" unless $ptr->isa("Language::Basic::Variable::Scalar");
    return $ptr;
} # end sub Language::Basic::Variable::Array::get_cell

package Language::Basic::Variable::Array::Numeric;
@Language::Basic::Variable::Array::Numeric::ISA = 
    qw (Language::Basic::Variable::Array Language::Basic::Variable::Numeric);
package Language::Basic::Variable::Array::String;
@Language::Basic::Variable::Array::String::ISA = 
    qw (Language::Basic::Variable::Array Language::Basic::Variable::String);
} # end package Language::Basic::Variable::Array

{
# set ISA for "return type" classes
package Language::Basic::Variable::Numeric;
@Language::Basic::Variable::Numeric::ISA = qw
    (Language::Basic::Variable Language::Basic::Numeric);
package Language::Basic::Variable::String;
@Language::Basic::Variable::String::ISA = qw
    (Language::Basic::Variable Language::Basic::String);
}
1; # end package Language::Basic::Variable
