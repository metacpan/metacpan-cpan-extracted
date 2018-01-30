package Inline::Java::Class ;

use strict ;
use Carp ;

$Inline::Java::Class::VERSION = '0.53_90' ;

$Inline::Java::Class::MAX_SCORE = 10 ;

# There is no use supporting exponent notation for integer types since
# Jave does not support it without casting.
my $INT_RE = '^[+-]?\d+$' ;
my $FLOAT_RE = '^([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$' ;

my $RANGE = {
	'java.lang.Byte' => {
		REGEXP => $INT_RE,
		MAX => 127,
		MIN => -128,
	},
	'java.lang.Short' => {
		REGEXP => $INT_RE,
		MAX => 32767,
		MIN => -32768,
	},
	'java.lang.Integer' => {
		REGEXP => $INT_RE,
		MAX => 2147483647,
		MIN => -2147483648,
	},
	'java.lang.Float' => {
		REGEXP => $FLOAT_RE,
		MAX => 3.4028235e38,
		MIN => -3.4028235e38,
		# POS_MIN	=> 1.4e-45,
		# NEG_MAX => -1.4e-45,
	},
	'java.lang.Long' => {
		REGEXP => $INT_RE,
		# MAX => 9223372036854775807,
		# MIN => -9223372036854775808,
	},
	'java.lang.Double' => {
		REGEXP => $FLOAT_RE,
		# MAX => 1.79e308,
		# MIN => -1.79e308,
		# POS_MIN => 4.9e-324,
		# NEG_MAX => -4.9e-324,
	},
} ;
$RANGE->{byte} = $RANGE->{'java.lang.Byte'} ;
$RANGE->{short} = $RANGE->{'java.lang.Short'} ;
$RANGE->{'int'} = $RANGE->{'java.lang.Integer'} ;
$RANGE->{long} = $RANGE->{'java.lang.Long'} ;
$RANGE->{float} = $RANGE->{'java.lang.Float'} ;
$RANGE->{double} = $RANGE->{'java.lang.Double'} ;

# java.lang.Number support. We allow the widest range
# i.e. Double
$RANGE->{'java.lang.Number'} = $RANGE->{'java.lang.Double'} ;


my %numeric_classes = map {($_ => 1)} qw(
	java.lang.Byte
	java.lang.Short
	java.lang.Integer
	java.lang.Long
	java.lang.Float
	java.lang.Double
	java.lang.Number
	byte
	short
	int
	long
	float
	double
) ;


my %double_classes = map {($_ => 1)} qw(
	java.lang.Double
	double
) ;

my %string_classes = map {($_ => 1)} qw(
	java.lang.String
	java.lang.StringBuffer
	java.lang.CharSequence
) ;

my %char_classes = map {($_ => 1)} qw(
	java.lang.Character
	char
) ;

my %bool_classes = map {($_ => 1)} qw(
	java.lang.Boolean
	boolean
) ;


# This method makes sure that the class we are asking for
# has the correct form for a Java class.
sub ValidateClass {
	my $class = shift ;

 	my $ret = ValidateClassSplit($class) ;
	
	return $ret ;
}


