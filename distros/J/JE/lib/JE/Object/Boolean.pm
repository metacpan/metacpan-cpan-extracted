package JE::Object::Boolean;

our $VERSION = '0.066';


use strict;
use warnings;

our @ISA = 'JE::Object';

use Scalar::Util 'blessed';

require JE::Code;
require JE::Boolean;
require JE::Object::Error::TypeError;
require JE::Object::Function;
require JE::String;

import JE::Code 'add_line_number';
sub add_line_number;

=head1 NAME

JE::Object::Boolean - JavaScript Boolean object class

=head1 SYNOPSIS

  use JE;

  $j = new JE;

  $js_bool_obj = new JE::Object::Boolean $j, 1;

  $perl_bool = $js_bool_obj->value;

  "$js_bool_obj";  # true

=head1 DESCRIPTION

This class implements JavaScript Boolean objects for JE. The difference
between this and JE::Boolean is that that module implements
I<primitive> boolean values, while this module implements the I<objects.>

=head1 METHODS

See L<JE::Types> for descriptions of most of the methods. Only what
is specific to JE::Object::Boolean is explained here.

=over

=cut

sub new {
	my($class, $global, $val) = @_;
	my $self = $class->SUPER::new($global, {
		prototype => $global->prototype_for('Boolean')
		          || $global->prop('Boolean')->prop('prototype')
	});

	$$$self{value} = defined $val
		? defined blessed $val
		  && $val->can('to_boolean')
			? $val->to_boolean->[0]
			: !!$val
		: !1;
	$self;
}


=item value

Returns a Perl scalar, either 1 or the empty string (well, actually !1).

=cut

sub value { $${$_[0]}{value} }


sub class { 'Boolean' }


sub _new_constructor {
	my $global = shift;
	my $f = JE::Object::Function->new({
		name            => 'Boolean',
		scope            => $global,
		argnames         => [qw/value/],
		function         => sub {
			defined $_[0] ? $_[0]->to_boolean :
				JE::Boolean->new($global, 0);
		},
		function_args    => ['args'],
		constructor      => sub {
			unshift @_, __PACKAGE__;
			goto &new;
		},
		constructor_args => ['scope','args'],
	});

	my $proto = bless $f->prop({
		name    => 'prototype',
		dontenum => 1,
		readonly => 1,
	}), __PACKAGE__;
	$global->prototype_for('Boolean',$proto);

	$$$proto{value} = !1;
	
	$proto->prop({
		name  => 'toString',
		value => JE::Object::Function->new({
			scope  => $global,
			name    => 'valueOf',
			no_proto => 1,
			function_args => ['this'],
			function => sub {
				my $self = shift;
				die JE::Object::Error::TypeError->new(
					$global, add_line_number
					"Argument to " .
					"Boolean.prototype.toString is not"
					. " a " .
					"Boolean object"
				) unless $self->class eq 'Boolean';

				return JE::String->_new($global,
					qw/false true/[$self->value]);
			},
		}),
		dontenum => 1,
	});

	$proto->prop({
		name  => 'valueOf',
		value => JE::Object::Function->new({
			scope  => $global,
			name    => 'valueOf',
			no_proto => 1,
			function_args => ['this'],
			function => sub {
				my $self = shift;
				die JE::Object::Error::TypeError->new(
					$global, add_line_number
					"Argument to " .
					"Boolean.prototype.valueOf is not"
					. " a " .
					"Boolean object"
				) unless $self->class eq 'Boolean';

				return JE::Boolean->new($global,
					$$$self{value});
			},
		}),
		dontenum => 1,
	});


	$f;
}

return "a true value";

=back

=head1 SEE ALSO

=over 4

=item JE

=item JE::Types

=item JE::Object

=item JE::Boolean

=back

=cut




