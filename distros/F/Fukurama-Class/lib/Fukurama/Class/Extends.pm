package Fukurama::Class::Extends;
use Fukurama::Class::Version(0.01);
use Fukurama::Class::Rigid;
use Fukurama::Class::Carp;
use Fukurama::Class::Tree();

our $LEVEL_DISABLE				= 0;
our $LEVEL_CHECK_NONE			= 1;
our $LEVEL_CHECK_REGISTERED		= 2;
our $LEVEL_CHECK_CHILDS			= 3;
our $LEVEL_CHECK_ALL			= 4;

our $CHECK_LEVEL = $LEVEL_CHECK_CHILDS;

my $REGISTER = {};
my $ERRORS = {};

=head1 NAME

Fukurama::Class::Extends - Pragma to extend class inheritation

=head1 VERSION

Version 0.01 (beta)

=head1 SYNOPSIS

 package MyClass;
 use Fukurama::Class::Extends('MyParent');

=head1 DESCRIPTION

This pragma-like module provides some extra check features for inheritation at compiletime.
It would check that your parent Module is loaded and that in multi-inheritation there is no
subroutine-conflict. Use Fukurama::Class instead, to get all the features for OO.

=head1 CONFIG

You can define the check-level which describes how the module will check inheritations.
The following levels are allowed:

=over 4

=item $Fukurama::Class::Extends::CHECK_LEVEL = $Fukurama::Class::Extends::LEVEL_DISABLE

There is no check. If you use this level, it's like you use B<use base qw(...)>. There are no side effects.
This level is recommended for production.

=item $Fukurama::Class::Extends::CHECK_LEVEL = $Fukurama::Class::Extends::LEVEL_CHECK_NONE

All registration processes are executed, but there would be no check.

=item $Fukurama::Class::Extends::CHECK_LEVEL = $Fukurama::Class::Extends::LEVEL_CHECK_REGISTERED

All classes, which use this module would checked for Multi-inheritation-conflicts.

=item $Fukurama::Class::Extends::CHECK_LEVEL = $Fukurama::Class::Extends::LEVEL_CHECK_CHILDS

All classes, which use this module AND all childs of these classes would checked for Multi-inheritation-conflicts.
This is the default behavior when you does'n change the check-level.

=item $Fukurama::Class::Extends::CHECK_LEVEL = $Fukurama::Class::Extends::LEVEL_CHECK_ALL

All classes would checked for Multi-inheritation-conflicts. This means really ALL classes. Even all perl-internals.
This level is only for the sake of completeness.

=back

=head1 EXPORT

-

=head1 METHODS

=over 4

