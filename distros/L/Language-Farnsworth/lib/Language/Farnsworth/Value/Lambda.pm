package Language::Farnsworth::Value::Lambda;

use strict;
use warnings;

use Language::Farnsworth::Dimension;
use Language::Farnsworth::Error;
use base 'Language::Farnsworth::Value';
use Language::Farnsworth::Value::Array;

use Data::Dumper;

use utf8;

our $VERSION = 0.6;

use overload 
    '+' => \&add,
    '-' => \&subtract,
    '*' => \&mult,
    '/' => \&div,
	'%' => \&mod,
	'**' => \&pow,
	'<=>' => \&compare,
	'bool' => \&bool;

use base qw(Language::Farnsworth::Value);

#this is the REQUIRED fields for Language::Farnsworth::Value subclasses
#
#dimen => a Language::Farnsworth::Dimension object
#
#this is so i can make a -> conforms in Language::Farnsworth::Value, to replace the existing code, i'm also planning on adding some definitions such as, TYPE_PARI, TYPE_STRING, TYPE_LAMBDA, TYPE_DATE, etc. to make certain things easier

sub new
{
  my $class = shift;
  my $scope = shift;
  my $args = shift;
  my $code = shift;
  my $branches = shift;
  my $name = shift;
 
  my $outmagic = shift; #i'm still not sure on this one

  debug 5, "Need error checking in lambda creation!";

  my $self = {};

  bless $self, $class;

  $self->{outmagic} = $outmagic;

  $self->{scope} = $scope;
  $self->{code} = $code;
  $self->{args} = $args;
  $self->{branches} = $branches;
  $self->{name} = $name;
  
  return $self;
}

sub getcode
{
	return $_[0]->{code};
}

sub getargs
{
	return $_[0]->{args};
}

sub getscope
{
	return $_[0]->{scope};
}

sub getbranches
{
	return $_[0]->{branches};
}

sub getname
{
	return defined($_[0]->{name}) ? $_[0]->{name} : "lambda"; 
}

sub setname
{
	return ($_[0]->{name} = $_[1]);
}

sub type
{
	return "Lambda";
}

#######
#The rest of this code can be GREATLY cleaned up by assuming that $one is of type, Language::Farnsworth::Value::Pari, this means that i can slowly redo a lot of this code

sub add
{
  my ($one, $two, $rev) = @_;

  error "Non reference given to addition of lambdas" unless ref($two);

  #if we're not being added to a Language::Farnsworth::Value::Pari, the higher class object needs to handle it.
  error "Scalar value given to addition to Lambda" if ($two->isa("Language::Farnsworth::Value::Pari"));
  return $two->add($one, !$rev) unless ($two->ismediumtype());
  if (!$two->istype("Lambda"))
  {
    error "Given non lambda to lambda operation";
  }

  #NOTE TO SELF this needs to be more helpful, i'll probably do this by creating an "error" class that'll be captured in ->evalbranch's recursion and use that to add information from the parse tree about WHERE the error occured
  error "Adding lambda is not a good idea\n"; 
}

sub subtract
{
  my ($one, $two, $rev) = @_;

  error "Non reference given to subtraction of lambda" unless ref($two);

  #if there's a higher type, use it, subtraction otherwise doesn't make sense on arrays
  error "Scalar value given to subtraction of Lambda" if ($two->isa("Language::Farnsworth::Value::Pari"));
  return $two->subtract($one, !$rev) unless ($two->ismediumtype());
  if (!$two->istype("Lambda"))
  {
    error "Given non lambda to lambda operation";
  }

  error "Subtracting lambdas? what did you think this would do, create a black hole?";
}

sub modulus
{
  my ($one, $two, $rev) = @_;

  error "Non reference given to modulus of lambda" unless ref($two);

  #if there's a higher type, use it, subtraction otherwise doesn't make sense on arrays
  error "Scalar value given to modulus to lambda" if ($two->isa("Language::Farnsworth::Value::Pari"));
  return $two->mod($one, !$rev) unless ($two->ismediumtype());
  if (!$two->istype("Lambda"))
  {
    error "Given non lambda to lambda operation";
  }

  error "Modulusing lambda? what did you think this would do, create a black hole?";
}

