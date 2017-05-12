package Math::Taylor;

use 5.006;
use strict;
use warnings;

our $VERSION = '1.00';

use Math::Symbolic qw/parse_from_string/;
use Math::Symbolic::MiscCalculus;
use Carp qw/confess cluck/;

our $Default_Point      = 0;
our $Default_Variable   = Math::Symbolic::Variable->new('x');
our $Default_Remainder_Type = 'lagrange';

=head1 NAME

Math::Taylor - Taylor Polynomials and remainders

=head1 SYNOPSIS

  use Math::Taylor;
  
  # Create new approximation
  my $approximation = Math::Taylor->new(
    function       => "sin(y) * cos(x)",
    point          => 2,
    variable       => 'y',
    remainder_type => 'cauchy',
  );
  
  # Calculate Taylor Polynomial of degree 2
  my $poly = $approximation->taylor_poly(2);
  print "$poly\n";
  
  # Upper bounds of the remainder are also availlable:
  my $remainder = $approximation->remainder(2, 'cauchy');

=head1 DESCRIPTION

Math::Taylor offers facilites to calculate Taylor Polynomials of any degree symbolically.
For its inner workings, it makes use of Math::Symbolic and specifically
Math::Symbolic::MiscCalculus.

Math::Taylor can also calculate two types of remainders for the Taylor Series.

=head2 EXPORT

This module does not export any functions. You will have to use the
object-oriented interface.

=head2 Methods

=over 2

=cut

=item Constructor new(OPTION => ARGUMENT)

new() is the constructor for Math::Taylor objects. It takes key => value
style named arguments. Valid options are 'function', 'variable', 'point'
and 'remainder_type'.

