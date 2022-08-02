# ABSTRACT Perl extension for Math Postfix and Infix
###############################################################################
##                                                                           ##
##  Copyright (c) 2022 - by Carlos Celso.                                    ##
##  All rights reserved.                                                     ##
##                                                                           ##
##  This package is free software; you can redistribuite it                  ##
##  and/or modify it under the same terms as Perl itself.                    ##
##                                                                           ##
###############################################################################

	package Math::Notation::PostfixInfix;

	use strict;
	use Exporter;

	use vars qw( @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION );

	our @ISA = qw( Exporter );

	our @EXPORT = qw( new Infix_to_Postfix Postfix_to_Infix Postfix_Test );
	
	our @EXPORT_OK = qw( new Infix_to_Postfix Postfix_to_Infix Postfix_Test );

	our %EXPORT_TAGS = ( all => [@EXPORT_OK] );

	our $VERSION = "2022.035.1";

	1;

###############################################################################
# create object

sub new()
{
	my $class = shift; $class = ref($class) || $class || 'Math::Notation::PostfixInfix';

	## save options
	#
	my $self = {@_};
	#
	## new object
	#
	my $bless = bless($self,$class);
	return 0 if (!defined($bless));

	$bless;
}

###############################################################################
# polish test

sub Postfix_Test()
{
	my $self = shift;
	my $array = shift;
	my $call = shift;
	my @opts = @_;
	my @rc;
	my $is_code = (ref($call) eq "CODE");

	## scan and test the rules
	#
	for (my $ix=0; $ix < @{$array}; $ix++)
	{
		my $rule = $array->[$ix];

		## make 'or' operator
		#
		if	($rule eq "|")
		{
			my $rc1 = pop(@rc);
			my $rc2 = pop(@rc);
			push(@rc,($rc1 | $rc2)+0);
		}

		## make 'and' operator
		#
 		elsif	($rule eq "&")
		{
			my $rc1 = pop(@rc);
			my $rc2 = pop(@rc);
			push(@rc,($rc1 & $rc2)+0);
		}

		## parsing format val1 [operand] val2
		#
		elsif	(($rule =~ /^(.*)\s+=\s+(.*)$/) || ($rule =~ /^(.*)\s+==\s+(.*)$/) || ($rule =~ /^(.*)\s+eq\s+(.*)$/i))
		{
			($is_code) ? push(@rc,&{$call}($rule,"eq",$1,$2,@opts)+0) : push(@rc,($1 == $2)+0);
		}
		elsif	(($rule =~ /^(.*)\s+!=\s+(.*)$/) || ($rule =~ /^(.*)\s+<>\s+(.*)$/) ||( $rule =~ /^(.*)\s+ne\s+(.*)$/i))
		{
			($is_code) ? push(@rc,&{$call}($rule,"ne",$1,$2,@opts)+0) : push(@rc,($1 != $2)+0);
		}
		elsif	(($rule =~ /^(.*)\s+>\s+(.*)$/) || ($rule =~ /^(.*)\s+gt\s+(.*)$/))
		{
			($is_code) ? push(@rc,&{$call}($rule,"gt",$1,$2,@opts)+0) : push(@rc,($1 > $2)+0);
		}
		elsif	(($rule =~ /^(.*)\s+<\s+(.*)$/) || ($rule =~ /^(.*)\s+lt\s+(.*)$/))
		{
			($is_code) ? push(@rc,&{$call}($rule,"lt",$1,$2,@opts)+0) : push(@rc,($1 < $2)+0);
		}
		elsif	(($rule =~ /^(.*)\s+>=\s+(.*)$/) || ($rule =~ /^(.*)\s+ge\s+(.*)$/))
		{
			($is_code) ? push(@rc,&{$call}($rule,"ge",$1,$2,@opts)+0) : push(@rc,($1 >= $2)+0);
		}
		elsif	(($rule =~ /^(.*)\s+<=\s+(.*)$/) || ($rule =~ /^(.*)\s+le\s+(.*)$/))
		{
			($is_code) ? push(@rc,&{$call}($rule,"le",$1,$2,@opts)+0) : push(@rc,($1 <= $2)+0);
		}

		## use nom parsed format
		#
		else
		{
			($is_code) ? push(@rc,&{$call}($rule,"*",0,0,@opts)+0) : push(@rc,1); 
		}
	}
	foreach my $rc(@rc)
	{
		next if ($rc);
		return 0;
	}
	return 1;
}

###############################################################################
# convert polish to text format

sub Postfix_to_Infix()
{
	my $self = shift;
	my $array = shift;
	my @temp;
	
	for (my $ix=0; $ix < @{$array}; $ix++)
	{
		my $rule = $array->[$ix];
		if	($rule eq "|")
		{
			my $st2 = pop(@temp);
			my $st1 = pop(@temp);
			($ix+1 >= @{$array}) ?  push(@temp,$st1." or ".$st2) : push(@temp,"(".$st1." or ".$st2.")");
		}
		elsif	($rule eq "&")
		{
			my $st2 = pop(@temp);
			my $st1 = pop(@temp);
			push(@temp,$st1." and ".$st2);
		}
		else
		{
			push(@temp,$rule);
		}
	}
	for (my $ix=1; $ix<@temp; $ix++)
	{
		my $st2 = pop(@temp);
		my $st1 = pop(@temp);
		push(@temp,$st1." and ".$st2);
	}
	return $Math::Notation::PostfixInfix{unpolish} = join(" ",@temp);
}

##############################################################################
# convert text to polish format

