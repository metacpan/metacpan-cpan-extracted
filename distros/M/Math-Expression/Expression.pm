#!/usr/bin/perl -w
#      /\
#     /  \		(C) Copyright 2003 Parliament Hill Computers Ltd.
#     \  /		All rights reserved.
#      \/
#       .		Author: Alain Williams, First written January 2003; last update July 2016
#       .		addw@phcomp.co.uk
#        .
#          .
#
#	SCCS: @(#)Expression.pm	1.47 07/21/16 12:48:37
#
# This module is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself. You must preserve this entire copyright
# notice in any use or distribution.
# The author makes no warranty what so ever that this code works or is fit
# for purpose: you are free to use this code on the understanding that any problems
# are your responsibility.

# Permission to use, copy, modify, and distribute this software and its documentation for any purpose and without fee is
# hereby granted, provided that the above copyright notice appear in all copies and that both that copyright notice and
# this permission notice appear in supporting documentation.

use strict;

package Math::Expression;

use Exporter;
use POSIX qw(strftime mktime);

# What local variables - visible elsewhere
use vars qw/
	@ISA @EXPORT
	/;

@ISA = ('Exporter');

@EXPORT = qw(
        &CheckTree
	&Eval
	&EvalToScalar
	&EvalTree
	&FuncValue
	&Parse
	&ParseString
	&ParseToScalar
	&SetOpts
	&VarSetFun
	&VarSetScalar
	$Version
);

our $VERSION = "1.47";

# Fundamental to this is a tree of nodes.
# Nodes are hashes with members:
# oper (var, *, >, ...)
# left & right (refs to nodes)
# monop (boolean)
# name (on var nodes)
# fname (on func nodes)
# val (on const nodes)
# flow (on flow nodes)

# Within ParseString() there are 2 stacks:
# @tree (of nodes) - this is what is eventually returned
#   Terminals (var, const) are pushed here as they are read in
# @operators all non terminals with JR-precedence > TOS-precedence start off being pushed here.
#   Where JR-precedence <= TOS-precedence do 'reduce', ie move from @operators to @tree as a tree,
#   with left/right children coming from @tree and the operator pushed to @tree.
# It is interesting to print the tree with the Data::Dumper or PrintTree().


# Operator precedence, higher means bind more tightly to operands - ie evaluate first.
# If precedence values are the same associate to the left.
# 2 values, depending on if it is the TopOfStack or JustRead operator - [TOS, JR]. See ':=' which right associates.
# Just binary operators makes life easier as well.
# Getting the precedence values right is a pain and for things like close paren, non obvious.
# Far apart numbers makes adding new ones easier.

my %OperPrec = (
	'var'	=>	[240, 240],
	'const'	=>	[240, 240],
	'['	=>	[70, 230],
	'++'	=>	[220, 220],
	'--'	=>	[220, 220],
	'M-'	=>	[200, 210],	# Monadic -
	'M+'	=>	[200, 210],	# Monadic +
	'M!'	=>	[200, 210],
	'M~'	=>	[200, 210],
	'**'	=>	[190, 190],
	'*'	=>	[180, 180],
	'/'	=>	[180, 180],
	'%'	=>	[180, 180],
	'+'	=>	[170, 170],
	'-'	=>	[170, 170],
	'.'	=>	[160, 160],
	'>'	=>	[150, 150],
	'<'	=>	[150, 150],
	'>='	=>	[150, 150],
	'<='	=>	[150, 150],
	'=='	=>	[150, 150],
	'!='	=>	[150, 150],
	'<>'	=>	[150, 150],
	'lt'	=>	[150, 150],
	'gt'	=>	[150, 150],
	'le'	=>	[150, 150],
	'ge'	=>	[150, 150],
	'eq'	=>	[150, 150],
	'ne'	=>	[150, 150],
	'&&'	=>	[140, 140],
	'||'	=>	[130, 130],
	':'	=>	[120, 120],
	'?'	=>	[110, 110],
	','	=>	[100, 101],		# Build list 1,2,3,4 as ,L[1]R[,L[2]R[,L[3]R[4]]]
	'('	=>	[90, 220],
	')'	=>	[90, 90],	
	'func'	=>	[210, 220],
	']'	=>	[70, 70],
	':='	=>	[50, 60],		# 6 to make := right assosc
	'}'	=>	[40, 00],
	'flow'	=>	[30, 40],
	';'	=>	[20, 20],
	'{'	=>	[10, 0],
	'EOF'	=>	[-50, -50],
);
# TOS, JR
# Nothing special about -ve precedence, just saves renumbering when I got to zero.

# Monadic/Unary operators:
my %MonOp = (
	'-'	=>	20,
	'+'	=>	20,
	'!'	=>	20,
	'~'	=>	20,
);

# MonVarOp - operate on variables, but treat much like monops:
my %MonVarOp = (
	'++'	=>	22,
	'--'	=>	22,
);

# Closing operators on opening ones. NOT [ ]
my %MatchOp = (
	'('	=>	')',
	'{'	=>	'}',
);

my %MatchOpClose = reverse %MatchOp; # Reverse lookup

# Inbuilt functions, copied to property Functions
my %InFuns = map { $_ => 1} qw/ abs aindex count defined int join localtime mktime pop printf push round shift split strftime strlen unshift /;
# Inbuilt functions that must be given a L value
# This does not need to be externally visible with our, any ExtraFuncEval that adds to it will cope
my %InFunLV = map { $_ => 1} qw / defined pop push shift unshift /;

# Escape chars recognised:
my %escapes = ( n => "\n", r => "\r", t => "\t", '\\' => '\\' );

# Default error output function
sub PrintError {
	my $self = shift;
	if(defined $self->{PrintErrFunc} && $self->{PrintErrFunc}) {
		$self->{PrintErrFunc}(@_);
		return;
	}

	printf STDERR @_;
	print STDERR "\n";
}

# Default function to set a variable value, store as a reference to an array.
# Assign to a variable. (Default function.) Args:
# 0	Self
# 1	Variable name, might look like a[2] in which case set element with last value in arg 2
#	Don't make an array bigger it already is, except to make it 1 element bigger
# 2	Value - an array
# Return the value;
sub VarSetFun {
	my ($self, $name, @value) = @_;

	unless(defined($name)) {
		$self->PrintError("Undefined variable name '$name' - need () to force left to right assignment ?");
	} else {
		if($name =~ /^(.+)\[(\d+)\]$/) {
			unless(defined($self->{VarHash}->{$1})) {
				if($2 == 0) {
					$self->{VarHash}->{$1} = $value[-1];
				} else {
					$self->PrintError("Can only create variable '%s' by setting element 0", $1);
				}
			} elsif($2 > $self->{ArrayMaxIndex}) {
				$self->PrintError("Array index %d is too large. Max is %d", $2, $self->{ArrayMaxIndex});
			} elsif($2 > @{$self->{VarHash}->{$1}}) {
				$self->PrintError("Extending array too much, '%s' has %d elements, trying to set element %d", $1, scalar @{$self->{VarHash}->{$1}}, $2);
		
			} else {
				$self->{VarHash}->{$1}[$2] = $value[-1];
			}
		} else {
			$self->{VarHash}->{$name} = \@value;
		}
	}

	return @value;
}

