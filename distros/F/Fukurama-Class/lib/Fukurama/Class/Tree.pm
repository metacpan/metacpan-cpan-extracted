package Fukurama::Class::Tree;
use Fukurama::Class::Version(0.03);
use Fukurama::Class::Rigid;
use Fukurama::Class::Carp;

my $CHECK = {};
my $BUILD = {};
my $IS_BUILD = 0;
my $EXEC_ONCE = {};
my $CLASSTREE = {};

my $FORBID_SUB_TYPES = ['system', 'tie', 'thread'];
my $FORBIDDEN_SUBS = {
	system	=> {
		import						=> 1,
		unimport					=> 1,
		can							=> 1,
		isa							=> 1,
		VERSION						=> 1,
		BEGIN						=> 1,
		UNITCHECK					=> 1,
		CHECK						=> 1,
		INIT						=> 1,
		END							=> 1,
		DESTROY						=> 1,
		AUTOLOAD					=> 1,
		MODIFY_CODE_ATTRIBUTES		=> 1,
		MODIFY_SCALAR_ATTRIBUTES	=> 1,
		MODIFY_ARRAY_ATTRIBUTES		=> 1,
		MODIFY_HASH_ATTRIBUTES		=> 1,
		MODIFY_GLOB_ATTRIBUTES		=> 1,
		FETCH_CODE_ATTRIBUTES		=> 1,
		FETCH_SCALAR_ATTRIBUTES		=> 1,
		FETCH_ARRAY_ATTRIBUTES		=> 1,
		FETCH_HASH_ATTRIBUTES		=> 1,
		FETCH_GLOB_ATTRIBUTES		=> 1,
	},
	thread	=> {
		CLONE		=> 1,
		CLONE_SKIP	=> 1,
	},
	tie	=> {
		TIESCALAR	=> 1,
		FETCH		=> 1,
		STORE		=> 1,
		UNTIE		=> 1,
		TIEARRAY	=> 1,
		FETCHSIZE	=> 1,
		STORESIZE	=> 1,
		EXTEND		=> 1,
		EXISTS		=> 1,
		DELETE		=> 1,
		CLEAR		=> 1,
		PUSH		=> 1,
		POP			=> 1,
		SHIFT		=> 1,
		UNSHIFT		=> 1,
		SPLICE		=> 1,
		TIEHASH		=> 1,
		FIRSTKEY	=> 1,
		NEXTKEY		=> 1,
		SCALAR		=> 1,
		TIEHANDLE	=> 1,
		WRITE		=> 1,
		PRINT		=> 1,
		PRINTF		=> 1,
		READ		=> 1,
		READLINE	=> 1,
		GETC		=> 1,
		CLOSE 		=> 1,
	},
};
=head1 NAME

Fukurama::Class::Tree - Helper-class to register class-handler

=head1 VERSION

Version 0.03 (beta)

=head1 SYNOPSIS

 my $BUILD_HANDLER = sub {
 	my $classname = $_[0];
 	my $classdef = $_[1];
 
	no strict 'refs';
	 
 	$classdef->{'implements'} = \@{$classname . '::INTERFACES'};
 	return;
 };
 my $CHECK_HANDLER = sub {
 	my $classname = $_[0];
 	my $classdef = $_[1];
 
 	my $paths = $classdef->{'implements'};
 	return if(ref($paths) ne 'ARRAY');
	# Do what ever you want (for interfaces, see Fukurama::Class::Implements)
	# ...
	return;
 };
 Fukurama::Class::Tree->register_build_handler($BUILD_HANDLER);
 Fukurama::Class::Tree->register_check_handler($CHECK_HANDLER);

=head1 DESCRIPTION

This module register class-definitions, read the inheritation-trees and execute checks to the registered class-defintions.
You can register handler to create you own class defintions and handler to check something at this classes.
It's a central helper class for most of Fukurama::Class - modules.

=head1 CONFIG

-
 
=head1 EXPORT

-

=head1 METHODS

=over 4

=item get_all_subs( class:STRING ) return:STRING()

Get all methods from the given class.

=item get_class_subs( class:STRING ) return:STRING[]

Get all methods for the given class. It omit all special-methods. See is_special_sub().

=item get_inheritation_path( class:STRING ) return:[ STRING[] ]

Return all inheritation class-paths for the given class.
For example, if a class B<MyClass> (multiple-)inherit from B<ParentA> and B<ParentB>, it will return these two inheritation-class-paths.
If the given class doesn't use any multi inheritation, you will get an arrayref with one classpath and these classpath will be
an array of all parents and grandparents etc. the given class. 

=item is_special_sub( subname:STRING ) return:BOOLEAN

Check, if the given subroutine(-name) is from an special method which is used perl "magically".
For example it returns true for I<import()>, I<unimport()>, I<DESTROY()> etc.

=item register_build_handler( handler:CODE ) return:VOID

