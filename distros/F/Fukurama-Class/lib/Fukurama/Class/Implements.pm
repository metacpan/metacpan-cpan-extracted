package Fukurama::Class::Implements;
use Fukurama::Class::Version(0.02);
use Fukurama::Class::Rigid;
use Fukurama::Class::Carp;
use Fukurama::Class::Tree();

our $LEVEL_DISABLE				= 0;
our $LEVEL_CHECK_NONE			= 1;
our $LEVEL_CHECK_ALL			= 2;

our $CHECK_LEVEL = $LEVEL_CHECK_ALL;

my $ERRORS = {};
my $ISA_ALREADY_DECORATED;
my $REGISTER = {};

=head1 NAME

Fukurama::Class::Implements - Pragma to provide interfaces

=head1 VERSION

Version 0.02 (beta)

=head1 SYNOPSIS

 package MyClass;
 use Fukurama::Class::Implements('MyParent');

=head1 DESCRIPTION

This pragma-like module enables te possibility to use interfaces (like in java). The implementation
of all subroutines (except perls speacials) will be checked at compiletime. Your package won't inherit
from this interface but every isa() will say that it is. Use Fukurama::Class instead, to get all the
features for OO.

=head1 CONFIG

You can define the check-level which describes how the module will check implementations.
The following levels are allowed:

=over 4

=item DISABLE (0)

There is no check and no change in UNIVERSAL. If you use this level, it's like you remove this module.
There are no side effects. You should only use this, if you never use the isa() method to check for interfaces.

=item CHECK_NONE (1)

All Registration-Processes are executed and UNIVERSAL::isa would be decorated, but there would be no check.
This level is recommended for production.

=item CHECK_ALL (2)

All Classes would checked for implementation. This is the default behavior when you does'n change the
check-level.

=back

=head1 EXPORT

=over 4

=item UNIVERSAL::isa

would be decorated

=back

=head1 METHODS

=over 4

=item implements( child_class:STRING, interface_class:STRING ) return:VOID

Helper-method, which would executed by every pragma usage.

=item run_check() return:VOID

Helper method for static perl (see Fukurama::Class > BUGS)

=item register_class_tree() return:VOID

Helper method to register needed handler in Fukurama::Class::Tree

=back

=head1 AUTHOR, BUGS, SUPPORT, ACKNOWLEDGEMENTS, COPYRIGHT & LICENSE

see perldoc of L<Fukurama::Class>

=cut