# Set a scalar variable function
# 0	Self
# 1	Variable name
# 2	Value - a scalar
# Return the value;
sub VarSetScalar {
	my ($self, $name, $value) = @_;
	my @arr;
	$arr[0] = $value;
	$self->{VarSetFun}($self, $name, @arr);
	return $value;
}

# Return the value of a variable - return an array
# 0	Self
# 1	Variable name
sub VarGetFun {
	my ($self, $name) = @_;

	return '' unless(exists($self->{VarHash}->{$name}));
	return @{$self->{VarHash}->{$name}};
}

# Return 1 if a variable is defined - ie has been assigned to
# 0	Self
# 1	Variable name
sub VarIsDefFun {
	my ($self, $name) = @_;

	return exists($self->{VarHash}->{$name}) ? 1 : 0;
}

# Parse a string argument, return a tree that can be evaluated.
# Report errors with $ErrFunc.
# 0	Self
# 1	String argument
sub ParseString {
	my ($self, $expr) = @_;

	my @operators = ();		# Operators stacked here until needed
	my @tree;			# Parsed tree ends up here
	my $newt;			# New Token
	my $ln = '';			# Last $newt->{oper}

	my $operlast = 1;		# Operator was last, ie not: var, const, ; ) string flow. Used to idenify monadic operators
	my $endAlready = 0;
	my $GenSemiColon = 0;		# Need to generate a ';'. Always do so after a '}'

	while(1) {
		my $semi = 0;
		$newt = {};

		# Lexical part:

		$expr =~ s/^\s*//;
		my $EndInput = $expr eq '';

		if($GenSemiColon) {
			# Generate an extra semicolon - after a close brace
			$newt->{oper} = ';';
			$operlast = 0;
			$EndInput = $GenSemiColon = 0;
		} # End of input string:
		elsif($EndInput) {
			$operlast = 0;
			# First time generate a ';' to terminate a set of statements:
			if($endAlready) {
				undef $newt;
			} else {
				$newt->{oper} = 'EOF';
				$EndInput = 0;
			}
			$endAlready = 1;
		} # Match integer/float constant:
		elsif($expr =~ s/^(((\d+(\.\d*)?)|(\.\d+))([ed][-+]?\d+)?)//i) {
			$newt->{oper} = 'const';
			$newt->{val} = $1;
			$newt->{type} = 'num';	# Used in debug/tree-print
			$operlast = 0;
		} # Match string bounded by ' or "
		elsif($expr =~ /^(['"])/ and $expr =~ s/^($1)([^$1]*)$1//) {
			$newt->{oper} = 'const';
			$newt->{val} = $2;
			# Double quoted, understand some escapes:
			$newt->{val} =~ s/\\([nrt\\]|x[\da-fA-F]{2}|u\{([\da-fA-F]+)\})/length($1) == 1 ? $escapes{$1} : defined($2) ? (chr hex $2) : (chr hex '0'.$1)/ge if($1 eq '"');
			$newt->{type} = 'str';
			$operlast = 0;
		} elsif($expr =~ s/^}//) {
			# Always need a ';' after this - magic one up to be sure
			# If not then flow operators screw up.
			$newt->{oper} = '}';
			$GenSemiColon = 1;
			$operlast = 1;
		} # Match (operators). Need \b after things like 'ne' so that it is not start of var name:
		elsif($expr =~ s@^(\+\+|--|:=|>=|<=|==|<>|!=|&&|\|\||lt\b|gt\b|le\b|ge\b|eq\b|ne\b|\*\*|[-~!./*%+,<>\?:\(\)\[\]{])@@) {
			$newt->{oper} = $1;
			# Monadic if the previous token was an operator and this one can be monadic:
			if($operlast && defined($MonOp{$1})) {
				$newt->{oper} = 'M' . $1;
				$newt->{monop} = $1;		# Monop flag & for error reporting
			}
			if(defined($MonVarOp{$1})) {
				$newt->{monop} = $1;		# Monop flag & for error reporting
			}

			# If we see '()' push the empty list as '()' will just be eliminated - as if never there.
			if($ln eq '(' && $1 eq ')') {
				push @tree, {oper => 'var', name => 'EmptyList'};
			} else {
				$operlast = 1 unless($1 eq ')' or $1 eq ']');
			}
		} # Flow: if/while:
		elsif($expr =~ s@^(if|while)@@) {
			$newt->{oper} = 'flow';
			$newt->{flow} = $1;
			$operlast = 0;
		} # Semi-colon:
		elsif($expr =~ s@^;@@) {
			$newt->{oper} = ';';
			$operlast = 0;
		} # Match 'function(', leave '(' in input:
		elsif($expr =~ s/^([_a-z][\w]*)\(/(/i) {
			unless($self->{Functions}->{$1}) {
				$self->PrintError("When parsing: found unknown function '%s'", $1);
				return;
			}
			$newt->{oper} = 'func';
			$newt->{fname} = $1;
			$operlast = 1;    # So that argument can be monadic
		} # Match VarName or $VarName or $123
		elsif($expr =~ s/^\$?([_a-z]\w*)//i) {
			$newt->{oper} = 'var';
			$newt->{name} = defined($1) ? $1 : defined($2) ? $2 : $3;
			$operlast = 0;
		} else {
			$self->PrintError("Unrecognised input in expression at '%s'", $expr);
			return;
		}

		# Processed everything ?
		if(!@operators && $EndInput) {
			return pop @tree;
		}

		# What is new token ?
		$ln = $newt ? $newt->{oper} : '';

		# Grammatical part
		# Move what we can from @operators to @tree

		my $loopb = 0; # Loop buster
		while(@operators || $newt) {

			# End of input ?
			if($EndInput and @operators == 0) {
				if(@tree != 1) {	# There should be one node left - the root
					$self->PrintError("Expression error - %s",
						$#tree == -1 ? "it's incomplete" : "missing operator");
					return;
				}
				return pop @tree;
			}

			# Terminal (var/const). Shift: push it onto the tree:
			if($newt and ($newt->{oper} eq 'var' or $newt->{oper} eq 'const')) {
				$operators[-1]->{after} = 1 if(@operators);

				push @tree, $newt;
				last;	# get next token
			} # It must be an operator, which must have a terminal to it's left side:

			# Eliminate () - where current node is a close bracket
			if($newt and @operators and $operators[-1]->{oper} eq '(' and $newt->{oper} eq ')') {
				if($EndInput and $#operators != 0) {
					$self->PrintError("Unexpected end of expression with unmatched '$operators[-1]->{oper}'");
					return;
				}

				pop @operators;
				last;	# get next token
			}

			# Should have a new node to play with - unless end of string
			if(!$newt && !$EndInput) {
				if($loopb++ > 40) {
					$self->PrintError("Internal error, infinite loop at: $expr");
					return;
				}
				next;
			}

			my $NewOpPrec;	# EOF is ultra low precedence
			$NewOpPrec = ($newt) ? $OperPrec{$newt->{oper}}[1] : -100; # Just read precedence
				

			# If there is a new operator & it is higher precedence than the one at the top of @operators, push it
			# Also put if @operators is empty
			if($newt && @operators) {
				print "Undefined NEWOPrec\n" unless defined $NewOpPrec;
				print "undefeined op-1 oper '$operators[-1]->{oper}'\n" unless(defined $OperPrec{$operators[-1]->{oper}}[0]);
			}
			if($newt && (!@operators or (@operators && $NewOpPrec > $OperPrec{$operators[-1]->{oper}}[0]))) {
				$operators[-1]->{after} = 1 if(@operators);
				push @operators, $newt;
				last;	# get next token
			}

			# Flows (if/while) must not be reduced unless the newop is ';' '}' 'EOF' - ALSO PUSH
			if(@operators && $operators[-1]->{oper} eq 'flow' && $newt && $newt->{oper} ne ';' && $newt->{oper} ne 'EOF' && $newt->{oper} ne '}') {
				$operators[-1]->{after} = 1 if(@operators);
				push @operators, $newt;
				last;
			}

			# Reduce, ie where we have everything move operators from @operators to @tree, their operands will be on @tree
			# Reduce when the new operator precedence is lower than or equal to the one at the top of @operators
			if(@operators && $NewOpPrec <= $OperPrec{$operators[-1]->{oper}}[0]) {

				# One of the pains is a trailing ';', ie nothing following it.
				# Detect it and junk it
				if($operators[-1]->{oper} eq ';' && !defined $operators[-1]->{after}) {
					pop @operators;
					next;
				}

				# If top op is { & new op is } - pop them:
				if(@operators && $newt && $operators[-1]->{oper} eq '{' && $newt->{oper} eq '}') {
					pop @operators; # Lose the open curly

					# Unless we uncovered a flow - get next token
					last unless(@operators && $operators[-1]->{oper} eq 'flow');

					$newt = undef; # So that we do a last below
				}
				my $op = pop @operators;
				my $func = $op->{oper} eq 'func';
				my $flow = $op->{oper} eq 'flow';
				my $monop = defined($op->{monop});

				# Enough on the tree ?
				unless(@tree >= (($func | $monop | $flow) ? 1 : 2)) {
					# ';' are special, don't need operands, also can lose empty ';' nodes
					next if($op->{oper} eq ';' or $op->{oper} eq 'EOF');

					$self->PrintError("Missing operand to operator '%s' at %s", $op->{oper},
						($expr ne '' ? "'$expr'" : 'end'));

					return;
				}

				# Push $op to @tree, first give it right & left children taken from the top of @tree
				$op->{right} = pop @tree;
				unless($monop or $func) {
					# Monadic operators & functions do not have a 'left' child.
					$op->{left} = pop @tree;
				}

				$op->{oper} = ';' if($op->{oper} eq 'EOF'); # ie join to previous
				push @tree, $op;

				$newt = undef
					if($newt && $op->{oper} eq '[' && $newt->{oper} eq ']');

				last unless($newt); # get next token
			}
		}
	}
}

# Check the tree for problems, args:
# 0	Self
# 1	a tree, return that tree, return undef on error.
# Report errors with $ErrFunc.
# To prevent a cascade of errors all due to one fault, use $ChkErrs to only print the first one.
my $ChkErrs;
sub CheckTree {
	$ChkErrs = 0;
	return &CheckTreeInt(@_);
}

# Internal CheckTree
sub CheckTreeInt {
	my ($self, $tree) = @_;
	return unless(defined($tree));

	return $tree if($tree->{oper} eq 'var' or $tree->{oper} eq 'const');

	my $ok = 1;

	if(defined($MatchOp{$tree->{oper}}) or defined($MatchOpClose{$tree->{oper}})) {
		$self->PrintError("Unmatched bracket '%s'", $tree->{oper});
		$ok = 0;
	}

	if(defined($MonVarOp{$tree->{oper}}) and (!defined($tree->{right}) or ($tree->{right}{oper} ne '[' and $tree->{right}{oper} ne 'var'))) {
		$self->PrintError("Operand to '%s' must be a variable or indexed array element", $tree->{oper});
		$ok = 0;
	}

	if($tree->{oper} eq '?' and $tree->{right}{oper} ne ':') {
		$self->PrintError("Missing ':' operator after '?' operator") unless($ChkErrs);
		$ok = 0;
	}

	if($tree->{oper} ne 'func') {
		unless((!defined($tree->{left}) and defined($tree->{monop})) or $self->CheckTree($tree->{left})) {
			$self->PrintError("Missing LH expression to '%s'", defined($tree->{monop}) ? $tree->{monop} : $tree->{oper}) unless($ChkErrs);
			$ok = 0;
		}
	}
	unless(&CheckTree($self, $tree->{right})) {
		$self->PrintError("Missing RH expression to '%s'", defined($tree->{monop}) ? $tree->{monop} : $tree->{oper}) unless($ChkErrs);
		$ok = 0;
	}

	if($tree->{oper} eq 'func') {
		my $fname = $tree->{fname};
		if($InFunLV{$fname} and
		   (!defined($tree->{right}->{oper}) or (($tree->{right}->{oper} ne 'var' and $tree->{right}->{oper} ne ',') and (!defined($tree->{right}->{left}->{oper}) or $tree->{right}->{left}->{oper} ne 'var')))) {
			$self->PrintError("First argument to $fname must be a variable");
			$ok = 0;
		}
	}

	$ChkErrs = 1 unless($ok);
	return $ok ? $tree : undef;
}

# Parse & check an argument string, return the parsed tree.
# Report errors with $ErrFunc.
# 0	Self
# 1	an expression
sub Parse {
	my ($self, $expr) = @_;

	return $self->CheckTree($self->ParseString($expr));
}

# Print a tree - for debugging purposes. Args:
# 0	Self
# 1	A tree
# Hidden second argument is the initial indent level.
sub PrintTree {
	my ($self, $nodp, $dl) = @_;

	$dl = 0 unless(defined($dl));
	$dl++;

	unless(defined($nodp)) {
		print "    " x $dl . "UNDEF\n";
		return;
	}

	print "    " x $dl;
	print "nod=$nodp [$nodp->{oper}] P-JR $OperPrec{$nodp->{oper}}[1] ";

	if($nodp->{oper} eq 'var') {
		print "var($nodp->{name}) \n";
	} elsif($nodp->{oper} eq 'const') {
		print "const($nodp->{val}) \n";
	} else {
		print "\n";
		print "    " x $dl;print "Desc L \n";
		$self->PrintTree($nodp->{left}, $dl);

		print "    " x $dl;print "op '$nodp->{oper}' P-TOS $OperPrec{$nodp->{oper}}[0] at $nodp\n";

		print "    " x $dl;print "Desc R \n";
		$self->PrintTree($nodp->{right}, $dl);
	}
}

# Evaluate a tree. Return a scalar.
# Args:
# 0	Self
# 1	The root of a tree.
sub EvalToScalar {
	my ($self, $tree) = @_;
	my @res = $self->Eval($tree);

	return $res[$#res];
}

# Parse a string, check and evaluate it, return a scalar
# Args:
# 0	Self
# 1	String to evaluate.
# Return undef on error.
sub ParseToScalar {
	my ($self, $expr) = @_;

	my $tree = $self->Parse($expr);
	return undef unless($tree);
	return $self->EvalToScalar($tree);
}

# Evaluate a tree. The result is an array, if you are expecting a single value it is the last (probably $#'th) element.
# Args:
# 0	Self
# 1	The root of a tree.
sub Eval {
	my ($self, $tree) = @_;

	$self->{LoopCount} = 0;	# Count all loops
	$self->{VarSetFun}($self, '_TIME', time);

	return $self->EvalTree($tree, 0);
}

# Evaluate a tree. The result is an array, if you are expecting a single value it is the last (probably $#'th) element.
# Args:
# 0	Self
# 1	The root of a tree.
# 2	Want Lvalue flag -- return variable name rather than it's value
# Report errors with the function $PrintErrFunc
# Checking undefined values is a pain, assignment of undef & concat undef is OK.
sub EvalTree {
	my ($self, $tree, $wantlv) = @_;

	return unless(defined($tree));

	my $oper = $tree->{oper};

	return $tree->{val}										if($oper eq 'const');
	return $wantlv ? $tree->{name} : $self->{VarGetFun}($self, $tree->{name})			if($oper eq 'var');

	# Some functions need to be given a lvalue
	return $self->{FuncEval}($self, $tree, $tree->{fname},
				$self->EvalTree($tree->{right}, defined($InFunLV{$tree->{fname}})))	if($oper eq 'func');

	if($oper eq '++' or $oper eq '--') {
		my ($right, @right, @left, $index, $name);
		# The variable is either a simple variable or an indexed array
		if($tree->{right}->{oper} eq '[') {
			$name = $tree->{right}->{left}->{name};
			$index = 1;

			@left = $self->EvalTree($tree->{right}->{left}, 0);

			@right = $self->EvalTree($tree->{right}->{right}, 0);
			$index = $right[-1];

			unless($index =~ /^-?\d+$/) {
				$self->PrintError("Array '%s' index is not integer '%s'", $name, $index);
				return undef;
			}

			$index += @left if($index < 0);	# Convert -ve index to a +ve one, will still be -ve if it was very -ve to start with

			return undef if($index < 0 or $index > @left);	# Out of bounds

			$right = $left[$index];
			$name = "$name\[$index\]";
		} else {
			@right = $self->EvalTree($tree->{right}, 0);
			$right = $right[-1];
			$name = $tree->{right}{name};
		}

		$oper eq '++' ? $right++ : $right--;

		$self->{VarSetFun}($self, $name, ($right));

		return $right;
	}

	# Monadic operators:
	if(!defined($tree->{left}) and defined($tree->{monop})) {
		$oper = $tree->{monop};

		# Evaluate the (RH) operand
		my @right = $self->EvalTree($tree->{right}, 0);
		my $right = $right[$#right];
		unless(defined($right)) {
			unless($self->{AutoInit}) {
				$self->PrintError("Operand to mondaic operator '%s' is not defined", $oper);
				return;
			}
			$right = 0;	# Monadics are all numeric
		}

		unless($right =~ /^([-+]?)0*([\d.]+)([ef][-+]?\d*|)$/i) {
			$self->PrintError("Operand to monadic '%s' is not numeric '%s'", $oper, $right);
			return;
		}
		$right = "$1$2$3";

		return -$right if($oper eq '-');
		return  $right if($oper eq '+');
		return !$right if($oper eq '!');
		return ~$right if($oper eq '~');

		$self->PrintError("Unknown monadic operator when evaluating: '%s'", $oper);
		return;
	}

	# This is complicated by multiple assignment: (a, b, c) := (1, 2, 3, 4). 'c' is given '(3, 4)'.
	# Assign the right value to the left node
	# Where the values list is shorter, leave vars alone: (a, b, c) := (1, 2) does not change c.
	if($oper eq ':=') {
		my @left = $self->EvalTree($tree->{left}, 1);
		my @right = $self->EvalTree($tree->{right}, $wantlv);

		# Easy case, assigning to one variable, assign the whole array:
		return $self->{VarSetFun}($self, @left, @right) if($#right <= 0);

		# Assign conseq values to conseq variables. The last var gets the rest of the values.
		# Ignore too many vars.
		for(my $i = 0; $i <= $#left; $i++) {
			last if($i > $#right);

			if($i == $#left and $i != $#right) {
				$self->{VarSetFun}($self, $left[$i], @right[$i ... $#right]);
				last;
			}
			$self->{VarSetFun}($self, $left[$i], $right[$i]);
		}

		return @right;
	}

	# Flow control: if/while
	if($oper eq 'flow') {
		if($tree->{flow} eq 'if') {
			# left is condition, right is body when true
			my @left = $self->EvalTree($tree->{left}, 0);
			return ($left[-1]) ? ($self->EvalTree($tree->{right}, 0))[-1] : 0;
		}
		if($tree->{flow} eq 'while') {
			my $ret = 0; # Return val, until get something better
			if( !$self->{PermitLoops}) {
				$self->PrintError("Loops not enabled, set property PermitLoops to do so");
				return;
			}
			while(1) {
				if($self->{MaxLoopCount} && ++$self->{LoopCount} > $self->{MaxLoopCount}) {
					$self->PrintError("Loop exceeded maximum iterations: MaxLoopCount = $self->{MaxLoopCount}");
					return;
				}
				# left is loop condition, right is body:
				my @left = $self->EvalTree($tree->{left}, 0);
				return $ret unless($left[-1]);
				$ret = ($self->EvalTree($tree->{right}, 0))[-1];
			}
			return $ret;
		}
	}

	# Evaluate left - may be able to avoid evaluating right.
	# Take care to avoid evaluating a tree twice, not just inefficient but nasty side effects with ++ & -- operators
	my @left = $self->EvalTree($tree->{left}, $wantlv);
	my $left = $left[$#left];
	if(!defined($left) and $oper ne ',' and $oper ne '.' and $oper ne ';') {
		unless($self->{AutoInit}) {
			$self->PrintError("Left value to operator '%s' is not defined", $oper);
			return;
		}
		$left = '';	# Set to the empty string
	}

	# Lazy evaluation:
	return $left ?  $self->EvalTree($tree->{right}{left}, $wantlv) :
			$self->EvalTree($tree->{right}{right}, $wantlv)		if($oper eq '?');

	# Constructing a list of variable names (for assignment):
	return (@left, $self->EvalTree($tree->{right}, 1))			if($oper eq ',' and $wantlv);

	# More lazy evaluation:
	if($oper eq '&&' or $oper eq '||') {
		return 0 if($oper eq '&&' and !$left);
		return 1 if($oper eq '||' and  $left);

		my @right = $self->EvalTree($tree->{right}, 0);

		return($right[$#right] ? 1 : 0);
	}

	# Everything else is a binary operator, get right side - value(s):
	my @right = $self->EvalTree($tree->{right}, 0);
	my $right = $right[-1];

	return (@left, @right)	if($oper eq ',');
	return @right		if($oper eq ';');

	# Array index. Beware: works differently depending on $wantlv.
	# Because when $wantlv it is the array name, not its contents
	if($oper eq '[') {
		return undef	# Check if the array member could exist; ie have index
			if($right !~ /^-?\d+$/);

		@left = $self->{VarGetFun}($self, $left[0]) if($wantlv);

		my $index = $right[-1];
		$index += @left if($index < 0);	# Convert -ve index to a +ve one

		return "$left\[$index]" # Return var[index] for assignment
			if($wantlv);

		return undef	# Check if the array member exists
			if($index < 0 || $index > @left);

		return $left[$index];
	}


	# Everything else just takes a simple (non array) value, use last value in a list which is in $right.
	# It is OK to concat undef.

	if($oper eq '.') {
		# If one side is undef, treat as empty:
		$left = ""  unless(defined($left));
		$right = "" unless(defined($right));
		if(length($left) + length($right) > $self->{StringMaxLength}) {
			$self->PrintError("Joined string would exceed maximum allowed %d", $self->{StringMaxLength});
			return "";
		}
		return $left . $right;
	}

	unless(defined($right)) {
		unless($self->{AutoInit}) {
			$self->PrintError("Right value to operator '%s' is not defined", $oper);
			return;
		}
		$right = '';
	}

	return $left lt $right ? 1 : 0 if($oper eq 'lt');
	return $left gt $right ? 1 : 0 if($oper eq 'gt');
	return $left le $right ? 1 : 0 if($oper eq 'le');
	return $left ge $right ? 1 : 0 if($oper eq 'ge');
	return $left eq $right ? 1 : 0 if($oper eq 'eq');
	return $left ne $right ? 1 : 0 if($oper eq 'ne');

	return ($left, $right) 		     if($oper eq ':');	# Should not be used, done in '?'
#	return $left ? $right[0] : $right[1] if($oper eq '?');	# Non lazy version

	# Everthing else is an arithmetic operator, check for left & right being numeric. NB: '-' 'cos may be -ve.
	# Returning undef may result in a cascade of errors.
	# Perl would treat 012 as an octal number, that would confuse most people, convert to a decimal interpretation.
	unless($left =~ /^([-+]?)0*([\d.]+)([ef][-+]?\d*|)/i) {
		unless($self->{AutoInit} and $left eq '') {
			$self->PrintError("Left hand operator to '%s' is not numeric '%s'", $oper, $left);
			return;
		}
		$left = 0;
	} else {
		$left = "$1$2$3";
	}

	unless($right =~ /^([-+]?)0*([\d.]+)([ef][-+]?\d*|)/i) {
		unless($self->{AutoInit} and $right eq '') {
			$self->PrintError("Right hand operator to '%s' is not numeric '%s'", $oper, $right);
			return;
		}
		$right = 0;
	} else {
		$right = "$1$2$3";
	}

	return $left *  $right if($oper eq '*');
	return $left /  $right if($oper eq '/');
	return $left %  $right if($oper eq '%');
	return $left +  $right if($oper eq '+');
	return $left -  $right if($oper eq '-');
	return $left ** $right if($oper eq '**');

	# Force return of true/false -- NOT undef
	return $left >  $right ? 1 : 0 if($oper eq '>');
	return $left <  $right ? 1 : 0 if($oper eq '<');
	return $left >= $right ? 1 : 0 if($oper eq '>=');
	return $left <= $right ? 1 : 0 if($oper eq '<=');
	return $left == $right ? 1 : 0 if($oper eq '==');
	return $left != $right ? 1 : 0 if($oper eq '!=');
	return $left != $right ? 1 : 0 if($oper eq '<>');

	$self->PrintError("Unknown operator when evaluating: '%s'", $oper);
	return;
}

# Evaluate a function:
sub FuncValue {
	my ($self, $tree, $fname, @arglist) = @_;

	# If there is a user supplied extra function evaluator, try that first:
	my $res;
	return $res if(defined($self->{ExtraFuncEval}) && defined($res = $self->{ExtraFuncEval}(@_)));

	my $last = $arglist[$#arglist];

	return int($last)					if($fname eq 'int');
	return abs($last)					if($fname eq 'abs');

	# Round in a +ve direction unless RoundNegatives when round away from zero:
	return int($last + 0.5 * ($self->{RoundNegatives} ? $last <=> 0 : 1))	if($fname eq 'round');

	return split $arglist[0], $arglist[$#arglist]		if($fname eq 'split');
	return join  $arglist[0], @arglist[1 ... $#arglist]	if($fname eq 'join');

	# Beware: could exceed max length with: printf("%2000s", "foo");
	if($fname eq 'printf') {
		unless($self->{EnablePrintf}) {
			$self->PrintError("Function 'printf' not enabled");
			return "";
		}
		my $s = sprintf $arglist[0], @arglist[1 ... $#arglist];
		return $s if(length($s) <= $self->{StringMaxLength});
		$self->PrintError("String would exceed maximum allowed %d", $self->{StringMaxLength});
		return "";
	}

	return mktime(@arglist)					if($fname eq 'mktime');
	return strftime($arglist[0], @arglist[1 ... $#arglist])	if($fname eq 'strftime');
	return localtime($last)					if($fname eq 'localtime');

	return $self->{VarIsDefFun}($self, $last)		if($fname eq 'defined');

	if($fname eq 'pop' or $fname eq 'shift') {
		my @a = $self->{VarGetFun}($self, $arglist[0]);
		my $p = $fname eq 'pop' ? pop(@a) : shift(@a);
		$self->{VarSetFun}($self, $last, @a);

		return $p;
	}

	if($fname eq 'push' or $fname eq 'unshift') {
		# Evaluate right->right and push/unshift that
		my $vn = shift @arglist;		# var name

		my @vv = $self->{VarGetFun}($self, $vn);# var value
		my @vp = $self->EvalTree($tree->{right}->{right}, 0); # var to push/unshift

		$fname eq 'push' ? push(@vv, @vp) : unshift(@vv, @vp);
		$self->{VarSetFun}($self, $vn, @vv);

		return scalar @vv;
	}

	return length($last)					if($fname eq 'strlen');
	return scalar @arglist					if($fname eq 'count');

	# aindex(array, val) returns index (from 0) of val in array, -1 on error
	if($fname eq 'aindex') {
		my $val = $arglist[$#arglist];
		for( my $inx = 0; $inx <= $#arglist - 1; $inx++) {
			return $inx if($val eq $arglist[$inx]);
		}
		return -1;
	}

	$self->PrintError("Unknown Function '$fname'");

	return '';
}

# Create a new parse/evalutation object.
# Initialise default options.
sub new {
	my $class = shift;

	# What we store about this evaluation environment, default values:
	my %ExprVars = (
		PrintErrFunc	=>	'',			# Printf errors
		VarHash		=>	{(			# Variable hash
					EmptyArray	=>	[()],
					EmptyList	=>	[()],
			)},
		VarGetFun	=>	\&VarGetFun,		# Get a variable - function
		VarIsDefFun	=>	\&VarIsDefFun,		# Is a variable defined - function
		VarSetFun	=>	\&VarSetFun,		# Set an array variable - function
		VarSetScalar	=>	\&VarSetScalar,		# Set a scalar variable - function
		FuncEval	=>	\&FuncValue,		# Evaluate - function
		AutoInit	=>	0,			# If true auto initialise variables
		ExtraFuncEval	=>	undef,			# User supplied extra function evaluator function
		RoundNegatives	=>	0,			# Round behaves differently with -ve numbers
		PermitLoops	=>	0,			# Are loops allowed
		MaxLoopCount	=>	50,			# Max # all loops
		ArrayMaxIndex	=>	100,			# Max index of an array
		StringMaxLength	=>	1000,			# Max string length
		EnablePrintf	=>	0,			# Enable printf function
		Functions	=>	{%InFuns},		# Known functions, initialise to builtins

	);

	my $self = bless \%ExprVars => $class;
	$self->SetOpt(@_);	# Process new options

	return $self;
}

# Set an option in the %template.
sub SetOpt {
	my $self = shift @_;

	while($#_ > 0) {
		$self->PrintError("Unknown option '$_[0]'") unless(exists($self->{$_[0]}));
		$self->PrintError("No value to option '$_[0]'") unless(defined($_[1]));
		$self->{$_[0]} = $_[1];
		shift;shift;
	}
}

1;

__END__

=head1 NAME

Math::Expression - Safely evaluate arithmetic/string expressions

=head1 DESCRIPTION

Evaluating an expression from an untrusted source can result in security or denial of service attacks.
Sometimes this needs to be done to do what the user wants.

This module solves the problem of evaluating expressions read from sources such as config/...
files and user web forms without the use of C<eval>.
String and arithmetic operators are supported (as in C/Perl),
as are: variables, loops, conditions, arrays and be functions (inbuilt & user defined).

The program may set initial values for variables and obtain their values once the expression
has been evaluated.

The name-space is managed (for security), user provided functions may be specified to set/get
variable values.
Error messages may be via a user provided function.
This is not designed for high computation use.

=head1 EXAMPLE

Shipping cost depends on item price by some arbitrary formula. The VAT amount can also
vary depending on political edict. Rather than nail these formula into the application code the
formula are obtained at run time from some configuration source. These formula are
entered by a non technical manager and are thus not to be trusted.

    use Math::Expression;
    my $ArithEnv = new Math::Expression;

# Obtain from a configuration source:
    my $ShippingFormula = 'Price >= 100 ? Price * 0.1 : (Price >= 50 ? Price * 0.15 : Price * 0.2)';
    my $VatFormula = 'VatTax := Price * 0.2';

# Price of what you are selling, set the price variable:
    my $price = 100;
    $ArithEnv->VarSetScalar('Price', $price);

# Obtain VAT & Shipping using the configured formula:
    my $VatTax = $ArithEnv->ParseToScalar($VatFormula);
    my $Shipping  = $ArithEnv->ParseToScalar($ShippingFormula);

    say "Price=$price VatTax=$VatTax Shipping=$Shipping";

# If these will be run many times, parse the formula once:

    my $VatExpr = $ArithEnv->Parse($VatFormula);
    my $ShipExpr = $ArithEnv->Parse($ShippingFormula);

# Evaluate it with the current price many times:

    $ArithEnv->VarSetScalar('Price', $price);
    $VatTax = $ArithEnv->EvalToScalar($VatExpr);
    $Shipping = $ArithEnv->EvalToScalar($ShipExpr);


=head1 HOW TO USE

An expression needs to be first compiled (parsed) and the resulting tree may be run (evaluated)
many times.
The result of an evaluation is an array.
Variables are preserved between evaluations.
You might also want to take computation results from stored variables.
Method C<ParseToScalar> does it all in one: parse, check & evaluate.

See examples later in this document.

For further examples of use please see the test program for the module.

=head2 Package methods

=over 4

=item new

This must be used before anything else to obtain a handle that can be used in calling other
functions.

=item SetOpt

The items following may be set.
In many cases you will want to set a function to extend what the standard one does.

These options may also be given to the C<new> function.

=over 4

=item PermitLoops

This must be set C<true> otherwise loops (C<while>) will not be allowed.
This is to prevent a denial of service attack when the expression is from an
untrusted source.

Default: false

=item MaxLoopCount

This it the maximum number of times that loops will be allowed to iterate.
Where there is more than one loop, all loops count towards this limit.
Think carefully before making this too high.

If set to zero, there is no iteration limit. This is probably unwise.

The count restarts when an Eval function is used to evaluate a tree.

Default: 50.

=item ArrayMaxIndex

The largest number that can be used as an index when assigning to an array.

Default: 100.

=item EnablePrintf

This must be set true for the C<printf> function to be allowed.
Beware this could take a long time to fail: C<printf('%1000000s', 'foo')>

Default: 0.

=item StringMaxLength

The longest that a string may be.

Default: 1000.

=item PrintErrFunc

This is a printf style function that will be called in the event of an error,
the error text will not have a trailing newline.
If this is not set the default is to C<printf STDERR>.

=item VarHash

The argument is a hash that will be used to store variables.
Changing the has between runs makes it is possible to manage distinct name spaces,
ie different computations use different sets of variables.

The name C<EmptyList> should, by convention, exist and be an empty array; this may be
used to assign an empty value to a variable.

=item VarGetFun

This specifies the that function returns the value of a variable as an array.
The arguments are: 0 - the value returned by C<new>; 1 - the name of the variable
wanted.
If no value is available you may return the empty array.

=item VarIsDefFun

This should return C<1> if the variable is defined, C<0> if it is not defined.
The arguments are the same as for C<VarGetFun>.

=item VarSetFun

This sets the value of a variable as an array.
The arguments are: 0 - the value returned by C<new>; 1 - the name of the variable
to be set; 2 - the value to set as an array.
The return value should be the variable value.

=item VarSetScalar

This sets the value of a variable as a simple scalar (ie one value).
The arguments are: 0 - the value returned by C<new>; 1 - the name of the variable
to be set; 2 - the value to set as a scalar.
The return value should be the variable value.

=item FuncEval

This will evaluate functions.
The arguments are:
0 - the value returned by C<new>;
1 - the tree as returned by C<ParseString>;
2 - the name of the function to be evaluated;
3... - an array of function arguments.
This should return the value of the function: scalar or array.

The purpose is to permit different functions than those provided (eg C<abs()>) to be made available.
This option B<replaces> the in built function evaluator C<FuncValue> which may be used as a model for
your own evaluator.

=item ExtraFuncEval

If defined this will be called when evaluating functions.
If a defined value is returned that value is used in the expression, it should be numeric or string.
If this returns C<undef> the name of function will be matched against the built in functions.
This is called before the standard functions are tested and thus can redefine the built in functions.
The arguments are as C<FuncEval>.

New function names must be added to property C<Functions>:

  $ArithEnv->{Functions}->{someFunc} = 1;

=item RoundNegatives

See the description of the C<round> function.

=item AutoInit

If true automatically initialise undefined values, to the empty string or '0' depending on use.
The default is that undefined values cause an error, except that concatentation (C<.>)
always results in the empty string being assumed.

=back

Example:

  my $ArithEnv = new Math::Expression(RoundNegatives => 1);

  my %Vars = (
	EmptyList       =>      [()],
  );

  $ArithEnv->SetOpt(
	VarHash => \%Vars,
	VarGetFun => \&VarValue,
	VarIsDefFun => \&VarIsDef,
	PrintErrFunc => \&MyPrintError,
	AutoInit => 1,
	);

=item ParseString

This parses an expression string and returns a tree that may be evaluated later.
The arguments are: 0 - the value returned by C<new>; 1 - the string to parse.
If there is an error a complaint will be made via C<PrintErrFunc> and the
undefined value returned.

=item CheckTree

This checks a parsed tree.
The arguments are: 0 - the value returned by C<new>; 1 - the tree to check.
The input tree is returned.
If there is an error a complaint will be made via C<PrintErrFunc> and the
undefined value returned.

=item Parse

This combines C<ParseString> and C<CheckTree>.

=item VarSetFun

This sets a variable, see the description in C<SetOpt>.

=item VarSetScalar

This sets a variable, see the description in C<SetOpt>.

=item FuncValue

This evaluates a function, see the description in C<SetOpt>.

=item EvalTree

Evaluate a tree or subtree. The result is an array, if you are expecting a single value it is the last (probably $#'th) element.
The arguments are: 0 - the value returned by C<new>; 1 - tree to evaluate; 2 - true if
a variable name is to be returned rather than it's value (don't set this).
You should not use this, use methods C<Eval> or C<EvalToScalar> instead.
This does B<not> reset the used loop count property C<LoopCount>.

=item Eval

Evaluate a tree. The result is an array, if you are expecting a single value it is the last (probably $#'th) element.
The arguments are: 0 - the value returned by C<new>; 1 - tree to evaluate.

=item EvalToScalar

Evaluate a tree. The result is a scalar (simple variable).
The arguments are: 0 - the value returned by C<new>; 1 - tree to evaluate.

=item ParseToScalar

Parse a string, check and Evaluate its tree. The result is a scalar (simple variable).
Undefined is returned on error.
The arguments are: 0 - the value returned by C<new>; 1 - tree to evaluate.

=back

=head2 Functions that may be used in expressions

The following functions may be used in expressions, if you want more than this write your own
function evaluator and set 'ExtraFuncEval' with method C<SetOpt>;
The POSIX package is used to provide some of the functions.

=over 4

=item int

Returns the integer part of an expression.

=item abs

Returns the absolute value of an expression.

=item round

Adds 0.5 to input and returns the integer part.
If the option C<RoundNegatives> is set round() is sign sensitive,
so for negative input subtracts 0.5 from input and returns the integer part.

=item split

Perl C<split>, the 0th argument is the RE to split on, the last argument what will be split.

=item join

Joins arguments 1..$#, separating elements with the 0th argument.

=item printf

The standard perl C<printf>, returns the formatted result.
To use this the option C<EnablePrintf> must be set true.

=item mktime

Passes all the arguments to C<mktime>, returns the result.

=item strftime

Passes all the arguments to C<strftime>, returns the result.

=item localtime

Returns the result of applying C<localtime> to the last argument.
The variable C<_TIME> is initialised to the current time

=item defined

Applies the C<VarIsDefFun> to the last argument.
Ie returns 1 if the variable is defined (has been assigned a value), 0 if it has not.

=item push, pop, shift, unshift

Add/remove elements from an array - as in perl.

=item strlen

The length of a string.

=item count

The number of elements in an array.

=item aindex

Searches the arguments for the last argument and returns the index.
Return -1 if it is not found.
Eg the following will return 1:

  months := 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec';
  aindex(months, 'Feb')

=back

Example of user defined functions:

    # Function that provides extra functions - ie user functions
    # sumArgs	numeric sum of arguments
    # A user defined function must return a scalar or list; it MUST not return undef.
    sub moreFunctions {
    	my ($self, $tree, $fname, @arglist) = @_;
    
    	if($fname eq 'sumArgs') {
    		my $sum = 0;
    		$sum += $_ for @arglist;
    		return $sum;
    	}
    
    	# Return undef so that in built functions are scanned
    	return undef;
    }
    
    # MUST put user defined functions here so that it is known as a function - while parsing:
    $ArithEnv->{Functions}->{sumArgs} = 1;
    
    $ArithEnv->SetOpt(ExtraFuncEval => \&moreFunctions);

Used in an expression thus:

    sum := sumArgs(2, 4, 6, 8)
    list : = (12, 13, 21, 9, -3)
    sum := sumArgs(list)

=head2 Variables

Variables can two forms, there is no difference in usage between any of them.
A variable name is either alphanumeric (starting with alpha, underscore is deemed an alpha), or
the same name with a leading C<$>. Both refer to the same variable.

	Variable
	_foo123
	$Variable
	$_foo123

A previous version of this module allowed more syntaxes.

=head2 Literals

Literals may be: integers, floating point in the forms nn.nn and with an exponent eg
(123.4, 1.234e2, 1.234e+2).
Strings are bounded by matching single C<'> or double quotes C<">.
In strings surrounded by double quotes the following escapes will be recognised:

	\n	newline
	\r	carriage return
	\t	tab
	\\	\
	\xXX	character with hex value XX. Eg: \x0A \x3b
	\u{XXX}	unicode character. Eg: \u{20AC} is the Euro

A backslash followed by anything else is left as is - ie the backslash will remain.

=head2 Operators and precedence

The operators should not surprise any Perl/C programmer, with the exception that assignemnt
is C<:=>. Operators associate left to right except for C<:=> which associates right to left.
Precedence may be overridden with parenthesis C<( )>.
C<E<lt>E<gt>> is the same as C<!=>.

	++ --	Pre increment/decrement only
	+ - ~ !	(Monadic)
	**
	* / %
	+ -
	.	String concatenation
	> < >= <= == != <>
	lt gt le ge eq ne
	&&
	||
	? :
	,
	:=

A semicolon (C<;>) may be used to separate statements; the value is that of the last expression.

Statements may be grouped with brackes: C<{ }>

	{ a := 10; b := a * 4 }

=head2 Order of evaluation

The order of evaluation of an expression is not defined except at sequence points.
The sequence points are: C<while> C<if> C<;> C<?:> C<&&> C<||>.
In particular C<&&> and C<||> only evaluate their right hand sides if they need to.

Thus which element of C<a> gets updated by the code below may change in a future release:

	a := (5, 6, 7); i := 0; a[++i] := ++i

Multiple assignment works:

	a := b := 3; if(1) a:= b := 4

Sets C<a> and C<b> to C<3> and then sets them to C<4>.

=head2 Arrays

Variables are implemented as arrays, if a simple scalar value is wanted (eg you want to go C<+>)
the last element of the array is used.
Arrays may be built using the comma operator, arrays may be joined using C<,> eg:

	a1 := (1, 2, 3, 4)
	a2 := (9, 8, 7, 6)
	a1 , a2

yeilds:

	1, 2, 3, 4, 9, 8, 7, 6

And:

	a2 + 10

yeilds:

	16

Arrays may be used to assign multiple values, eg:

	(v1, v2, v3) := (42, 44, 48)

If there are too many values the last variable receives the remainder.
If there are not enough values the last ones are unchanged.

You may use C<[]> to numerically index into arrays to obtain and set scalar values.
Arrays cannot contain other arrays.
Array indexes start with C<0>. Negative indicies index from the end of the array, thus -1 is the last element.

	a := (20,21,22); a[1] + a[2]
	a := (20,21,22); a[1] := 9; ++a[k + j]
	i := -1; j := 2; a := (20,21,22); a[i + j] := 3

When setting values you can extend an array one element at a time.
You can create a variable by setting index C<0>.

Index greater than C<ArrayMaxIndex> cannot be used to assign to an array. See method C<SetOpt>.

Assigning C<()> is the same as assigning C<EmptyList>, eg:

	em := ()

=head2 Conditions and loops

Conditional assignment B<used> to be done by use of the ternary operator, but no longer:

	a > b ? ( c := 3 ) : 0

Variables may be the result of a conditional, so below one of C<aa> or C<bb>
is assigned a value:

	a > b ? aa : bb := 124

C<if> and C<while> may be used to perform conditionals and loops:

	if(i < 3) { i := i + j; j := 0}
	if(i < 3) i := 10;
	i := 0; a := 0; if(i < 4) {i := i + 1; a := 9 }; a+i
	i := 0; b := 1; while(++i < 4) b := b * 2;  b
	i := 0; while(i < 4) {i := i + 1;}; i

Note how the braces may be omitted if there is one statement after the C<if>.
You can nest C<if> and C<while> within each other.

If the expression is from an untrusted source, loops may cause a denial of service attack.
So: the following are avaiable to use with C<SetOpt>: C<PermitLoops> and C<MaxLoopCount>,
see the above description for details.

=head2 Miscellaneous and examples

There is no C<;> so each strings Parsed must be one expression.

	my $tree1 = $ArithEnv->Parse('a := 10');
	my $tree2 = $ArithEnv->Parse('b := 3');
	my $tree3 = $ArithEnv->Parse('a + b');

	$ArithEnv->EvalToScalar($tree1);
	$ArithEnv->EvalToScalar($tree2);
	print "Result: ", $ArithEnv->EvalToScalar($tree3), "\n";
	say "a * b = " . $ArithEnv->ParseToScalar('a * b');
	say $ArithEnv->ParseToScalar('"a != b is " . (a != b)');
	say $ArithEnv->ParseToScalar('2 * 3 / 4');
	say $ArithEnv->ParseToScalar('1.2e2 + 0');

prints:

	Result: 13
	a * c = 30
	a != b is 1
	1.5
	120

	$ArithEnv->ParseToScalar('FirstName := "George"');
	$ArithEnv->ParseToScalar('SurName := "Williams"');
	say "Son's name is " . $ArithEnv->ParseToScalar('FirstName . " " . SurName');
	say "Name is George = " . $ArithEnv->ParseToScalar('FirstName eq "George"');

prints:

	Son's name is George Williams
	Name is George = 1

	$ArithEnv->VarSetScalar('_TimeYesterday', time - 86400);
	say $ArithEnv->ParseToScalar('strftime("Yesterday date=%Y/%m/%d", localtime(_TimeYesterday))');
	say $ArithEnv->ParseToScalar('strftime("Today date=%Y/%m/%d", localtime(_TIME))');

prints:

	Yesterday date=2015/03/21'
	Today date=2015/03/22'

	say $ArithEnv->ParseToScalar('10 + (44, 66, 22 + 1)');
	say $ArithEnv->ParseToScalar('c := 12; d := 3; c * d');


prints:

	33
	36

=head1 AUTHOR

Alain D D Williams <addw@phcomp.co.uk>

=head2 Copyright and Version

Version "1.47", this is available as: $Math::Expression::Version.

Copyright (c) 2003, 2016 Parliament Hill Computers Ltd/Alain D D Williams. All rights reserved.
This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. Please see the module source
for the full copyright.

=cut

# end
