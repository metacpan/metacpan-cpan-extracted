package Fukurama::Class::HideCaller;
use Fukurama::Class::Version(0.01);
use Fukurama::Class::Rigid;
use Fukurama::Class::Carp;

my $IS_DECORATED = undef;
our $REGISTER = {};
our $DISABLE;
my $USAGE_ERROR;

=head1 NAME

Fukurama::Class::HideCaller - Pragma to hide wrapper-classes in callers stack

=head1 VERSION

Version 0.01 (beta)

=head1 SYNOPSIS

 package MyWrapperClass;
 use Fukurama::Class::HideCaller('MyWrapperClass');
 
 sub wrap_around_test {
 	my $sub = \&MyClass::test;
 	no warnings;
 	*MyClass::test = sub {
	 	print "before, ";
	 	&{$sub}(@_);
	 	print "after";
 	}
 }
 
 package MyClass;
 sub test {
 	no warnings;
 	print "middle, caller: " . [caller(0)]->[0] . ", ";
 }
 
 package main;
 MyWrapperClass->wrap_around_test();
 MyClass->test();
 # will print: before, middle, caller: main, after
 # without the HideCaller, it will print: before, middle, caller: MyWrapper, after

=head1 DESCRIPTION

This pragma-like module provides functions to hide a wrapper-class in callers stack. It's a helper class
to provide parameter and return value checking without changings in any caller stack.

=head1 CONFIG

You can disable the whole behavior of this class by setting

 $Fukurama::Class::HideCaller::DISABLE = 1;
 
=head1 EXPORT

=over 4

=item CORE::GLOBAL::caller

would be decorated

=back

=head1 METHODS

=over 4

=item register_class( hidden_wrapper_class:STRING ) return:VOID

Register a wrapper class to competely hide in caller stack.

=back

=head1 AUTHOR, BUGS, SUPPORT, ACKNOWLEDGEMENTS, COPYRIGHT & LICENSE

see perldoc of L<Fukurama::Class>

=cut

# AUTOMAGIC void
sub import {
	my $class = $_[0];
	my $hidden_class = $_[1];
	
	if(!$IS_DECORATED) {
		$class->_decorate_caller();
		$IS_DECORATED = 1;
	}
	$class->register_class($hidden_class) if(defined($hidden_class));
	return;
}
# void
sub register_class {
	my $class = $_[0];
	my $hidden_class = $_[1];
	
	if(!$IS_DECORATED && !$USAGE_ERROR) {
		$USAGE_ERROR = 1;
		_croak("Wrong usage: you have to say\n\t'use " . __PACKAGE__ . ";' or\n\t'use " . __PACKAGE__ . "('CLASSNAME')'");
	}
	if(!UNIVERSAL::isa($hidden_class, $hidden_class)) {
		_croak("Class '$hidden_class' is not a valid class");
	}
	$REGISTER->{$hidden_class} = 1;
	return;
}
# AUTOMAGIC void
END {
	
	if(!$DISABLE && !$IS_DECORATED && !$USAGE_ERROR) {
		$USAGE_ERROR = 1;
		_croak("Wrong usage: you have to say\n\t'use " . __PACKAGE__ . ";' or\n\t'use " . __PACKAGE__ . "('CLASSNAME')'");
	}
}
# void
sub _decorate_caller {
	my $class = $_[0];
	
	no strict 'refs';
	
	my $old = *CORE::GLOBAL::caller{'CODE'};
	if($old) {
		
		no warnings 'redefine';
		
		# inspired by Hook::LexWrap code
		*CORE::GLOBAL::caller = sub {
			my $level = $_[0] || 0;
			my $i = 1;
			my $called_sub = undef;
			while(1) {
				my @caller = &$old($i++) or return;
				$caller[3] = $called_sub if($called_sub);
				$called_sub = ((${__PACKAGE__ . '::REGISTER'}->{$caller[0]} && !${__PACKAGE__ . '::DISABLE'}) ? $caller[3] : undef);
				next if($called_sub || $level-- != 0);
				return (wantarray ? (@_ ? @caller : @caller[0..2]) : $caller[0]);
			}
		};
	} else {
		# inspired by Hook::LexWrap code
		*CORE::GLOBAL::caller = sub {
			my $level = $_[0] || 0;
			my $i = 1;
			my $called_sub = undef;
			while(1) {
				my @caller = CORE::caller($i++) or return;
				$caller[3] = $called_sub if($called_sub);
				$called_sub = ((${__PACKAGE__ . '::REGISTER'}->{$caller[0]} && !${__PACKAGE__ . '::DISABLE'}) ? $caller[3] : undef);
				next if($called_sub || $level-- != 0);
				return (wantarray ? (@_ ? @caller : @caller[0..2]) : $caller[0]);
			}
		};
	}
	return;
}
1;
