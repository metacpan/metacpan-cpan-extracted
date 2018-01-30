package Inline::Java::Protocol ;

use strict ;
use Inline::Java::Object ;
use Inline::Java::Array ;
use Carp ;
use MIME::Base64 ;
BEGIN {
	eval "require Encode" ;
}


$Inline::Java::Protocol::VERSION = '0.53_90' ;

my %CLASSPATH_ENTRIES = () ;


sub new {
	my $class = shift ;
	my $obj = shift ;
	my $inline = shift ;

	my $this = {} ;
	$this->{obj_priv} = $obj || {} ;
	$this->{inline} = $inline ;

	bless($this, $class) ;
	return $this ;
}


sub AddClassPath {
	my $this = shift ;
	my @paths = @_ ;

	@paths = map {
		my $e = $_ ;
		if ($CLASSPATH_ENTRIES{$e}){
			() ;
		}
		else{
			Inline::Java::debug(2, "adding to classpath: '$e'") ;
			$CLASSPATH_ENTRIES{$e} = 1 ;
			$e ;
		}
	} @paths ;

	my $data = "add_classpath " . join(" ", map {encode($_)} @paths) ;

	return $this->Send($data) ;
}


sub ServerType {
	my $this = shift ;

	Inline::Java::debug(3, "getting server type") ;

	my $data = "server_type" ;

	return $this->Send($data) ;
}


# Known issue: $classes must contain at least one class name.
sub Report {
	my $this = shift ;
	my $classes = shift ;

	Inline::Java::debug(3, "reporting on $classes") ;

	my $data = join(" ", 
		"report", 
		$this->ValidateArgs([$classes]),
	) ;

	return $this->Send($data) ;
}


sub ISA {
	my $this = shift ;
	my $proto = shift ;

	my $class = $this->{obj_priv}->{java_class} ;

	return $this->__ISA($proto, $class) ;
}


sub __ISA {
	my $this = shift ;
	my $proto = shift ;
	my $class = shift ;

	Inline::Java::debug(3, "checking if $class is a $proto") ;

	my $data = join(" ", 
		"isa", 
		Inline::Java::Class::ValidateClass($class),
		Inline::Java::Class::ValidateClass($proto),
	) ;

	return $this->Send($data) ;
}


sub ObjectCount {
	my $this = shift ;

	Inline::Java::debug(3, "getting object count") ;

	my $data = join(" ", 
		"obj_cnt", 
	) ;

	return $this->Send($data) ;
}


# Called to create a Java object
sub CreateJavaObject {
	my $this = shift ;
	my $class = shift ;
	my $proto = shift ;
	my $args = shift ;

	Inline::Java::debug(3, "creating object new $class" . $this->CreateSignature($args)) ; 	

	my $data = join(" ", 
		"create_object", 
		Inline::Java::Class::ValidateClass($class),
		$this->CreateSignature($proto, ","),
		$this->ValidateArgs($args),
	) ;

	return $this->Send($data, 1) ;
}


# Calls a Java method.
sub CallJavaMethod {
	my $this = shift ;
	my $method = shift ;
	my $proto = shift ;
	my $args = shift ;

	my $id = $this->{obj_priv}->{id} ;
	my $class = $this->{obj_priv}->{java_class} ;
	Inline::Java::debug(3, "calling object($id).$method" . $this->CreateSignature($args)) ;

	my $data = join(" ", 
		"call_method", 
		$id,
		Inline::Java::Class::ValidateClass($class),
		$this->ValidateMethod($method),
		$this->CreateSignature($proto, ","),
		$this->ValidateArgs($args),
	) ;

	return $this->Send($data) ;
}


# Casts a Java object.
sub Cast {
	my $this = shift ;
	my $class = shift ;

	my $id = $this->{obj_priv}->{id} ;
	Inline::Java::debug(3, "creating a new reference to object($id) with type $class") ;

	my $data = join(" ", 
		"cast", 
		$id,
		Inline::Java::Class::ValidateClass($class),
	) ;

	return $this->Send($data) ;
}


