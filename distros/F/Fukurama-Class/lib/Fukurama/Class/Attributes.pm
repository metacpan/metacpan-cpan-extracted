package Fukurama::Class::Attributes;
use Fukurama::Class::Version(0.01);
use Fukurama::Class::Rigid;
use Fukurama::Class::Carp;

use Fukurama::Class::Tree();
use Fukurama::Class::AttributesHandler();
use Fukurama::Class::Attributes::OOStandard();
use Fukurama::Class::Extends();
use Fukurama::Class::Implements();

our $LEVEL_CHECK_NONE	= 0;
our $LEVEL_CHECK_ALL	= 1;

our $CHECK_LEVEL = $LEVEL_CHECK_ALL;

my $INIT;
my $REGISTERED_ATTRIBUTE_HANDLER;
my $REGISTERED_CLASSES;
my $INHERITATION_CHECK_SUBS;
my $INHERIT_METHOD_NAME;
BEGIN {
	$REGISTERED_ATTRIBUTE_HANDLER = {
		'Fukurama::Class::Attributes::OOStandard'	=> 0,
	};
	$REGISTERED_CLASSES = {};
	$INHERITATION_CHECK_SUBS = {};
	$INHERIT_METHOD_NAME = 'check_inheritation';
}

=head1 NAME

Fukurama::Class::Attributes - Pragma like module to extend code attributes

=head1 VERSION

Version 0.01 (beta)

=head1 SYNOPSIS

 package MyAttributeClass;
 sub MyFirstCodeAttribute {
 	my $class = $_[0];
 	my $subroutine_data = $_[1];
 	
 	... do some checks or what you want ...
 	
 	return;
 }
 sub check_inheritation {
 	my $class = $_[0];
	my $method_name = $_[1];
	my $parent_class = $_[2];
	my $child_class = $_[3];
	my $inheritation_type = $_[4];
	
	return;
 }
 
 package MyClass;
 BEGIN {
 	use Fukurama::Class::Attributes();
 	Fukurama::Class::Attributes->add_attribute_handler('MyAttributeClass');
 }
 use Fukurama::Class::Attributes;
 sub my_method : Method(static|void|) {
 	return;
 }
 sub other_sub : MyFirstCodeAttribute() {
 	...
 }

=head1 DESCRIPTION

This pragma-like module provides functions to extend code attributes for yourself and check
the inheritation. It includes Fukurama::Attributes::OOStandard, which enables Method and Constructor
definitoins for subroutines. Use Fukurama::Class instead, to get all the features for OO.

=head1 CONFIG

You can disables all checks, which includes syntax and inheritation check by saying:

$Fukurama::Class::Attributes::CHECK_LEVEL = $Fukurama::Class::Attributes::LEVEL_CHECK_NONE;

=head1 EXPORT

-

=head1 METHODS

=over 4

=item add_attribute_handler( handler_class:CLASS ) return:BOOLEAN

Add all defined attribute-methods of the given class, so you can use their code attributes in
all of your subroutines. See section L<CREATE AN OWN ATTRIBUTE CLASS> for the rules.

=item remove_attribute_handler( handler_class:CLASS ) return:BOOLEAN

Remove all defined attribute-methods of the given class, so you can't use their anymore as code attributes.

=item register_class( export_to_class:CLASS ) return:BOOLEAN

Export all code attributes to the given class so you can use all registered code attributes in there.
Every child of the given class can even use this behavior.

=item run_check( ) return:VOID

Helper method for static perl (see Fukurama::Class > BUGS)
Its calls Fukurama::Class::AttributeHandler->run_check(), which check the correct syntax of all registered
code attributes and check some defined conventions.

E.g. for code attribute B<Method>: it will check that the access level of child class methods are the same or
stricter than the parent class method.

=back

=head1 CREATE AN OWN ATTRIBUTE CLASS

An "attribute class" describe one (or many) code attributes, which you can use like B<my_method : MyNewCodeAttribute(Foo) {...}>
There are the following rules for the class-methods:

