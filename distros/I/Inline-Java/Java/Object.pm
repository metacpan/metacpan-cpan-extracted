package Inline::Java::Object ;
@Inline::Java::Object::ISA = qw(Inline::Java::Object::Tie) ;

use strict ;
use Inline::Java::Protocol ;
use Carp ;

$Inline::Java::Object::VERSION = '0.53' ;

# Here we store as keys the knots and as values our blessed private objects
my $PRIVATES = {} ;


# Bogus constructor. We fall here if no public constructor is defined
# in the Java class.
sub new {
	my $class = shift ;
	
	croak "No public constructor defined for class $class" ;
}


# Constructor. Here we create a new object that will be linked
# to a real Java object.
sub __new {
	my $class = shift ;
	my $java_class = shift ;
	my $inline = shift ;
	my $objid = shift ;
	my $proto = shift ;
	my $args = shift ;

	my %this = () ;

	my $knot = tie %this, $class ;
	my $this = bless(\%this, $class) ;

	my $pkg = $inline->get_api('pkg') ;
	if ($class ne "Inline::Java::Object"){
		$class = Inline::Java::java2perl($pkg, $java_class) ;
	}

	my $priv = Inline::Java::Object::Private->new($class, $java_class, $inline) ;
	$PRIVATES->{$knot} = $priv ;

	if ($objid <= -1){
		my $obj = undef ;
		eval {
			$obj = $this->__get_private()->{proto}->CreateJavaObject($java_class, $proto, $args) ;
		} ;		
		croak $@ if $@ ;

		if (! defined($this->__get_private()->{id})){
			# Use created a java::lang::String or something...
			return $obj ;
		}
	}
	else{
		$this->__get_private()->{id} = $objid ;
		Inline::Java::debug(2, "creating object in java ($class):") ;
	}

	Inline::Java::debug_obj($this) ;

	return $this ;
}


sub __get_private {
	my $this = shift ;
	
	my $knot = tied(%{$this}) || $this ;

	my $priv = $PRIVATES->{$knot} ;
	if (! defined($priv)){
		croak "Unknown Java object reference $knot" ;
	}

	return $priv ;
}


# Checks to make sure all the arguments can be "cast" to prototype
# types.
sub __validate_prototype {
	my $this = shift ;
	my $method = shift ;
	my $args = shift ;
	my $protos = shift ;
	my $inline = shift ;

	my @matched = () ;

	my @proto_values = values %{$protos} ; 
	my @errors = () ;
	foreach my $s (@proto_values){
		my $proto = $s->{SIGNATURE} ;
		my $stat = $s->{STATIC} ;
		my $idx = $s->{IDX} ;
		my $new_args = undef ;
		my $score = undef ;

		my $sig = Inline::Java::Protocol->CreateSignature($proto) ;
		Inline::Java::debug(3, "matching arguments to $method$sig") ;
		
		eval {
			($new_args, $score) = Inline::Java::Class::CastArguments($args, $proto, $inline) ;
		} ;
		if ($@){
			if (scalar(@proto_values) == 1){
				# Here we have only 1 prototype, so we return the error.
				croak $@ ;
			}
			push @errors, $@ ;
			Inline::Java::debug(3, "error trying to fit args to prototype: $@") ;
			next ;
		}

		# We passed!
		Inline::Java::debug(3, "match successful: score is $score") ;
		my $h = {
			PROTO =>	$proto,
			NEW_ARGS =>	$new_args,
			NB_ARGS =>	scalar(@{$new_args}),
			SCORE =>	$score,
			STATIC =>	$stat,
			IDX =>		$idx,
		} ;

		# Tiny optimization: abort if type coerce was used and matched for
		# every parameter
		if (Inline::Java::Class::IsMaxArgumentsScore($new_args, $score)){
			Inline::Java::debug(3, "perfect match found, aborting search") ;
			@matched = () ;
			push @matched, $h ;
			last ;
		}
		else{
			push @matched, $h ;
		}
	}

	my $nb_matched = scalar(@matched) ;
	if (! $nb_matched){
		my $name = (ref($this) ? $this->__get_private()->{class} : $this) ;
		my $sa = Inline::Java::Protocol->CreateSignature($args) ;
		my $msg = "In method $method of class $name: Can't find any signature that matches " .
			"the arguments passed $sa.\nAvailable signatures are:\n"  ;
		my $i = 0 ;
		foreach my $s (@proto_values){
			my $proto = $s->{SIGNATURE} ;	
			my $static = ($s->{STATIC} ? "static " : "") ;

			my $sig = Inline::Java::Protocol->CreateSignature($proto) ;
			$msg .= "\t$static$method$sig\n" ;
			$msg .= "\t\terror was: $errors[$i]" ;
			$i++ ;
		}
		chomp $msg ;
		croak $msg ;
	}

	my $chosen = undef ;
	foreach my $h (@matched){
		my $idx = ($chosen ? $chosen->{IDX} : 0) ;
		my $max = ($chosen ? $chosen->{SCORE} : 0) ;

		my $s = $h->{SCORE} ;
		my $i = $h->{IDX} ;
		if ($s > $max){
			$chosen = $h ;
		}
		elsif ($s == $max){
			# Here if the scores are equal we take the last one since
			# we start with inherited methods and move to class mothods
			if ($i > $idx){
				$chosen = $h ;
			}
		}
	}

	if ((! $chosen->{STATIC})&&(! ref($this))){
		# We are trying to call an instance method without an object
		# reference
		croak "Method $method of class $this must be called from an object reference" ;
	}

	# Here we will be polite and warn the user if we had to choose a 
	# method by ourselves.
	if ($inline->get_java_config('WARN_METHOD_SELECT')){
		if (($nb_matched > 1)&&
			($chosen->{SCORE} < ($chosen->{NB_ARGS} * 10))){
			my $msg = "Based on the arguments passed, I had to choose between " .
				"the following method signatures:\n" ;
			foreach my $m (@matched){
				my $s = Inline::Java::Protocol->CreateSignature($m->{PROTO}) ;
				my $c = ($m eq $chosen ? "*" : " ") ;
				$msg .= "  $c $method$s\n" ;
			}
			$msg .= "I chose the one indicated by a star (*). To force " .
				"the use of another signature or to disable this warning, use " .
				"the casting functionality described in the documentation." ;
			carp $msg ;		
		}
	}

	return (
		$chosen->{PROTO}, 
		$chosen->{NEW_ARGS}, 
		$chosen->{STATIC},
	) ;
}