# Sets a member variable.
sub SetJavaMember {
	my $this = shift ;
	my $member = shift ;
	my $proto = shift ;
	my $arg = shift ;

	my $id = $this->{obj_priv}->{id} ;
	my $class = $this->{obj_priv}->{java_class} ;
	Inline::Java::debug(3, "setting object($id)->{$member} = " . ($arg->[0] || '')) ;
	my $data = join(" ", 
		"set_member", 
		$id,
		Inline::Java::Class::ValidateClass($class),
		$this->ValidateMember($member),
		Inline::Java::Class::ValidateClass($proto->[0]),
		$this->ValidateArgs($arg),
	) ;

	return $this->Send($data) ;
}


# Gets a member variable.
sub GetJavaMember {
	my $this = shift ;
	my $member = shift ;
	my $proto = shift ;

	my $id = $this->{obj_priv}->{id} ;
	my $class = $this->{obj_priv}->{java_class} ;
	Inline::Java::debug(3, "getting object($id)->{$member}") ;

	my $data = join(" ", 
		"get_member", 
		$id,
		Inline::Java::Class::ValidateClass($class),
		$this->ValidateMember($member),
		Inline::Java::Class::ValidateClass($proto->[0]),
		"undef:",
	) ;

	return $this->Send($data) ;
}


sub ReadFromJavaHandle {
	my $this = shift ;
	my $len = shift ;

	my $id = $this->{obj_priv}->{id} ;
	my $class = $this->{obj_priv}->{java_class} ;
	Inline::Java::debug(3, "reading from handle object($id)") ;

	my $data = join(" ", 
		"read", 
		$id,
		$len,
	) ;

	return $this->Send($data) ;
}


sub MakeJavaHandleBuffered {
	my $this = shift ;

	my $id = $this->{obj_priv}->{id} ;
	Inline::Java::debug(3, "making handle object($id) buffered") ;

	my $data = join(" ", 
		"make_buffered", 
		$id,
	) ;

	return $this->Send($data) ;
}


sub ReadLineFromJavaHandle {
	my $this = shift ;

	my $id = undef ;
	if (! defined($this->{obj_priv}->{buffered})){
		my $nid = $this->MakeJavaHandleBuffered() ;
		$this->{obj_priv}->{buffered} = Inline::Java::Object->__new('<buffer>', $this->{inline}, $nid) ;
	}
	$id = $this->{obj_priv}->{buffered}->__get_private()->{id} ;
	Inline::Java::debug(3, "reading line from handle object($id)") ;

	my $data = join(" ", 
		"readline", 
		$id,
	) ;

	return $this->Send($data) ;
}


sub WriteToJavaHandle {
	my $this = shift ;
	my $str = shift ;

	my $id = $this->{obj_priv}->{id} ;
	Inline::Java::debug(3, "writing to handle object($id)") ;

	my $data = join(" ", 
		"write", 
		$id,
		$this->ValidateArgs([$str]),
	) ;

	return $this->Send($data) ;
}


sub CloseJavaHandle {
	my $this = shift ;

	my $id = $this->{obj_priv}->{id} ;
	my $class = $this->{obj_priv}->{java_class} ;
	Inline::Java::debug(3, "closing handle object($id)") ;

	my $data = join(" ", 
		"close", 
		$id,
	) ;

	return $this->Send($data) ;
}


# Deletes a Java object
sub DeleteJavaObject {
	my $this = shift ;
	my $obj = shift ;

	if (defined($this->{obj_priv}->{id})){
		my $id = $this->{obj_priv}->{id} ;
		my $class = $this->{obj_priv}->{java_class} ;

		Inline::Java::debug(3, "deleting object $obj $id ($class)") ;

		my $data = join(" ", 
			"delete_object", 
			$id,
		) ;

		$this->Send($data) ;
	}
}


# This method makes sure that the method we are asking for
# has the correct form for a Java method.
sub ValidateMethod {
	my $this = shift ;
	my $method = shift ;

	if ($method !~ /^(\w+)$/){
		croak "Invalid Java method name $method" ;
	}	

	return $method ;
}


