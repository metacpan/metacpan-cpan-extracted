package JE::Object::Proxy;

our $VERSION = '0.066';

use strict;
use warnings; no warnings 'utf8';

# ~~~ delegate overloaded methods?

use JE::Code 'add_line_number';
use Scalar::Util 1.09 qw'refaddr';

require JE::Object;

our @ISA = 'JE::Object';


=head1 NAME

JE::Object::Proxy - JS wrapper for Perl objects

=head1 SYNOPSIS

  $proxy = new JE::Object::Proxy $JE_object, $some_Perl_object;

=cut




sub new {
	my($class, $global, $obj) = @_;

	my $class_info = $$$global{classes}{ref $obj};

	my $self = ($class eq __PACKAGE__ # allow subclassing
	            && ($$class_info{hash} || $$class_info{array})
			? __PACKAGE__."::Array" : $class)
		   ->JE::Object::new($global,
		{ prototype => $$class_info{prototype} });

	@$$self{qw/class_info value/} = ($class_info, $obj);

	while(my($name,$args) = each %{$$class_info{props}}) {
		$self->prop({ name => $name, @$args });
	}

	$self;
}




sub class { $${$_[0]}{class_info}{name} }




sub value { $${$_[0]}{value} }




sub id {
	refaddr $${$_[0]}{value};
}




sub to_primitive { # ~~~ This code should  probably  be  moved  to 
                   #     &JE::bind_class for the sake of efficiency.
	my($self, $hint) = (shift, @_);

	my $guts = $$self;
	my $value = $$guts{value};
	my $class_info = $$guts{class_info};

	if(exists $$class_info{to_primitive}) {
		my $tp = $$class_info{to_primitive};
		if(defined $tp) {
			ref $tp eq 'CODE' and
				return $$guts{global}->upgrade(
					&$tp($value, @_)
				);
			($tp, my $type) = JE::_split_meth($tp);
			return defined $type
			?  $$guts{global}->_cast($value->$tp(@_),$type)
			:  $$guts{global}->upgrade($value->$tp(@_))
		} else {
			die add_line_number
				"The object ($$class_info{name}) cannot "
				. "be converted to a primitive";
		}
	} else {
		if(overload::Method($value,'""') ||
		   overload::Method($value,'0+') ||
		   overload::Method($value,'bool')){
			return $$guts{global}->upgrade("$value");
		}
		return SUPER::to_primitive $self @_;
	}
}



sub to_string {
	my($self, $hint) = (shift, @_);

	my $guts = $$self;
	my $value = $$guts{value};
	my $class_info = $$guts{class_info};

	if(exists $$class_info{to_string}) {
		my $tp = $$class_info{to_string};
		if(defined $tp) {
			ref $tp eq 'CODE' and
				return $$guts{global}->upgrade(
					&$tp($value, @_)
				)->to_string;
			($tp, my $type) = JE::_split_meth $tp;
			return ( defined $type
			  ?  $$guts{global}->upgrade($value->$tp(@_))
			  :  $$guts{global}->_cast($value->$tp(@_),$type)
			)->to_string
		} else {
			die add_line_number
				"The object ($$class_info{name}) cannot "
				. "be converted to a string";
		}
	} else {
		return SUPER::to_string $self @_;
	}
}




sub to_number {
	my($self, $hint) = (shift, @_);

	my $guts = $$self;
	my $value = $$guts{value};
	my $class_info = $$guts{class_info};

	if(exists $$class_info{to_number}) {
		my $tp = $$class_info{to_number};
		if(defined $tp) {
			ref $tp eq 'CODE' and
				return $$guts{global}->upgrade(
					&$tp($value, @_)
				)->to_number;
			($tp, my $type) = JE::_split_meth $tp;
			return ( defined $type
			  ?  $$guts{global}->upgrade($value->$tp(@_))
			  :  $$guts{global}->_cast($value->$tp(@_),$type)
			)->to_number
		} else {
			die add_line_number
				"The object ($$class_info{name}) cannot "
				. "be converted to a number";
		}
	} else {
		return SUPER::to_number $self @_;
	}
}




package JE::Object::Proxy::Array; # so this extra stuff doesn't slow down
our $VERSION = '0.066';           # 'normal' usage
our @ISA = 'JE::Object::Proxy';
require JE::Number;

sub prop {
	my $self = shift;
	my $wrappee = $self->value;
	my $name = shift;
	my $class_info = $$$self{class_info};

	if ($$class_info{array}) {
		if($name eq 'length') {
			@_ ? ($#$wrappee = $_[0]-1, return shift)
			   : return new JE::Number
			      $self->global, scalar @$wrappee
		}
		if($name =~ /^(?:0|[1-9]\d*)\z/ and $name < 4294967295){
			@_ ? $$class_info{array}{store}(
				$wrappee,$name,$_[0]) && return shift
		  	 : do {
				my $ret =
				   $$class_info{array}{fetch}(
				      $wrappee,$name);
				defined $ret and return $ret;
			   }
		}
	}
	if ($$class_info{hash}and !exists $$class_info{props}{$name}) {
		if(@_){
			$$class_info{hash}{store}->(
				$wrappee,$name,$_[0]
			) and return shift;
		}else{
			my $ret = $$class_info{hash}{fetch}
				($wrappee,$name);
			defined $ret and return $ret;
		}
	}
	SUPER::prop $self $name, @_;
}

sub keys {
	my $self = shift;
	my $wrappee = $self->value;
	my $class_info = $$$self{class_info};
	my @keys;
	if ($$class_info{array}){
		@keys = grep(exists $wrappee->[$_], 0..$#$wrappee);
	}
	if($$class_info{hash}) {
		push @keys, keys %$wrappee;
	}
	push @keys, SUPER::keys $self;
	my @new_keys; my %seen;
	$seen{$_}++ or push @new_keys, $_ for @keys;
	@new_keys;
}

sub delete {
	my $self = shift;
	my $wrappee = $self->value;
	my($name) = @_;
	my $class_info = $$$self{class_info};
	if ($$class_info{array}){
		if ($name =~ /^(?:0|[1-9]\d*)\z/ and $name < 4294967295 and
		    exists $wrappee->[$name]) {
			delete $wrappee->[$name];
			return !$self->exists($name);
		}
		elsif ($name eq 'length') {
			return !1
		}
	}
	if($$class_info{hash} && !exists $$class_info{props}{$name} and
	   exists $wrappee->{$name}) {
		delete $wrappee->{$name};
		return !exists $wrappee->{$name};
	}
	SUPER::delete $self @_;
}

sub exists {
	my $self = shift;
	my $wrappee = $self->value;
	my($name) = @_;
	my $class_info = $$$self{class_info};
	if ($$class_info{array}){
		if ($name =~ /^(?:0|[1-9]\d*)\z/ and $name < 4294967295) {
			return 1 if exists $wrappee->[$name];
			# If it doesn’t exists, try hash keys below.
		}
		elsif ($name eq 'length') {
			return 1
		}
	}
	if($$class_info{hash}) {
	   return 1 if exists $wrappee->{$name};
	}
	SUPER::exists $self @_;

}


1;

