package Math::MVPoly::Parser; 

# Copyright (c) 1998 by Brian Guarraci. All rights reserved.
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

use strict;
use Math::MVPoly::Ideal;
use Math::MVPoly::Polynomial;

sub
new
{
	my $self;

	$self = {};
	$self->{VARIABLES}	= {};
	$self->{STATUS}		= {};
	$self->{VERBOSE}	= 0;

	bless($self);
	return $self;
}

sub
variables
{
        my $self = shift;
        if (@_) { $self->{VARIABLES} = shift }
        return $self->{VARIABLES};
}

sub
status
{
        my $self = shift;
        if (@_) { $self->{STATUS} = shift }
        return $self->{STATUS};
}

sub
verbose
{
        my $self = shift;
        if (@_) { $self->{VERBOSE} = shift }
        return $self->{VERBOSE};
}

sub
statusIsValid
{
        my $self = shift;

	return ($self->status() == 0)
}

sub
statusToString
{
        my $self = shift;
	my $s;
	my $status;

	$status = $self->status();

	if ($status eq 0)
	{
		$s = "Valid";
	}
	elsif ($status eq 1)
	{
		$s = "Syntax Error";	
	}
	elsif ($status eq 2)
	{
		$s = "Variable Not Found";
	}
	elsif ($status eq 3)
	{
		$s = "Monomial Ordering Not Defined.";
	}
	elsif ($status eq 4)
	{
		$s = "Variable Ordering Not Defined.";
	}
	elsif ($status eq 5)
	{
		$s = "Attempt to use multi-variables under lex monomial ordering.";
	}
	elsif ($status eq 6)
	{
		$s = "Attempt to use lex monomial ordering with multi-variate polynomials.";
	}
	else
	{
		$s = $status; 
	}

	return $s;
}

sub
toString
{
	my $self = shift();
	my $s;
	my $myVars;
	my $name;
	my $r;

	$myVars = $self->variables();

	$s = "";

	foreach $name (keys %$myVars)
	{
		$r = $self->varToString($name);
		$s .= "$name = $r\n";
	}	

	return $s;
}

sub
setVariable
{
	my $self = shift;
	my $var = shift;
	my $val = shift;
	my $myVars;

	$myVars = $self->variables();
	$myVars->{$var} = $val;
}

sub
getVariable
{
	my $self = shift;
	my $var = shift;
	my $val;
	my $myVars;

	$myVars = $self->variables();

	$val = $myVars->{$var};

	return $val;
}

sub
haveVariable
{
	my $self = shift;
	my $var = shift;
	my $myVars;
	my $flag;

	$myVars = $self->variables();

	$flag = 0;

	if (exists($myVars->{$var}))
	{
		$flag = 1;
	}

	return $flag;
}

