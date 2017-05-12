package Language::Farnsworth::Functions::Standard;

use strict;
use warnings;

use Language::Farnsworth::Value::Types;
use Language::Farnsworth::Error;
use utf8;

use Data::Dumper;

use Math::Pari;

sub init
{
   my $env = shift;
    
   $env->eval("push{arr byref isa [], x isa ...} := {arr =arr+x};");
   $env->eval("unshift{arr byref isa [], x isa ...} := {arr =x+arr};");

   #$env->{funcs}->addfunc("push", [["arr", undef, $array, 0], ["in", undef, "VarArg", 0]],\&push); #actually i might rewrite this in farnsworth now that it can do it
   $env->{funcs}->addfunc("pop", [["arr", undef, TYPE_ARRAY, 0]],\&pop, $env); #eventually this maybe too
   $env->{funcs}->addfunc("shift", [["arr", undef, TYPE_ARRAY, 1]], \&shift, $env);
   #$env->{funcs}->addfunc("unshift", [["arr", undef, $array, 0], ["in", undef, "VarArg", 0]], \&unshift);
   $env->{funcs}->addfunc("sort", [["arr", undef, "VarArg", 0]],\&sort, $env);

   $env->{funcs}->addfunc("length", [["in", undef, undef, 0]],\&length, $env);

   $env->{funcs}->addfunc("ord", [["in", undef, TYPE_STRING, 0]],\&ord, $env);
   $env->{funcs}->addfunc("chr", [["in", undef, TYPE_PLAIN, 0]],\&chr, $env);
   $env->{funcs}->addfunc("index", [["str", undef, TYPE_STRING, 0],["substr", undef, TYPE_STRING, 0],["pos", TYPE_PLAIN, TYPE_PLAIN, 0]],\&index, $env);
   $env->{funcs}->addfunc("eval", [["str", undef, TYPE_STRING, 0]],\&eval, $env); #needs special case!
   
   $env->eval('map{sub isa {`x`}, x isa ...} := {var xx=[]+x; if (length[xx] == 1 && xx@0$ conforms []) {xx = x@0$}; if (length[xx] == 1 && !(xx conforms [])) {xx = [xx]}; var z=[]+xx; var e; var out=[]; while(length[z]) {e = shift[z]; push[out, (sub)[e]]}; out}');

   $env->{funcs}->addfunc("substrLen", [["str", undef, TYPE_STRING, 0],["left", undef, TYPE_PLAIN, 0],["length", undef, TYPE_PLAIN, 0]],\&substrlen, $env); #this one works like perls
   $env->eval("substr{str,left,right}:={substrLen[str,left,right-left]}");
   $env->eval("left{str,pos}:={substrLen[str,0,pos]}");
   $env->eval("right{str,pos}:={substrLen[str,length[str]-pos,pos]}");

   $env->{funcs}->addfunc("reverse", [["in", undef, undef, 0]],\&reverse, $env);

   $env->eval("now{x = \"UTC\" isa \"\"} := {setzone[#now#, x]}");
   $env->{funcs}->addfunc("setzone", [["date", undef, TYPE_DATE, 0],["zone", undef, TYPE_STRING, 0]], \&setzone, $env);

   #$env->{funcs}->addfunc("unit", [["in", undef, undef, 0]], \&unit);
   $env->{funcs}->addfunc("units", [["in", undef, undef, 0]], \&units, $env);
   $env->{funcs}->addfunc("error", [["in", undef, TYPE_STRING, 0]], \&doerror, $env);
   $env->{funcs}->addfunc("return", [["in", undef, undef, 0]], \&doreturn, $env);
   $env->{funcs}->addfunc("match", [["regex", undef, TYPE_STRING, 0], ["input", undef, TYPE_STRING, 0], ["options",TYPE_STRING,TYPE_STRING, 0]], \&match, $env);

   $env->eval('max{x isa ...} := {var z; if (length[x] == 1 && x@0$ conforms []) {z = x@0$} else {z=x}; var n = length[z]; var m=z@0$; var q; while((n=n-1)>=0){q=z@n$; q>m?m=q:0}; m}'); 
   $env->eval('min{x isa ...} := {var z; if (length[x] == 1 && x@0$ conforms []) {z = x@0$} else {z=x}; var n = length[z]; var m=z@0$; var q; while((n=n-1)>=0){q=z@n$; q<m?m=q:0}; m}'); 
}

sub doerror
{
	#with an array we give the number of elements, with a string we give the length of the string
	my ($args, $eval)= @_;

	my $input = $eval->{vars}->getvar("in"); #i should clean this up more too

	error $input->getstring();
}

sub doreturn
{
	#with an array we give the number of elements, with a string we give the length of the string
	my ($args, $eval)= @_;

	my $input = $eval->{vars}->getvar("in"); #i should clean this up more too

	farnsreturn $input;
}

sub match
{
	my ($args, $eval)= @_;

	my $input = $eval->{vars}->getvar("input"); 
	my $regex = $eval->{vars}->getvar("regex");
	my $options = $eval->{vars}->getvar("options"); 

	error $@ if $@;
}

