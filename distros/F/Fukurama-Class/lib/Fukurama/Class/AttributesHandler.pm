package Fukurama::Class::AttributesHandler;
use Fukurama::Class::Version(0.01);
use Fukurama::Class::Rigid;
use Fukurama::Class::Carp;

my $ATT_METHODS;
my $EXPORTED;
my $LAST_ATTRIBUTE_METHOD;
my $SUBS;
my $HELPER_METHODS;
BEGIN {
	$ATT_METHODS = {};
	$EXPORTED = {};
	$SUBS = {};
	$LAST_ATTRIBUTE_METHOD = undef;
	$HELPER_METHODS = {};
}

=head1 NAME

Fukurama::Class::AttributesHandler - Helper class to provide corrrect handling of attributes

=head1 VERSION

Version 0.01 (beta)

=head1 SYNOPSIS

 {
 	package MyAttributeHandler;
 	sub MyAttribute {
 		my $class = $_[0];
 		my $method_data = $_[1];
 		
 		warn("Method '$method_data->{'sub_name'}' was resolved at compiletime with data: '$method_data->{'data'}'");
 		# says: Method 'my_own_method' was resolved at compiletime with data: 'foo, bar'
 	}
 }
 {
 	package MyClass;
 	use Fukurama::Class::AttributesHandler();
 	Fukurama::Class::AttributesHandler->register_attributes('MyAttributeHandler');
 	Fukurama::Class::AttributesHandler->export('MyClass');
 	
 	sub my_own_method : MyAttribute(foo, bar) {}
 }

=head1 DESCRIPTION

This module enables the possibility to define your own subroutine-attributes. This is also done with the CPAN L<Attribute> module
but here you get extra information for the subroutine, which use the attribute. E.g. the resolved methodname.

This helper class is used from Fukurama::Class::Attribute::OOStandard to enable the OO-method-signatures.

=head1 EXPORT

=over 4

=item MODIFY_CODE_ATTRIBUTES

would be decorated if it exist or created if it isn't in the current class.

=back

=head1 METHODS

=over 4

=item register_attributes( attribute_handler_class:STRING ) return:BOOLEAN

Register a handler class which defines attributes. See L<How to define an attribute-handler-class> below

=item export( export_to_class:STRING ) return:BOOLEAN

This will export or decorate the MODIFY_CODE_ATTRIBUTES to the export_to_class class. Be sure that you call this method
in a BEGIN block. Perl check them all at compiletime and croak, if some is not defined.

=item get_registered_subs( ) return:HASHREF

Get the method-definitions from all methods in your code, which use attributes over this attribute handler.
This is to check th code structure (or to create some documentation...)

=item register_helper_method( methodname:STRING ) return:VOID

All registered methodnames would be omitted as attributes, when a attribute-handler-class is parsed. But
if they are missed in a attribute-handler-class, the registration would fail.

=item run_check( ) return:VOID

Resolve all method names, which are unresolved at compiletime, and calls the atribute-definition-methods
in the handler-class. This is a helper method for static perl (see Fukurama::Class > BUGS)

=back

=head1 How to define an attribute-handler-class

All methods of an attribute-handler-class have to be attribute-definitions, except these, which are registered via register helper methods.
This methods have to start with an uppercase letter (it is a perl specification). They will get a hash reference as single parameter.
In this hash you will find information of the method which use your attribute. They are:

=over 4

=item class:STRING

The name of the class, which contain the subroutine which use the attribute (*puh*). Can be empty in some cases. Look at L<resolved>.

=item sub_name:STRING

The resolved name of the subroutine, which use the attribute. Perls attributes doesn't resolve the name by itself,
so you will normally only get the sub-reference and not the name. It can be empty in some cases. Look at L<resolved>.

=item data:STRING

The defined attribute-data. if you say 'sub new : MyAtt(this is a $test)' you will get the string 'this is a $test'.

=item sub:CODEREF

The code-refrence of the subroutine, which use the attribute.

=item resolved:BOOLEAN

A flag for the status of method name resolving for this method. In some cases, if you force a call, this flag will
be FALSE and the B<sub_name> will be empty.