new() may be called as a class method (C<Math::Taylor->new(...)> to create
an object from scratch or on an existing object to clone the object. In that
case, the function and variable objects are I<deeply cloned>. (If you don't
know what that means, rest assured that it's the sane behaviour.) If you
use key => value pairs to set attributes, these overwrite the attributes
copied from the prototype.

Any Math::Taylor object requires that at least a function attribute is defined.
that means, if you create objects from scratch, you have to specify
a C<function => $ms_tree> attribute.

Details on the attributes of the Math::Taylor objects can be learned from the
documentation of the accessor methods for these attributes (below).

new() returns a Math::Taylor object.

=cut

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    confess "Math::Taylor called with uneven number of arguments."
      if @_ % 2;

    my %args = @_;

    # function to approximate,
    # variable of the function
    # point to approximate about
    my $self = {
        function       => undef,
        variable       => $Default_Variable,
        point          => $Default_Point,
        remainder_type => $Default_Remainder_Type,
    };

    # Clone prototype if applicable.
    if ( ref($proto) ) {
        $self->{function} = $proto->{function}->new();
        $self->{variable} = $proto->{variable}->new()
          if defined $proto->{variable};
        $self->{point} = $proto->{point} if defined $proto->{point};
        $self->{remainder_type} = $proto->{remainder_type}
          if defined $proto->{remainder_type};
    }

    bless $self => $class;

    $self->function( $args{function} ) if exists $args{function};
    $self->variable( $args{variable} ) if exists $args{variable};
    $self->point( $args{point} )       if exists $args{point};

    confess "Cannot create a Math::Taylor object without at least a function."
      if not defined $self->function();

    return $self;
}

=item Accessor function()

This accessor can be used to get or set the function to approximate through the
Math::Taylor object.

Called with no arguments, the method just returns the Math::Symbolic tree that
internally represents the function.

Called with an argument, the first argument is treated as a new function for
the approximation and the corresponding attribute is set. The function may be
specified in one of two formats: Either as a Math::Symbolic tree or as a string
which will be parsed as a Math::Symbolic tree. For details on the syntax of
such strings, please refer to L<Math::Symbolic> and L<Math::Symbolic::Parser>.
it should, however be relatively straighforward. A few examples:

  $taylor->function('sin(x)^2/x'); # (square of the sine of x) divided by x
  my $func = $taylor->function();  # returns the tree for the above
  print $func."\n";                # print out the function
  $taylor->function($anotherfunc); # set the function differently

Please note that when setting the function to an existing Math::Symbolic tree,
the tree is I<not> cloned. If you modify the tree thereafter, the modifications
will propagate to the function in the Math::Taylor object. This is not a bug,
it is a documented feature and wanted action-at-a-distance.

When using function() to access the function attribute, the Math::Symbolic tree
is not cloned either.

=cut

sub function {
    my $self = shift;
    if ( not @_ ) {
        return $self->{function};
    }
    my $function = shift;

    if ( not defined $function ) {
        confess "Won't set the function of a Math::Taylor object to 'undef'.\n";
    }
    elsif ( ref($function) =~ /^Math::Symbolic/ ) {
        $self->{function} = $function;
    }
    elsif ( not ref($function) ) {
        my $parsed;
        eval { $parsed = parse_from_string($function); };
        if (   $@
            or not defined $parsed
            or not ref($parsed) =~ /^Math::Symbolic/ )
        {
            confess <<"HERE"
Could not parse function of Math::Taylor object as Math::Symbolic tree.
Argument was: '$function'
Error (if any) was: '$@'
HERE
        }
        $self->{function} = $parsed;
    }
    return $self->{function};
}

=item Accessor point()

This accessor can be used to get or set the point about which to
approximate using the Taylor Series. If this attribute is not set,
it defaults to C<0>.

Called with no arguments, the method just returns the number.

Called with an argument, the first argument is treated as a point to
approximate about and the corresponding attribute is set accordingly.

The method always returns the current point (which should be a real
number).

=cut

sub point {
    my $self = shift;
    if ( not @_ ) {
        return $self->{point};
    }
    my $point = shift;
    if ( defined $point ) {
        $self->{point} = $point;
    }
    else {
        confess
"Cannot set the 'point' attribute of a Math::Taylor object to 'undef'.";
    }
    return $self->{point};
}

=item Accessor variable()

This accessor can be used to get or set the variable in respect to which
the function should be approximated. If the variable attribute remains
unset, it defaults to 'x'.

Called with no arguments, the method just returns the Math::Symbolic::Variable
object which internally represents the variable. You can use this object
in a string to interpolate as the variable name.

Called with an argument, the first argument is treated as a new variable
in respect to which the function should be approximated. The variable
may be specified either as a string which will be parsed as the name of
a new Math::Symbolic::Variable object or as an existing 
Math::Symbolic::Variable.

The method always returns the current variable.

When retrieving or setting the variable as a Math::Symbolic::Variable object,
the object is not cloned.

Please refer to L<Math::Symbolic::Variable> for details.

=cut

sub variable {
    my $self = shift;
    if ( not @_ ) {
        return $self->{variable};
    }
    my $variable = shift;
    if (
        defined $variable
        and ( ref($variable) eq 'Math::Symbolic::Variable'
            or not ref($variable) )
      )
    {
        if ( not ref($variable) ) {
            my $parsed;
            eval { $parsed = Math::Symbolic::Variable->new($variable); };
            if (   $@
                or not defined $parsed
                or not ref($parsed) =~ /^Math::Symbolic::Variable/ )
            {
                confess <<"HERE"
Could not parse variable of Math::Taylor object as Math::Symbolic::Variable.
Argument was: '$variable'
Error (if any) was: '$@'
HERE
            }
            $variable = $parsed;
        }

        # Is the variable contained in the function at all?
        $self->_is_variable_in_function( $self->{function}, $variable );
    }
    else {
        confess
          "Tried to create a variable for Math::Taylor object from dubious"
          . "source. Source: '"
          . ( !defined($variable) ? 'undef' : $variable ) . "'";
    }
    $self->{variable} = $variable;
    return $variable;
}

# Internal method to test whether a given variable is actually part of
# a function's signature.
sub _is_variable_in_function {
    my $self      = shift;
    my $function  = shift;
    my $var       = shift;
    my %signature = map { ( $_, undef ) } $function->explicit_signature();
    if ( not exists $signature{ $var->to_string() } ) {
        confess <<"HERE";
Variable not contained in function to approximate.
Variable: '$var'
Function: '$function'
HERE
    }
}

=item Accessor remainder_type()

This accessor can be used to get or set the type of remainder
of the Taylor Series. If this attribute is not set,
it defaults to C<lagrange>.

Called with no arguments, the method just returns the remainder type.

Called with an argument, the first argument is treated as a name of a
remainder type to calculate. Valid values are either 'lagrange' or 'cauchy'.

For details, I have to refer you to the documentation of 
L<Math::Symbolic::MiscCalculus>.

The method always returns the current remainder type.

=cut

sub remainder_type {
    my $self = shift;
    if ( not @_ ) {
        return $self->{remainder_type};
    }
    my $err = shift;
    if ( defined $err and $err eq 'lagrange' or $err eq 'cauchy' ) {
        $self->{remainder_type} = $err;
    }
    else {
        confess
"Cannot set the 'remainder_type' attribute of a Math::Taylor object to anything\n"
          . "but 'cauchy' or 'lagrange'.";
    }
    return $self->{remainder_type};
}



=item taylor_poly()

This method calculates the Taylor polynomial of specified degree or of
degree 1 if none has been specified. The polynomial is returned as a Math::Symbolic tree.

Optional argument is the degree of the polynomial. Zeroth degree is the first
element of the series. That means, it's just the function evaluated at the
point of approximation.

=cut

sub taylor_poly {
	my $self = shift;
	my $degree = shift;
	$degree = 1 if not defined $degree;
	confess("The degree of a Taylor approximation has to be >= 0.")
		unless $degree >= 0;

	# Get all necessary data.
	my $function = $self->function()->new();
	my $variable = $self->variable();
	my $pos = $self->point();

	# Make sure we don't have any vars in the function that clash with
	# the nomenclature of the output of TaylorPolynomial:
	# If TaylorPolynomial uses "x" as variable, it will include "x_0" as
	# a new variable in the output.
	my $posname = $variable->to_string() . '_0';	
	my %sig = map {($_, undef)} $function->explicit_signature();
	my @replace;
	if (exists $sig{$posname}) {
		my $newname = $posname;
		while (exists $sig{$newname}) {
			$newname .= '_';
		}
		$function->implement($posname => $newname);
		@replace = ($newname, $posname);
	}

	my $poly = Math::Symbolic::MiscCalculus::TaylorPolynomial(
		$function,
		$degree,
		$variable,
		$pos
	);
	
	if (not defined $poly or not ref($poly) =~ /^Math::Symbolic/) {
		confess(
		"Could not calculate Taylor approximation of degree $degree using\n"
		."function '$function',\n position '$pos',\n and variable '$variable'."
		);
	}

	# Insert value for x_0
	$poly->implement($posname => $pos);
	
	# Undo all changes to variable names.
	if (@replace) {
		$poly->implement(@replace);
	}

	return $poly;
}



=item remainder()

This method calculates and returns the remainder of a Taylor polynomial of
specified degree. If no degree (>= 0) is specified as first argument,
degree 1 is assumed.

Depending on what has been set as remainder_type, the calculated
remainder may be either the Lagrange Remainder or the Cauchy Remainder.

The method takes two arguments, both optional. The first is the degree as
stated above. The second is the name of a new variable introduced to the
remainder term. This variable is called I<theta> in the documentation
of Math::Symbolic::MiscCalculus and ranges between 0 and 1. The default name is
thus I<theta>. Be careful when you are approximation a formula containing a
variable of that name.

For details, refer to the following web pages and Perl modules:

L<Math::Symbolic::MiscCalculus>

I<Eric W. Weisstein. "Lagrange Remainder." From MathWorld -- 
A Wolfram Web Resource. http://mathworld.wolfram.com/LagrangeRemainder.html>

I<Eric W. Weisstein. "Cauchy Remainder." From MathWorld -- 
A Wolfram Web Resource. http://mathworld.wolfram.com/CauchyRemainder.html>

=cut

sub remainder {
	my $self = shift;
	my $degree = shift;
	$degree = 1 if not defined $degree;
	confess("The degree of a Taylor approximation has to be >= 0.")
		unless $degree >= 0;
	
	my $tvar = shift;
	$tvar = Math::Symbolic::Variable->new('theta') if not defined $tvar;
	$tvar = Math::Symbolic::Variable->new($tvar);
	
	# Get all necessary data.
	my $function = $self->function()->new();
	my $variable = $self->variable();
	my $pos = $self->point();
	my $type = $self->{remainder_type};

	# Make sure we don't have any vars in the function that clash with
	# the nomenclature of the output of TaylorPolynomial:
	# If TaylorPolynomial uses "x" as variable, it will include "x_0" as
	# a new variable in the output.
	my $posname = $variable->to_string() . '_0';	
	my %sig = map {($_, undef)} $function->explicit_signature();
	my @replace;
	if (exists $sig{$posname}) {
		my $newname = $posname;
		while (exists $sig{$newname}) {
			$newname .= '_';
		}
		$function->implement($posname => $newname);
		@replace = ($newname, $posname);
	}

	# get remainder;
	my $rem;
	if ($type eq 'lagrange') {
		$rem = Math::Symbolic::MiscCalculus::TaylorErrorLagrange(
			$function, $degree, $variable, $pos, $tvar
		);
	} else {
		$rem = Math::Symbolic::MiscCalculus::TaylorErrorCauchy(
			$function, $degree, $variable, $pos, $tvar
		);
	}
	
	# Insert value for x_0
	$rem->implement($posname => $pos);
	
	# Undo all changes to variable names.
	if (@replace) {
		$rem->implement(@replace);
	}

	return $rem;
}





1;
__END__

=pod

=back

=head1 SEE ALSO

Have a look at L<Math::Symbolic> and in particular
L<Math::Symbolic::MiscCalculus> which implements the calculation of
the Taylor Polynomial.

New versions of this module can be found on
http://steffen-mueller.net or CPAN. 

The following web pages should explain enough about Taylor Expansions.

I<Eric W. Weisstein. "Taylor Series." From MathWorld -- 
A Wolfram Web Resource. http://mathworld.wolfram.com/TaylorSeries.html>

I<Eric W. Weisstein. "Lagrange Remainder." From MathWorld -- 
A Wolfram Web Resource. http://mathworld.wolfram.com/LagrangeRemainder.html>

I<Eric W. Weisstein. "Cauchy Remainder." From MathWorld -- 
A Wolfram Web Resource. http://mathworld.wolfram.com/CauchyRemainder.html>

=head1 AUTHOR

Steffen Mueller, E<lt>symbolic-module at steffen-mueller dot netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Steffen Mueller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.6.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
