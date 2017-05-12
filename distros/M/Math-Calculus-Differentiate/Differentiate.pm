# ########################################################################################
# A CALCULUS DIFFERENTIATION OBJECT
# An implementation of algebraic differentiation by Jonathan Worthington.
# Copyright (C) Jonathan Worthington 2004
# This module may be used and distributed under the same terms as Perl.
# ########################################################################################

package Math::Calculus::Differentiate;
use 5.006;
use Math::Calculus::Expression;
use strict;
our $VERSION = '0.3';
our @ISA = qw/Math::Calculus::Expression/;

=head1 NAME

Math::Calculus::Differentiate - Algebraic Differentiation Engine

=head1 SYNOPSIS

  use Math::Calculus::Differentiate;

  # Create an object.
  my $exp = Math::Calculus::Differentiate->new;
  
  # Set a variable and expression.
  $exp->addVariable('x');
  $exp->setExpression('x^2 + 5*x') or die $exp->getError;
  
  # Differentiate and simplify.
  $exp->differentiate or die $exp->getError;;
  $exp->simplify or die $exp->getError;;
  
  # Print the result.
  print $exp->getExpression; # Prints 2*x + 5
  

=head1 DESCRIPTION

This module can take an algebraic expression, parse it into a tree structure, modify
the tree to give a representation of the differentiated function, simplify the tree
and turn the tree back into an output of the same form as the input.

It supports differentiation of expressions including the +, -, *, / and ^ (raise to
power) operators, bracketed expressions to enable correct precedence and the functions
ln, exp, sin, cos, tan, sec, cosec, cot, sinh, cosh, tanh, sech, cosech, coth, asin,
acos, atan, asinh, acosh and atanh.

=head1 EXPORT

None by default.

=head1 METHODS

=item new

  $exp = Math::Calculus::Differentiate->new;

Creates a new instance of the differentiation engine, which can hold an individual
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


# Differentiate.
# ##############

=item differentiate

  $exp->differentiate('x');

Differentiates the expression that was stored with setExpression with respect to the variable
passed as a parameter. Returns undef on failure and a true value on success.

=cut

sub differentiate {
	# Get invocant and variable.
	my ($self, $variable) = @_;
	
	# Check variable is in the list of variables.
	return undef unless grep { $_ eq $variable } @{$self->{'variables'}};
	
	# Clear error and traceback, and pass control to the differentiate routine.
	$self->{'error'} = $self->{'traceback'} = undef;
	eval {
		$self->{'expression'} = $self->differentiateTree($variable, $self->{'expression'});
	};
	
	# Return an appropriate value (or lack thereof...).
	if ($self->{'error'}) {
		return undef;
	} else {
		return 1;
	}
}


=item simplify

  $exp->simplify;

Attempts to simplify the expression that is stored internally. It is a very good idea to call
this after calling differentiate, as the tree will often not be in the most compact possible
form, and this will affect the readability of output from getExpression and the performance
of future calls to differentiate if you are intending to obtain higher derivatives. Returns
undef on failure and a true value on success.

=item getTraceback

  $exp->getTraceback;

When setExpression and differentiate are called, a traceback is generated to describe
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


# ########################################################################################
# Private Methods
# ########################################################################################