Register a handler subroutine to build your own class-defintion. For example you can implement an own syntax to define
interface-implementations. The build-handler takes two parameters: the name and the definition-hash (which you can extend)
for each loaded class.

=item register_check_handler( handler:CODE ) return:VOID

Register a handler subroutine to check the classes. For example you can check an self-defined interface syntax. The check-handler
takes two parameters: the name and the definition-hash, which was build via bild-handler, for each loaded class.

=item run_check() return:VOID

Helper method for static perl (see Fukurama::Class > BUGS)
This method will find all loades classes, run all registered build-handler for each loaded class and, when this is finished,
it runs all registered check-handler (even for each loaded class).

=back

=head1 AUTHOR, BUGS, SUPPORT, ACKNOWLEDGEMENTS, COPYRIGHT & LICENSE

see perldoc of L<Fukurama::Class>

=cut

# void
sub run_check {
	my $class = $_[0];
	my $type = $_[1];
	
	$type = 'MANUAL' if(!defined($type));
	
	return if($EXEC_ONCE->{$type});
	$class->_build();
	$class->_check();
	$EXEC_ONCE->{$type} = 1;
	return;
}
# void
sub register_build_handler {
	my $class = $_[0];
	my $handler = $_[1];
	
	_croak("Can only register subrefs as handler, not '$handler'") if(ref($handler) ne 'CODE');
	$BUILD->{int($handler)} = $handler;
	return;
}
# void
sub register_check_handler {
	my $class = $_[0];
	my $handler = $_[1];
	
	_croak("Can only register subrefs as handler, not '$handler'") if(ref($handler) ne 'CODE');
	$CHECK->{int($handler)} = $handler;
	return;
}
# void
sub _build {
	my $class = $_[0];
	
	no warnings 'recursion';
	
	$CLASSTREE = {};
	$class->_read_class('', $CLASSTREE);
	$IS_BUILD = 1;
	
	return;
}
# void
sub _read_class {
	my $class = $_[0];
	my $parent_class = $_[1];
	my $classtree = $_[2];
	
	no strict 'refs';
	
	foreach my $child_class (keys %{$parent_class . '::'}) {
		my $classname = ($parent_class . '::' . $child_class);
		$classname =~ s/^(?:::)(?:main|)//;
		$classname =~ s/::$//;
		next if(!UNIVERSAL::isa($classname, $classname) || $classname =~ m/[^a-zA-Z0-9_:]/);
		next if($classtree->{$classname});
		
		$classtree->{$classname} = {};
		foreach my $build_handler (values(%$BUILD)) {
			&$build_handler($classname, $classtree->{$classname});
		}
		$class->_read_class($classname, $classtree);
	}
	return;
}
# void
sub _check {
	my $class = $_[0];
	
	_croak("Can't check classtree without build!") if(!$IS_BUILD);
	foreach my $class (keys(%$CLASSTREE)) {
		foreach my $check_handler (values(%$CHECK)) {
			&$check_handler($class, $CLASSTREE->{$class});
		}
	}
	return;
}
# string()
sub get_class_subs {
	my $class = $_[0];
	my $used_class = $_[1];
	
	return grep { !$class->is_special_sub($_) } $class->get_all_subs($used_class);
}
# string ()
sub get_all_subs {
	my $class = $_[0];
	my $used_class = $_[1];
	
	no strict 'refs';
	
	my $subs = {};
	foreach my $glob (%{$used_class . '::'}) {
		next if((ref($glob) && ref($glob) ne 'GLOB') || !*$glob{'CODE'});
		$subs->{*$glob{'NAME'}} = undef;
	}
	return keys(%$subs);
}
# boolean
sub is_special_sub {
	my $class = $_[0];
	my $subname = $_[1];
	
	foreach my $type (@$FORBID_SUB_TYPES) {
		return 1 if($FORBIDDEN_SUBS->{$type}->{$subname});
	}
	return 0;
}
# void
sub _get_inheritation_path {
	my $class = $_[0];
	my $child = $_[1];
	my $child_path = $_[2];
	my $all_path_routes = $_[3];

	no strict 'refs';
	
	my $parents = \@{$child . '::ISA'};
	if(!scalar(@$parents)) {
		push(@$all_path_routes, [@$child_path]) if(scalar(@$child_path));
		return;
	}
	
	foreach my $parent (@$parents) {
		my $class_allways_in_path = grep({ $_ eq $parent } @$child_path);
		next if($class_allways_in_path);
		$class->_get_inheritation_path($parent, [@$child_path, $parent], $all_path_routes);
	}
	return;
}
# array[]
sub get_inheritation_path {
	my $class = $_[0];
	my $child_class = $_[1];
	
	return [] if(!$child_class);
	my $all_path_routes = [];
	$class->_get_inheritation_path($child_class, [], $all_path_routes);
	return $all_path_routes;
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