sub mult
{
  my ($one, $two, $rev) = @_;

  error "Non reference given to multiplication of lambdas" unless ref($two);
  #if there's a higher type, use it, subtraction otherwise doesn't make sense on arrays
  #confess "Scalar value given to multiplcation to lambda. ED: This will make white holes later" if ($two->isa("Language::Farnsworth::Value::Pari"));
  return $two->mult($one, !$rev) unless ($two->ismediumtype() || $two->istype("Pari") || $two->istype("Lambda"));
  
#  if (!$two->istype("Lambda"))
#  {
#    confess "Given non lambda to lambda operation";
#  }

  my $args = $two->istype("Array") ? $two :  new Language::Farnsworth::Value::Array([$two]);

  #this code is debug code, but i'm afraid to take it out, when i put it here it started working properly
  #print "LAMBDAMULT\n";
  #eval{print Dumper($one->{scope}->{vars}->getvar('x'), $one->{scope}->{vars}->getvar('y'))}; #this bug was fixed

  return $one->{scope}->{funcs}->calllambda($one, $args); #needs to be updated

#  die "Multiplying lambdas? what did you think this would do, create a black hole? ED: this will make black holes later";
}

sub div
{
  my ($one, $two, $rev) = @_;

  #############################################
  #############################################
  ##      WARNING! WARNING! WARNING!         ##
  #############################################
  #############################################
  #
  # This entire section is experimental, and not checked for errors in testing, and is liable to cause the sun to explode
  
  print "INSIDE LAMBDA DIVISION\n";

  error "Non reference given to division of lambdas" unless ref($two);

  #if there's a higher type, use it
  
  return $two->div($one, !$rev) unless ($two->ismediumtype()|| $two->istype("Pari") || $two->istype("Lambda"));

  if ($two->isa("Language::Farnsworth::Value::Pari"))
  {
	  #ok i've got a simple thing here i think!
	  #its not simple, will not be simple and will not end up working right, this is a hack to make 10 kg per cubic meter, and the like to work, until i add objects
	  my $onevalue = Language::Farnsworth::Value::Pari->new(1); #don't use 1.0 it'll coerce things into floats unneccesarily
	  my $newv = $onevalue * $one; #this'll remultiply things!
	  my $ret = $two / $newv; #this COULD be dangerous since i can see how to make an inf loop in a division this way
	  return $ret;
  }

  if (!$two->istype("Lambda"))
  {
    error "Given non lambda to lambda operation";
  }

  error "Dividing lambdas? what did you think this would do, create a black hole?";
}

sub bool
{
#	my $self = shift;

	#seems good enough of an idea to me
	#i have a bug HERE
#	print "BOOLCONV\n";
#	print Dumper($self);
#	print "ENDBOOLCONV\n";
	return 1; #for now lambdas are ALWAYS true!
	
#	print Dumper [caller()];
#	die "FUCK\n";
}

sub pow
{
  my ($one, $two, $rev) = @_;

  error "Non reference given to exponentiation of lambda" unless ref($two);

  #if there's a higher type, use it, subtraction otherwise doesn't make sense on arrays
  error "Scalar given to exponentiation of lambda" if ($two->isa("Language::Farnsworth::Value::Pari"));
  return $two->pow($one, !$rev) unless ($two->ismediumtype());
  if (!$two->istype("Lambda"))
  {
    error "Given non boolean to lambdas operation";
  }

  error "Exponentiating lambdas? what did you think this would do, create a black hole?";
}

sub compare
{
  my ($one, $two, $rev) = @_;

  error "Non reference given to compare of lambda" unless ref($two);

  #if we're not being added to a Language::Farnsworth::Value::Pari, the higher class object needs to handle it.
  error "Scalar value given to division to lambdas" if ($two->istype("Pari"));
  return $two->compare($one, !$rev) unless ($two->istype("Lambda"));

  return 0; #i don't have any metric for comparing lambdas, so... they'll always be equal
}

sub eval
{
	my ($self, $two, $eval) = @_;

    my $args = $two->istype("Array") ? $two :  new Language::Farnsworth::Value::Array([$two]); 

  #this code is debug code, but i'm afraid to take it out, when i put it here it started working properly
  #print "LAMBDAMULT\n";
  #eval{print Dumper($one->{scope}->{vars}->getvar('x'), $one->{scope}->{vars}->getvar('y'))}; #this bug was fixed

    return $eval->{funcs}->calllambda($self, $args, $eval); #needs to be updated	
}

sub tostring
{
	my $self = shift;
	return $self->deparsetree($self->getbranches())
}