=item extends( child_class:STRING, childs_parent_class:STRING ) return:VOID

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
	
	my $inheritation_paths = Fukurama::Class::Tree->get_inheritation_path($classname);
	$classdef->{'extends'} = $inheritation_paths if(scalar(@$inheritation_paths));
	return;
};
# void
my $CHECK_HANDLER = sub {
	my $classname = $_[0];
	my $classdef = $_[1];
	
	my $paths = $classdef->{'extends'};
	return if(ref($paths) ne 'ARRAY' || !__PACKAGE__->_check_this_class($classname, $paths));
	
	my $parent_path_subs = [];
	foreach my $path (@$paths) {
		my $path_subs = __PACKAGE__->_get_all_subs_for_classpath($path);
		push(@$parent_path_subs, {
			subs	=> $path_subs,
			path	=> $path,
		});
	}
	my $all_subs = {};
	foreach my $entry (@$parent_path_subs) {
		foreach my $subname (keys(%{$entry->{'subs'}})) {
			if($all_subs->{$subname} && !__PACKAGE__->_is_same_sub($subname, $entry->{'subs'}->{$subname}, $all_subs->{$subname}->{'subs'}->{$subname})) {
				my $other_entry = $all_subs->{$subname};
				my $ident = "$classname\::$entry->{'subs'}->{$subname}";
				next if($ERRORS->{$ident});
				_carp("Multi-inheritation-warning for class '$classname':\n" .
					"  > sub '$subname' is defined twice in parent-classes\n" .
					"  > '$entry->{'subs'}->{$subname}' and '$other_entry->{'subs'}->{$subname}'\n" .
					"    > inheritation-path for '$entry->{'subs'}->{$subname}':\n" .
					"        $classname > " . join(' > ', @{$entry->{'path'}}) . "\n" .
					"    > inheritation-path for '$other_entry->{'subs'}->{$subname}':\n" .
					"        $classname > " . join(' > ', @{$other_entry->{'path'}}) . "\n", 1);
				$ERRORS->{$ident} = 1;
			}
			$all_subs->{$subname} = $entry;
		}
	}
	return;
};
# AUTOMAGIC void
sub import {
	my $class = $_[0];
	my $parent = $_[1];
	
	my ($child) = caller(0);
	local $Carp::CarpLevel = $Carp::CarpLevel + 1;
	$class->extends($child, $parent);
	return undef;
}
# void
sub extends {
	my $class = $_[0];
	my $child = $_[1];
	my $parent = $_[2];
	my $import_depth = $_[3] || 0;
	
	local $SIG{'__DIE__'} = sub {};
	
	no strict 'refs';
	
	if($CHECK_LEVEL > $LEVEL_DISABLE) {
		if(!%{"$child\::"} && eval("use $parent();return 1")) {
			_croak($@, $import_depth);
		}
	}
	if(!eval("package $child;use base qw($parent);return 1") || $@) {
		_croak("Can't extend class '$parent' in child class '$child':\n$@", $import_depth);
	}
	
	return if($CHECK_LEVEL == $LEVEL_DISABLE);
	$REGISTER->{$child} = 1;
	$class->register_class_tree();
	return;
}
# STATIC void
sub register_class_tree {
	my $class = $_[0];
	
	Fukurama::Class::Tree->register_build_handler($BUILD_HANDLER);
	Fukurama::Class::Tree->register_check_handler($CHECK_HANDLER);
	return;
}
# STATIC boolean
sub _check_this_class {
	my $class = $_[0];
	my $classname = $_[1];
	my $paths = $_[2];
	
	return 1 if($CHECK_LEVEL == $LEVEL_CHECK_ALL);
	return 0 if($CHECK_LEVEL == $LEVEL_CHECK_NONE);
	
	return 1 if($REGISTER->{$classname});
	return 0 if($CHECK_LEVEL == $LEVEL_CHECK_REGISTERED);
	
	if($CHECK_LEVEL == $LEVEL_CHECK_CHILDS) {
		foreach my $path (@$paths) {
			foreach my $path_class (@$path) {
				return 1 if($REGISTER->{$path_class});
			}
		}
	}
	return 0;
}
# boolean
sub _is_same_sub {
	my $class = $_[0];
	my $subname = $_[1];
	my $first_class = $_[2];
	my $second_class = $_[3];
	
	no strict 'refs';
	
	return 1 if(*{$first_class . '::' . $subname}{'CODE'} == *{$second_class . '::' . $subname}{'CODE'});
	return 0;
}
# hashref
sub _get_all_subs_for_classpath {
	my $class = $_[0];
	my $path = $_[1];
	
	my $path_subs = {};
	foreach my $parent (@$path) {
		foreach my $subname (Fukurama::Class::Tree->get_class_subs($parent)) {
			$path_subs->{$subname} ||= $parent;
		}
	}
	return $path_subs;
}
# void
sub run_check {
	my $class = $_[0];
	my $type = $_[1];
	
	$type = 'MANUAL' if(!defined($type));
	Fukurama::Class::Tree->run_check('CHECK') if($CHECK_LEVEL > $LEVEL_DISABLE);
	return;
}

no warnings 'void'; # avoid 'Too late to run CHECK/INIT block'

# AUTOMAGIC void
CHECK {
	__PACKAGE__->run_check('CHECK');
}
# AUTOMAGIC void
END {
	__PACKAGE__->run_check('END');
}
1;
