package Language::Farnsworth::FunctionDispatch;

use strict;
use warnings;

use Data::Dumper;

use Language::Farnsworth::Variables;
use Language::Farnsworth::Value::Lambda;
use Language::Farnsworth::Value::Array;
use Language::Farnsworth::Error;

sub new
{
	my $self = {};
	bless $self, (shift);
}

sub addfunc
{
#	debug 3, "ADDFUNC", Dumper(\@_);
	my $self = shift;
	my $name = shift;
	my $args = shift;
	my $value = shift;
	my $scope = shift;
	
	error "No scope given for function $name" unless defined($scope);
	
#generate a "false" lambda tree for this, this will go away
#bless [ @_[2,4] ], 'Lambda'
    my $argbranch = bless [], 'Arglist';
    
    for (@$args)
    {
    	push @$argbranch, bless $_, 'Argele';
    }
    
    my $branch = bless [$argbranch, $value], 'Lambda';

	#i should really have some error checking here
	#warn "Depreciated function definition encoutered";
#	debug 3, "--------------------------", "FUNCTION: ".$name;
#	debug 3, Dumper($branch);
#	debug 3, Dumper($value);
#	debug 3, Dumper($args);
	
	my $lambda = new Language::Farnsworth::Value::Lambda($scope, $args, $value, $branch, $name);
	
	$self->{funcs}{$name} = {name=>$name, lambda=>$lambda};
}

sub addfunclamb
{
	my $self = shift;
	my $name = shift;
	my $lambda = shift;
	
	$lambda->setname($name);
	
	$self->{funcs}{$name} = {name => $name, lambda => $lambda};
}

sub getfunc
{
	my $self = shift;
	my $name = shift; #which one to get, we return the hashref
	return $self->{funcs}{$name};
}

sub isfunc
{
	my $self = shift;
	my $name = shift;

	return exists($self->{funcs}{$name});
}