# This method makes sure that the member we are asking for
# has the correct form for a Java member.
sub ValidateMember {
	my $this = shift ;
	my $member = shift ;

	if ($member !~ /^(\w+)$/){
		croak "Invalid Java member name $member" ;
	}	

	return $member ;
}


# Validates the arguments to be used in a method call.
sub ValidateArgs {
	my $this = shift ;
	my $args = shift ;
	my $callback = shift ;

	my @ret = () ;
	foreach my $arg (@{$args}){
		if (! defined($arg)){
			push @ret, "undef:" ;
		}
		elsif (ref($arg)){
			if ((UNIVERSAL::isa($arg, "Inline::Java::Object"))||(UNIVERSAL::isa($arg, "Inline::Java::Array"))){
				my $obj = $arg ;
				if (UNIVERSAL::isa($arg, "Inline::Java::Array")){
					$obj = $arg->__get_object() ; 
				}
				my $class = $obj->__get_private()->{java_class} ;
				my $id = $obj->__get_private()->{id} ;
				push @ret, "java_object:$class:$id" ;
			}
			elsif (UNIVERSAL::isa($arg, 'Inline::Java::double')){
				push @ret, "double:" . encode(${$arg}) ;
			}
			elsif ($arg =~ /^(.*?)=/){
				my $id = Inline::Java::Callback::PutObject($arg) ;
				# Bug. The delimiter is :, so we need to escape the package separator (::)
				my $pkg = $1 ;
				$pkg =~ s/:/\//g ;
				push @ret, "perl_object:$pkg:$id" ;
			}
			else {
				if (! $callback){
					croak "A Java method or member can only have Java objects, Java arrays, Perl objects or scalars as arguments" ;
				}
				else{
					croak "A Java callback function can only return Java objects, Java arrays, Perl objects or scalars" ;
				}
			}
		}
		else {
			push @ret, "scalar:" . encode($arg) ;
		}
	}

	return @ret ;
}


sub CreateSignature {
	my $this = shift ;
	my $proto = shift ;
	my $del = shift || ", " ;

	no warnings ;
	my $sig = join($del, @{$proto}) ;
	return "($sig)" ;
}


# This actually sends the request to the Java program. It also takes
# care of registering the returned object (if any)
sub Send {
	my $this = shift ;
	my $data = shift ;
	my $const = shift ;

	my $resp = Inline::Java::__get_JVM()->process_command($this->{inline}, $data) ;
	if ($resp =~ /^error scalar:([\w+\/=+]*)$/){
		my $msg = decode($1) ;
		Inline::Java::debug(3, "packet recv error: $msg") ;
		croak $msg ;
	}
	elsif ($resp =~ s/^ok //){
		return $this->DeserializeObject($const, $resp) ;
	}

	croak "Malformed response from server: $resp" ;
}


