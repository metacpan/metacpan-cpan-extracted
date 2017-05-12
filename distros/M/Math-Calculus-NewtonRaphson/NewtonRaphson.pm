# ########################################################################################
# A NEWTON RAPHSON OBJECT
# This module takes an equation in symbolic form and uses the Newton Raphson technique
# to solve it.
# Copyright (C) Jonathan Worthington 2004
# This module may be used and distributed under the same terms as Perl.
# ########################################################################################

package Math::Calculus::NewtonRaphson;
use Math::Calculus::Expression;
use Math::Calculus::Differentiate;
use strict;
our $VERSION = '0.1';
our @ISA = qw/Math::Calculus::Expression/;
our $MAXITERATIONS = 100;

=head1 NAME

Math::Calculus::NewtonRaphson - Algebraic Newton Raphson Implementation

=head1 SYNOPSIS

  use Math::Calculus::NewtonRaphson;

  # Create an object.
  my $exp = Math::Calculus::NewtonRaphson->new;
  
  # Set a variable and expression.
  $exp->addVariable('x');
  $exp->setExpression('x^2 - 5') or die $exp->getError;
  
  # Apply Newton Raphson.
  my $result = $exp->newtonRaphson(2) or die $exp->getError;
  print $result; # Prints 1.4142...
  

=head1 DESCRIPTION

This module can take an algebraic expression, parses it and then uses the Newton Raphson
method to solve the it. The Newton Raphson method relies on the fact that the expression
you pass in evaluates to zero where there is a solution. That is, to solve:-

x^2 = 5

You would need to pass in:-

x^2 - 5

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

  $exp = Math::Calculus::NewtonRaphson->new;

Creates a new instance of the Newton Raphson object, which can hold an individual
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


# Newton Raphson.
# ###############

=item newtonRaphson

  $result = $exp->newtonRaphson($variable, $guess, %mappings);

Attempts to solve the expression for the given variable using the Newton Raphson method,
using the passed value as the first guess. The mappings hash allows any other non-numeric
constants to be mapped to numeric values - a pre-requisite for solving such equations.

=cut

sub newtonRaphson {
	# Get invocant and variable.
	my ($self, $variable, $guess, %mappings) = @_;
	
	# Clear error and traceback.
	$self->{'error'} = $self->{'traceback'} = '';
	
	# Check variable is in the list of variables.
	unless (grep { $_ eq $variable } @{$self->{'variables'}})
	{
		$self->{'error'} = 'Function variable was not declared.';
		return undef;
	}
	
	# Attempt to differentiate the expression.
	my $diffExp = Math::Calculus::Differentiate->new;
	$diffExp->setExpression($self->getExpression);
	$diffExp->addVariable($_) foreach @{$self->{'variables'}};
	unless ($diffExp->differentiate($variable)) {
		$self->{'error'} = 'Unable to differentiate expression';
		return undef;
	}
	
	# Build up an expression for us to plug values into.
	my $fiter = {
		operation	=> '/',
		operand1	=> $self->{'expression'},
		operand2	=> $diffExp->getExpressionTree
	};
	
	# Now iterate.
	my $curGuess = $guess;
	my $lastGuess = !$guess;
	my $iterations = 0;
	while ($iterations < $MAXITERATIONS && $curGuess != $lastGuess) {
		# Write traceback.
		$self->{'traceback'} .= "$iterations\t$curGuess\n";
		
		# Sub value in.
		$lastGuess = $curGuess;
		eval {
			$curGuess = $lastGuess - $self->evaluateTree($fiter, $variable => $lastGuess, %mappings);
		} || ($self->{'error'} ||= "Fatal error! $@");
		
		# Increment iterations counter.
		$iterations++;
	}
	
	# Return an appropriate value (or lack thereof...).
	if ($self->{'error'}) {
		return undef;
	} else {
		return $curGuess;
	}
}


=item getTraceback

  $exp->getTraceback;

When setExpression and newtonRaphson are called, a traceback is generated to describe
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

1;

