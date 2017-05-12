package Math::LinearCombination;

require 5.005_62;
use strict;
use warnings;
use Carp;
our ($VERSION);
$VERSION = '0.03';
use fields (
   '_entries', # hash sorted on variable id's, with a ref to hash for
	       # each variable-coefficient pair:
	       #  { var => $var_object, coeff => $num_coefficient }
);

use overload
    '+'    => 'add',
    '-'    => 'subtract',
    '*'    => 'mult',
    '/'    => 'div',
    "\"\"" => 'stringify';

### Object builders
sub new {
    # parse the arguments
    my $proto = shift;
    my $pkg = ref($proto) || $proto;
    if(@_ == 1 
       && defined(ref $_[0]) 
       && $_[0]->isa('Math::LinearCombination')) {
	# new() has been invoked as a copy ctor
	return $_[0]->clone();
    }
    elsif(@_) {
	croak "Invalid nr. of arguments passed to new()";
    }

    # construct the object
    my Math::LinearCombination $this = fields::new($pkg);

    # apply default values
    $this->{_entries} = {};

    $this;
}

sub make { 
    # alternative constructor, which accepts a sequence (var1, coeff1, var2, coeff2, ...)
    # as an initializer list
    my $proto = shift;
    my $pkg = ref($proto) || $proto;
    my $ra_args = \@_;
    if(defined($ra_args->[0]) 
       && defined(ref $ra_args->[0]) 
       && ref($ra_args->[0]) eq 'ARRAY') {
	$ra_args = $ra_args->[0]; # argument array was passed as a ref
    };
    my $this = new $pkg;
    while(@$ra_args) {
	my $var = shift @$ra_args;
	defined(my $coeff = shift @$ra_args) or die "Odd number of arguments";
	$this->add_entry(var => $var, coeff => $coeff);
    }
    return $this;
}

sub clone {
    my Math::LinearCombination $this = shift;
    my Math::LinearCombination $clone = $this->new();
    $clone->add_inplace($this);
    return $clone;
}

sub add_entry {
    my Math::LinearCombination $this = shift;
    my %arg = (@_ == 1 && defined(ref $_[0]) && ref($_[0]) eq 'HASH')
	? %{$_[0]} : @_;

    exists $arg{var} or croak "No `var' argument given to add_entry()";
    my $var = $arg{var};
    UNIVERSAL::can($var,'id') or croak "Given `var' argument has no id() method";
    UNIVERSAL::can($var,'name') or croak "Given `var' argument has no name() method";
    UNIVERSAL::can($var,'evaluate') or croak "Given `var' argument has no evaluate() method";

    exists $arg{coeff} or croak "No `coeff' argument given to add_entry()";
    my $coeff = $arg{coeff};

    my $entry = $this->{_entries}->{$var->id()} ||= {};
    if(exists $entry->{var}) { # we're adding to an existing entry
	$entry->{var} == $var or 
	    croak "add_entry() found distinct variable with same id";
    }
    else { # we're initializing a new entry
	$entry->{var} = $var;
    }
    $entry->{coeff} += $coeff;

    return;
}

### Accessors
sub get_entries {
    my Math::LinearCombination $this = shift;
    return $this->{_entries};
}

sub get_variables {
    my Math::LinearCombination $this = shift;
    my @vars = map { $this->{_entries}->{$_}->{var} } sort keys %{$this->{_entries}};
    return wantarray ? @vars : \@vars;
}

sub get_coefficients {
    my Math::LinearCombination $this = shift;
    my @coeffs = map { $this->{_entries}->{$_}->{coeff} } sort keys %{$this->{_entries}};
    return wantarray ? @coeffs : \@coeffs;
}

### Mathematical manipulations
sub add_inplace {
    my Math::LinearCombination $this = shift;
    my Math::LinearCombination $arg  = shift;
    while(my($id,$entry) = each %{$arg->{_entries}}) {
	$this->add_entry($entry);
    }
    $this->remove_zeroes();
    return $this;
}

sub add {
    my ($a,$b) = @_;
    my $sum = $a->clone();
    $sum->add_inplace($b);
    return $sum;
}

sub subtract {
    my ($a,$b,$flip) = @_;
    my $diff = $flip ? $a->clone() : $b->clone(); # the negative term ...
    $diff->negate_inplace(); # ... is negated
    $diff->add_inplace($flip ? $b : $a); # and the positive term is added
    return $diff;
}