-Every Attribute has to start with an uppercase letter

-Only on other method can be there, the subroutine B<check_inheritation()>

-All these methods have to be void

Attribute methods take on parameter, a hash reference, which contain informations about the method, which uses
the actual code-attribute. For every subroutine which contains this code attribute, the corresponding
method in your attribute class would be called. The parameter contain the following data:

 resolved	=> BOOLEAN, # the subroutine is resolved (only internal use to avoid calls without the name of the subroutine)
 data		=> STRING,  # the attribute-data. If you say B<sub get : Method(public||)> it youd contain B<public||>
 sub_name	=> STRING,  # the name of the subroutine, which call this attribute
 executed	=> BOOLEAN, # this attribute for this subroutine is allways called (only internal use to avoid double callings)
 attribute	=> STRING,  # the name of the attribute. Its the same like the name of your code-attribute-method.
 handler	=> HASHREF, # Contain a reference to your code-attribute method and class. Only for internal use.
 sub		=> CODEREF, # The code referense of the subroutine, which contain the code attribute.
 class		=> STRING,	# The class in which the subroutine is declared, which contain the code attribute.
 
There are many things which you can do with code attributes, e.g. the Method and Constructor definitions from
Fukurama::Class::Attributes::OOStandard or some simple things like in Catalyst. So, do what you need.
 
The check_inheritation() method is optional, check the code attribute inheritation for each class and take the following parameters:

 $method_name  : STRING # the methodname which is checked
 $parent_class : STRING # the parent class of the actual checked class
 $child_class  : STRING # the actual checked class
 $inheritation_type : STRING # the type of inheritation. extend is standard, implement even exists
 
With this method you can compare every subroutine, which contain a code attribute, with all parents. If you use multi
inheritation or interfaces there can be more than one parent. And it even compares in the same way all grandparents etc.

=head1 AUTHOR, BUGS, SUPPORT, ACKNOWLEDGEMENTS, COPYRIGHT & LICENSE

see perldoc of L<Fukurama::Class>

=cut