sub Infix_to_Postfix
{
	my $self = shift;
	my $txt = shift;
	
	@{$Math::Notation::PostfixInfix{polish}} = ();
	@{$Math::Notation::PostfixInfix{operand}{0}} = ();
	$Math::Notation::PostfixInfix{square} = 0;

	if (($txt =~ /^(and|or|\&\&|\|\|)/) || ($txt =~ /^\s+(and|or|\&\&|\|\|)/) || ($txt =~ /(and|or|\&\&|\|\|)$/) || ($txt =~ /(and|or|\&\&|\|\|)\s+$/))
	{
		$! = "and/or at begin/end detected";
	}
	else {Math::Notation::PostfixInfix->_Parse($txt);}
	return @{$Math::Notation::PostfixInfix{polish}};
}

##############################################################################
#

sub _Parse()
{
	my $self = shift;
	my $txt = shift; $txt =~ s/^\s+|\s+$//g;

	$Math::Notation::PostfixInfix{text} = \$txt;

	my $tmp;
	while ($txt)
	{
		if	($txt =~ /^\((.*)/) {Math::Notation::PostfixInfix->_ParseSquareNew(); $txt=$1;}
		elsif	($txt =~ /^\)(.*)/) {Math::Notation::PostfixInfix->_ParseSquareEnd(); $txt=$1;}
		else
		{
			my ($a1,$b1) = ($txt =~ /^(.*?)\s+(.*)$/);
			my ($a2,$b2,$c2) = ($txt =~ /^(.*?)(\(\))(.*)$/);

			if	($a1 && $a2)	{ ($tmp,$txt) = (length($a1) < length($a2)) ? ($a1,$b1) : ($a2,"(".$b2.")".$c2); }
			elsif	($b2)		{ ($tmp,$txt) = ($a2,"(".$b2.")".$c2); }
			elsif	($b1)		{ ($tmp,$txt) = ($a1,$b1); }
			else				{ ($tmp,$txt) = ($txt,""); }

			($tmp,$txt) = ($1,")".$txt) if ($tmp =~ /(.*)\)$/);
			if ($tmp =~ /(^and|^or|^\&\&|^\|\|)/)
			{
				Math::Notation::PostfixInfix->_ParseOperator($tmp);
			}
			else
			{
				Math::Notation::PostfixInfix->_ParseOperand($tmp);
			}
		}
	}
	if ($Math::Notation::PostfixInfix{square} > 0)
	{
		print STDERR "Square mismatch, too many open ($Math::Notation::PostfixInfix{square})\n";
		exit(-1);
	}
	while ($Math::Notation::PostfixInfix{square} > -1)
	{
		while (@{$Math::Notation::PostfixInfix{operand}{$Math::Notation::PostfixInfix{square}}})
		{
			$Math::Notation::PostfixInfix{last} = 1;
			Math::Notation::PostfixInfix->_ParseOperand(pop(@{$Math::Notation::PostfixInfix{operand}{$Math::Notation::PostfixInfix{square}}}));
		}
		$Math::Notation::PostfixInfix{square}--;
	}
}

##############################################################################
#

sub _ParseOperator()
{
	my $self = shift;
	my $oper = shift;

	if	($oper =~ /^and$/i)	{ $oper = "&"; }
	elsif	($oper =~ /^\&\&$/i)	{ $oper = "&"; }
	elsif	($oper =~ /^or$/i)	{ $oper = "|"; }
	elsif	($oper =~ /^\|\|$/i)	{ $oper = "|"; }

	my $no = @{$Math::Notation::PostfixInfix{operand}{$Math::Notation::PostfixInfix{square}}};
	if ($no && $Math::Notation::PostfixInfix{operand}{$Math::Notation::PostfixInfix{square}}->[$no-1] eq "&")
	{
		$Math::Notation::PostfixInfix{last} = 1;
		Math::Notation::PostfixInfix->_ParseOperand(pop(@{$Math::Notation::PostfixInfix{operand}{$Math::Notation::PostfixInfix{square}}}));
	}
	push(@{$Math::Notation::PostfixInfix{operand}{$Math::Notation::PostfixInfix{square}}},$oper);
	$Math::Notation::PostfixInfix{last} = 1;
}

##############################################################################
#

sub _ParseOperand()
{
	my $self = shift;
	my $info = shift;

	if ($Math::Notation::PostfixInfix{last} || @{$Math::Notation::PostfixInfix{polish}} == 0)
	{
		push(@{$Math::Notation::PostfixInfix{polish}},$info);
		$Math::Notation::PostfixInfix{last} = 0;
	}
 	else { $Math::Notation::PostfixInfix{polish}->[@{$Math::Notation::PostfixInfix{polish}}-1] .= " ".$info; }

}

##############################################################################
#

sub _ParseSquareNew()
{
	my $self = shift;

	$Math::Notation::PostfixInfix{square}++;
	@{$Math::Notation::PostfixInfix{operand}{$Math::Notation::PostfixInfix{square}}} = ();
}

##############################################################################
#

sub _ParseSquareEnd()
{
	my $self = shift;

	$Math::Notation::PostfixInfix{last} = 1;
	Math::Notation::PostfixInfix->_ParseOperand(pop(@{$Math::Notation::PostfixInfix{operand}{$Math::Notation::PostfixInfix{square}}}));
	$Math::Notation::PostfixInfix{square}--;
	if ($Math::Notation::PostfixInfix{square} < 0)
	{
		print STDERR "Square mismatch, too many close\n";
		exit(-1);
	}
}

__END__
