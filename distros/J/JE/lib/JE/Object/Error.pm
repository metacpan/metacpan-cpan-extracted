package JE::Object::Error;

our $VERSION = '0.066';


use strict;
use warnings;

our @ISA = 'JE::Object';

require JE::Object;
require JE::String;


# ~~~ Need to add support for line number, script name, etc., or perhaps
#     just a reference to the corresponding JE::Code object.

=head1 NAME

JE::Object::Error - JavaScript Error object class

=head1 SYNOPSIS

  use JE::Object::Error;

  # Somewhere in code called by an eval{}
  die new JE::Object::Error $global, "(Error message here)";

  # Later:
  $@->prop('message');  # error message
  $@->prop('name');     # 'Error'
  "$@";                 # 'Error: ' plus the error message

=head1 DESCRIPTION

This class implements JavaScript Error objects for JE. This is the base
class for all JavaScript's native error objects. (See L<SEE ALSO>, below.)

=head1 METHODS

See L<JE::Types> for descriptions of most of the methods. Only what
is specific to JE::Object::Error is explained here.

The C<value> method returns the string S<'Error: '> followed by the error
message. 'Error' will be replaced with the class name (the result of 
calling
C<< ->class >>) for subclasses. 

=cut

sub new {
	my($class, $global, $val) = @_;
	my($js_class) = $class->name;
	my $self = $class->SUPER::new($global, { 
		prototype => $global->prototype_for($js_class) ||
			$global->prop($js_class)->prop('prototype')
	});

	$self->prop({
		dontenum => 1,
		name => 'message',
		value => JE::String->_new($global, $val),
	}) if defined $val and ref $val ne 'JE::Undefined';
	$self;
}

sub value { $_[0]->method('toString')->value }

sub class { 'Error' }
*name = *class;

sub _new_constructor {
	my $global = shift;
	my $con = sub {
			__PACKAGE__->new(@_);
	};
	my $args = ['scope','args'];
	my $f = JE'Object'Function->new({
		name             => 'Error',
		scope            => $global,
		argnames         => ['message'],
		function         => $con,
		function_args    => $args,
		constructor      => $con,
		constructor_args => $args,
	});

	my $proto = bless $f->prop({
	 name => 'prototype', dontenum => 1, readonly => 1
	});
	
	$global->prototype_for('Error',$proto);
	$proto->prop({
				name  => 'toString',
				value => JE::Object::Function->new({
					scope  => $global,
					name   => 'toString',
					length => 0,
					function_args => ['this'],
					function => sub {
						my $self = shift;
						JE::String->_new(
							$$$self{global},
							$self->prop(
							 'name'
							) .
							': ' .
							$self->prop(
								'message'							)
						);
					}
				}),
				dontenum => 1,
	});
	$proto->prop({
				name  => 'name',
				value => JE::String->_new($global, 'Error'),
				dontenum => 1,
	});
	$proto->prop({
				name  => 'message',
				value => JE::String->_new($global,
					'Unknown error'),
				dontenum => 1,
	});

	weaken $global;
	$f
}

sub _new_subclass_constructor {
	my($package,$global) = @_;

	my $f = JE::Object::Function->new({
		name             => my $name = $package->name,
		scope            => $global,
		argnames         => ['message'],
		function         =>(sub { $package->new(@_) },
		function_args    => ['scope','args'],
		constructor      => #  "
		constructor_args => #  "
		                   )[ 0..3,0,4,2 ],
	});

	my $proto = $f->prop({
		name    => 'prototype',
		dontenum => 1,
		readonly => 1,
	});
	$global->prototype_for($name=>$proto);
	bless $proto, $package;
	$proto->prototype(
			   $global->prototype_for('Error')
			|| $global->prop('Error')->prop('prototype')
	);
	$proto->prop({
				name  => 'name',
				value => JE::String->_new($global, $name),
				dontenum => 1,
	});
	(my $msg = $name) =~ s/(?!^)([A-Z])(?![A-Z])/ \l$1/g;
	$proto->prop({
				name  => 'message',
				value => JE::String->_new($global, $msg),
				dontenum => 1,
	});

	weaken $global;
	$f;
}


return "a true value";

=head1 SEE ALSO

=over 4

=item L<JE>

=item L<JE::Object>

=item L<JE::Object::Error::RangeError>

=item L<JE::Object::Error::SyntaxError>

=item L<JE::Object::Error::TypeError>

=item L<JE::Object::Error::URIError>

=item L<JE::Object::Error::ReferenceError>

=back

=cut