sub units
{
	#with an array we give the number of elements, with a string we give the length of the string
	my ($args, $eval)= @_;

	my $input = $eval->{vars}->getvar("in"); #i should clean this up more too

	error "Need number with units for units[]" unless $input->istype("Pari");

	my $units = $input->getdimen();

	return  Language::Farnsworth::Value::Pari->new(1.0, $units);
}

sub setzone
{
        #with an array we give the number of elements, with a string we give the length of the string
        my ($args, $eval)= @_;
           
        my $date = $eval->{vars}->getvar("date"); #i should clean this up more too
        my $zone = $eval->{vars}->getvar("zone"); #i should clean this up more too

	$date->getdate()->set_time_zone($zone->getstring());        
        
        return $date;
}

#sub unit
#{
	#this code needs to be removed, and turned into an operator, its working in the wrong level all together.
	#args is... a Language::Farnsworth::Value array
#	my ($args, $eval, $branches)= @_;
	
	#print Dumper($branches);

#	if ((ref($branches->[1][0]) ne "Fetch") || (!$eval->{units}->isunit($branches->[1][0][0])))
#	{
#		error "First argument to unit[] must be a unit name";
#	}

#	my $unitvar = $eval->{units}->getunit($branches->[1][0][0]);
#
#	return $unitvar; #if its undef, its undef! i should really make some kind of error checking here
#}

sub sort
{
	#args is... a Language::Farnsworth::Value array
	my ($args, $eval)= @_;
    my $arr = $eval->{vars}->getvar("arr");
    
   	my $argcount = $arr->getarray();

	my $sortlambda;

	if (ref($arr->getarrayref()->[0]) eq "Language::Farnsworth::Value::Lambda")
	{
		$sortlambda = shift(@{$arr->getarrayref});
	}
	else
	{
		#i should really do this outside the sub ONCE, but i'm lazy for now
		$sortlambda = $eval->eval("{`a,b` a <=> b}");
	}

	my $sortsub = sub
	{
		my $val = $eval->evalbranch(bless [(bless [$a, $b], 'Array'), $sortlambda], 'LambdaCall');
		
		0+$val->toperl(); #return this, just to make sure the value is right
	};

	my @sorts;

	if ($arr->getarray() > 1)
	{
		#we've been given a bunch of things, assume we need to sort them like that
		push @sorts, $arr->getarray();
	}
	elsif (($arr->getarray() == 1) && (ref($arr->getarrayref()->[0]) eq "Language::Farnsworth::Value::Array"))
	{
		#given an array as a second value, dereference it since its the only thing we've got
		push @sorts, $arr->getarrayref()->[0]->getarray();
	}
	else
	{
		#ok you want me to sort ONE thing? i'll sort that one thing, in O(1) time!
		return $arr->getarrayref()->[0];
	}

	my @rets = CORE::sort $sortsub @sorts;

	#print "SORT RETURNING!\n";
	#print Dumper(\@rets);

	return new Language::Farnsworth::Value::Array([@rets]);
}

sub push
{
	#args is... a Language::Farnsworth::Value array
	my ($args, $eval)= @_;
	
	my $array = $eval->{vars}->getvar("arr");

	unless ($array->istype("Array"))
	{
		error "First argument to push must be an array";
	}

	#ok type checking is done, do the push!
	
	my @input = $args->getarray();
	shift @input; #remove the original array value

	#i should probably flatten arrays here so that; a=[1,2,3]; push[a,a]; will result in a = [1,2,3,1,2,3]; instead of a = [1,2,3,[1,2,3]];
    #no i shouldn't, i'll be adding the ability to make them flatten in the parser

	CORE::push @{$array->getarrayref()}, @input;

	return new Language::Farnsworth::Value::Pari(0+@input); #returns number of items pushed
}

sub unshift
{
	#args is... a Language::Farnsworth::Value array
	my ($args, $eval)= @_;
	
	my $array = $eval->{vars}->getvar("arr");

	unless ($array->istype("Array"))
	{
		error "First argument to push must be an array";
	}

	#ok type checking is done, do the push!
	
	my @input = $args->getarray();
	shift @input; #remove the original array value

	#i should probably flatten arrays here so that; a=[1,2,3]; push[a,a]; will result in a = [1,2,3,1,2,3]; instead of a = [1,2,3,[1,2,3]];
    #no i shouldn't, i'll be adding the ability to make them flatten in the parser

	CORE::unshift @{$array->getarrayref()}, @input;

	return new Language::Farnsworth::Value::Pari(0+@input); #returns number of items pushed
}

sub pop
{
	#args is... a Language::Farnsworth::Value array
	my ($args, $eval)= @_;
	
	my $array = $eval->{vars}->getvar("arr");
	
	unless ($array->istype("Array"))
	{
		error "Argument to pop must be an array";
	}

	#ok type checking is done, do the pop
	
	my $retval = CORE::pop @{$array->getarrayref()};

	return $retval; #pop returns the value of the element removed
}