sub setupargs
{
	my $self = shift;
	my $eval = shift;
	my $args = shift;
	my $argtypes = shift;
	my $name = shift; #name to display
	#my $branch = shift;

	my $vars = $eval->{vars}; #get the scope we need

ARG:for my $argc (0..$#$argtypes)
	{
		my $n = $argtypes->[$argc][0]; #the rest are defaults and constraints
		my $v = $args->getarrayref()->[$argc];

		my $const = $argtypes->[$argc][2];

		if (ref($const) eq "VarArg")
		{
		   warn "Working around bug in lambdas!";
		   $const = "VarArg";
		}

		if (!defined($v))# || ($v->{dimen}{dimen}{"undef"})) #uncomment for undef== default value
		{
			#i need a default value!
			if (!defined($argtypes->[$argc][1]) && defined($argtypes->[$argc][0])  && (defined($const) && ref($const) !~ /Language::Farnsworth::Value/ && $const ne "VarArg"))
			{
				error "Required argument $argc to function $name\[\] missing\n";
			}

			$v = $argtypes->[$argc][1];
		}

		if (defined($const) && ref($const) =~ /Language::Farnsworth::Value/)
		{
			#we have a constraint
			if (!$v->conforms($const))
			{
				error "Constraint not met on argument $argc to $name\[\]\n";
			}
		}
		elsif (defined($const) && $const eq "VarArg")
		{
			#we've got a variable argument, it needs to slurp all the rest of the arguments into an array!
			my $last = $#{$args->getarrayref()};
			my @vargs = @{$args->getarrayref()}[$argc..$last];
			my $v = new Language::Farnsworth::Value::Array(\@vargs);
			$vars->declare($n, $v); #set the variable
			last ARG; #don't parse ANY more arguments
		}

		if (defined $n)  #happens when no arguments! so we check if the name is defined
		{
			#print "SETVAR $n: ";
			#print Dumper($argtypes->[$argc]);
			#print Dumper($vars->{vars});
			if (!$argtypes->[$argc][3]) #make sure that it shouldn't be byref
			{ 
				$vars->declare($n, $v);
			}
			else
			{
				#it should be by ref
				if ($v->getref())
				{
				  $vars->setref($n, $v->getref());
			    }
				else
				{
					error "Can't get reference from expression for argument $argc";
				}
			}

			#print Dumper($vars->{vars});
		}
	}
}

sub callfunc
{
	my $self = shift;
	my $eval = shift;
	my $name = shift;
	my $args = shift;
	my $branches = shift;

    error "Given object as function name, check should happen before this" if (ref($name)); 
	error "Function $name is not defined" unless $self->isfunc($name);

	my $lambda = $self->{funcs}{$name}{lambda};

#	warn "-------------ATTEMPTING TO CALL FUNCTION!-------------\n";
#	warn "FUNCTION NAME : $name\n";
#	warn "Dumper of func: ".Dumper($lambda->{code});
#    warn "$eval";
#    warn "".$lambda->getscope();
#	warn "--------------------THAT IS ALL\n";

    if ($name eq "eval")
    {
      return $lambda->eval($args, $eval);
    }
    else
    {
	  return $lambda * $args;
    }
}

sub calllambda
{
	my $self = shift;
	my $lambda = shift;
	my $args = shift;
	my $eval = shift;

    $eval = $lambda->getscope() unless defined($eval);

	my $argtypes = $lambda->getargs();
	my $fval = $lambda->getcode();
    my $name = $lambda->getname();

#	warn "LAMBDA---------------\n";
#	warn Dumper($argtypes, $args, $fval);

	my $nvars = new Language::Farnsworth::Variables($eval->{vars});

	my %nopts = (vars => $nvars, funcs => $self, units => $eval->{units}, parser => $eval->{parser});
	my $neval = $eval->new(%nopts);

    unless($self->checkparams($args, $argtypes))
    {
    	if ($lambda->getname())
    	{
    		error "Number of arguments not correct to ".$lambda->getname();
    	}
    	else
    	{
    		error "Number of arguments not correct to lambda";
    	}
    }
	

	$self->setupargs($neval, $args, $argtypes, $name);

#    warn ref($fval);

	if (ref($fval) ne "CODE")
	{
#		warn "-------------ATTEMPTING TO CALL LAMBDA!-------------\n";
		#print "FUNCTION NAME : $name\n";
#		warn "Dumper of lambda: ".Dumper($fval);
#		warn "--------------------THAT IS ALL\n";

		return $self->callbranch($neval, $fval);
	}
	else
	{
		#we have a code ref, so we need to call it, we use perlwrap{} to capture
		return perlwrap {$fval->($args, $neval, $eval)};
	}
#	return $self->callbranch($neval, $fval);
}

sub callbranch
{
	my $self = shift;
	my $eval = shift;
	my $branches = shift;
#	my $name = shift; #unused


#	print "CALLBRANCHES :: ";
#	print $name if defined $name;
#	print " :: $eval\n";

    my $return = eval {$eval->evalbranch($branches)};
    #warn Dumper($@);
    if (ref($@) && $@->isa("Language::Farnsworth::Error"))
    {
    	#warn Dumper($@->isreturn);
    	if ($@->isreturn)
    	{
    		return $@->getmsg();
    	}
    	else
    	{   #redie the error
    		die $@;
    	}
    }
    elsif ($@)
    {
    	warn "Unhandled perl exception!!!!!!";
    	error EPERL, $@;
    }
    
	return $return;
}

#this was supposed to be the checks for types and such, but now its something else entirely, mostly
sub checkparams 
{
	my $self = shift;
	my $args = shift;
	my $argtypes = shift;

	my $vararg = 0;

	my $neededargs = 0;
	my $badargs = 0;

	for my $argt (@$argtypes)
	{
		$neededargs++ unless (defined($argt->[1]) || !defined($argt->[0]));
		$badargs++ if (!defined($argt->[0]));
	}

	#might want to change the !~ to something else?
	#warn "Strange bug here to investigate, lambdas produce blessed array refs for vararg... wtf";
	$vararg = 1 if (grep {defined($_->[2]) && ref($_->[2]) !~ /Language::Farnsworth::Value/ && (($_->[2] eq "VarArg") || (ref($_->[2]) eq "VarArg"))} @{$argtypes}); #find out if there is a vararg arg

	#print "NEEDED: $neededargs :: $vararg\n";
	#print Data::Dumper->Dump([$argtypes, $args->getarrayref()], [qw(argtypes args)]);

    return 1 if ($vararg || ($args->getarray() <= (@{$argtypes}-$badargs) && $args->getarray() >= $neededargs));

	#return 0 unless (ref($args) eq "Language::Farnsworth::Value") && ($args->{dimen}->compare({dimen=>{array=>1}}));

	return 0;
}

sub getref
{
	my $self = shift;
	my $argc = shift;
	my $branch = shift;
	my $name = shift;

	#print "\n\nGETREF\n";
	#print Dumper($branch);

	if (ref $branch->[1] ne "Array")
	{
		#this should add support for some other stuff
		error "Cannot get a reference if function/lambda is called without []";
	}

	my $argexpr = $branch->[1][$argc];
	
	#print Dumper($argbranches->[$argc]);
	
	if (ref $argexpr ne "Fetch")
	{
		error "Argument $argc to $name\[\] is not referencable";
	}

	my $ref = $self->{funcs}{$name}->{scope}{vars}->getref($argexpr->[0]);

	#warn Dumper($argexpr, $ref);

	return $ref;
}

1;