my $class_name_regexp = '([\w$]+)(((\.([\w$]+))+)?)' ;
my $class_regexp1 = qr/^($class_name_regexp)()()()$/o ;
my $class_regexp2 = qr/^(\[+)([BCDFIJSZ])()()$/o ;
my $class_regexp3 = qr/^(\[+)([L])($class_name_regexp)(;)$/o ;
sub ValidateClassSplit {
	my $class = shift ;

	if (($class =~ $class_regexp1)||
		($class =~ $class_regexp2)||
		($class =~ $class_regexp3)){
		return (wantarray ? ($1, $2, $3, $4) : $class) ;
	}

	croak "Invalid Java class name $class" ;
}


sub CastArguments {
	my $args = shift ;
	my $proto = shift ;
	my $inline = shift ;

	Inline::Java::debug_obj($args) ;
	Inline::Java::debug_obj($proto) ;

	my $nb_args = scalar(@{$args}) ;
	if ($nb_args != scalar(@{$proto})){
		croak "Wrong number of arguments" ;
	}

	my $ret = [] ;
	my $score = 0 ;
	for (my $i = 0 ; $i < $nb_args ; $i++){
		my $arg = $args->[$i] ;
		my $pro = $proto->[$i] ;
		my @r = CastArgument($arg, $pro, $inline) ;
		$ret->[$i] = $r[0] ;
		
		$score += $r[1] ;
	}

	return ($ret, $score) ;
}


sub CastArgument {
	my $arg = shift ;
	my $proto = shift ;
	my $inline = shift ;

	ValidateClass($proto) ;

	my $arg_ori = $arg ;
	my $proto_ori = $proto ;

	my $array_score = 0 ;

	my @ret = eval {
		my $array_type = undef ;
		if ((defined($arg))&&(UNIVERSAL::isa($arg, "Inline::Java::Class::Coerce"))){
			my $v = $arg->__get_value() ;
			$proto = $arg->__get_type() ;
			$array_type = $arg->__get_array_type() ;
			$arg = $v ;
		}

		if ((ClassIsReference($proto))&&
			(defined($arg))&&
			(! UNIVERSAL::isa($arg, "Inline::Java::Object"))){
			# Here we allow scalars to be passed in place of java.lang.Object
			# They will wrapped on the Java side.
			if (UNIVERSAL::isa($arg, "ARRAY")){
				if (! UNIVERSAL::isa($arg, "Inline::Java::Array")){
					my $an = Inline::Java::Array::Normalizer->new($inline, $array_type || $proto, $arg) ;
					$array_score = $an->{score} ;
					my $flat = $an->FlattenArray() ; 

					# We need to create the array on the Java side, and then grab 
					# the returned object.
					my $obj = Inline::Java::Object->__new($array_type || $proto, $inline, -1, $flat->[0], $flat->[1]) ;
					$arg = new Inline::Java::Array($obj) ;
				}
				else{
					Inline::Java::debug(4, "argument is already an Inline::Java array") ;
				}
			}
			else{
				if (ref($arg)){
					# We got some other type of ref...
					if ($arg !~ /^(.*?)=/){
						# We do not have a blessed reference, so ...
						croak "Can't convert $arg to object $proto" ;
					}
				}
				else {
					# Here we got a scalar
					# Here we allow scalars to be passed in place of java.lang.Object
					# They will wrapped on the Java side.
					if ($proto ne "java.lang.Object"){
						croak "Can't convert $arg to object $proto" ;
					}
				}
			}
		}
		if ((ClassIsPrimitive($proto))&&(ref($arg))){
			croak "Can't convert $arg to primitive $proto" ;
		}

		if (ClassIsNumeric($proto)){
			if (! defined($arg)){
				# undef gets lowest score since it can be passed
				# as anything
				return (0, 1) ;
			}
			my $re = $RANGE->{$proto}->{REGEXP} ;
			my $min = $RANGE->{$proto}->{MIN} ;
			my $max = $RANGE->{$proto}->{MAX} ;
			Inline::Java::debug(4, 
				"min = " . ($min || '') . ", " . 
				"max = " . ($max || '') . ", " .
				"val = $arg") ;
			if ($arg =~ /$re/){
				if (((! defined($min))||($arg >= $min))&&
					((! defined($max))||($arg <= $max))){
					# number is a pretty precise match, but it's still
					# guessing amongst the numeric types
					my $points = 5.5 ;
					if (($inline->get_java_config('NATIVE_DOUBLES'))&&(ClassIsDouble($proto))){
						# We want to send the actual double bytes to Java
						my $bytes = pack("d", $arg) ;
						$arg = bless(\$bytes, 'Inline::Java::double') ;
						return ($arg, $points) ;
					}
					else {
						return ($arg, $points) ;
					}
				}
				croak "$arg out of range for type $proto" ;
			}
			croak "Can't convert $arg to $proto" ;
		}
		elsif (ClassIsChar($proto)){
			if (! defined($arg)){
				# undef gets lowest score since it can be passed
				# as anything
				return ("\0", 1) ;
			}
			if (length($arg) == 1){
				# char is a pretty precise match
				return ($arg, 5) ;
			}
			croak "Can't convert $arg to $proto" ;
		}
		elsif (ClassIsBool($proto)){
			if (! defined($arg)){
				# undef gets lowest score since it can be passed
				# as anything
				return (0, 1) ;
			}
			elsif (! $arg){
				# bool gets lowest score since anything is a bool
				return (0, 1) ;
			}
			else{
				# bool gets lowest score since anything is a bool
				return (1, 1) ;
			}
		}
		elsif (ClassIsString($proto)){
			if (! defined($arg)){
				# undef gets lowest score since it can be passed
				# as anything
				return (undef, 1) ;
			}
			# string get almost lowest score since anything can match it
			# except objects
			if ($proto eq "java.lang.StringBuffer"){
				# in case we have both protos, we want to give String
				# the advantage
				return ($arg, 1.75) ;
			}
			return ($arg, 2) ;
		}
		else{
			if (! defined($arg)){
				# undef gets lowest score since it can be passed
				# as anything
				return ($arg, 1) ;
			}

			# Here the prototype calls for an object of type $proto
			# We must ask Java if our object extends $proto		
			if (ref($arg)){
				if ((UNIVERSAL::isa($arg, "Inline::Java::Object"))||(UNIVERSAL::isa($arg, "Inline::Java::Array"))){
					my ($msg, $score) = $arg->__isa($proto) ;
					if ($msg){
						croak $msg ;
					}
					Inline::Java::debug(3, "$arg is a $proto") ;
	
					# a matching object, pretty good match, except if proto
					# is java.lang.Object
					if ($proto eq "java.lang.Object"){	
						return ($arg, 1) ;
					}
				
					# Here we deduce points the more our argument is "far"
					# from the prototype.
					if (! UNIVERSAL::isa($arg, "Inline::Java::Array")){
						return ($arg, 7 - ($score * 0.01)) ;
					}
					else{
						# We need to keep the array score somewhere...
						return ($arg, $array_score) ;
					}
				}
				else {
					# We want to send a Perl object to the Java side.
					my $ijp = new Inline::Java::Protocol(undef, $inline) ;
					my $score = $ijp->__ISA('org.perl.inline.java.InlineJavaPerlObject', $proto) ;
					if ($score == -1){
						croak "$proto is not a kind of org.perl.inline.java.InlineJavaPerlObject" ;
					}

					Inline::Java::debug(3, "$arg is a $proto") ;
					
					# a matching object, pretty good match, except if proto
					# is java.lang.Object
					if ($proto eq "java.lang.Object"){	
						return ($arg, 1) ;
					}
					else{
						return ($arg, 7 - ($score * 0.01)) ;
					}
				}
			}

			# Here we are passing a scalar as an object, this is pretty
			# vague as well
			return ($arg, 1) ;
		}
	} ;
	die("$@\n") if $@ ;

	if ((defined($arg_ori))&&(UNIVERSAL::isa($arg_ori, "Inline::Java::Class::Coerce"))){
		# It seems we had casted the variable to a specific type
		if ($arg_ori->__matches($proto_ori)){
			Inline::Java::debug(3, "type coerce match!") ;
			$ret[1] = $Inline::Java::Class::MAX_SCORE ;
		}
		else{
			# We have coerced to something that doesn't exactly match
			# any of the available types. 
			# For now we don't allow this.
			croak "Coerce ($proto) doesn't exactly match prototype ($proto_ori)" ;
		}
	}

	return @ret ;
}


sub IsMaxArgumentsScore {
	my $args = shift ;
	my $score = shift ;

	if ((scalar(@{$args}) * 10) == $score){
		return 1 ;
	}

	return 0 ;
}


sub ClassIsNumeric {
	my $class = shift ;

	return $numeric_classes{$class} ;
}


sub ClassIsDouble {
	my $class = shift ;

	return $double_classes{$class} ;
}


sub ClassIsString {
	my $class = shift ;

	return $string_classes{$class} ;
}


sub ClassIsChar {
	my $class = shift ;

	return $char_classes{$class} ;
}


sub ClassIsBool {
	my $class = shift ;

	return $bool_classes{$class} ;
}


sub ClassIsPrimitive {
	my $class = shift ;

	if ((ClassIsNumeric($class))||(ClassIsString($class))||(ClassIsChar($class))||(ClassIsBool($class))){
		return 1 ;
	}

	return 0 ;
}


sub ClassIsReference {
	my $class = shift ;

	if (ClassIsPrimitive($class)){
		return 0 ;
	}

	return 1 ;
}


sub ClassIsArray {
	my $class = shift ;

	if ((ClassIsReference($class))&&($class =~ /^(\[+)(.*)$/)){
		return 1 ;
	}

	return 0 ;
}



######################## Inline::Java::Class::Coerce ########################
package Inline::Java::Class::Coerce ;


use Carp ;

sub new {
	my $class = shift ;
	my $type = shift ;
	my $value = shift ;
	my $array_type = shift ;

	if (UNIVERSAL::isa($value, "Inline::Java::Class::Coerce")){
		# This allows chaining
		$value = $value->get_value() ;
	}
	
	my $this = {} ;
	$this->{cast} = Inline::Java::Class::ValidateClass($type) ;
	$this->{value} = $value ;
	$this->{array_type} = $array_type ;

	bless($this, $class) ;
	return $this ;
}


sub __get_value {
	my $this = shift ;

	return $this->{value} ;
}


sub __get_type {
	my $this = shift ;

	return $this->{cast} ;
}

sub __get_array_type {
	my $this = shift ;

	return $this->{array_type} ;
}


sub __matches {
	my $this = shift ;
	my $proto = shift ;

	return ($proto eq $this->{cast}) ;
}


1 ;