sub negate_inplace {
    my Math::LinearCombination $this = shift;
    $this->multiply_with_constant_inplace(-1.0);
    return $this;
}

sub multiply_with_constant_inplace {
    my Math::LinearCombination $this = shift;
    my $constant = shift;
    while(my($id,$entry) = each %{$this->{_entries}}) {
	$entry->{coeff} *= $constant;
    }
    $this->remove_zeroes();
    return $this;
}

sub mult {
    my ($a,$b) = @_;
    my $prod = $a->clone(); # clones the linear combination
    $prod->multiply_with_constant_inplace($b); # multiplies with the scalar
    return $prod;
}

sub div {
    my ($a,$b,$flip) = @_; 
    die "Unable to divide a scalar (or anything else) by a " . ref($a) . ". Stopped"
	if $flip;
    return $a->mult(1.0/$b);
}

sub evaluate { 
    my Math::LinearCombination $this = shift;
    my $val = 0.0;
    while(my($id,$entry) = each %{$this->{_entries}}) {
	$val += $entry->{var}->evaluate() * $entry->{coeff};
    }
    return $val;
}

sub remove_zeroes {
    my Math::LinearCombination $this = shift;
    my @void_ids = grep { $this->{_entries}->{$_}->{coeff} == 0.0 } keys %{$this->{_entries}};
    delete $this->{_entries}->{$_} foreach @void_ids;
    return;
}

### I/O
sub stringify {
    my Math::LinearCombination $this = shift;

    my @str_entries;
    foreach my $key (sort keys %{$this->{_entries}}) {
	my $var   = $this->{_entries}->{$key}->{var};
	my $coeff = $this->{_entries}->{$key}->{coeff};
	my $str_entry = '';
	if($coeff < 0.0 || @str_entries) { # adds the sign only if needed
	    $str_entry .= $coeff > 0.0 ? '+' : '-';
	}
	if(abs($coeff) != 1.0) { # adds the coefficient value if not +1 or -1
	    $str_entry .= sprintf("%g ", abs($coeff));
	}
	$str_entry .= $var->name();
	push @str_entries, $str_entry;
    }

    return @str_entries ? join(' ', @str_entries) : '0.0';
}

1;

__END__

=head1 NAME

Math::LinearCombination - sum of variables with a numerical coefficient

=head1 SYNOPSIS

  use Math::LinearCombination;
  use Math::SimpleVariable; # for the variable objects

  # build a linear combination
  my $x1 = new Math::SimpleVariable(name => 'x1');
  my $x2 = new Math::SimpleVariable(name => 'x2');
  my $lc = new Math::LinearCombination();
  $lc->add_entry(var => $x1, coeff => 3.0);
  $lc->add_entry(var => $x2, coeff => 1.7);
  $lc->add_entry(var => $x2, coeff => 0.3); # so x2 has a coefficient of 2.0
  print $lc->stringify(), "\n";

  # do some manipulations
  $lc->negate_inplace(); # reverts the coefficient signs
  $lc->multiply_with_constant_inplace(2.0); # doubles all coefficients
 
  # evaluate the linear combination
  $x1->{value} = 3;
  $x2->{value} = -1;
  print $lc->evaluate(), "\n"; # prints -14

=head1 DESCRIPTION

Math::LinearCombination is a module for representing mathematical
linear combinations of variables, i.e. expressions of the format

  a1 * x1 + a2 * x2 + ... + an * xn

with x1, x2, ..., xn variables, and a1, a2, ..., an numerical coefficients.
Evaluation and manipulation of linear combinations is also supported.
The numerical coefficients a_i and variables x_i are stored as pairs
in an internal data structure and should not be manipulated directly.
All access and manipulation should be performed through the methods.

It is important to note that no specific class is required for the
variable objects. You can provide objects of any class, provided
that the following methods are defined on those objects:

=over 4

=item name()

returning a string with the variable name.

=item id()

returning a unique identifier for that variable. For most applications
it will suffice to have id() invoke name().

=item evaluate()

returning a numerical evaluation of the variable.

=back

The Math::LinearCombination class was designed together with Math::SimpleVariable.
The latter supports all the required methods, and it is thus logical to use only
Math::SimpleVariable objects in your linear combinations, or brew your own class
which is derived from Math::SimpleVariable.