sub shift
{
	#args is... a Language::Farnsworth::Value array
	my ($args, $eval)= @_;
	
	my $var = $eval->{vars}->getvar("arr");
	my $varref = $var->getref();

	error "Need lvalue for input to shift[]" unless defined $varref;

	#if ((ref($branches->[1][0]) ne "Fetch") || (!$eval->{vars}->isvar($branches->[1][0][0])))
	#{
	#	die "Argument to shift must be a variable";
	#}

	#my $arrayvar = $eval->{vars}->getvar($branches->[1][0][0]);

	unless (ref($var) eq "Language::Farnsworth::Value::Array")
	{
		error "Argument to shift must be an array";
	}

	#ok type checking is done, do the pop
	
	my $retval = CORE::shift @{${$varref}->getarrayref()};

	return $retval; #pop returns the value of the element removed
}

sub length
{
	#with an array we give the number of elements, with a string we give the length of the string
	my ($args, $eval)= @_;
	my @argsarry = $args->getarray();

	my @rets;

	for my $arg (@argsarry)
	{
		if (ref($arg) eq "Language::Farnsworth::Value::Array")
		{
			CORE::push @rets, Language::Farnsworth::Value::Pari->new(scalar $arg->getarray());
		}
		elsif (ref($arg) eq "Language::Farnsworth::Value::String")
		{
			CORE::push @rets, Language::Farnsworth::Value::Pari->new(length $arg->getstring());
		}
		else
		{
			#until i decide how this should work on regular numbers, just do this
			CORE::push @rets, Language::Farnsworth::Value::Pari->new(0);
		}
	}

	if (@rets > 1)
	{
		return Language::Farnsworth::Value::Array->new(\@rets);
	}
	else
	{
		return $rets[0];
	}
}

sub reverse
{
	#with an array we give the number of elements, with a string we give the length of the string
	my ($args, $eval)= @_;
	my @argsarry = $args->getarray();

	my @rets;

	for my $arg (reverse @argsarry) #this will make reverse[1,2,3,4] return [4,3,2,1]
	{
		if (ref($arg) eq "Language::Farnsworth::Value::Array")
		{
			CORE::push @rets, Language::Farnsworth::Value::Array->new([reverse $arg->getarray()]);
		}
		elsif (ref($arg) eq "Language::Farnsworth::Value::String")
		{
			CORE::push @rets, Language::Farnsworth::Value::String->new("".reverse($arg->getstring()));
		}
		else
		{
			CORE::push @rets, $arg; #should i make it print the reverse of all its arguments? yes, lets fix that
		}
	}

	if (@rets > 1)
	{
		return Language::Farnsworth::Value::Array->new(\@rets);
	}
	else
	{
		return $rets[0];
	}
}

sub substrlen
{
	#with an array we give the number of elements, with a string we give the length of the string
	my ($args, $eval)= @_;
	my @arg = $args->getarray();

	if (ref $arg[0] eq "Language::Farnsworth::Value::String")
	{
		#do i need to do something to convert these to work? (the 1,2 anyway?)
		my $ns = substr($arg[0]->getstring(), $arg[1]->toperl(), $arg[2]->toperl());
		#print "SUBSTR :: $ns\n";
		return Language::Farnsworth::Value::String->new($ns);
	}
	else
	{
		error "substr and friends only works on strings";
	}
}

sub ord
{
	#with an array we give the number of elements, with a string we give the length of the string
	my ($args, $eval)= @_;

        my $input = $eval->{vars}->getvar("in"); #i should clean this up more too

	my $ns = ord($input->getstring()); 
	return Language::Farnsworth::Value::Pari->new($ns);
}

sub chr
{
	#with an array we give the number of elements, with a string we give the length of the string
	my ($args, $eval)= @_;

        my $input = $eval->{vars}->getvar("in"); #i should clean this up more too

	my $ns = chr($input->toperl()); 
	return Language::Farnsworth::Value::String->new($ns);
}

sub index
{
	#with an array we give the number of elements, with a string we give the length of the string
	my ($args, $eval)= @_;

	my $string = $eval->{vars}->getvar("str")->getstring();
	my $substr = $eval->{vars}->getvar("substr")->getstring();
	my $pos = $eval->{vars}->getvar("pos")->toperl();

	my $ns = index $string, $substr, $pos; #substr($arg[0]{pari}, "".$arg[1]{pari}, "".$arg[2]{pari});
	return Language::Farnsworth::Value::Pari->new($ns); #give string flag of 1, since we don't know what language is intended
}

sub eval
{
	#with an array we give the number of elements, with a string we give the length of the string
	my ($args, $eval, $reval)= @_;
	my $evalstr = $eval->{vars}->getvar("str")->getstring();

#	my $nvars = new Language::Farnsworth::Variables($eval->{vars});
#	my %nopts = (vars => $nvars, funcs => $eval->{funcs}, units => $eval->{units}, parser => $eval->{parser});
#	my $neval = $eval->new(%nopts);

	return $reval->eval($evalstr);
}

1;
