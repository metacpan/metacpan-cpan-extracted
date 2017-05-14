# ########################################################################################
# A TAYLOR SERIES EQUIVALENCE OBJECT
# Copyright (C) Jonathan Worthington 2005
# This module may be used and distributed under the same terms as Perl.
# ########################################################################################

package Math::Calculus::TaylorEquivalent;
use Math::Calculus::Expression;
use strict;
our $VERSION = '0.1';
our @ISA = qw/Math::Calculus::Expression/;
our $DEFAULTCOMPTERMS = 5;
our $DEFAULTERROR = 0;

=head1 NAME

Math::Calculus::TaylorEquivalent - Estimating expression equivalence by decomposition
into basis functions.

=head1 SYNOPSIS

  use Math::Calculus::TaylorEquivalent;

  # Create an object.
  my $exp1 = Math::Calculus::TaylorEquivalent->new;
  my $exp2 = Math::Calculus::TaylorEquivalent->new;
  
  # Set variables and expressions.
  $exp1->addVariable('x');
  $exp1->setExpression('(x + 1)*(x - 1)') or die $exp1->getError;
  $exp2->addVariable('x');
  $exp2->setExpression('x^2 - 1') or die $exp2->getError;
  
  # Check equivalence.
  my $result = $exp1->taylorEquivalent($exp2, 'x', 0);
  die $exp1->getError unless defined $result;
  print $result; # Prints 1
  
  # Example where they are not equivalent.
  $exp2->addVariable('x');
  $exp2->setExpression('x^2 + 1') or die $exp2->getError;
  
  # Check equivalence.
  my $result = $exp1->taylorEquivalent($exp2, 'x', 0);
  die $exp1->getError unless defined $result;
  print $result; # Prints 0
  

=head1 DESCRIPTION

This module provides an expression object with a Taylor Equivalent method, which
decomposes the expression and another expression into the first N terms of their
Taylor series and compares the co-efficients so try and decide whether the expressions
are equivalent.

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


# Taylor Equivalent.
# ##################

=item taylorEquivalent

  $boolean = $exp1->taylorEquivalent($exp2, $variable, $about);
  $boolean = $exp1->taylorEquivalent($exp2, $variable, $about, $compTerms);
  $boolean = $exp1->taylorEquivalent($exp2, $variable, $about, $compTerms, $maxError);

Takes the current expression and another expression and calculates the first
$compTerms (default 5) terms of their Taylor Series. Tnese terms are then
compared, and if the difference between the co-efficients in each is no greater
than $maxError (default 0) then it returns true. This suggests that the expressions
are equivalent. The Taylor series is taken with respect to the variable $variable
and about $about. 0 is often a good value.
=cut

sub taylorEquivalent {
	# Get invocant and parameters.
	my ($self, $exp2, $variable, $about, $compTerms, $error) = @_;
	
	# Clear error and traceback.
	$self->{'error'} = $self->{'traceback'} = '';
	
	# Check variable is in the list of variables.
	unless (grep { $_ eq $variable } @{$self->{'variables'}})
	{
		$self->{'error'} = 'Function variable was not declared.';
		return undef;
	}
	
	# Check number of terms is sane.
	unless ($compTerms =~ /^\d+$/)
	{
		$compTerms = $DEFAULTCOMPTERMS;
	}
	
	# Check error condition is OK or use default.
	unless ($error =~ /^\d+(?:\.\d+)?$/)
	{
		$error = $DEFAULTERROR;
	}
	
	# Check about value is sane.
	unless ($about =~ /^[\-\d\.]+$/)
	{
		$self->{'error'} = 'Attempt to evaluate Taylor series about an invalid value.';
		return undef;
	}
	
	# Now calculate co-efficients for each expression.
	my @coeffs1 = $self->taylorSeries_coeffs($variable, $compTerms, $about);
	my @coeffs2 = $exp2->taylorSeries_coeffs($variable, $compTerms, $about);
	
	# Do comparrison.
	my $result = 1;
	for (my $i = 0; $i < $compTerms; $i++) {
		if (abs($coeffs1[$i] - $coeffs2[$i]) > $error) {
			$result = 0;
			last;
		}
	}
	
	# Return the result if no errors.
	if ($self->{'error'}) {
		return undef;
	} else {
		return $result;
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
