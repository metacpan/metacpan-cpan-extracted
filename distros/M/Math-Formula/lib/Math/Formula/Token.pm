# This code is part of Perl distribution Math-Formula version 0.17.
# The POD got stripped from this file by OODoc version 3.03.
# For contributors see file ChangeLog.

# This software is copyright (c) 2023-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later

#oodist: *** DO NOT USE THIS VERSION FOR PRODUCTION ***
#oodist: This file contains OODoc-style documentation which will get stripped
#oodist: during its release in the distribution.  You can use this file for
#oodist: testing, however the code of this development version may be broken!

use warnings;
use strict;

package Math::Formula::Token;{
our $VERSION = '0.17';
}


#!!! The declarations of all other packages in this file are indented to avoid
#!!! indexing by CPAN.

#!!! Classes and methods which are of interest of normal users are documented
#!!! in ::Types, because the package set-up caused too many issues with OODoc.

# The object is an ARRAY.
sub new(%) { my $class = shift; bless [@_], $class }


# Returns the token in string form.  This may be a piece of text as parsed
# from the expression string, or generated when the token is computed.

sub token  { $_[0][0] //= $_[0]->_token($_[0]->value) }
sub _token { $_[1] }

# MF::PARENS, parenthesis tokens
# Parser object to administer parenthesis, but disappears in the AST.

package
	MF::PARENS;

use base 'Math::Formula::Token';  #XXX module does not load with 'use parent'

sub level { $_[0][1] }

# MF::OPERATOR, operator of yet unknown type.
# In the AST upgraded to either MF::PREFIX or MF::INFIX.

package
	MF::OPERATOR;

use base 'Math::Formula::Token';
use Log::Report 'math-formula', import => [ 'panic' ];

use constant {
	# Associativity
	LTR => 1, RTL => 2, NOCHAIN => 3,
};

# method operator(): Returns the operator value in this token, which
# "accidentally" is the same value as the M<token()> method produces.
sub operator() { $_[0][0] }

sub compute
{	my ($self, $context) = @_;
	panic +(ref $self) . ' does not compute';
}

my %table;
{
	# Prefix operators and parenthesis are not needed here
	# Keep in sync with the table in Math::Formula
	my @order =	(
#		[ LTR,     ',' ],
		[ LTR,     '?', ':' ],        # ternary ?:
		[ NOCHAIN, '->' ],
		[ LTR,     qw/or xor/, '//' ],
		[ LTR,     'and' ],
		[ NOCHAIN, qw/ <=> < <= == != >= > / ],
		[ NOCHAIN, qw/ cmp lt le eq ne ge gt/ ],
		[ LTR,     qw/+ - ~/ ],
		[ LTR,     qw!* / %! ],
		[ LTR,     qw/=~ !~ like unlike/ ],
		[ LTR,     '#', '.' ],
	);

	my $level;
	foreach (@order)
	{	my ($assoc, @line) = @$_;
		$level++;
		$table{$_} = [ $level, $assoc ] for @line;
	}
}

# method find($operator)
# Returns a list with knowledge about a know operator.
# The first argument is a priority level for this operator.  The actual
# priority numbers may change over releases of this module.
# The second value is a constant of associativety.  Either the constant
# LTR (compute left to right), RTL (right to left), or NOCHAIN (non-stackable
# operator).

sub find($) { @{$table{$_[1]} // panic "op $_[1]" } }

# MF::PREFIX, monadic prefix operator
# Prefix operators process the result of the expression which follows it.
# This is a specialization from the MF::OPERATOR type, hence shares its methods.

package
	MF::PREFIX;

use base 'MF::OPERATOR';

# method child(): Returns the AST where this operator works on.
sub child() { $_[0][1] }

sub compute($$)
{	my ($self, $context) = @_;
	my $value = $self->child->compute($context)
		or return undef;

	$value->prefix($self->operator, $context);
}

# MF::INFIX, infix (dyadic) operator
# Infix operators have two arguments.  This is a specialization from the
# MF::OPERATOR type, hence shares its methods.

package
	MF::INFIX;

use base 'MF::OPERATOR';

# method left(): Returns the AST left from the infix operator.
sub left()  { $_[0][1] }

# method right(): Returns the AST right from the infix operator.
sub right() { $_[0][2] }

my %comparison = (
	'<'  => [ '<=>', sub { $_[0] <  0 } ],
	'<=' => [ '<=>', sub { $_[0] <= 0 } ],
	'==' => [ '<=>', sub { $_[0] == 0 } ],
	'!=' => [ '<=>', sub { $_[0] != 0 } ],
	'>=' => [ '<=>', sub { $_[0] >= 0 } ],
	'>'  => [ '<=>', sub { $_[0] >  0 } ],
	'lt' => [ 'cmp', sub { $_[0] <  0 } ],
	'le' => [ 'cmp', sub { $_[0] <= 0 } ],
	'eq' => [ 'cmp', sub { $_[0] == 0 } ],
	'ne' => [ 'cmp', sub { $_[0] != 0 } ],
	'ge' => [ 'cmp', sub { $_[0] >= 0 } ],
	'gt' => [ 'cmp', sub { $_[0] >  0 } ],
);

sub _compare_ops { keys %comparison }

sub compute($$)
{	my ($self, $context) = @_;

	my $left  = $self->left->compute($context)
		or return undef;

	my $right = $self->right->compute($context)
		or return undef;

	# Comparison operators are all implemented via a space-ship, when available.
	# Otherwise, the usual track is taken.

	my $op = $self->operator;
	if(my $rewrite = $comparison{$op})
	{	my ($spaceship, $compare) = @$rewrite;
		if(my $result = $left->infix($spaceship, $right, $context))
		{	return MF::BOOLEAN->new(undef, $compare->($result->value));
		}
	}

	$left->infix($op, $right, $context);
}


# MF::TERNARY,  if ? then : else
# Ternary operators have three arguments.  This is a specialization from the
# MF::OPERATOR type, hence shares its methods.

package
	MF::TERNARY;

use base 'MF::OPERATOR';

sub condition() { $_[0][1] }
sub then()      { $_[0][2] }
sub else()      { $_[0][3] }

sub compute($$)
{	my ($self, $context) = @_;

	my $cond  = $self->condition->compute($context)
		or return undef;

	($cond->value ? $self->then : $self->else)->compute($context)
}

# When used, this returns a MF::STRING taken from the captures in the context.

package
	MF::CAPTURE;
use base 'Math::Formula::Token';

sub seqnr() { $_[0][0] }

sub compute($$)
{	my ($self, $context) = @_;
	my $v = $context->capture($self->seqnr -1);
	defined $v ? MF::STRING->new(undef, $v) : undef;
}

1;
