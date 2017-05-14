# ########################################################################################
# A TAYLOR SERIES OBJECT
# This module takes an expression stored in a Math::Calculus::Expression object and
# returns the Taylor Series of it.
# Copyright (C) Jonathan Worthington 2005
# This module may be used and distributed under the same terms as Perl.
# ########################################################################################

package Math::Calculus::TaylorSeries;
use Math::Calculus::Expression;
use strict;
our $VERSION = '0.1';
our @ISA = qw/Math::Calculus::Expression/;
our $MAXITERATIONS = 100;

=head1 NAME

Math::Calculus::TaylorSeries - Decomposition of an expression into its Taylor Series

=head1 SYNOPSIS

  use Math::Calculus::TaylorSeries;

  # Create an object.
  my $exp = Math::Calculus::TaylorSeries->new;
  
  # Set a variable and expression.
  $exp->addVariable('x');
  $exp->setExpression('sin(x)') or die $exp->getError;
  
  # Get expression object for first 4 terms about x = 0.
  my $result = $exp->taylorSeries('x', 4, 0) or die $exp->getError;
  print $result->getExpression; # Prints x - x^3/6 + x^5/120 - x^7/5040
  

=head1 DESCRIPTION

This module can take an algebraic expression, parses it and then decomposes it into
a Taylor series, returning a new expression containing the first N elements.

It understands expressions containing any of the operators +, -, *, / and ^ (raise to
power), bracketed expressions to enable correct precedence and the functions ln,
exp, sin, cos, tan, sec, cosec, cot, sinh, cosh, tanh, sech, cosech, coth, asin,
acos, atan, asinh, acosh and atanh.

=head1 EXPORT

None by default.

=head1 METHODS

=cut

# Constructor
# ###########

=item new

  $exp = Math::Calculus::TaylorSeries->new;

Creates a new instance of the Taylor Series object, which can hold an individual
expression.

=item addVariable

  $exp->addVariable('x');

Sets a certain named value in the expression as being a variable. A named value must be
an alphabetic chracter.