=item attribute:STRING

The name of the attribute. This is the same like the name of your attribute-method.

=item handler:HASHREF

A reference to your attribute class and to the actual attribute method.

=item executed: BOOLEAN

An internal flag to avoid double callings of your attribute-methods.

=back

=head1 AUTHOR, BUGS, SUPPORT, ACKNOWLEDGEMENTS, COPYRIGHT & LICENSE

see perldoc of L<Fukurama::Class>

=cut

# STATIC boolean
sub register_attributes {
	my $class = $_[0];
	my $attribute_class = $_[1];
	
	my @subs = ();
	my $check_methods_exist = {};
	{
		
		no strict 'refs';
		
		my %symbols = %{$attribute_class . '::'};
		if(!scalar(%symbols) && !eval("use $attribute_class;return 1;")) {
			_croak("Failed to load attribute-class '$attribute_class' (maybe this class is empty?): $@\n");
			return 0;
		}
		foreach my $name (keys(%symbols)) {
			next if(!*{$attribute_class . '::' . $name}{'CODE'});
			if($HELPER_METHODS->{$name}) {
				$check_methods_exist->{$name} = 1;
				next;
			}
			push(@subs, $name);
		}
	}
	
	my @missed_helper_methods = ();
	foreach my $name (keys(%$HELPER_METHODS)) {
		next if($check_methods_exist->{$name});
		push(@missed_helper_methods, $name);
	} 
	if(scalar(@missed_helper_methods)) {
		my $msg = join("', '", @missed_helper_methods);
		_croak("Needed helper method(s) '$msg' is/are not defined in attribute-class '$attribute_class'. (Maybe class is not compiled yet?)");
	}
	
	foreach my $name (@subs) {
		$class->_register_attribute($attribute_class, $name, 0);
	}
	foreach my $name (@subs) {
		$class->_register_attribute($attribute_class, $name, 1);
	}
	return 1;
}
# STATIC hashref
sub get_registered_subs {
	my $class = $_[0];
	
	return $SUBS;
}
# STATIC void
sub _register_attribute {
	my $class = $_[0];
	my $attribute_class = $_[1];
	my $name = $_[2];
	my $execute_register = $_[3];
	
	if($ATT_METHODS->{$name}) {
		_croak("Attribute '$name' from attribute-class '$attribute_class' always registered for '$ATT_METHODS->{$name}->{'class'}'", 1);
		return;
	}
	if($name !~ m/^[A-Z]/) {
		my $helper_msg = "'" . join("', '", keys(%$HELPER_METHODS)) . "'";
		_croak("Every attribute must start with an uppercase letter (except the helper-method(s) $helper_msg " .
			"which is/are not an attribute).\n" .
			"Attribute '$name' from attribute-class '$attribute_class' is not allowed.", 1);
		return;
	}

	return if(!$execute_register);
	{
		
		no strict 'refs';
		
		$ATT_METHODS->{$name} = {
			class		=> $attribute_class,
			coderef		=> *{$attribute_class . '::' . $name}{'CODE'},
		};
	}
	return;
}
# STATIC boolean
sub export {
	my $class = $_[0];
	my $export_to_class = $_[1];
	
	return 0 if($EXPORTED->{$export_to_class});
	$EXPORTED->{$export_to_class} = 1;
	$class->_decorate_attribute_handler($export_to_class, "$export_to_class\::MODIFY_CODE_ATTRIBUTES");
	return 1;
}
# STATIC void
sub register_helper_method {
	my $class = $_[0];
	my $methodname = $_[1];
	
	$HELPER_METHODS->{$methodname} = 1;
	return;
}
# STATIC void
sub _decorate_attribute_handler {
	my $class = $_[0];
	my $caller_class = $_[1];
	my $identifier = $_[2];

	no warnings 'redefine';
	no strict 'refs';

	my $old = *{$identifier}{CODE};
	*{$identifier} = sub {
		my @unknown_attributes = &_attribute_handler(@_);
		if($old && @unknown_attributes) {
			my $caller_class = $_[0];
			my $sub_ref = $_[1];
			
			@_ = ($caller_class, $sub_ref, @unknown_attributes);
			goto &$old;
		}
		return @unknown_attributes;
	};
	return;
}
# AUTOMAGIC string()
sub _attribute_handler {
	my $caller_class = shift(@_);
	my $sub_ref = shift(@_);
	my @attributes = @_;

	if($LAST_ATTRIBUTE_METHOD && !$LAST_ATTRIBUTE_METHOD->{'resolved'}) {
		my $succes = __PACKAGE__->_resolve_sub($LAST_ATTRIBUTE_METHOD);
		if(!$LAST_ATTRIBUTE_METHOD->{'executed'}) {
			my $success = __PACKAGE__->_exec_attribute($LAST_ATTRIBUTE_METHOD);
		}
	}
	my @unknown_attributes = ();
	foreach my $attribute_string (@attributes) {
		my ($name, $data) = __PACKAGE__->_split_attribute($attribute_string);
		my $handler = $ATT_METHODS->{$name};
		if(!$handler) {
			push(@unknown_attributes, $attribute_string);
			next;
		}
		if($SUBS->{int($sub_ref)}) {
			_croak("Internal failure: subroutine '$sub_ref' allways registered");
		}
		$LAST_ATTRIBUTE_METHOD = {
			'attribute'	=> $name,
			'handler'	=> $handler,
			'sub'		=> $sub_ref,
			'class'		=> $caller_class,
			'data'		=> $data,
			'resolved'	=> 0,
			'executed'	=> 0,
		};
		$SUBS->{int($sub_ref)} = $LAST_ATTRIBUTE_METHOD;
	}
	return @unknown_attributes;
}
# STATIC boolean
sub _resolve_sub {
	my $class = $_[0];
	my $sub_data = $_[1];
	
	return 1 if($sub_data->{'resolved'});
	
	no strict 'refs';

	my $symbols = \%{$sub_data->{'class'} . '::'};
	foreach my $key (keys(%$symbols)) {
		next if(!$symbols->{$key} || !*{$symbols->{$key}}{CODE});
		if(*{$symbols->{$key}}{CODE} == $sub_data->{'sub'}) {
			$sub_data->{'sub_name'} = $key;
			$sub_data->{'resolved'} = 1;
			return 1;
		}
	}
	return 0;
}
# STATIC string()
sub _split_attribute {
	my $class = $_[0];
	my $string = $_[1];

	my ($name, $data) = $string =~ m/^([^\(]*)(?:\((.*)\)|)$/i;
	if(!$name) {
		_croak("Attribute '$string' is malformed", 1);
	}
	return ($name, $data);
}
# STATIC sub
sub _exec_attribute {
	my $class = $_[0];
	my $sub_data = $_[1];
	
	return 1 if($sub_data->{'executed'});
	my $att_class = $sub_data->{'handler'}->{'class'};
	my $att_method = $sub_data->{'handler'}->{'coderef'};
	
	local $Carp::CarpLevel = $Carp::CarpLevel + 2;
	if($att_class->$att_method($sub_data)) {
		$sub_data->{'executed'} = 1;
		return 1;
	}
	return 0;
}
# STATIC void
sub run_check {
	my $class = $_[0];
	
	foreach my $ref_no (keys %$SUBS) {
		my $entry = $SUBS->{$ref_no};
		if(!$entry->{'executed'}) {
			if(!__PACKAGE__->_resolve_sub($entry)) {
				_croak("Internal error: can't resolve sub '$entry->{'sub'}'");
			}
			if(!__PACKAGE__->_exec_attribute($entry)) {
				_croak("Internal error: can't execute attribute '$entry->{'attribute'}' for sub '$entry->{'class'}->$entry->{'sub_name'}'");
			}
		}
	}
	return;
}

no warnings 'void'; # avoid 'Too late to run CHECK/INIT block'

# AUTOMAGIC
CHECK {
	__PACKAGE__->run_check();
}
# AUTOMAGIC
END {
	__PACKAGE__->run_check();
}
1;
