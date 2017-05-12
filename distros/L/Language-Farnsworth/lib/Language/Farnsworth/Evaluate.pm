#!/usr/bin/perl

package Language::Farnsworth::Evaluate;

use strict;
use warnings;

use Data::Dumper;

use Language::Farnsworth::FunctionDispatch;
use Language::Farnsworth::Variables;
use Language::Farnsworth::Units;
use Language::Farnsworth::Parser;
use Language::Farnsworth::Value::Types;
use Language::Farnsworth::Value::Pari;
use Language::Farnsworth::Value::Date;
use Language::Farnsworth::Value::String;
use Language::Farnsworth::Value::Undef;
use Language::Farnsworth::Value::Lambda;
use Language::Farnsworth::Value::Array;
use Language::Farnsworth::Value::Boolean;
use Language::Farnsworth::Output;
use Language::Farnsworth::Error;

use Math::Pari;# ':hex'; #why not? because it fucks up so fucking badly that fuck isn't a strong enough word

sub new
{
    my $class = shift;
	my $self = {};
	bless $self;

	my %opts = (@_);

	if (ref($opts{funcs}) eq "Language::Farnsworth::FunctionDispatch")
	{
		$self->{funcs} = $opts{funcs};
	}
	else
	{
		$self->{funcs} = new Language::Farnsworth::FunctionDispatch();
	}

	if (ref($opts{vars}) eq "Language::Farnsworth::Variables")
	{
		$self->{vars} = $opts{vars};
	}
	else
	{
		$self->{vars} = new Language::Farnsworth::Variables();
	}

	if (ref($opts{units}) eq "Language::Farnsworth::Units")
	{
		$self->{units} = $opts{units};
	}
	else
	{
		$self->{units} = new Language::Farnsworth::Units();
	}

	if (ref($opts{parser}) eq "Language::Farnsworth::Parser")
	{
		$self->{parser} = $opts{parser};
	}
	else
	{
		$self->{parser} = new Language::Farnsworth::Parser();
	}

	$self->{dumpbranches} = 0;

    return $self;
}

sub DESTROY
{
	debug 2,"SCOPE DIE: $_[0]";
}

sub eval
{
	my $self = shift;
	my $code = shift; #i should probably take an array, so i can use arrays of things, but that'll be later

	$code =~ s/^\s*//;
	$code =~ s/\s*$//;

	my $tree = $self->{parser}->parse($code); #should i catch the exceptions here? dunno

	debug 3, Dumper($tree);

    my $ret = eval{$self->evalbranch($tree)};
    
    #capture return[] at minimum level
    if ($@ && $@->isa("Language::Farnsworth::Error")&&$@->isreturn())
    {
    	return $@->getmsg();
    }
    elsif ($@ && $@->isa("Language::Farnsworth::Error"))
    {
    	return $@;
    }
    elsif ($@)
    {
    	error EPERL, $@;
    }
    else
    {
    	return $ret;
    }
}