The following methods are available for Math::LinearCombination objects:

=over 4

=item $lc = new Math::SimpleVariable([$other_lc])

constructs a new Math::SimpleVariable object. An existing Math::SimpleVariable object
can be passed to it optionally, in which case a clone of that object is returned. (see
also the clone() method).

=item $lc = make Math::SimpleVariable($x1,$a1,$x2,$a2,...)

also constructs a new Math::SimpleVariable object, but additionally initializes
it with variable-coefficient pairs x_i, a_i. The number of arguments should thus
be even, and the variable objects need to obey the requirements imposed on variables.

=item $lc->clone()

returns an exact copy of $lc, with none of the variables or coefficients shared.
I.e. you can change the contents of the new (old) linear combination without any
impact on the old (new) one.

=item $lc->add_entry('var' => $x, 'coeff' => $a)

adds the variable $x to the linear combination with $a as coefficient. 
add_entry() throws an error when a variable with the same id() is already
present in the linear combination. So do not use add_entry() for adding
linear combinations, but use add_inplace() or the '+' operator (see below)
instead.

=item $ra_entries = $lc->get_entries()

returns a ref to a hash with all the entries of the linear combination.
The hash is sorted on the id() of the variables, and each entry is a ref
to a hash with the following fields:

=over 4

=item var

the variable object

=item coeff

the numerical coefficient

=back

=item @vars = $lc->get_variables()

returns an array with all the variable objects in the linear combination.
get_variables() is context aware, so you can invoke it as 

  $ra_vars = $lc->get_variables

to return a reference to the array of variables instead. The variables
are sorted on their id().

=item @coeffs = $lc->get_coefficients()

same as get_variables(), but returns the coefficients instead. The coefficients
are also sorted on the id() of the corresponding variables.

=item $lc->add_inplace($lc2)

mathematically adds the Math::LinearCombination object $lc2 to $lc and returns 
the changed $lc.

=item $sum = $lc->add($lc2)

mathematically adds $lc2 to $lc. The result is stored in a newly created 
Math::LinearCombination object. Both $lc and $lc2 are left in the same state as before.

=item $lc->negate_inplace()

inverts the sign of the coefficient for each variable in the linear combination.

=item $diff = $lc->subtract($lc2)

mathematically subtracts $lc2 from $lc. The results is stored in a newly created
Math::LinearCombination object. Both $lc and $lc2 are left in the same state as before.

=item $lc->multiply_with_constant_inplace($c)

multiplies each coefficient in $lc with the numerical constant $c.

=item $prod = $lc->mult($lc2)

mathematically multiplies $lc with $lc2. The result is stored in a newly created
Math::LinearCombination object. Both $lc and $lc2 are left in the same state as before.

=item $quot = $lc->div($c)

divides $lc by the numerical constant $c. The result is stored in a newly created
Math::LinearCombination object. $lc is left in the same state as before.
Note that it is not possible to divide a linear combination by another
linear combination, as the result is generally not a linear combination.

=item $eval = $lc->evaluate()

evaluates the linear combination $lc numerically, using the values of the
variables obtained by invoking evaluate() on them.

=item $lc->remove_zeroes() 

removes all variable-coefficient pairs with zero coefficients from the linear combination.
This method is used internally in the methods above, so normally you should never need it.

=item $lc->stringify()

returns a string representing the linear combination. Returns '0.0' for empty linear combinations.

=back

In order to make the mathematical manipulation of linear combinations less verbose,
a number of operators have been overloaded to use the methods above. The overloaded
operators are:

=over 4

=item 

'+' for adding two linear combinations;

=item 

'-' for subtracting two linear combinations;

=item 

'*' for multiplying two linear combinations;

=item 

'/' for dividing a linear combination by a number;

=item 

and '""' for stringifying a linear combination, i.e. you can use a linear combination objects
in any place where interpolation of variables is possible and get the string representation.

=back

=head1 SEE ALSO

=over 4

=item perl(1)

=item L<Math::SimpleVariable>

=back

=head1 VERSION

This is CVS $Revision: 1.11 $ of Math::LinearCombination,
last edited at $Date: 2001/10/31 12:50:02 $.

=head1 AUTHOR

Wim Verhaegen E<lt>wimv@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 2001 Wim Verhaegen. All rights reserved.
This program is free software; you may redistribute
and/or modify it under the same terms as Perl itself.

=cut