sub __isa {
	my $this = shift ;
	my $proto = shift ;
	
	my $ret = undef ;
	eval {
		$ret = $this->__get_private()->{proto}->ISA($proto) ;
	} ;
	if ($@){
		return ($@, 0) ;
	}

	if ($ret == -1){
		my $c = $this->__get_private()->{java_class} ;
		return ("$c is not a kind of $proto", 0) ;
	}

	return ('', $ret) ;
}


sub __cast {
	my $this = shift ;
	my $class = shift ;

	my $ret = $this->__get_private()->{proto}->Cast($class) ;

	return $ret ;
} 


sub __get_member {
	my $this = shift ;
	my $key = shift ;

	if ($this->__get_private()->{class} eq "Inline::Java::Object"){
		croak "Can't get member '$key' for an object that is not bound to Perl" ;
	}

	Inline::Java::debug(3, "fetching member variable '$key'") ;

	my $inline = $this->__get_private()->{inline} ;
	my $fields = $inline->get_fields($this->__get_private()->{class}) ;

	my $types = $fields->{$key} ;
	if ($types){
		# We take the last one, which is more specific. Eventually
		# we should use a scoring method just like for the methods
		my $sign = undef ;
		foreach my $s (values %{$types}){
			if ((! defined($sign))||($s->{IDX} > $sign->{IDX})){
				$sign = $s ;
			}
		}

		my $proto = $sign->{TYPE} ;

		my $ret = $this->__get_private()->{proto}->GetJavaMember($key, [$proto], [undef]) ;
		Inline::Java::debug(3, "returning member (" . ($ret || '') . ")") ;
	
		return $ret ;
	}
	else{
		my $name = $this->__get_private()->{class} ;
		croak "No public member variable '$key' defined for class '$name'" ;
	}
}


sub __set_member {
	my $this = shift ;
	my $key = shift ;
	my $value = shift ;

	if ($this->__get_private()->{class} eq "Inline::Java::Object"){
		croak "Can't set member '$key' for an object that is not bound to Perl" ;
	}

	my $inline = $this->__get_private()->{inline} ;
	my $fields = $inline->get_fields($this->__get_private()->{class}) ;

	my $types = $fields->{$key} ;
	if ($types){
		# We take the last one, which is more specific. Eventually
		# we should use a scoring method just like for the methods
		my $sign = undef ;
		foreach my $s (values %{$types}){
			if ((! defined($sign))||($s->{IDX} > $sign->{IDX})){
				$sign = $s ;
			}
		}

		my $proto = $sign->{TYPE} ;
		my $new_args = undef ;
		my $score = undef ;

		($new_args, $score) = Inline::Java::Class::CastArguments([$value], [$proto], $this->__get_private()->{inline}) ;
		$this->__get_private()->{proto}->SetJavaMember($key, [$proto], $new_args) ;
	}
	else{
		my $name = $this->__get_private()->{class} ;
		croak "No public member variable '$key' defined for class '$name'" ;
	}
}