#evaluate a single branch
sub evalbranch
{
	my $self = shift;

	my $branch = shift;
	my $type = ref($branch); #this'll grab what kind from the bless on the tree

	my $return; #to make things simpler later on

	#print Data::Dumper->Dump([$branch],["BRANCH"]);

	if ($type eq "Add")
	{
		my $a = $self->makevalue($branch->[0]);
		my $b = $self->makevalue($branch->[1]);
		$return = $a + $b;
	}
	elsif ($type eq "Sub")
	{
		my $a = $self->makevalue($branch->[0]);
		my $b = $self->makevalue($branch->[1]);
		$return = $a - $b;
	}
	elsif ($type eq "Mul")
	{
	    if ((ref($branch->[0]) eq "Fetch") && (ref($branch->[1]) eq "Array") && ($branch->[2] eq "imp"))
		{
		    #we've got a new style function call!
			my $a = $branch->[0][0]; #grab the function name
			my $b = $self->makevalue($branch->[1]);

#			print STDERR "----------------FUNCCALL! $a\n";
#			print STDERR "$self";
#			print Dumper($a, $b);
			
			if ($self->{funcs}->isfunc($a)) #check if there is a func $a
			{   #$return = $self->{funcs}->callfunc($self, $name, $args, $branch);
				$return = $self->{funcs}->callfunc($self, $a, $b, $branch);
			}
			else #otherwise we try to 
			{
				$a = $self->makevalue($branch->[0]); #evaluate it, since it wasn't a function
				
				$return = $a * $b; #do the multiplication
			}
		}
		else
		{
		    my $a = $self->makevalue($branch->[0]);
			my $b = $self->makevalue($branch->[1]);

			#print "-----------SUBMULT!\n";
			#print Dumper($a,$b);

			$return = $a * $b;
		}
	}
	elsif ($type eq "Div")
	{
		my $a = $self->makevalue($branch->[0]);
		my $b = $self->makevalue($branch->[1]);
		#print Dumper($a, $b);
		$return = $a / $b;
	}
	elsif ($type eq "Conforms")
	{
		my $a = $self->makevalue($branch->[0]);
		my $b = $self->makevalue($branch->[1]);
		$return = new Language::Farnsworth::Value::Boolean($a->conforms($b));
	}
	elsif ($type eq "Mod")
	{
		my $a = $self->makevalue($branch->[0]);
		my $b = $self->makevalue($branch->[1]);
		$return = $a % $b;
	}
	elsif ($type eq "Pow")
	{
		my $a = $self->makevalue($branch->[0]);
		my $b = $self->makevalue($branch->[1]);
		$return = $a ** $b;
	}
	elsif ($type eq "And")
	{
		my $a = $self->makevalue($branch->[0]);

		if ($a->bool())
		{
			my $b = $self->makevalue($branch->[1]);
			$return = $a && $b ? 1 : 0;
			$return = Language::Farnsworth::Value::Boolean->new($return); #make sure its the right type
		}
		else
		{
			$return = Language::Farnsworth::Value::Boolean->new(0); #make sure its the right type
		}
	}
	elsif ($type eq "Or")
	{
		my $a = $self->makevalue($branch->[0]);

		if ($a->bool())
		{
			$return = Language::Farnsworth::Value::Boolean->new(1); #make sure its the right type
		}
		else
		{
			my $b = $self->makevalue($branch->[1]);
			$return = $a || $b ? 1 : 0;
			$return = Language::Farnsworth::Value::Boolean->new($return); #make sure its the right type
		}
	}
	elsif ($type eq "Xor")
	{
		my $a = $self->makevalue($branch->[0]);
		my $b = $self->makevalue($branch->[1]);
		$return = $a->bool() ^ $b->bool() ? 1 : 0;
		$return = Language::Farnsworth::Value::Boolean->new($return); #make sure its the right type
	}
	elsif ($type eq "Not")
	{
		my $a = $self->makevalue($branch->[0]);
		$return = $a->bool() ? 0 : 1;
		$return = Language::Farnsworth::Value::Boolean->new($return); #make sure its the right type
	}
	elsif ($type eq "Gt")
	{
		my $a = $self->makevalue($branch->[0]);
		my $b = $self->makevalue($branch->[1]);
		$return = ($a > $b) ? 1 : 0;
		$return = Language::Farnsworth::Value::Boolean->new($return); #make sure its the right type
	}
	elsif ($type eq "Lt")
	{
		my $a = $self->makevalue($branch->[0]);
		my $b = $self->makevalue($branch->[1]);
		$return = $a < $b ? 1 : 0;
		$return = Language::Farnsworth::Value::Boolean->new($return); #make sure its the right type
	}
	elsif ($type eq "Ge")
	{
		my $a = $self->makevalue($branch->[0]);
		my $b = $self->makevalue($branch->[1]);
		$return = $a >= $b ? 1 : 0;
		$return = Language::Farnsworth::Value::Boolean->new($return); #make sure its the right type
	}
	elsif ($type eq "Le")
	{
		my $a = $self->makevalue($branch->[0]);
		my $b = $self->makevalue($branch->[1]);
		$return = $a <= $b ? 1 : 0;
		$return = Language::Farnsworth::Value::Boolean->new($return); #make sure its the right type
	}
	elsif ($type eq "Compare")
	{
		my $a = $self->makevalue($branch->[0]);
		my $b = $self->makevalue($branch->[1]);
		$return = $a <=> $b;
		$return = Language::Farnsworth::Value::Pari->new($return); #make sure its the right type
	}
	elsif ($type eq "Eq")
	{
		my $a = $self->makevalue($branch->[0]);
		my $b = $self->makevalue($branch->[1]);
		$return = $a == $b ? 1 : 0;
		$return = Language::Farnsworth::Value::Boolean->new($return); #make sure its the right type
	}
	elsif ($type eq "Ne")
	{
		my $a = $self->makevalue($branch->[0]);
		my $b = $self->makevalue($branch->[1]);
		$return = $a != $b ? 1 : 0;
		$return = Language::Farnsworth::Value::Boolean->new($return); #make sure its the right type
	}
	elsif ($type eq "Ternary")
	{
		#turing completeness FTW
		my $left = $self->makevalue($branch->[0]);
		#$left = $left->bool() != new Language::Farnsworth::Value::Pari(0, $left->{dimen}); #shouldn't need it anymore, since i got ->bool working
		$return = $left ? $self->makevalue($branch->[1]) : $self->makevalue($branch->[2]);
	}
	elsif ($type eq "If")
	{
		#turing completeness FTW
		my $left = $self->makevalue($branch->[0]);
		#$left = $left != new Language::Farnsworth::Value(0, $left->{dimen});
		
		if ($left)
		{
			$return = $self->makevalue($branch->[1]);
		}
		else
		{
			$return = $self->makevalue($branch->[2]);
		}
	}
	elsif ($type eq "Store")
	{
		my $value = $self->makevalue($branch->[1]);
		my $lvalue = $self->makevalue($branch->[0]);
		$return = $value; #make stores evaluate to the value on the right
		#$self->{vars}->setvar($name, $value);
		$lvalue->{stored}++; #testing
		my $cloned = $value->clone();
		#warn "SETTING VALUES";
		#warn Data::Dumper->Dump([$lvalue, $lvalue->getref(), $value, $cloned], [qw($lvalue \$ref $value $cloned)]);
		$cloned->setref(\$cloned);
		debug 6, "---STORE---\n",Data::Dumper->Dump([$lvalue, $value, $cloned, $lvalue->getref()],[qw(lvalue value cloned lvalref)]);
		${$lvalue->{_ref}} = $cloned;
		debug 6, "---STORE---\n",Data::Dumper->Dump([$lvalue, $value, $cloned, $lvalue->getref()],[qw(lvalue value cloned lvalref)]);
#		eval {
#			my $rrval = $self->makevalue($branch->[0]);
#			debug 2, Data::Dumper->Dump([$rrval, $lvalue, $cloned], [qw(rrval lvalue cloned)]);
#		}; #keep it from killing things ahead of time
#		undef $@;
	}
	elsif ($type eq "StoreAdd")
	{
		my $value = $self->makevalue($branch->[1]);
		my $lvalue = $self->makevalue($branch->[0]);
				
		my $cloned = $value->clone();
		$return = (${$lvalue->getref()} = $lvalue + $cloned);
	}
	elsif ($type eq "StoreSub")
	{
		my $value = $self->makevalue($branch->[1]);
		my $lvalue = $self->makevalue($branch->[0]);
		
		my $cloned = $value->clone();
		$return = (${$lvalue->getref()} = $lvalue - $cloned);
	}
	elsif ($type eq "StoreDiv")
	{
		my $value = $self->makevalue($branch->[1]);
		my $lvalue = $self->makevalue($branch->[0]);
		
		my $cloned = $value->clone();
		$return = (${$lvalue->getref()} = $lvalue / $cloned);
	}
	elsif ($type eq "StoreMul")
	{
		my $value = $self->makevalue($branch->[1]);
		my $lvalue = $self->makevalue($branch->[0]);
		
		my $cloned = $value->clone();
		$return = (${$lvalue->getref()} = $lvalue * $cloned);
	}
	elsif ($type eq "StoreMod")
	{
		my $value = $self->makevalue($branch->[1]);
		my $lvalue = $self->makevalue($branch->[0]);
	
		my $cloned = $value->clone();
		$return = (${$lvalue->getref()} = $lvalue % $cloned);
	}
	elsif ($type eq "StorePow")
	{
		my $value = $self->makevalue($branch->[1]);
		my $lvalue = $self->makevalue($branch->[0]);
		
		my $cloned = $value->clone();
		$return = (${$lvalue->getref()} = $lvalue ** $cloned);
	}
	elsif ($type eq "PreInc")
	{
		my $lvalue = $self->makevalue($branch->[0]);
		$return = (${$lvalue->getref()} = $lvalue+VALUE_ONE());
	}
	elsif ($type eq "PostInc")
	{
		my $lvalue = $self->makevalue($branch->[0]);
		my $val = $lvalue->clone();
		${$lvalue->getref()} = $val+VALUE_ONE();

		$return = $val;
	}
	elsif ($type eq "PreDec")
	{
		my $lvalue = $self->makevalue($branch->[0]);
		$return = (${$lvalue->getref()} = $lvalue-VALUE_ONE());	
	}
	elsif ($type eq "PostDec")
	{
		my $lvalue = $self->makevalue($branch->[0]);
		my $val = $lvalue->clone();
		${$lvalue->getref()} = $val-VALUE_ONE();

		$return = $val;	
	}
	elsif ($type eq "DeclareVar")
	{
		my $name = $branch->[0];
		my $value;
		#print "\n\n DECLARING $name\n";
		#print Dumper($branch);

		if (defined($branch->[1]))
		{
			$value = $self->makevalue($branch->[1]);
		}
		else
		{
			$value = $self->makevalue(bless [0], 'Num');
		}

		$return = $value; #make stores evaluate to the value on the right
		$self->{vars}->declare($name, $value);
	}
	elsif ($type eq "DeclareFunc")
	{
		#print Dumper($branch);
		my $name = $branch->[0];
		my $lambda = $self->makevalue($branch->[1]);

		#should i allow constants? if i do i'll have to handle them differently, for now it'll be an error
		error "Right side of function declaration for '$name' did not evaluate to a lambda" unless ($lambda->istype("Lambda"));

		$self->{funcs}->addfunclamb($name, $lambda);
		$return = $lambda;
	}	
	elsif ($type eq "FuncDef")
	{
		#print Dumper($branch);
		my $name = $branch->[0];
		my $args = $branch->[1];
		my $value = $branch->[2]; #not really a value, but in fact the tree to run for the function

		my $nvars = new Language::Farnsworth::Variables($self->{vars}); #lamdbas get their own vars
		my %nopts = (vars => $nvars, funcs => $self->{funcs}, units => $self->{units}, parser => $self->{parser});
		my $scope = $self->new(%nopts);

		my $vargs;

		for my $arg (@$args)
		{
			my $reference = $arg->[3];
			my $constraint = $arg->[2];
			my $default = $arg->[1];
			my $name = $arg->[0]; #name

			if (defined($default))
			{
				$default = $self->makevalue($default); #should be right
			}

			if (defined($constraint))
			{
				#print Dumper($constraint);
				$constraint = $self->makevalue($constraint); #should be right
				#print Dumper($constraint);
			}

			push @$vargs, [$name, $default, $constraint, $reference];
		}

		$self->{funcs}->addfunc($name, $vargs, $value, $scope);
		$return = undef; #cause an error should someone manage to make it parse other than the way i think it should be
	}
	elsif ($type eq "Lambda")
	{
		my $args = $branch->[0];
		my $code = $branch->[1];

		#print "==========LAMBDA==========\n";
		#print Data::Dumper->Dump([$args,$code], ["args", "code"]);

		my $nvars = new Language::Farnsworth::Variables($self->{vars}); #lamdbas get their own vars
		my %nopts = (vars => $nvars, funcs => $self->{funcs}, units => $self->{units}, parser => $self->{parser});
		my $scope = $self->new(%nopts);

		#this should probably get a function in Language::Farnsworth::FunctionDispatch
		my $vargs;

		for my $arg (@$args)
		{
			my $reference = $arg->[3];
			my $constraint = $arg->[2];
			my $default = $arg->[1];
			my $name = $arg->[0]; #name

#			if ($reference)
#			{
#				#we've got a reference for lambdas!
#				error "Passing arguments by reference for lambdas is unsupported at this time";
#			}

			if (defined($default))
			{
				$default = $self->makevalue($default); #should be right
			}

			if (defined($constraint))
			{
				#print Dumper($constraint);
				$constraint = $self->makevalue($constraint); #should be right
				#print Dumper($constraint);
			}

			push @$vargs, [$name, $default, $constraint, $reference];
		}

		$return = new Language::Farnsworth::Value::Lambda($scope, $vargs, $code, $branch);
	}
	elsif ($type eq "LambdaCall") #still used in ONE place, sort[] in Standard.pm, i need to get the code to use mult but that's being a pita and i'm done trying to do it at the moment
	{		
		my $left = $self->makevalue($branch->[0]);
		my $right = $self->makevalue($branch->[1]);

		error "Right side of lamdbda call must evaluate to a Lambda\n" unless $right->istype("Lambda");

		#need $args to be an array
		my $args = $left->istype("Array") ? $left :  new Language::Farnsworth::Value::Array([$left]); 

		$return = $self->{funcs}->calllambda($right, $args); #needs to be updated
	}
	elsif (($type eq "Array") || ($type eq "SubArray"))
	{
		my $array = []; #fixes bug with empty arrays
		for my $bs (@$branch) #iterate over all the elements
		{
			my $type = ref($bs); #find out what kind of thing we are
			my $value = $self->makevalue($bs);

			#print "ARRAY FILL -- $type\n";

#			if ($value->istype("Array"))
#			{
				#since we have an array, but its not in a SUBarray, we dereference it before the push
				#push @$array, $value->getarray() unless ($type eq "SubArray");
				#push @$array, $value;# if ($type eq "SubArray");
				#}
			#else
			{
				#print "ARRAY VALUE --- ".Dumper($value);
				#its not an array or anything so we push it on
				push @$array, $value; #we return an array ref! i need more error checking around for this later
			}
		}
		$return = new Language::Farnsworth::Value::Array($array);
	}
	elsif ($type eq "ArgArray")
	{
		my $array = []; #autovivification wasn't working?
		for my $bs (@$branch) #iterate over all the elements
		{
			my $type = ref($bs); #find out what kind of thing we are
			my $value = $self->makevalue($bs);

			#even if it is an array we don't want to deref it here, because thats the wrong behavior, this will make things like push[a, 1,2,3] work properly
			push @$array, $value; #we return an array ref! i need more error checking around for this later
		}
		$return = new Language::Farnsworth::Value::Array($array);
	}
	elsif ($type eq "ArrayFetch")
	{
		#print "\n\nAFETCH\n";
		my $var = $self->makevalue($branch->[0]); #need to check if this is an array, and die if not
		my $listval = $self->makevalue($branch->[1]);
		my @rval;

		#print Data::Dumper->Dump([$branch, $var, $listval], ["branch","var","listval"]);

		for ($listval->getarray())
		{
			my $index = $_->getpari()*1.0;
			#print STDERR "ARFET: ".$_->toperl()."\n";
			#ok this line FOR WHATEVER REASON, makes Math::Pari.xs die in isnull(), WHY i don't know, there's something wrong here somewhere
			#my $float = $_ * (Language::Farnsworth::Value::Pari->new(1.0)); #makes rationals work right
			
			my $input = $var->getarrayref()->[$index]; 
			
			#error "Array out of bounds\n" #old message, check is down below now;
			$var->getarrayref()->[$index] = TYPE_UNDEF unless defined $input; 
			$input = $var->getarrayref()->[$index] unless defined $input; #reset the value if needed, this code should be redone but i don't feel like it right now XXX
			
			$input->setref(\$var->getarrayref()->[$index]);
			push @rval, $input;
		}

		#print Dumper(\@rval);

		if (@rval > 1)
		{
			my $pr = new Language::Farnsworth::Value::Array([@rval]);
			$return = $pr;
			$return->setref(\$return); #i think this should work fine
		}
		else
		{
			$return = $rval[0];
		}
	}
	elsif ($type eq "ArrayStore")
	{
		my $var = $self->makevalue(bless [$branch->[0]], 'Fetch'); #need to check if this is an array, and die if not
		my $listval = $self->makevalue($branch->[1]);
		my $rval = $self->makevalue($branch->[2]);

		#print Dumper($branch, $var, $listval);

		if ($listval->getarray() > 1)
		{
			error "Assigning to slices not implemented yet\n";
		}
		
		error "Only numerics may be given as array indexes!" unless ($listval->getarrayref()->[0]->istype("Pari"));

		my $num = $listval->getarrayref()->[0]->getpari() + 0; #the +0 makes sure its coerced into a number

		$var->getarrayref()->[$num] = $rval;

		for my $value ($var->getarray())
		{
			$value = $self->makevalue(bless [0], 'Num') if !defined($value);
		}

		$return = $rval;
	}
	elsif ($type eq "While")
	{
		my $cond = $branch->[0]; #what to check each time
		my $stmts = $branch->[1]; #what to run each time

		my $condval = $self->makevalue($cond);
		while ($condval)
		{
			my $v = $self->makevalue($stmts);
			$condval = $self->makevalue($cond);
		}

		$return = undef; #cause errors
	}
	elsif ($type eq "Stmt")
	{
		for my $bs (@$branch) #iterate over all the statements
		{   
			if (defined($bs))
			{
				my $r = $self->makevalue($bs);
				$return = $r if defined $r; #this has interesting semantics!
			}
		}
	}
	elsif ($type eq "Paren")
	{
		$return = $self->makevalue($branch->[0]);
	}
	elsif ($type eq "SetDisplay")
	{
		#TODO make error checking
		print Dumper($branch);
		my $combo = $branch->[0][0]; #is a string?
		my $right = $self->makevalue($branch->[1]);

		Language::Farnsworth::Output->setdisplay($combo, $right);
	}
	elsif ($type eq "UnitDef")
	{
		my $unitsize = $self->makevalue($branch->[1]);
		my $name = $branch->[0];
		$self->{units}->addunit($name, $unitsize);
		$return = $unitsize;
	}
	elsif ($type eq "DefineDimen")
	{
		my $unit = $branch->[1];
		my $dimen = $branch->[0];
		$self->{units}->adddimen($dimen, $unit);
	}
	elsif ($type eq "DefineCombo")
	{
		my $combo = $branch->[1]; #should get me a string!
		my $value = $self->makevalue($branch->[0]);
		Language::Farnsworth::Output::addcombo($combo, $value);
	}
	elsif (($type eq "SetPrefix") || ($type eq "SetPrefixAbrv"))
	{
		my $name = $branch->[0];
		my $value = $self->makevalue($branch->[1]);
		#carp "SETTING PREFIX0: $name : $value : ".Dumper($branch->[1]) if ($name eq "m");
		$self->{units}->setprefix($name, $value);
	}
	elsif ($type eq "Trans")
	{
		my $left = $self->makevalue($branch->[0]);
		my $rights = eval {$self->makevalue($branch->[1])};
		print "TRANS: right side eval\n";
		#print Dumper($@);
		my $right = $rights;

		if (!$@ && defined($rights) && $rights->istype("String")) #if its a string we do some fun stuff
		{
			print "STRINGED\n";
			$right = $self->eval($rights->getstring()); #we need to set $right to the evaluation $rights
			#print Dumper($rights, $right);
			print "ERRORED: ".Dumper($@);
		}

		if (!$@)
		{
			debug 1,"\n\nLEFT\n";
			debug 1,ref($left);
			debug 1,"RIGHT\n";
			debug 1,ref($right);
			
			if ($left->conforms($right)) #only do this if they are the same
			{
				print "Got Conformity\n";
				my $dispval = ($left / $right);

				#$return = $left; 
				%$return = %$left; #ok this makes NO SENSE as to WHY it would behave like it was...
				bless $return, ref($left);
				
				if ($rights->istype("String"))
				{
					#right side was a string, use it
					$return->{outmagic} = [$dispval, $rights];
				}
				else
				{
					$return->{outmagic} = [$dispval];
				}
			}
			elsif ($right->istype("Lambda"))
			{
				print "Got a lambda";
				$return = $right * $left; #simple enough, just use the overloaded operator
			}
# this code isn't being used is it? fuck i need better docs and tests
#			elsif ($self->{funcs}->isfunc($branch->[1][0]))
#			{
#				$left = $left->istype("Array") ? $left : new Language::Farnsworth::Value::Array([$left]);
#				$return = $self->{funcs}->callfunc($self, $branch->[1][0], $left);
#
#				if ($rights->istype("String"))
#				{
#					#right side was a string, use it
#					my $nm = {%$return}; #do a shallow copy!
#					bless $nm, ref($return); #rebless it
#					$return->{outmagic} = [$nm, $rights];
#				}
#			}
			else
			{
				error "Conformance error, can't convert from ".($left->type($self))." to ".($right->type($self))."\n";
			}
		}
		else
		{
			#$right doesn't evaluate... so we check for a function?
			$left = $left->istype("Array") ? $left : new Language::Farnsworth::Value::Array([$left]);
			$return = $self->{funcs}->callfunc($self, $branch->[1][0], $left);

			if (defined($rights) && $rights->istype("String"))
			{
				#right side was a string, use it
				my $nm = {%$return}; #do a shallow copy!
				bless $nm, ref($return); #rebless it
				$return->{outmagic} = [$nm, $rights];
			}
		}
	}

	if (!defined($return))
	{
		#this creates a "true" undefined value for returning, this makes things funner! it also introduced a bug from naive coding above, which has been fixed
		$return = new Language::Farnsworth::Value::Undef();
	}
	
	return $return;
}