# void
my $BUILD_HANDLER = sub {
	my $classname = $_[0];
	my $classdef = $_[1];
	
	my $interface_def = $REGISTER->{$classname};
	return if(!$interface_def);
	
	my $inheritation_paths = [];
	foreach my $interface (keys(%$interface_def)) {
		my $interface_inheritation_paths = Fukurama::Class::Tree->get_inheritation_path($interface);
		foreach my $path (@$interface_inheritation_paths) {
			unshift(@$path, $interface);
			push(@$inheritation_paths, $path);
		}
		push(@$inheritation_paths, [$interface]) if(!scalar(@$interface_inheritation_paths));
	}
	$classdef->{'implements'} = $inheritation_paths if(scalar(@$inheritation_paths));
	return;
};
# void
my $CHECK_HANDLER = sub {
	my $classname = $_[0];
	my $classdef = $_[1];
	
	return if($CHECK_LEVEL <= $LEVEL_CHECK_NONE);
	my $paths = $classdef->{'implements'};
	return if(ref($paths) ne 'ARRAY');
	
	my $interface_list = {};
	foreach my $path (@$paths) {
		my $level = 0;
		foreach my $class (@$path) {
			++$level;
			$interface_list->{$class} ||= ($level == 1 ? 1 : 0);
		}
	}
	__PACKAGE__->_check_implementations($classname, $interface_list);
	return;
};
# AUTOMAGIC void
sub import {
	my $class = $_[0];
	my $interface = $_[1];
	my $import_depth = $_[2];
	
	$import_depth ||= 0;
	my $child = [caller($import_depth)]->[0];
	$class->implements($child, $interface);
	return undef;
}
# void
sub implements {
	my $class = $_[0];
	my $child = $_[1];
	my $interface = $_[2];
	
	return if($CHECK_LEVEL == $LEVEL_DISABLE);

	no strict 'refs';

	$class->_decorate_isa();
	if(!%{"$interface\::"} && !eval("use $interface();return 1")) {
		_croak($@);
	}
	$REGISTER->{$child} ||= {};
	$REGISTER->{$child}->{$interface} = undef;
	$class->register_class_tree();
	return;
}
# void
sub register_class_tree {
	my $class = $_[0];
	
	Fukurama::Class::Tree->register_build_handler($BUILD_HANDLER);
	Fukurama::Class::Tree->register_check_handler($CHECK_HANDLER);
	return;
}
# void
sub run_check {
	my $class = $_[0];
	my $type = $_[1];
	
	return if($CHECK_LEVEL <= $LEVEL_CHECK_NONE);
	$type = 'MANUAL' if(!defined($type));
	
	if($CHECK_LEVEL == $LEVEL_CHECK_ALL) {
		Fukurama::Class::Tree->run_check($type);
	}
	return;
}
# void
sub _check_implementations {
	my $class = $_[0];
	my $checked_class = $_[1];
	my $checked_class_interfaces = $_[2];
	
	my $error_list = [];
	my $interface_defs = [];
	my @interfaces = keys(%$checked_class_interfaces);
	foreach my $interface (@interfaces) {
		push(@$interface_defs, {
			class	=> $interface,
			subs	=> [Fukurama::Class::Tree->get_class_subs($interface)],
		});
	}
	my $class_def = {};
	foreach my $sub (Fukurama::Class::Tree->get_class_subs($checked_class)) {
		$class_def->{$sub} = undef;
	}
	$class->_check_class_def($checked_class, $class_def, $interface_defs, $error_list);
	
	if(@$error_list) {
		my $errors = '';
		foreach my $e (@$error_list) {
			my $key = $e->{'class'} . '-' . $e->{'method'};
			next if($ERRORS->{$key});
			$errors .= "\n  > You doesn't implement method '$e->{method}' in class '$e->{class}' which is defined in interface(es): " .
				join(', ', @{$e->{interfaces}});
			$ERRORS->{$key} = 1;
		}
		_croak(scalar(@$error_list) . " Interface-Error(s):$errors\n", 1) if($errors);
	}
	return;
}
# void
sub _check_class_def {
	my $class = $_[0];
	my $obj_class = $_[1];
	my $class_def = $_[2];
	my $interface_defs = $_[3];
	my $errorlist = $_[4];
	
	my $interface_methods = $class->_merge_interface_methods($interface_defs);
	foreach my $method (keys %$interface_methods) {
		$class->_check_method_implementation($obj_class, $method, exists($class_def->{$method}), $interface_methods->{$method}, $errorlist);
	}
	return;
}
# void
sub _check_method_implementation {
	my $class = $_[0];
	my $obj_class = $_[1];
	my $method = $_[2];
	my $class_method_exist = $_[3];
	my $interface_method_list = $_[4];
	my $error_list = $_[5];
	
	if(!$class_method_exist) {
		my $definitions = [];
		foreach my $interface (@$interface_method_list) {
			push(@$definitions, $interface);
		}
		push(@$error_list, {
			class		=> $obj_class,
			method		=> $method,
			interfaces	=> $definitions,
		});
	}
	return;
}
# hash[]
sub _merge_interface_methods {
	my $class = $_[0];
	my $interface_defs = $_[1];
	
	my $methodnames = {};
	foreach my $def (@$interface_defs) {
		foreach my $method (@{$def->{'subs'}}) {
			$methodnames->{$method} ||= [];
			push(@{$methodnames->{$method}}, $def->{'class'});
		}
	}
	return $methodnames;
}
# string{}
sub _has_interface {
	my $class = $_[0];
	my $obj_class = $_[1];
	my $interface_class = $_[2];
	
	return 0 if(!defined($obj_class));
	my $interfaces = $REGISTER->{$obj_class};
	return 0 if(!$interfaces || !exists($interfaces->{$interface_class}));
	return 1;
}
# void
sub _decorate_isa {
	my $class = $_[0];
	
	no strict 'refs';
	no warnings 'redefine';
	
	return if($ISA_ALREADY_DECORATED);
	
	my $identifier = 'UNIVERSAL::isa';
	my $old = *{$identifier}{'CODE'};
	die("Unable to decorate non existing sub $identifier") if(!$old);
	
	*{$identifier} = sub {
		my $obj_class = $_[0];
		my $type = $_[1];
		
		return 1 if($class->_has_interface($obj_class, $type));
		
		goto &$old;
	};
	$ISA_ALREADY_DECORATED = 1;
	return;
}

no warnings 'void'; # avoid 'Too late to run CHECK/INIT block'

# AUTOMAGIC void
sub CHECK {
	__PACKAGE__->run_check('CHECK');
}
# AUTOMAGIC void
sub END {
	__PACKAGE__->run_check('END');
}
1;