=item setExpression

  $exp->setExpression('x^2 + 5*x);

Takes an expression in human-readable form and stores it internally as a tree structure,
checking it is a valid expression that the module can understand in the process. Note that
the engine is strict about syntax. For example, note above that you must write 5*x and not
just 5x. Whitespace is allowed in the expression, but does not have any effect on precedence.
If you require control of precedence, use brackets; bracketed expressions will always be
evaluated first, as you would normally expect. The module follows the BODMAS precedence
convention. Returns undef on failure and a true value on success.

=item getExpression

  $expr = $exp->getExpression;

Returns a textaul, human readable representation of the expression that is being stored.

=cut


# Taylor Series.
# ##############

=item taylorSeries

  $result = $exp->taylorSeries($variable, $terms, $about);

Finds the first $terms non-zero terms of the Taylor series of the expression object
for the variable $variable evaluated about the value $about and returns a new
expression object that represents it.
=cut

sub taylorSeries {
	# Get invocant and variable.
	my ($self, $variable, $terms, $about) = @_;
	
	# Clear error and traceback.
	$self->{'error'} = $self->{'traceback'} = '';
	
	# Check variable is in the list of variables.
	unless (grep { $_ eq $variable } @{$self->{'variables'}})
	{
		$self->{'error'} = 'Function variable was not declared.';
		return undef;
	}
	
	# Check number of terms is sane.
	unless ($terms =~ /^\d+$/ && $terms > 1)
	{
		$self->{'error'} = 'Attempt to evaluate Taylor series with an invalid number of terms.';
		return undef;
	}
	
	# Check about value is sane.
	unless ($about =~ /^[\-\d\.]+$/)
	{
		$self->{'error'} = 'Attempt to evaluate Taylor series about an invalid value.';
		return undef;
	}
	
	# Create a clone of the expression object that we'll differentiate and prepare to find co-efficients.
	my $diffExp = $self->clone;
	my @coeffs = ();
	my $coeffsFound = 0;
	
	# Loop until we've found enough terms or we hit our maximum number of iterations.
	my $numIters = 0;
	while ($coeffsFound < $terms) {
		# Evaluate.
		my $coeff = $diffExp->evaluate($variable => $about);
		return undef unless defined($coeff);
		
		# Put in co-effs list, and if it's non-zero then state we've found a term.
		push @coeffs, $coeff;
		$coeffsFound++ if $coeff != 0;
		
		# Differentiate for next round.
		return undef unless $diffExp->differentiate($variable);
		$diffExp->simplify;
		
		# Sanity check - we may run out of terms.
		last if ++$numIters == $MAXITERATIONS;
	}
	
	# Now we need to generate the expression with the real co-efficients.
	my @termList = ();
	for (my $i = 0; $i < @coeffs; $i++) {
		# If the co-efficient is non-zero, create the term and put it on the list.
		if ($coeffs[$i] != 0) {
			my $term = $coeffs[$i];
			$term .= '*' . $variable if $i > 0;
			$term .= '^' . $i if $i > 1;
			$term .= '/' . $self->fact($i);
			push @termList, $term;
		}
	}
	
	# Create a new expression object containing the term, and simplify.
	my $newExp = Math::Calculus::Expression->new;
	unless ($newExp->setExpression(join '+', @termList)) {
		$self->{'error'} = "Could not parse generated taylor series expression.";
	}
	$newExp->simplify;
	
	# Return the Taylor series, if no errors.
	if ($self->{'error'}) {
		return undef;
	} else {
		return $newExp;
	}
}


# Taylor Series Co-efficients.
# ############################

=item taylorSeries_coeffs

  $result = $exp->taylorSeries($variable, $numcoeffs, $about);

Returns an array containing the first $numcoeffs terms when the Taylor series for
the variable $variable is found about $about.
=cut

sub taylorSeries_coeffs {
	# Get invocant and variable.
	my ($self, $variable, $numCoeffs, $about) = @_;
	
	# Clear error and traceback.
	$self->{'error'} = $self->{'traceback'} = '';
	
	# Check variable is in the list of variables.
	unless (grep { $_ eq $variable } @{$self->{'variables'}})
	{
		$self->{'error'} = 'Function variable was not declared.';
		return ();
	}
	
	# Check number of co-efficients is sane.
	unless ($numCoeffs =~ /^\d+$/)
	{
		$self->{'error'} = 'Attempt to evaluate Taylor series with an invalid number of terms.';
		return ();
	}
	
	# Check about value is sane.
	unless ($about =~ /^[\-\d\.]+$/)
	{
		$self->{'error'} = 'Attempt to evaluate Taylor series about an invalid value.';
		return ();
	}
	
	# Create a clone of the expression object that we'll differentiate and prepare to find co-efficients.
	my $diffExp = $self->clone;
	my @coeffs = ();
	
	# Loop until we've found enough co-efficients.
	my $numIters = 0;
	while ($numIters < $numCoeffs) {
		# Evaluate.
		my $coeff = $diffExp->evaluate($variable => $about);
		return () unless defined($coeff);
		
		# Put in co-effs list.
		push @coeffs, $coeff;
		
		# Differentiate for next round.
		return undef unless $diffExp->differentiate($variable);
		$diffExp->simplify;
		
		# Increment counter.
		$numIters++;
	}
	
	# Return the list, if no errors.
	if ($self->{'error'}) {
		return ();
	} else {
		return @coeffs;
	}
}


=item getTraceback

  $exp->getTraceback;

When setExpression and taylorSeries are called, a traceback is generated to describe
what these functions did. If an error occurs, this traceback can be extremely useful
in helping track down the source of the error.

=item getError

  $exp->getError;

When any method other than getTraceback is called, the error message stored is cleared, and
then any errors that occur during the execution of the method are stored. If failure occurs,
call this method to get a textual representation of the error.

=head1 SEE ALSO

The author of this module has a website at L<http://www.jwcs.net/~jonathan/>, which has
the latest news about the module and a web-based frontend to allow you to test the module
out for yourself.

=head1 AUTHOR

Jonathan Worthington, E<lt>jonathan@jwcs.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Jonathan Worthington

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.1 or,
at your option, any later version of Perl 5 you may have available.

=cut


# Factorial routine.
sub fact {
	return $_[1] == 0 ? 1 : $_[1] * $_[0]->fact($_[1] - 1);
}


1;