sub makevalue
{
	my $self = $_[0];
	my $input = $_[1]; #switching from shift here, so that i can keep @_ intact for recursing

#	print "MAKEVALUE---------\n";
#	print Dumper($input);

	if (ref($input) eq "Num")
	{
		#need to make a value here with Language::Farnsworth::Value!
		my $val = new Language::Farnsworth::Value::Pari($input->[0]);
		return $val;
	}
	if (ref($input) eq "HexNum")
	{
		#need to make a value here with Language::Farnsworth::Value!
		#print "HEX VALUE: ".$input->[0]."\n";
		#my $value = eval $input->[0]; #this SHOULD work, shouldn't be a security risk since its validated through the lexer and parser.
		my $val = new Language::Farnsworth::Value::Pari($input->[0],undef,undef,1);
		return $val;
	}
	elsif (ref($input) eq "Fetch")
	{
		#this needs to decide between variable and unit, but that'll come later
		#esp since i also have to have this overridable for functions!

		my $name = $input->[0];
		if ($self->{vars}->isvar($name))
		{
			return $self->{vars}->getvar($input->[0]);
		}
		elsif ($self->{units}->isunit($name))
		{
			#print "FETCH: $name\n" if ($name eq "milli");
			return $self->{units}->getunit($name);
		}
		
		error "Undefined symbol '$name'\n";
	}
	elsif (ref($input) eq "GetFunc")
	{
		my $name = $input->[0];
		if ($self->{funcs}->isfunc($name))
		{
			return $self->{funcs}->getfunc($name)->{lambda};
		}
		else
		{
			error "Undefined function '$name'";			
		}
	}
	elsif (ref($input) eq "String") #we've got a string that should be a value!
	{
		my $value = $input->[0];
		#here it comes in with quotes, so lets remove them
		#$value =~ s/^"(.*)"$/$1/; #no longer needed
		#$value =~ s/\\"/"/g; #i'm gonna move these into the constructor i think
		#$value =~ s/\\\\/\\/g;
		$value =~ s/\\(.)/qq("\\$1")/eeg;
		my $ss = sub
		{
			my $var =shift; 
			$var =~ s/^[\$]//; 
			my $output = undef;
			if ($var !~ /^{.*}$/) 
			{
				$output = new Language::Farnsworth::Output($self->{units}, $self->{vars}->getvar($var), $self);
			} 
			else 
			{
				$var =~ s/[{}]//g;
				$output = new Language::Farnsworth::Output($self->{units}, $self->eval($var), $self);
			}

			"".$output;
		};
		$value =~ s/(?<!\\)(\$\w+|\${[^}]+})/$ss->($1)/eg;
		my $val = new Language::Farnsworth::Value::String($value);
		return $val;
	}
	elsif (ref($input) eq "Date")
	{
		#print "\n\n\nMaking DATE!\n\n\n";
		my $val = new Language::Farnsworth::Value::Date($input->[0]);
#		print Dumper($val);
		return $val;
	}
	elsif (ref($input) eq "VarArg")
	{
		#warn "Got a VarArg, code untested, want to mark when i get them\n"; #just so i can track down the inevitable crash
		return "VarArg";
	}
	elsif (ref($input) =~ /Language::Farnsworth::Value/)
	{
		debug 5, "Got a Language::Farnsworth::Value::*, i PROBABLY shouldn't be getting these, i'm just going to let it fall through";
		return $input;
	}

	#return $self->evalbranch($input);
	goto &evalbranch; #EVIL GOTO! but might save a stack frame! OMG!
}

1;
__END__

=encoding utf8

=head1 NAME

Language::Farnsworth::Evaluate

=head1 DESCRIPTION

This is an internally used class and has nothing of value to be used by the "public"

=head1 TODO

Clean up some of the code and try to create/document a public interface, since this will be neccesary for creating the plugin interface.

=head1 AUTHOR

Ryan Voots E<lt>simcop@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Ryan Voots

This library is free software; It is licensed exclusively under the Artistic License version 2.0 only.