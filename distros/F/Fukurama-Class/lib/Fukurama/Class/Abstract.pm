package Fukurama::Class::Abstract;
use Fukurama::Class::Version(0.01);
use Fukurama::Class::Rigid;
use Fukurama::Class::Carp;
use Fukurama::Class::Tree();

my $CLASS = {};
my $DECORATED_SUBS = {};
our $DISABLE = 0;

=head1 NAME

Fukurama::Class::Abstract - Pragma to provide abstract classes

=head1 VERSION

Version 0.01 (beta)

=head1 SYNOPSIS

 package MyClass;
 use Fukurama::Class::Abstract;

=head1 DESCRIPTION

This pragma-like module provides functions to check the usage of all class-methods. All calls from childs,
which inherits from this class are ok, all other will croak at runtime.
Use Fukurama::Class instead, to get all the features for OO.

=head1 CONFIG

You can disable the whole behavior of this class by setting

 $Fukurama::Class::Abstract::DISABLE = 1;
 
=head1 EXPORT

All methods of your abstract class would be decorated with a caller-check method.

=head1 METHODS

=over 4

=item abstract( abstract_class:STRING ) return:VOID

Set the given class as abstract.

=item run_check( ) return:VOID

Helper method for static perl (see Fukurama::Class > BUGS)
This method decorates all non-special subroutines in the registered, abstract classes
that all calls would be checked.

=back

=head1 AUTHOR, BUGS, SUPPORT, ACKNOWLEDGEMENTS, COPYRIGHT & LICENSE

see perldoc of L<Fukurama::Class>

=cut

# AUTOMAGIC void
sub import {
	my $class = $_[0];
	
	my ($caller_class) = caller(0);
	$class->abstract($caller_class);
	return undef;
}
# STATIC void
sub abstract {
	my $class = $_[0];
	my $caller_class = $_[1];
	
	$CLASS->{$caller_class} = undef;
	return 1;
}
# STATIC void
sub run_check {
	my $class = $_[0];
	
	return if($DISABLE);
	foreach my $obj_class (keys(%$CLASS)) {
		foreach my $identifier (@{$class->_get_subs($obj_class)}) {
			$class->_decorate_sub($obj_class, $identifier);
		}
	}
	return;
}
# STATIC void
sub _decorate_sub {
	my $class = $_[0];
	my $obj_class = $_[1];
	my $identifier = $_[2];
	
	return if(exists($DECORATED_SUBS->{$identifier}));
	my ($subname) = $identifier =~ m/([^:]+)$/;
	return if(Fukurama::Class::Tree->is_special_sub($subname));
	
	no strict 'refs';
	no warnings 'redefine';
	
	my $old = *{$identifier}{CODE};
	*{$identifier} = sub {
		my $used_obj = ref($_[0]) || $_[0];
		
		if(!$used_obj || $used_obj eq $obj_class || !UNIVERSAL::isa($used_obj, $obj_class)) {
			$class->_throw_error($used_obj, $obj_class, $identifier);
		}
		goto $old;
	};
	
	$DECORATED_SUBS->{$identifier} = undef;
	return;
}
# STATIC void
sub _throw_error {
	my $class = $_[0];
	my $obj_class = $_[1];
	my $caller_class = $_[2];
	my $identifier = $_[3];
	
	$obj_class = '' if(!defined($obj_class));
	_croak("Abstract class '$obj_class' used in class '$caller_class'. Sub '$identifier' called.", 2);
	return;
}
# STATIC array
sub _get_subs {
	my $class = $_[0];
	my $obj_class = $_[1];
	
	no strict 'refs';
	
	my $subs = [];
	foreach my $name (%{$obj_class . '::'}) {
		my $identifier = $obj_class . '::' . $name;
		next if(!*{$identifier}{'CODE'});
		push(@$subs, $identifier);
	}
	return $subs;
}

no warnings 'void'; # avoid 'Too late to run CHECK/INIT block'

# AUTOMAGIC void
CHECK {
	__PACKAGE__->run_check();
}
1;