sub AUTOLOAD {
	my $this = shift ;
	my @args = @_ ;

	use vars qw($AUTOLOAD) ;
	my $func_name = $AUTOLOAD ;
	# Strip package from $func_name, Java will take of finding the correct
	# method.
	$func_name =~ s/^(.*)::// ;

	Inline::Java::debug(5, "$func_name") ;

	my $name = (ref($this) ? $this->__get_private()->{class} : $this) ;
	if ($name eq "Inline::Java::Object"){
		croak "Can't call method '$func_name' on an object ($name) that is not bound to Perl" ;
	}

	croak "No public method '$func_name' defined for class '$name'" ;
}


sub DESTROY {
	my $this = shift ;
	
	my $knot = tied %{$this} ;
	if (! $knot){
		Inline::Java::debug(4, "destroying Inline::Java::Object::Tie") ;
		
		if (! Inline::Java::get_DONE()){

			my $class = $this->__get_private()->{class} ;
			Inline::Java::debug(2, "destroying object in java ($class):") ;

			{
				local $@ ;
				eval {
					$this->__get_private()->{proto}->DeleteJavaObject($this) ;
				} ;
				if ($@){
					# We croaked here. Was there already a pending $@?
					my $name = $this->__get_private()->{class} ;
					croak "In method DESTROY of class $name: $@" ;
				}
			}

			# Here we have a circular reference so we need to break it
			# so that the memory is collected.
			my $priv = $this->__get_private() ;
			my $proto = $priv->{proto} ;
			$priv->{proto} = undef ;
			$proto->{obj_priv} = undef ;
			$PRIVATES->{$this} = undef ;
		}
		else{
			Inline::Java::debug(4, "script marked as DONE, object destruction not propagated to Java") ;
		}
	}
	else{
		Inline::Java::debug(4, "destroying Inline::Java::Object") ;
	}
}



######################## Hash Methods ########################
package Inline::Java::Object::Tie ;
@Inline::Java::Object::Tie::ISA = qw(Tie::StdHash) ;


use Tie::Hash ;
use Carp ;


sub TIEHASH {
	my $class = shift ;

	return $class->SUPER::TIEHASH(@_) ;
}


sub STORE {
	my $this = shift ;
	my $key = shift ;
	my $value = shift ;

	return $this->__set_member($key, $value) ;
}


sub FETCH {
 	my $this = shift ;
 	my $key = shift ;

	return $this->__get_member($key) ;
}


sub FIRSTKEY { 
	my $this = shift ;

	return $this->SUPER::FIRSTKEY() ;
}


sub NEXTKEY { 
	my $this = shift ;

	return $this->SUPER::NEXTKEY() ;
}


sub EXISTS { 
 	my $this = shift ;
 	my $key = shift ;

	my $inline = $this->__get_private()->{inline} ;
	my $fields = $inline->get_fields($this->__get_private()->{class}) ;

	if ($fields->{$key}){
		return 1 ;
	}
	
	return 0 ;
}


sub DELETE { 
 	my $this = shift ;
 	my $key = shift ;

	croak "Operation DELETE not supported on Java object" ;
}


sub CLEAR { 
 	my $this = shift ;

	croak "Operation CLEAR not supported on Java object" ;
}


sub DESTROY {
	my $this = shift ;
}




######################## Static Member Methods ########################
package Inline::Java::Object::StaticMember ;
@Inline::Java::Object::StaticMember::ISA = qw(Tie::StdScalar) ;


use Tie::Scalar ;
use Carp ;

my $DUMMIES = {} ;


sub TIESCALAR {
	my $class = shift ;
	my $dummy = shift ;
	my $name = shift ;

	my $this = $class->SUPER::TIESCALAR(@_) ;

	$DUMMIES->{$this} = [$dummy, $name] ;

	return $this ;
}


sub STORE {
	my $this = shift ;
	my $value = shift ;

	my ($obj, $key) = @{$DUMMIES->{$this}} ;

	return $obj->__set_member($key, $value) ;
}


sub FETCH {
 	my $this = shift ;

	my ($obj, $key) = @{$DUMMIES->{$this}} ;

	return $obj->__get_member($key) ;
}


sub DESTROY {
	my $this = shift ;
}



######################## Private Object ########################
package Inline::Java::Object::Private ;

sub new {
	my $class = shift ;
	my $obj_class = shift ;
	my $java_class = shift ;
	my $inline = shift ;
	
	my $this = {} ;
	$this->{class} = $obj_class ;
	$this->{java_class} = $java_class ;
	$this->{inline} = $inline ;
	$this->{proto} = new Inline::Java::Protocol($this, $inline) ;

	bless($this, $class) ;

	return $this ;
}


sub DESTROY {
	my $this = shift ;

	Inline::Java::debug(4, "destroying Inline::Java::Object::Private") ;
}



1 ;