sub deparsetree
{
	my $self = shift;
	my $branch = shift;

	my $type = ref($branch);
	my $return;
	
	if ($type eq "CODE")
	{
		#got perl code here!
		return "/* PERL CODE */";
	}
	elsif ($type eq "PreDec")
	{
		my $a = $self->deparsetree($branch->[0]);
		return "--$a"
	}
	elsif ($type eq "PreInc")
	{
		my $a = $self->deparsetree($branch->[0]);
		return "++$a"
	}
	elsif ($type eq "PostDec")
	{
		my $a = $self->deparsetree($branch->[0]);
		return "$a--"
	}
	elsif ($type eq "PostInc")
	{
		my $a = $self->deparsetree($branch->[0]);
		return "$a++"
	}
	elsif ($type eq "Add")
	{
		my $a = $self->deparsetree($branch->[0]);
		my $b = $self->deparsetree($branch->[1]);
		return $a . " + " . $b;
	}
	elsif ($type eq "Sub")
	{
		my $a = $self->deparsetree($branch->[0]);
		my $b = $self->deparsetree($branch->[1]);
		return $a . " - " . $b;
	}
	elsif ($type eq "Mul")
	{
		my $a = $self->deparsetree($branch->[0]);
		my $b = $self->deparsetree($branch->[1]);
		my $t = $branch->[2];

		return $a . ($t eq 'imp' ? '' : ' * ') . $b; #NOTE: this should listen to the 'imp' or '*' in the tree!
	}
	elsif ($type eq "Div")
	{
		my $a = $self->deparsetree($branch->[0]);
		my $b = $self->deparsetree($branch->[1]);
		my $t = $branch->[2];

		$return = $a . " $t " . $b;
	}
	elsif ($type eq "Conforms")
	{
		my $a = $self->deparsetree($branch->[0]);
		my $b = $self->deparsetree($branch->[1]);
		return "$a conforms $b";
	}
	elsif ($type eq "Mod")
	{
		my $a = $self->deparsetree($branch->[0]);
		my $b = $self->deparsetree($branch->[1]);
		return "$a % $b";
	}
	elsif ($type eq "Pow")
	{
		my $a = $self->deparsetree($branch->[0]);
		my $b = $self->deparsetree($branch->[1]);
		return "$a ^ $b";
	}
	elsif ($type eq "And")
	{
		my $a = $self->deparsetree($branch->[0]);
		my $b = $self->deparsetree($branch->[1]);

		return "$a && $b";
	}
	elsif ($type eq "Or")
	{
		my $a = $self->deparsetree($branch->[0]);
		my $b = $self->deparsetree($branch->[1]);
		
		return "$a || $b";
	}
	elsif ($type eq "Xor")
	{
		my $a = $self->deparsetree($branch->[0]);
		my $b = $self->deparsetree($branch->[1]);
		return "$a ^^ $b";
	}
	elsif ($type eq "Not")
	{
		my $a = $self->deparsetree($branch->[0]);
		return "!$a";
	}
	elsif ($type eq "Gt")
	{
		my $a = $self->deparsetree($branch->[0]);
		my $b = $self->deparsetree($branch->[1]);
		return "$a > $b";
	}
	elsif ($type eq "Lt")
	{
		my $a = $self->deparsetree($branch->[0]);
		my $b = $self->deparsetree($branch->[1]);
		return "$a < $b";
	}
	elsif ($type eq "Ge")
	{
		my $a = $self->deparsetree($branch->[0]);
		my $b = $self->deparsetree($branch->[1]);
		return "$a >= $b";
	}
	elsif ($type eq "Le")
	{
		my $a = $self->deparsetree($branch->[0]);
		my $b = $self->deparsetree($branch->[1]);
		return "$a <= $b";
	}
	elsif ($type eq "Compare")
	{
		my $a = $self->deparsetree($branch->[0]);
		my $b = $self->deparsetree($branch->[1]);
		return "$a <=> $b";
	}
	elsif ($type eq "Eq")
	{
		my $a = $self->deparsetree($branch->[0]);
		my $b = $self->deparsetree($branch->[1]);
		return "$a == $b";
	}
	elsif ($type eq "Ne")
	{
		my $a = $self->deparsetree($branch->[0]);
		my $b = $self->deparsetree($branch->[1]);
		return "$a != $b";
	}
	elsif ($type eq "Ternary")
	{
		my $left = $self->deparsetree($branch->[0]);
		my $one = $self->deparsetree($branch->[1]);
		my $two = $self->deparsetree($branch->[2]);

		return "$left ? $one : $two";
	}
	elsif ($type eq "If")
	{
		my $return = "";
		my $left = $self->deparsetree($branch->[0]);
        my $std = $self->deparsetree($branch->[1]);
		
		$return = "if ($left) { $std }";

		if ($branch->[2])
		{
			my $else = $self->deparsetree($branch->[2]);
			$return .= " else { $else }";
		}
		
		#$return .= ";"; #NOTE: DO I NEED THIS? probably not!

		return $return;
	}
	elsif ($type eq "Store")
	{
		my $name = $self->deparsetree($branch->[0]);
		my $value = $self->deparsetree($branch->[1]);

		return "$name = $value";
	}
	elsif ($type eq "StoreAdd")
	{
		my $name = $self->deparsetree($branch->[0]);
		my $value = $self->deparsetree($branch->[1]);

		return "$name += $value";
	}
	elsif ($type eq "StoreSub")
	{
		my $name = $self->deparsetree($branch->[0]);
		my $value = $self->deparsetree($branch->[1]);

		return "$name -= $value";
	}
	elsif ($type eq "StoreMul")
	{
		my $name = $self->deparsetree($branch->[0]);
		my $value = $self->deparsetree($branch->[1]);

		return "$name *= $value";
	}
	elsif ($type eq "StoreDiv")
	{
		my $name = $self->deparsetree($branch->[0]);
		my $value = $self->deparsetree($branch->[1]);

		return "$name /= $value";
	}
	elsif ($type eq "StoreMod")
	{
		my $name = $self->deparsetree($branch->[0]);
		my $value = $self->deparsetree($branch->[1]);

		return "$name %= $value";
	}
	elsif ($type eq "StorePow")
	{
		my $name = $self->deparsetree($branch->[0]);
		my $value = $self->deparsetree($branch->[1]);

		return "$name ^= $value";
	}
	elsif ($type eq "DeclareVar")
	{
		my $name = $branch->[0];

		my $return = "var $name";

		if (defined($branch->[1]))
		{
			my $val =  $self->deparsetree($branch->[1]);
			$return .= " = $val";
		}

		return $return;
	}
	elsif ($type eq "FuncDef")
	{
		#print Dumper($branch);
		my $name = $branch->[0];
		my $args = $branch->[1];
		my $value = $self->deparsetree($branch->[2]); #not really a value, but in fact the tree to run for the function

		my $return = "${name}{";

		my @vargs;
		my $vargs = "";

		for my $arg (@$args)
		{
			my $foobs="";
			my $constraint = $arg->[2];
			my $default = $arg->[1];
			my $name = $arg->[0]; #name

			$foobs = $name;
			if (defined($default))
			{
				$foobs .= " = ".$self->deparsetree($default); #should be right
			}

			if (defined($constraint))
			{
				#print Dumper($constraint);
				$foobs .= " isa ".$self->deparsetree($constraint); #should be right
				#print Dumper($constraint);
			}

			push @vargs, $foobs;
		}

		$vargs = join " , ", @vargs;

		$return .= "$vargs} := { $value }";
	}
	elsif ($type eq "FuncCall")
	{
		my $name = $branch->[0];
		my $args = $self->deparsetree($branch->[1]); #this is an array, need to evaluate it

		return "$name\[$args\]";
	}
#	| 'defun' NAME '=' expr { bless [ @_[2,4] ], 'DeclareFunc' }
    elsif ($type eq "DeclareFunc")
    {
    	my $name = $branch->[0];
    	my $value = $self->deparsetree($branch->[1]);
    	
    	return "defun $name = $value"; 
    }
    elsif ($type eq "GetFunc")
    {
    	my $name = $branch->[0];
    	return "&$name";
    }
	elsif ($type eq "Lambda")
	{
		my $args = $branch->[0];
		my $code = $self->deparsetree($branch->[1]);

        my @vargs;
		my $vargs = "";

		for my $arg (@$args)
		{
			my $foobs="";
			my $reference = $arg->[3];
			my $constraint = $arg->[2];
			my $default = $arg->[1];
			my $name = $arg->[0]; #name

			$foobs = $name;
			if ($reference)
			{
				$foobs .= " byref "; #should be right
			}

			if (defined($default))
			{
				$foobs .= " = ".$self->deparsetree($default); #should be right
			}

			if (defined($constraint))
			{
				#print Dumper($constraint);
				$foobs .= " isa ".$self->deparsetree($constraint); #should be right
				#print Dumper($constraint);
			}

			push @vargs, $foobs;
		}
		$vargs = join " , ", @vargs;

		return "{`$vargs` $code}";
	}
	elsif ($type eq "LambdaCall")
	{		
		my $left = $self->deparsetree($branch->[0]);
		my $right = $self->deparsetree($branch->[1]);

		return "$left => $right";
	}
	elsif (($type eq "Array") || ($type eq "SubArray"))
	{
		my $array = []; #fixes bug with empty arrays
		for my $bs (@$branch) #iterate over all the elements
		{
			my $type = ref($bs); #find out what kind of thing we are
			my $value = $self->deparsetree($bs);

			#since we have an array, but its not in a SUBarray, we dereference it before the push
			push @$array, $value;
			#push @$array, '['.$value.']' if ($type eq "SubArray");
		}
		return '[ '.(join ', ',@$array).' ]';
		
	}
	elsif ($type eq "ArgArray")
	{
		my $array = [];
		for my $bs (@$branch) #iterate over all the elements
		{
			my $value = $self->deparsetree($bs);

			push @$array, $value; #we return an array ref! i need more error checking around for this later
		}
		return join ', ', @$array;
	}
	elsif ($type eq "ArrayFetch")
	{
		my $var = $self->deparsetree($branch->[0]); #need to check if this is an array, and die if not
		my $listval = $self->deparsetree($branch->[1]);
		
		$listval = substr $listval, 1,length($listval)-2; #strip the []

		return "$var\@$listval\$";
	}
	elsif ($type eq "ArrayStore")
	{
		my $var = $self->deparsetree(bless [$branch->[0]], 'Fetch'); #need to check if this is an array, and die if not
		my $listval = $self->deparsetree($branch->[1]);
		my $rval = $self->deparsetree($branch->[2]);

		$listval = substr $listval, 1,length($listval)-2; #strip the []

		return "$var\@$listval\$ = $rval";
	}
	elsif ($type eq "While")
	{
		my $cond = $self->deparsetree($branch->[0]); #what to check each time
		my $stmts = $self->deparsetree($branch->[1]); #what to run each time

		return "while ($cond) { $stmts }"
	}
	elsif ($type eq "Stmt")
	{
		my $return = "";
		for my $bs (@$branch) #iterate over all the statements
		{   my $r = $self->deparsetree($bs);
			$return .= "$r; " if defined $r; #this has interesting semantics!
		}
		return $return;
	}
	elsif ($type eq "Paren")
	{
		return '(' . $self->deparsetree($branch->[0]) . ')';
	}
	elsif ($type eq "SetDisplay")
	{
		my $combo = $branch->[0][0]; #is a string?
		my $right = $self->deparsetree($branch->[1]);

		return "$combo :-> $right";
	}
	elsif ($type eq "UnitDef")
	{
		my $unitsize = $self->deparsetree($branch->[1]);
		my $name = $branch->[0];
		
		return "$name := $unitsize";
	}
	elsif ($type eq "DefineDimen")
	{
		my $unit = $branch->[1];
		my $dimen = $branch->[0];
		
		return "$dimen =!= $unit";
	}
	elsif ($type eq "DefineCombo")
	{
		my $combo = $branch->[1]; #should get me a string!
		my $value = $self->deparsetree($branch->[0]);
		
		return "$value ||| $combo";
	}
	elsif (($type eq "SetPrefix") || ($type eq "SetPrefixAbrv"))
	{
		my $name = $branch->[0];
		my $value = $self->deparsetree($branch->[1]);

		return "$name ::- $value";
	}
	elsif ($type eq "Trans")
	{
		my $left = $self->deparsetree($branch->[0]);
		my $right = $self->deparsetree($branch->[1]);

		return "$left -> $right";
	}
	elsif (($type eq "Num") || ($type eq "Fetch") || ($type eq "HexNum"))
	{
		return $branch->[0]; #its already a string!
	}
	elsif ($type eq "String")
	{
		return '"'.$branch->[0].'"';
	}
	elsif ($type eq "Date")
	{
		return "#".$branch->[0]."#";
	}
	elsif ($type eq "VarArg")
	{
		return "...";
	}
	elsif (!defined($branch))
	{
		return ""; #got an undefined value, just make it blank
	}
	elsif ($type =~ /^Language::Farnsworth::Value/) # use the output class for all real values
	{
		my $output = Language::Farnsworth::Output->new($self->getscope()->{units}, $branch, $self->getscope());
		return $output."";
	}
	elsif ($branch eq "VarArg")
	{
		return "...";
	}
	else
	{
#		cluck "Unhandled input!";
		return '/*'.Dumper($branch).'*/';
	}
}

1;