sub
printConstant
{
	my $self = shift;
	my $info = shift;
	my $s;

	$s = $$info[1];

	if ($s =~ /^\"/)
	{
		$s =~ s/\"//g;
	}

	return $s;
}

sub
varToString
{
	my $self = shift;
	my $name = shift;
	my $v;
	my $i;
	my $s;

	$s = "";

	if ($self->haveVariable($name))
	{
		$v = $self->getVariable($name);

		if (ref($v))
		{
			$v->verbose($self->verbose());
			$s .= $v->toString();
		}
		elsif (ref($v) eq "ARRAY")
		{
			for $i (0..$#$v)
			{
				if (ref($$v[$i]))
				{
					$$v[$i]->verbose($self->verbose());
					$s .= $$v[$i]->toString();
				}
				else
				{
					$s .= $$v[$i];
				}

				if ($i < $#$v)
				{
					$s .= ", ";
				}	
			}
		}
		else
		{
			$s .= $v;
		}
	}
	else
	{
		$self->status(2);
	}

	return $s;
}

sub
printVariable
{
	my $self = shift;
	my $info = shift;
	my $name;
	my $s;
	my $r;

	$name = $$info[1];

	$r = $self->varToString($name);
	$s = "$name = $r";

	return $s;
}

sub
printCommand
{
	my $self = shift;
	my $info = shift;
	my $s;

	$s = $self->doFunction($info);

	return $s;	
}

sub
doPrint
{
	my $self = shift;
	my $info = shift;
	my $cmd_info;
	my $type;
	my $result;

	$cmd_info = $self->getBlockInfo($$info[2]);

	$type = $$cmd_info[0];

	if ($type eq "const")
	{
		$result = $self->printConstant($cmd_info);
	}
	elsif ($type eq "variable")
	{
		$result = $self->printVariable($cmd_info);
	}
	else
	{
		$self->status(1);
	}

	if ($self->statusIsValid())
	{
		$result .= "\n";	
	}

	return $result;
}

sub
doGBasis
{
	my $self = shift;
	my $info = shift;
	my $r;
	my @parts;
	my $F;
	my $list;
	my $p;
	my $v;

	$F = Math::MVPoly::Ideal->new();

	$list = [];
	foreach $p (@$info[2..$#$info])
	{
		# TODO: get info about p to see if it is a variable or a polynomial expr.
		$v = $self->getVariable($p);
		push(@$list, $v);
	}
	$F->set($list);

	$r = $F->getGBasis();

	return $r; 
}

sub
doSPoly
{
	my $self = shift;
	my $info = shift;
	my $v1;
	my $v2;
	my $n1;
	my $n2;
	my $r;

	$n1 = $$info[2];
	$n2 = $$info[3];

	$v1 = $self->getVariable($n1);
	$v2 = $self->getVariable($n2);

	$r = $v1->spoly($v2);

	return $r; 
}

sub
doMonLCM
{
	my $self = shift;
	my $info = shift;
	my $v1;
	my $v2;
	my $n1;
	my $n2;
	my $r;

	$n1 = $$info[2];
	$n2 = $$info[3];

	$v1 = $self->getVariable($n1);
	$v2 = $self->getVariable($n2);

	$v1 = $v1->getLT();
	$v2 = $v2->getLT();

	$r = $v1->getLCM($v2);

	$v1 = Math::MVPoly::Polynomial->new();
	$r = $v1->add($r);

	return $r; 
}

sub
doReduce
{
	my $self = shift;
	my $info = shift;
	my $v1;
	my $v2;
	my $n1;
	my $n2;
	my $r;

	$n1 = $$info[2];
	$v1 = $self->getVariable($n1);

	$v1->reduce();
}

sub
doGCD
{
	my $self = shift;
	my $info = shift;
	my $v1;
	my $v2;
	my $n;
	my $g;

	$n = $$info[2];
	$v1 = $self->getVariable($n);

	foreach $n (@$info[3..$#$info])
	{
		$v2 = $self->getVariable($n);
		$g = $v1->gcd($v2);
		$v1 = $g;
	}

	return $g; 
}

sub
doMult
{
	my $self = shift;
	my $info = shift;
	my $v1;
	my $v2;
	my $n1;
	my $n2;
	my $r;

	$n1 = $$info[2];
	$n2 = $$info[3];

	$v1 = $self->getVariable($n1);
	$v2 = $self->getVariable($n2);

	$r = $v1->mult($v2);

	return $r; 
}

sub
doQuo
{
	my $self = shift;
	my $info = shift;
	my $v1;
	my $v2;
	my $n1;
	my $n2;
	my $r;

	$n1 = $$info[2];
	$n2 = $$info[3];

	$v1 = $self->getVariable($n1);
	$v2 = $self->getVariable($n2);

	$r = $v1->divide($v2);

	return $$r[0];
}

sub
doRem
{
	my $self = shift;
	my $info = shift;
	my $v1;
	my $v2;
	my $n1;
	my $n2;
	my $r;

	$n1 = $$info[2];
	$n2 = $$info[3];

	$v1 = $self->getVariable($n1);
	$v2 = $self->getVariable($n2);

	$r = $v1->divide($v2);

	return $$r[1];
}

sub
doNormalf
{
	my $self = shift;
	my $info = shift;
	my $v1;
	my $v2;
	my $n1;
	my $n2;
	my $r;

	$n1 = $$info[2];
	$n2 = $$info[3];

	$v1 = $self->getVariable($n1);
	$v2 = $self->getVariable($n2);

	$r = $self->doDivide($info);

	return $$r[$#$r];
}

sub
doDivide
{
	my $self = shift;
	my $info = shift;
	my $v1;
	my $v2;
	my $v;
	my $n;
	my $n1;
	my $n2;
	my $r;
	my $s;
	my $arr;
	my @parts;

	$n1 = $$info[2];
	$n2 = $$info[3];

	$v1 = $self->getVariable($n1);

	if ($#$info > 3)
	{
		$arr = [];
		foreach $n (@$info[3..$#$info])
		{
			$v = $self->getVariable($n);
			push(@$arr, $v);
		}

		$r = $v1->divide($arr);		
	}
	else
	{
		$v2 = $self->getVariable($n2);
		$r = $v1->divide($v2);
	}

	return $r; 
}

sub
doSubtract
{
	my $self = shift;
	my $info = shift;
	my $v1;
	my $v2;
	my $n1;
	my $n2;
	my $r;

	$n1 = $$info[2];
	$n2 = $$info[3];

	$v1 = $self->getVariable($n1);
	$v2 = $self->getVariable($n2);

	$r = $v1->subtract($v2);

	return $r; 
}

sub
doAdd
{
	my $self = shift;
	my $info = shift;
	my $v1;
	my $v2;
	my $n1;
	my $n2;
	my $r;

	$n1 = $$info[2];
	$n2 = $$info[3];

	$v1 = $self->getVariable($n1);
	$v2 = $self->getVariable($n2);

	$r = $v1->add($v2);

	return $r; 
}

sub
doFunction
{
	my $self = shift;
	my $info = shift;
	my $cmd;
	my $result;

	$cmd = $$info[1];

	if ($cmd eq "print")
	{
		$result = $self->doPrint($info);
	}
	elsif ($cmd eq "monOrder")
	{
		$self->doMonomialOrdering($info);
	}
	elsif ($cmd eq "varOrder")
	{
		$self->doVariableOrdering($info);
	}
	elsif ($cmd eq "gbasis")
	{
		$result = $self->doGBasis($info);
	}
	elsif ($cmd eq "monLCM")
	{
		$result = $self->doMonLCM($info);
	}
	elsif ($cmd eq "spoly")
	{
		$result = $self->doSPoly($info);
	}
	elsif ($cmd eq "reduce")
	{
		$self->doReduce($info);
	}
	elsif ($cmd eq "gcd")
	{
		$result = $self->doGCD($info);
	}
	elsif ($cmd eq "mult")
	{
		$result = $self->doMult($info);
	}
	elsif ($cmd eq "add")
	{
		$result = $self->doAdd($info);
	}
	elsif ($cmd eq "subtract")
	{
		$result = $self->doSubtract($info);
	}
	elsif ($cmd eq "divide")
	{
		$result = $self->doDivide($info);
	}
	elsif ($cmd eq "normalf")
	{
		$result = $self->doNormalf($info);
	}
	elsif ($cmd eq "quo")
	{
		$result = $self->doQuo($info);
	}
	elsif ($cmd eq "rem")
	{
		$result = $self->doRem($info);
	}
	elsif ($cmd eq "value")
	{
		$result = $self->doValue($info);
	}
	elsif ($cmd eq "verbose")
	{
		$self->doVerbose($info);
	}
	elsif ($cmd eq "state")
	{
		$result = $self->doState($info);
	}
	else
	{
		$self->status(1);
	}

	return $result;	
}

sub
doMonomialOrdering
{
	my $self = shift;
	my $info = shift;
	my $monOrder;
	my $vars;
	my $v;
	my $varOrder;

	$monOrder = $$info[2];
	$monOrder =~ s/\W//g;


	# do some sanity checking

	if ($self->haveVariableOrdering())
	{
		$varOrder = $self->getVariable("varOrder");

		if ($monOrder eq "tdeg" && $#$varOrder > 1)
		{
			$self->status(6);
			return;
		}
	}

	if ($monOrder eq "tdeg" ||
	    $monOrder eq "grlex" ||
	    $monOrder eq "grevlex" ||
	    $monOrder eq "lex")
	{
		$self->setVariable("monOrder", $monOrder);

		# iterate through the variables and see if there are any 
		# polynomials.  Once found, change the monomial ordering 
		# and apply the change

		$vars = $self->variables();
		foreach $v (values %$vars)
		{
			if (ref($v) ne "" and 
	                    ref($v) ne "ARRAY" and
			    ref($v) ne "HASH")
			{
				$v->monOrder($monOrder);
				$v->applyOrder();
			}
		}
	}
	else
	{
		$self->status(1);
	}
}

sub
haveMonomialOrdering
{
	my $self = shift;
	my $flag;

	$flag = 0;

	if ($self->haveVariable("monOrder"))
	{
		$flag = 1;
	}	

	return $flag;
}

sub
doVariableOrdering
{
	my $self = shift;
	my $info = shift;
	my @vars;
	my $varOrder;
	my $vars;
	my $v;

	@vars = (@$info[2..$#$info]);

	# do some sanity checking

	if (! $self->haveMonomialOrdering())
	{
		$self->status(3);
		return;
	}
	elsif ($self->getVariable("monOrder") eq "tdeg" && $#vars > 1)
	{
		$self->status(5);
		return;
	}

	if ($#vars >= 0)
	{
		$varOrder = [@vars];
		$self->setVariable("varOrder", $varOrder);

		# iterate through the variables and see if there are any 
		# polynomials.  Once found, change the variable ordering

		$vars = $self->variables();
		foreach $v (values %$vars)
		{
			if (ref($v) ne "" and 
	                    ref($v) ne "ARRAY" and
			    ref($v) ne "HASH")
			{
				$v->varOrder([@vars]);
				$varOrder = $v->varOrder();
			}
		}
	}
	else
	{
		$self->status(1);
	}
}

sub
haveVariableOrdering
{
	my $self = shift;
	my $flag;

	$flag = 0;

	if ($self->haveVariable("varOrder"))
	{
		$flag = 1;
	}	

	return $flag;
}

sub
doVerbose
{
	my $self = shift;
	my $info = shift;
	my $v;
	my $p;
	my $vars;

	# toggle the verbose status
	$v = ! $self->verbose();
	$self->verbose($v);

	$vars = $self->variables();
	foreach $p (values %$vars)
	{
		if (ref($p))
		{
			$p->verbose($v);
		}
	}
}

sub
doState
{
	my $self = shift;
	my $s;

	$s = "\nState:\n\n";
	$s .= $self->toString();

	return $s;
}

sub
doValue
{
	my $self = shift;
	my $info = shift;
	my $v1;
	my $n1;
	my $r;

	$n1 = $$info[2];

	if ($self->haveVariable($n1))
	{
		$v1 = $self->getVariable($n1);

		# tell the object to copy itself - go go magic polymorphism!
		$r = $v1->new();
		$r->copy($v1);
	}
	else
	{
		$self->status(2);
		$r = "";
	}

	return $r;
}


sub
doAssignment
{
	my $self = shift;
	my $info = shift;
	my $cmd;
	my $var;
	my $set_info;
	my $type;
	my $v;
	my $p;
	my $monOrder;
	my $varOrder;

	$var = $$info[1];
	$cmd = $$info[2];

	$set_info = $self->getBlockInfo($cmd);

	$type = $$set_info[0];

	if ($type eq "function")
	{
		$v = $self->doFunction($set_info);
	}
	elsif ($type eq "variable")
	{
		if (! $self->haveMonomialOrdering())
		{
			$self->status(3);
		}
		if (!  $self->haveVariableOrdering())
		{
			$self->status(4);
		}
		else
		{
			$monOrder = $self->getVariable("monOrder");
			$varOrder = $self->getVariable("varOrder");
			$v = Math::MVPoly::Polynomial->new();
			$v->monOrder($monOrder);
			$v->varOrder([@$varOrder]);
			$v->fromString($$set_info[1]);
		}
	}
	elsif ($type eq "const")
	{
		$v = $$set_info[1];
	}
	else
	{
		$self->status(1);
	}

	if ($self->statusIsValid())
	{
		$self->setVariable($var, $v);	
	}
}

sub
getBlockInfo
{
	my $self = shift;
	my $s = shift;
	my $type;
	my $info;
	my $op;
	my @parts;
	my @args;	

	# remove the white space
	$s =~ s/\s//g;

	# 'deduce' the nature of $s
	if ($s =~ /\=/g)
	{
		@parts = split(/[\=]/, $s);
		$info = ["assignment", @parts];
	}
	elsif ($s =~ /[\(\)]/g)
	{
		@parts = split(/[\(\)]/, $s);
		@args = split(/[\,]/, $parts[1]);
		$info = ["function", $parts[0], @args];
	}
	elsif ($s =~ /[\"\'\,]/g)
	{
		$info = ["const", $s];
	}
	else
	{
		$info = ["variable", $s];
	}

	return $info;
}

sub
parseLine
{
	my $self = shift;
	my $s	 = shift;
	my $lnum = shift;
	my $info;
	my $type;
	my $result;

	$self->status(0);

	$info = $self->getBlockInfo($s);
	$type = $$info[0];

	if ($type eq "function")
	{
		$result = $self->doFunction($info);
	}
	elsif ($type eq "assignment")
	{
		$self->doAssignment($info);
	}			
	else
	{
		$self->status(1);
	}

	if (! $self->statusIsValid())
	{
		$result = $self->statusToString()." @ $lnum\n";
	}

	return $result;
}

sub
parseCGICmdString
{
	my $self = shift;
	my $s = shift;
	my $r;

	$r = $self->parseCmdString($s);

	# replace the EOL with the HTML EOL
	$r =~ s/\n/<br>\n/g;

	return $r;
}

sub
parseCmdString
{
	my $self = shift;
	my $s = shift;
	my $i;
	my @line;
	my $l;
	my $r;
	my $outs;

	@line = split(";",$s);

	$outs = "";

	foreach $i (0..$#line)
	{
		$_ = $line[$i];

		# remove white space
		s/\s//g;

		# skip comment lines
		if (/^ *\#/ || length($_) == 0)
		{
			next;
		}

		$outs .= $self->parseLine($_,$i);

		# leave if there was an error
		last if (! $self->statusIsValid());
	}

	return $outs;
}

sub
parseFile
{
	my $self = shift;
	my $fname = shift;
	my $s;
	my $r;
	
	open(INFILE, $fname);

	$s = "";

	while(<INFILE>)
	{
		$s .= $_;
	}

	close(INFILE);

	$r = $self->parseCmdString($s);

	return $r;
}

1;

__END__

=head1 NAME

Parser - a simple algebraic command parser

=head1 DESCRIPTION

=over 4

=item new

Return a reference to a new Parser object.

=for html <p>

=item variables

=item variables HASHREF

If input is passed, then assign this input as the new value of variables.  Return the current value of variables to teh caller.

=for html <p>

=item status

=item status INT

If input is passed, then assign this input as the new value to the current status.  Return the current status to the caller.

=for html <p>

=item statusIsValid

Returns a boolean indicating whether or not the current status is 'valid.'

=for html <p>

=item statusToString

Converts the current status value into its string representation and returns it.

=for html <p>

=item toString

Return a string representing the internal state of the parser.

=for html <p>

=item setVariable NAME,VALUE

Set the variable NAME to VALUE.

=for html <p>

=item getVariable NAME

Return the value of variable NAME to the caller.

=for html <p>

=item haveVariable NAME

Return a boolean indicating the existence of variable NAME.

=for html <p>

=item printConstant INFO

Return a string representing the constant referred to by INFO.

=for html <p>

=item printVariable INFO

Return a string representing the variable referred to by INFO.

=for html <p>

=item printCommand

Return a string representing the results of the command referred to by INFO.

=for html <p>

=item doPrint

Based on the block info, generate a string containing a printable value.

=for html <p>

=item doGBasis

Calculate the Groebner Basis of p1,...,p2.

=for html <p>

=item doSPoly

Calculate the S-Poly of p1 and p2.

=for html <p>

=item doMonLCM

Calculate the monomial Least Common Multiple of p1 and p2.

=for html <p>

=item doReduce

Attempt to reduce a polyomial to a simpler form.

=for html <p>

=item doGCD

Determine the Greatest Common Divisor of p1 and p2, where p1 and p2 are single variabel polynomials.

=for html <p>

=item doMult

Perform polynomial multiplication.

=for html <p>

=item doQuo

Determine the quotient of p1 / p2, where p1 and p2 are single variable polynomials.

=for html <p>

=item doRem

Determine the remainder of a p1 / p2.

=for html <p>

=item doNormalf

Calculate the normal form of p1 / (p2,...,pn).

=for html <p>

=item doDivide

Perform polynomial division. 

=for html <p>

=item doSubtract

Perform polynomial subtraction. 

=for html <p>

=item doAdd

Perform polynomial addition.

=for html <p>

=item doFunction

Determine and execute a function as indicated by the block info.

=for html <p>

=item doMonomialOrdering

Modify the monomial ordering.

=for html <p>

=item haveMonomialOrdering

Return a boolean indicating the existence of a monomial ordering.

=for html <p>

=item doVariableOrdering

Modify the variable ordering.

=for html <p>

=item haveVariableOrdering

Return a boolean indicating the existence of a variable ordering.

=for html <p>

=item doVerbose 

Toggle the verbose state of the interpreter and and polynomials contained within.

=for html <p>

=item doState

Generate a string representing the state of the variables in the interpreter.

=for html <p>

=item doValue

See value() in Language Commands. 

=for html <p>

=item doAssignment

Determine and assign a value to a variable.

=for html <p>

=item getBlockInfo

Query a string to determine its nature relative to the parsing scheme and return the info.

=for html <p>

=item varToString VARNAME

Retrieve the contents of VARNAME and convert the value into a string.

=for html <p>

=item parseLine STRING

Parse the string as a command.

=for html <p>

=item parseCmdString STRING

Isolate each command in STRING by parsing on ';', and then iterate through the list and call parseLine for each.  

=for html <p>

=item parseCGICmdString STRING

Operates almost identically to parseCmdString except that the resulting string is parsed, replacing each EOL with an HTML EOL. 

=for html <p>

=item parseFile FILENAME

Read a file and pass it to parseCmdString.

=back

=head1 AUTHOR

Brian Guarraci <bguarrac@hotmail.com>