# Differentiate Tree explores the current expression tree, recursively differentiating
# the branches of the tree.
# ########################################################################################
sub differentiateTree {
	# Get invocant, variable and tree.
	my ($self, $variable, $tree) = @_;
	
	# Generate traceback.
	$self->{'traceback'} .= "Parsing " . $self->prettyPrint($tree) . "\n";
	
	# If we're at a node...
	unless (ref $tree) {
		# Is it the variable?
		if ($tree eq $variable) {
			# It goes to 1.
			return 1;
		
		# Or - the variable...
		} elsif ($tree eq "-$variable") {
			# It goes to -1.
			return -1;
		
		# Otherwise, it's a constant and goes to zero.
		} else {
			return 0;
		}
	} else {
		# We've got a complex expression. Our actions from here depend on what the
		# expression is.
		
		# Addition or subtraction - just differentiate each operand.
		if ($tree->{'operation'} eq '+' || $tree->{'operation'} eq '-') {
			return {
				operation	=> $tree->{'operation'},
				operand1	=> $self->differentiateTree($variable, $tree->{'operand1'}),
				operand2	=> $self->differentiateTree($variable, $tree->{'operand2'})
			};
		
		# Multiplication.
		} elsif ($tree->{'operation'} eq '*') {
			# Check if any branches are constant.
			my $o1c = $self->isConstant($variable, $tree->{'operand1'});
			my $o2c = $self->isConstant($variable, $tree->{'operand2'});
			
			# If they're both constant, return the tree as it is.
			if ($o1c && $o2c) {
				return $tree;
			
			# If the first is constant, only differentiate the second.
			} elsif ($o1c) {
				return {
					operation	=> $tree->{'operation'},
					operand1	=> $tree->{'operand1'},
					operand2	=> $self->differentiateTree($variable, $tree->{'operand2'})
				};
			
			# If the second is constant, only differentiate the first.
			} elsif ($o2c) {
				return {
					operation	=> $tree->{'operation'},
					operand1	=> $self->differentiateTree($variable, $tree->{'operand1'}),
					operand2	=> $tree->{'operand2'}
				};
			
			# Otherwise, it's the product rule. d[uv] = udv + vdu
			} else {
				return {
					operation	=> '+',
					operand1 	=>
						{
							operation	=> '*',
							operand1	=> $tree->{'operand1'},
							operand2	=> $self->differentiateTree($variable, $tree->{'operand2'})
						},
					operand2 	=>
						{
							operation	=> '*',
							operand1	=> $tree->{'operand2'},
							operand2	=> $self->differentiateTree($variable, $tree->{'operand1'})
						}
				};
			}
		
		# Division.
		} elsif ($tree->{'operation'} eq '/') {
			# Check if any branches are constant.
			my $o1c = $self->isConstant($variable, $tree->{'operand1'});
			my $o2c = $self->isConstant($variable, $tree->{'operand2'});
			
			# If they're both constant, return the tree as it is.
			if ($o1c && $o2c) {
				return $tree;
			
			# If the denominator is constant, just differentiate the top.
			} elsif ($o2c) {
				return {
					operation	=> '/',
					operand1	=> $self->differentiateTree($variable, $tree->{'operand1'}),
					operand2	=> $tree->{'operand2'}
				};
			
			# If the numerator is constant, e.g. k/u, then return k * d[u^-1].
			} elsif ($o1c) {
				my $uinv = {
					operation	=> '^',
					operand1	=> $tree->{'operand2'},
					operand2	=> -1
				};
				return {
					operation	=> '*',
					operand1	=> $tree->{'operand1'},
					operand2	=> $self->differentiateTree($variable, $uinv)
				}
			
			# Otherwise, neither is constant. Use d[u/v] = (vdu - udv) / v^2.
			} else {
				my $vdu = {
					operation	=> '*',
					operand2	=> $tree->{'operand2'},
					operand1	=> $self->differentiateTree($variable, $tree->{'operand1'})
				};
				my $udv = {
					operation	=> '*',
					operand2	=> $tree->{'operand1'},
					operand1	=> $self->differentiateTree($variable, $tree->{'operand2'})
				};
				return {
					operation	=> '/',
					operand1	=>
						{
							operation	=> '-',
							operand1	=> $vdu,
							operand2	=> $udv
						},
					operand2	=>
						{
							operation	=> '^',
							operand1	=> $tree->{'operand2'},
							operand2	=> 2
						}
				};
			}	
			
			
		# Powers.
		} elsif ($tree->{'operation'} eq '^') {
			# Check if any branches are constant.
			my $o1c = $self->isConstant($variable, $tree->{'operand1'});
			my $o2c = $self->isConstant($variable, $tree->{'operand2'});
			
			# If they're both constant, return the tree as it is.
			if ($o1c && $o2c) {
				return $tree;
			
			# If the power is constant...
			} elsif ($o2c) {
				# d[(f(x))^n] = n*f'(x)*f(x)^(n-1)
				return {
					operation	=> '*',
					operand1	=> $tree->{'operand2'},
					operand2	=>
						{
							operation	=> '*',
							operand1	=> $self->differentiateTree($variable, $tree->{'operand1'}),
							operand2	=>
								{
									operation	=> '^',
									operand1	=> $tree->{'operand1'},
									operand2	=>
										{
											operation	=> '-',
											operand1	=> $tree->{'operand2'},
											operand2	=> 1
										}
								}
						}
				};
			
			# If the value being raised to a power is constant...
			} elsif ($o1c) {
				# d[k^v] = dv * ln(k) * exp(ln(k) * v)
				my $dv = $self->differentiateTree($variable, $tree->{'operand2'});
				my $lnk = {
					operation	=> 'ln',
					operand1	=> $tree->{'operand1'},
					operand2	=> undef
				};
				return {
					operation	=> '*',
					operand1	=> $dv,
					operand2	=>
						{
							operation	=> '*',
							operand1	=> $lnk,
							operand2	=>
								{
									operation	=> 'exp',
									operand1	=>
										{
											operation	=> '*',
											operand1	=> $lnk,
											operand2	=> $tree->{'operand2'}
										},
									operand2	=> undef
								}
						}
				};
				
			
			# If it's a function of the variable raised to another function of the variable...
			} else {
				# d[u^v] = exp(ln(u) * v) * ((vdu)/u + ln(u)dv)
				my $lnu = {
					operation	=> 'ln',
					operand1	=> $tree->{'operand1'},
					operand2	=> undef
				};
				my $dv = $self->differentiateTree($variable, $tree->{'operand2'});
				my $vdu = {
					operation	=> '*',
					operand1	=> $tree->{'operand2'},
					operand2	=> $self->differentiateTree($variable, $tree->{'operand1'})
				};
				return {
					operation	=> '*',
					operand1	=>
						{
							operation	=> 'exp',
							operand1	=>
								{
									operation	=> '*',
									operand1	=> $lnu,
									operand2	=> $tree->{'operand2'}
								},
							operand2	=> undef
						},
					operand2	=>
						{
							operation	=> '+',
							operand1	=>
								{
									operation	=> '/',
									operand1	=> $vdu,
									operand2	=> $tree->{'operand1'}
								},
							operand2	=>
								{
									operation	=> '*',
									operand1	=> $lnu,
									operand2	=> $dv
								}
						}
				};
			}
		
		# Natural logarithm
		} elsif ($tree->{'operation'} =~ /^(\-?)ln$/) {
			# Stash negativity.
			my $neg = $1;
			
			# d[ln(u)] = du/u
			my $du = $self->differentiateTree($variable, $tree->{'operand1'});
			return {
				operation	=> '*',
				operand1	=> "${neg}1",
				operand2	=>
					{
						operation	=> '/',
						operand1	=> $du,
						operand2	=> $tree->{'operand1'}
					}
			};
			
		# Exponential (e)
		} elsif ($tree->{'operation'} =~ /^(\-?)exp$/) {
			# Stash negativity.
			my $neg = $1;
			
			# d[exp(u)] = exp(u)du
			my $du = $self->differentiateTree($variable, $tree->{'operand1'});
			return {
				operation	=> '*',
				operand1	=> $du,
				operand2	=> $tree
			};
			
		# sin
		} elsif ($tree->{'operation'} =~ /^(\-?)sin$/) {
			# Stash negativity.
			my $neg = $1;
			
			# d[sin(u)] = cos(u)du
			my $du = $self->differentiateTree($variable, $tree->{'operand1'});
			return {
				operation	=> '*',
				operand1	=> $du,
				operand2	=>
					{
						operation	=> "${neg}cos",
						operand1	=> $tree->{'operand1'},
						operand2	=> undef
					}
			};
		
		# cos
		} elsif ($tree->{'operation'} =~ /^(\-?)cos$/) {
			# Stash negativity.
			my $neg = $1 eq '-' ? '' : '-';
			
			# d[cos(u)] = -sin(u)du
			my $du = $self->differentiateTree($variable, $tree->{'operand1'});
			return {
				operation	=> '*',
				operand1	=> $du,
				operand2	=>
					{
						operation	=> "${neg}sin",
						operand1	=> $tree->{'operand1'},
						operand2	=> undef
					}
			};
		
		# tan
		} elsif ($tree->{'operation'} =~ /^(\-?)tan$/) {
			# Stash negativity.
			my $neg = $1;
			
			# d[tan(u)] = (sec(u))^2 * du
			my $du = $self->differentiateTree($variable, $tree->{'operand1'});
			return {
				operation	=> '*',
				operand1	=> "${neg}1",
				operand2	=>
					{
						operation	=> '*',
						operand1	=> $du,
						operand2	=>
							{
								operation	=> '^',
								operand1	=>
									{
										operation	=> "sec",
										operand1	=> $tree->{'operand1'},
										operand2	=> undef
									},
								operand2	=> 2
							}
					}
			};
		
		# sec
		} elsif ($tree->{'operation'} =~ /^(\-?)sec$/) {
			# Stash negativity.
			my $neg = $1;
			
			# Convert to 1/cos and differentiate.
			return $self->differentiateTree($variable, {
				operation	=> '/',
				operand1	=> "${neg}1",
				operand2	=> 
					{
						operation	=> 'cos',
						operand1	=> $tree->{'operand1'},
						operand2	=> undef
					}
			});
		
		# cosec
		} elsif ($tree->{'operation'} =~ /^(\-?)cosec$/) {
			# Stash negativity.
			my $neg = $1;
			
			# Convert to 1/sin and differentiate.
			return $self->differentiateTree($variable, {
				operation	=> '/',
				operand1	=> "${neg}1",
				operand2	=> 
					{
						operation	=> 'sin',
						operand1	=> $tree->{'operand1'},
						operand2	=> undef
					}
			});
		
		# cot
		} elsif ($tree->{'operation'} =~ /^(\-?)cot$/) {
			# Stash negativity.
			my $neg = $1;
			
			# Convert to 1/tan and differentiate.
			return $self->differentiateTree($variable, {
				operation	=> '/',
				operand1	=> "${neg}1",
				operand2	=> 
					{
						operation	=> 'tan',
						operand1	=> $tree->{'operand1'},
						operand2	=> undef
					}
			});
		
		# sinh
		} elsif ($tree->{'operation'} =~ /^(\-?)sinh$/) {
			# Stash negativity.
			my $neg = $1;
			
			# d[sinh(u)] = cosh(u)du
			my $du = $self->differentiateTree($variable, $tree->{'operand1'});
			return {
				operation	=> '*',
				operand1	=> $du,
				operand2	=>
					{
						operation	=> "${neg}cosh",
						operand1	=> $tree->{'operand1'},
						operand2	=> undef
					}
			};
		
		# cosh
		} elsif ($tree->{'operation'} =~ /^(\-?)cosh$/) {
			# Stash negativity.
			my $neg = $1;
			
			# d[cosh(u)] = sinh(u)du
			my $du = $self->differentiateTree($variable, $tree->{'operand1'});
			return {
				operation	=> '*',
				operand1	=> $du,
				operand2	=>
					{
						operation	=> "${neg}sinh",
						operand1	=> $tree->{'operand1'},
						operand2	=> undef
					}
			};
		
		# tanh
		} elsif ($tree->{'operation'} =~ /^(\-?)tanh$/) {
			# Stash negativity.
			my $neg = $1;
			
			# d[tanh(u)] = (sech(u))^2 * du
			my $du = $self->differentiateTree($variable, $tree->{'operand1'});
			return {
				operation	=> '*',
				operand1	=> "${neg}1",
				operand2	=>
					{
						operation	=> '*',
						operand1	=> $du,
						operand2	=>
							{
								operation	=> '^',
								operand1	=>
									{
										operation	=> "sech",
										operand1	=> $tree->{'operand1'},
										operand2	=> undef
									},
								operand2	=> 2
							}
					}
			};
		
		# sech
		} elsif ($tree->{'operation'} =~ /^(\-?)sech$/) {
			# Stash negativity.
			my $neg = $1;
			
			# Convert to 1/cosh and differentiate.
			return $self->differentiateTree($variable, {
				operation	=> '/',
				operand1	=> "${neg}1",
				operand2	=> 
					{
						operation	=> 'cosh',
						operand1	=> $tree->{'operand1'},
						operand2	=> undef
					}
			});
		
		# cosech
		} elsif ($tree->{'operation'} =~ /^(\-?)cosech$/) {
			# Stash negativity.
			my $neg = $1;
			
			# Convert to 1/sinh and differentiate.
			return $self->differentiateTree($variable, {
				operation	=> '/',
				operand1	=> "${neg}1",
				operand2	=> 
					{
						operation	=> 'sinh',
						operand1	=> $tree->{'operand1'},
						operand2	=> undef
					}
			});
		
		# coth
		} elsif ($tree->{'operation'} =~ /^(\-?)coth$/) {
			# Stash negativity.
			my $neg = $1;
			
			# Convert to 1/tanh and differentiate.
			return $self->differentiateTree($variable, {
				operation	=> '/',
				operand1	=> "${neg}1",
				operand2	=> 
					{
						operation	=> 'tanh',
						operand1	=> $tree->{'operand1'},
						operand2	=> undef
					}
			});
		
		# asin
		} elsif ($tree->{'operation'} =~ /^(\-?)asin$/) {
			# Stash negativity.
			my $neg = $1;
			
			# d[asin(u)] = du / (1 - u^2)^0.5
			my $du;
			if ($neg) {
				$du = {
					operation	=> '-',
					operand1	=> '0',
					operand2	=> $self->differentiateTree($variable, $tree->{'operand1'})
				};
			} else {
				$du = $self->differentiateTree($variable, $tree->{'operand1'});
			}
			return {
				operation	=> '/',
				operand1	=> $du,
				operand2	=>
					{
						operation	=> '^',
						operand1	=>
							{
								operation	=> '-',
								operand1	=> 1,
								operand2	=>
									{
										operation	=> '^',
										operand1	=> $tree->{'operand1'},
										operand2	=> 2
									}
							},
						operand2	=> 0.5
					}
			};
		
		# acos
		} elsif ($tree->{'operation'} =~ /^(\-?)acos$/) {
			# Stash negativity.
			my $neg = $1;
			
			# d[acos(u)] = -du / (1 - u^2)^0.5
			my $du;
			if ($neg) {
				$du = $self->differentiateTree($variable, $tree->{'operand1'});
			} else {
				$du = {
					operation	=> '-',
					operand1	=> '0',
					operand2	=> $self->differentiateTree($variable, $tree->{'operand1'})
				};
			}
			return {
				operation	=> '/',
				operand1	=> $du,
				operand2	=>
					{
						operation	=> '^',
						operand1	=>
							{
								operation	=> '-',
								operand1	=> 1,
								operand2	=>
									{
										operation	=> '^',
										operand1	=> $tree->{'operand1'},
										operand2	=> 2
									}
							},
						operand2	=> 0.5
					}
			};
		
		# atan
		} elsif ($tree->{'operation'} =~ /^(\-?)atan$/) {
			# Stash negativity.
			my $neg = $1;
			
			# d[atan(u)] = du / (1 + u^2)
			my $du;
			if ($neg) {
				$du = {
					operation	=> '-',
					operand1	=> '0',
					operand2	=> $self->differentiateTree($variable, $tree->{'operand1'})
				};
			} else {
				$du = $self->differentiateTree($variable, $tree->{'operand1'});
			}
			return {
				operation	=> '/',
				operand1	=> $du,
				operand2	=>
					{
						operation	=> '+',
						operand1	=> 1,
						operand2	=>
							{
								operation	=> '^',
								operand1	=> $tree->{'operand1'},
								operand2	=> 2
							}
					}
			};
		
		# asinh
		} elsif ($tree->{'operation'} =~ /^(\-?)asinh$/) {
			# Stash negativity.
			my $neg = $1;
			
			# d[asinh(u)] = du / (1 + u^2)^0.5
			my $du;
			if ($neg) {
				$du = {
					operation	=> '-',
					operand1	=> '0',
					operand2	=> $self->differentiateTree($variable, $tree->{'operand1'})
				};
			} else {
				$du = $self->differentiateTree($variable, $tree->{'operand1'});
			}
			return {
				operation	=> '/',
				operand1	=> $du,
				operand2	=>
					{
						operation	=> '^',
						operand1	=>
							{
								operation	=> '+',
								operand1	=> 1,
								operand2	=>
									{
										operation	=> '^',
										operand1	=> $tree->{'operand1'},
										operand2	=> 2
									}
							},
						operand2	=> 0.5
					}
			};
		
		# acosh
		} elsif ($tree->{'operation'} =~ /^(\-?)acosh$/) {
			# Stash negativity.
			my $neg = $1;
			
			# d[acosh(u)] = du / (u^2 - 1)^0.5
			my $du;
			if ($neg) {
				$du = {
					operation	=> '-',
					operand1	=> '0',
					operand2	=> $self->differentiateTree($variable, $tree->{'operand1'})
				};
			} else {
				$du = $self->differentiateTree($variable, $tree->{'operand1'});
			}
			return {
				operation	=> '/',
				operand1	=> $du,
				operand2	=>
					{
						operation	=> '^',
						operand1	=>
							{
								operation	=> '-',
								operand1	=>
									{
										operation	=> '^',
										operand1	=> $tree->{'operand1'},
										operand2	=> 2
									},
								operand2	=> 1
							},
						operand2	=> 0.5
					}
			};
		
		# atanh
		} elsif ($tree->{'operation'} =~ /^(\-?)atanh$/) {
			# Stash negativity.
			my $neg = $1;
			
			# d[atanh(u)] = du / (1 - u^2)
			my $du;
			if ($neg) {
				$du = {
					operation	=> '-',
					operand1	=> '0',
					operand2	=> $self->differentiateTree($variable, $tree->{'operand1'})
				};
			} else {
				$du = $self->differentiateTree($variable, $tree->{'operand1'});
			}
			return {
				operation	=> '/',
				operand1	=> $du,
				operand2	=>
					{
						operation	=> '-',
						operand1	=> 1,
						operand2	=>
							{
								operation	=> '^',
								operand1	=> $tree->{'operand1'},
								operand2	=> 2
							}
					}
			};
		
		# Otherwise, we don't know what it is.
		} else {
			$self->{'error'} = "Could not differentiate " . $self->prettyPrint($tree);
			die;
		}
	}
}

1;



