package Fukurama::Class::Attributes::OOStandard;
use Fukurama::Class::Version(0.02);
use Fukurama::Class::Rigid;
use Fukurama::Class::Carp();
use Fukurama::Class::Attributes::OOStandard::DefinitionCheck();

my $DEF_CHECK = 'Fukurama::Class::Attributes::OOStandard::DefinitionCheck';
my $SUB_DEF = qr/[a-z \t\n\r]*/;
my $RETURN_DEF = qr/[a-zA-Z_:, \t\n\r\[\]\(\)]*/;
my $PARAM_DEF = qr/[a-zA-Z_:, \t\n\r\[\]\(\)]*/;

my $CONSTRUCTOR_DEF_CHECK = qr/^($SUB_DEF\|$PARAM_DEF;?$PARAM_DEF)$/;
my $METHOD_DEF_CHECK = qr/^($SUB_DEF\|$RETURN_DEF\@?$RETURN_DEF\|$PARAM_DEF;?$PARAM_DEF)$/;

our $LEVEL_CHECK_NONE = 0;
our $LEVEL_CHECK_SYNTAX = 1;
our $LEVEL_CHECK_FORCE_INHERITATION = 2;
our $LEVEL_CHECK_FORCE_ATTRIBUTES = 3;

our $CHECK_LEVEL = $LEVEL_CHECK_FORCE_ATTRIBUTES;
our $DISABLE_RUNTIME_CHECK;

=head1 NAME

Fukurama::Class::Attribute::OOStandard - Plugin for code attributes

=head1 VERSION

Version 0.02 (beta)

=head1 SYNOPSIS

 package MyClass;
 use Fukurama::Class::Attributes;
 
 sub my_sub : Method(static|boolean|string,hashref) {
 	my $class = $_[0];
 	my $string = $_[1];
 	my $hashref = $_[2];
 	
 	return 1;
 }

=head1 DESCRIPTION

This plugin for Fukurama::Class::Attributes provides code attributes to declare and check
method an constructor definitions at compiletime and parameter and return value checks at runtime.

=head1 CONFIG

You can define the check-level which describes how the module will check your declarations for methods and constructors.
The following levels are allowed:

=over 4

=item $Fukurama::Class::Attributes::OOStandard::CHECK_LEVEL = $Fukurama::Class::Attributes::OOStandard::LEVEL_CHECK_NONE

There is no check. This level is recommended for production.

=item $Fukurama::Class::Attributes::OOStandard::CHECK_LEVEL = $Fukurama::Class::Attributes::OOStandard::LEVEL_CHECK_SYNTAX

All registration processes are executed and the definitions of the code attributes would be checked at compiletime.
This level is only for the sake of completeness.

=item $Fukurama::Class::Attributes::OOStandard::CHECK_LEVEL = $Fukurama::Class::Attributes::OOStandard::LEVEL_CHECK_FORCE_INHERITATION

If you define a code attribute at the parent class, you have to define the same or extended in child class. You can only
extend optional parameters and thighten the method access level. All other woud fail at compiletime.

=item $Fukurama::Class::Attributes::OOStandard::CHECK_LEVEL = $Fukurama::Class::Attributes::OOStandard::LEVEL_CHECK_FORCE_ATTRIBUTES

The default behavior. You have to define code attributes for all methods in your class, except perl internals.

=back

The runtime check for parameter and return values can be disabled by saying:

$Fukurama::Class::Attributes::OOStandard::DISABLE_RUNTIME_CHECK = 1;

This is recommended for production.

=head1 EXPORT

-

=head1 METHODS

=over 4

=item Constructor( subroutine_data:\HASH ) return:VOID

Code attribute, which defines a constructor subroutine.

=item Method( subroutine_data:\HASH ) return:VOID

Code Attribute, which defines a method.

=item check_inheritation( method_name:STRING, parent_class:CLASS, child_class:CLASS, inheritation_type:STRING ) return:VOID

Helper method to compare every method declarations for code attributes in your class whith all in the parent methods.

=back

=head1 AUTHOR, BUGS, SUPPORT, ACKNOWLEDGEMENTS, COPYRIGHT & LICENSE

see perldoc of L<Fukurama::Class>

=cut

# STATIC boolean
sub Constructor {
	my $class = $_[0];
	my $sub_data = $_[1];
	
	local $Carp::CarpLevel = $Carp::CarpLevel + 1;
	$DEF_CHECK->set_type('constructor');
	if($sub_data->{'data'} !~ $CONSTRUCTOR_DEF_CHECK) {
		$DEF_CHECK->throw_def_error($sub_data, "constructor syntax is wrong");
	}
	
	my $def = $DEF_CHECK->resolve_def($sub_data);
	my $sub_def = $def->[0]->[0];
	if(!grep({$_->{'data'} eq 'static'} @$sub_def)) {
		push(@$sub_def, {
			'type'	=> '',
			'data'	=> 'static',
		});
	}
	@$sub_def = grep({$_->{'data'} ne ''} @$sub_def);
	my $para_def = $def->[1]->[0];
	my $opt_para_def = $def->[1]->[1];
	my $result_def = [{
		'type'	=> '',
		'data'	=> $sub_data->{'class'},
	}];
	my $array_result_def = [];
	
	my $translated_def = $DEF_CHECK->get_translated_def($sub_data, $def, $sub_def, $result_def, $array_result_def, $para_def, $opt_para_def);
	$DEF_CHECK->try_check_translated_def($sub_data, $translated_def, $def);
	$DEF_CHECK->decorate_sub($translated_def) if(!$DISABLE_RUNTIME_CHECK);
	return 1;
}
# STATIC boolean
sub Method {
	my $class = $_[0];
	my $sub_data = $_[1];
	
	local $Carp::CarpLevel = $Carp::CarpLevel + 1;
	$DEF_CHECK->set_type('method');
	if($sub_data->{'data'} !~ $METHOD_DEF_CHECK) {
		$DEF_CHECK->throw_def_error($sub_data, "method syntax is wrong");
	}
	
	my $def = $DEF_CHECK->resolve_def($sub_data);
	my $sub_def = $def->[0]->[0];
	my $result_def = $def->[1]->[0];
	my $array_result_def = $def->[1]->[1];
	my $para_def = $def->[2]->[0];
	my $opt_para_def = $def->[2]->[1];
	
	my $translated_def = $DEF_CHECK->get_translated_def($sub_data, $def, $sub_def, $result_def, $array_result_def, $para_def, $opt_para_def);
	$DEF_CHECK->try_check_translated_def($sub_data, $translated_def, $def);
	$DEF_CHECK->decorate_sub($translated_def) if(!$DISABLE_RUNTIME_CHECK);
	return 1;	
}
# STATIC void
sub check_inheritation {
	my $class = $_[0];
	my $method_name = $_[1];
	my $parent_class = $_[2];
	my $child_class = $_[3];
	my $inheritation_type = $_[4];
	
	$DEF_CHECK->check_inheritation($method_name, $parent_class, $child_class, $inheritation_type);
	return;
}
1;