sub DeserializeObject {
	my $this = shift ;
	my $const = shift ;
	my $resp = shift ;

	if ($resp =~ /^scalar:([\w+\/=+]*)$/){
		return decode($1) ; 
	}
	elsif ($resp =~ /^double:(.*)$/){
		my $bytes = decode($1) ;
		my $d = unpack('d', $bytes) ;
		return $d ;
	}
	elsif ($resp =~ /^undef:$/){
		return undef ;
	}
	elsif ($resp =~ /^java_(object|array|handle):([01]):(\d+):(.*)$/){
		# Create the Perl object wrapper and return it.
		my $type = $1 ;
		my $thrown = $2 ;
		my $id = $3 ;
		my $class = $4 ;

		if ($thrown){
			# If we receive a thrown object, we jump out of 'constructor
			# mode' and process the returned object.
			$const = 0 ;
		}

		if ($const){
			$this->{obj_priv}->{java_class} = $class ;
			$this->{obj_priv}->{id} = $id ;

			return undef ;
		}
		else {
			my $pkg = $this->{inline}->get_api('pkg') ;

			my $obj = undef ;
			my $elem_class = $class ;

			Inline::Java::debug(3, "checking if stub is array...") ;
			if ($type eq 'array'){
				my @d = Inline::Java::Class::ValidateClassSplit($class) ;
				$elem_class = $d[2] ;
			}

			my $perl_class = "Inline::Java::Object" ;
			if ($elem_class){
				# We have a real class or an array of real classes
				$perl_class = Inline::Java::java2perl($pkg, $elem_class) ;
				if (Inline::Java::Class::ClassIsReference($elem_class)){
					if (! Inline::Java::known_to_perl($pkg, $elem_class)){
						if (($thrown)||($this->{inline}->get_java_config('AUTOSTUDY'))){
							Inline::Java::debug(2, "autostudying $elem_class...") ;
							$this->{inline}->_study([$elem_class]) ;
						}
						else{	
							# Object is not known to Perl, it lives as a 
							# Inline::Java::Object
							$perl_class = "Inline::Java::Object" ;
						}
				 	}
				}
			}
			else{
				# We should only get here if an array of primitives types
				# was returned, and there is nothing to do since
				# the block below will handle it.
			}

			if ($type eq 'array'){
				Inline::Java::debug(3, "creating array object...") ;
				$obj = Inline::Java::Object->__new($class, $this->{inline}, $id) ;
				$obj = new Inline::Java::Array($obj) ;
				Inline::Java::debug(3, "array object created...") ;
			}
			# To be finished at a later time...
			# elsif ($type eq 'handle'){
			# 	Inline::Java::debug(3, "creating handle object...") ;
			# 	$obj = Inline::Java::Object->__new($class, $this->{inline}, $id) ;
			# 	$obj = new Inline::Java::Handle($obj) ;
			# 	Inline::Java::debug(3, "handle object created...") ;
			# }
			else{
				$obj = $perl_class->__new($class, $this->{inline}, $id) ;
			}

			if ($thrown){
				Inline::Java::debug(3, "throwing stub...") ;
				my ($msg, $score) = $obj->__isa('org.perl.inline.java.InlineJavaPerlException') ;
				if ($msg){
					die $obj ;
				}
				else{
					die $obj->GetObject() ;
				}
			}
			else{
				Inline::Java::debug(3, "returning stub...") ;
				return $obj ;
			}
		}
	}
	elsif ($resp =~ /^perl_object:(\d+):(.*)$/){
		my $id = $1 ;
		my $pkg = $2 ;

		return Inline::Java::Callback::GetObject($id) ;
	}
	else{
		croak "Malformed response from server: $resp" ;
	}
}


sub encode {
	my $s = shift ;

	# Get UTF-8 byte representation of the data.
	my $bytes = undef ;
	if ($INC{'Encode.pm'}){
		$bytes = Encode::encode_utf8($s) ;
	}
	else {
		$bytes = $s ;
		$bytes =~ s/([\x80-\xFF])/chr(0xC0|ord($1)>>6).chr(0x80|ord($1)&0x3F)/eg ;
	}

	# Base-64 encode it.
	my $base64 = encode_base64($bytes, '') ;
	
	return $base64 ;
}


sub decode {
	my $s = shift ;

	# Decode the Base-64 data into bytes (UTF-8 representation of the data).
	my $bytes = decode_base64($s) ;

	# Take the UTF-8 encoding and convert it back to logical characters.
	my $string = undef ;
	if ($INC{'Encode.pm'}){
		$string = Encode::decode_utf8($bytes) ;
	}
	else {
		$string = $bytes ;
		$string =~ s/([\xC2\xC3])([\x80-\xBF])/chr(ord($1)<<6&0xC0|ord($2)&0x3F)/eg ;
	}

	if (utf8->can('downgrade')){
		utf8::downgrade($string, 1) ;
	}

	return $string ;
}


sub DESTROY {
	my $this = shift ;

	Inline::Java::debug(4, "destroying Inline::Java::Protocol") ;
}


1 ;