# STATIC boolean
sub add_attribute_handler {
	my $class = $_[0];
	my $handler_class = $_[1];
	
	$REGISTERED_ATTRIBUTE_HANDLER ||= {};
	return 0 if(defined($REGISTERED_ATTRIBUTE_HANDLER->{$handler_class}));
	$REGISTERED_ATTRIBUTE_HANDLER->{$handler_class} = 1;
	return 1;
}
# STATIC boolean
sub remove_attribute_handler {
	my $class = $_[0];
	my $handler_class = $_[1];
	
	return 0 if(!$REGISTERED_ATTRIBUTE_HANDLER || !defined($REGISTERED_ATTRIBUTE_HANDLER->{$handler_class})
		|| $REGISTERED_ATTRIBUTE_HANDLER->{$handler_class});
	delete($REGISTERED_ATTRIBUTE_HANDLER->{$handler_class});
	return 1;
}
# AUTOMAGIC void
sub import {
	
	my $caller_class = caller();
	__PACKAGE__->register_class($caller_class);
	return;
}
# STATIC void
sub register_class {
	my $class = $_[0];
	my $export_to_class = $_[1];
	
	if(!$INIT) {
		$class->_init();
		$INIT = 1;
	}
	
	foreach my $handler_class (keys(%$REGISTERED_ATTRIBUTE_HANDLER)) {
		next if($REGISTERED_ATTRIBUTE_HANDLER->{$handler_class});
		Fukurama::Class::AttributesHandler->register_attributes($handler_class);
		
		no strict 'refs';
		
		my $inheritation_sub = *{$handler_class . '::' . $INHERIT_METHOD_NAME}{'CODE'};
		$INHERITATION_CHECK_SUBS->{$handler_class} = $inheritation_sub;
		$REGISTERED_ATTRIBUTE_HANDLER->{$handler_class} = 1;
	}
	
	$REGISTERED_CLASSES->{$export_to_class} = 1;
	Fukurama::Class::AttributesHandler->export($export_to_class);
	return;
}
# STATIC void
sub _init {
	my $class = $_[0];
	
	Fukurama::Class::AttributesHandler->register_helper_method($INHERIT_METHOD_NAME);
	return if($CHECK_LEVEL == $LEVEL_CHECK_NONE);
	
	my $CHECK_HANDLER = sub {
		my $classname = $_[0];
		my $classdef = $_[1];
		
		return if($CHECK_LEVEL == $LEVEL_CHECK_NONE);
		__PACKAGE__->_check_inheritation($classname, $classdef);
		return;
	};
	
	Fukurama::Class::Extends->register_class_tree();
	Fukurama::Class::Implements->register_class_tree();
	Fukurama::Class::Tree->register_check_handler($CHECK_HANDLER);
	return;
}
# STATIC void
sub _check_inheritation {
	my $class = $_[0];
	my $classname = $_[1];
	my $classdef= $_[2];
	
	foreach my $inherit_data (@{$class->_get_parent_classes($classname, $classdef)}) {
		my $filtered_inherit_path = $class->_get_registered_parents($inherit_data->{'path'});
		next if(!scalar(@$filtered_inherit_path));
		push(@$filtered_inherit_path, $classname);
		
		my $parent_path = [];
		while(scalar(@$filtered_inherit_path) > 1) {
			my $parent = shift(@$filtered_inherit_path);
			my $child = $filtered_inherit_path->[0];
			
			$class->_merge_class_definition($parent, $child, $parent_path, $inherit_data->{'type'});
			push(@$parent_path, $parent);
		}
	}
	return;
}
# STATIC void
sub _merge_class_definition {
	my $class = $_[0];
	my $parent = $_[1];
	my $child = $_[2];
	my $parent_path = $_[3];
	my $inheritation_type = $_[4];
	
	my $parent_methods = {};
	foreach my $parent_class (@$parent_path, $parent) {
		foreach my $parent_method (Fukurama::Class::Tree->get_all_subs($parent_class)) {
			$parent_methods->{$parent_method} = $parent_class;
		}
	}
	
	my $child_methods = {};
	foreach my $child_method (Fukurama::Class::Tree->get_all_subs($child)) {
		$child_methods->{$child_method} = $child;
	}
	
	my @all_methods = (keys(%$child_methods), keys(%$parent_methods));
	my %unique_methods = ();
	@unique_methods{@all_methods} = (1) x scalar(@all_methods);
	
	foreach my $method (keys(%unique_methods)) {
		my $parent_class = $parent_methods->{$method} || $parent;
		foreach my $handler_class (keys(%$INHERITATION_CHECK_SUBS)) {
			&{$INHERITATION_CHECK_SUBS->{$handler_class}}($handler_class, $method, $parent_class, $child, $inheritation_type);
		}
	}
	return;
}
# STATIC string[]
sub _get_parent_classes {
	my $class = $_[0];
	my $check_class = $_[1];
	my $classdef = $_[2];
	
	my @all_paths = ();
	foreach my $type (keys(%$classdef)) {
		foreach my $inherit_path (@{$classdef->{$type}}) {
			push(@all_paths, {
				type	=> $type,
				path	=> $inherit_path,
			});
		}
	}
	return \@all_paths;
}
# STATIC string[]
sub _get_registered_parents {
	my $class = $_[0];
	my $path = $_[1];
	
	my @filtered_path = ();
	my $was_registered = 0;
	foreach my $parent (reverse(@$path)) {
		next if(!$was_registered && !$REGISTERED_CLASSES->{$parent});
		$was_registered = 1;
		push(@filtered_path, $parent);
	}
	return \@filtered_path;
}
# STATIC void
sub run_check {
	Fukurama::Class::AttributesHandler->run_check();
}

no warnings 'void'; # avoid 'Too late to run CHECK/INIT block'

# AUTOMAGIC
CHECK {
	Fukurama::Class::AttributesHandler->run_check();
}
# AUTOMAGIC
END {
	Fukurama::Class::AttributesHandler->run_check();
}
1;
