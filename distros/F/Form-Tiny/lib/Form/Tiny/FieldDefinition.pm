package Form::Tiny::FieldDefinition;

use v5.10;
use strict;
use warnings;
use Moo;
use Types::Standard qw(Enum Bool HasMethods CodeRef InstanceOf HashRef);
use Types::Common::String qw(NonEmptySimpleStr);
use Types::TypeTiny qw(StringLike);
use Carp qw(croak);
use Scalar::Util qw(blessed);

use Form::Tiny::Utils qw(try has_form_meta);
use Form::Tiny::Error;
use Form::Tiny::Path;

use namespace::clean;

our $VERSION = '2.08';

has 'name' => (
	is => 'ro',
	isa => NonEmptySimpleStr,
	required => 1,
);

has 'name_path' => (
	is => 'ro',
	isa => InstanceOf ['Form::Tiny::Path'],
	reader => 'get_name_path',
	init_arg => undef,
	lazy => 1,
	default => sub { Form::Tiny::Path->from_name(shift->name) },
);

has 'required' => (
	is => 'ro',
	isa => Enum [0, 1, 'soft', 'hard'],
	default => sub { 0 },
);

has 'type' => (
	is => 'ro',
	isa => HasMethods ['validate', 'check'],
	predicate => 'has_type',
);

has 'addons' => (
	is => 'rw',
	isa => HashRef,
	default => sub { {} },
);

has 'coerce' => (
	is => 'ro',
	isa => Bool | CodeRef,
	default => sub { 0 },
);

has 'adjust' => (
	is => 'ro',
	isa => CodeRef,
	predicate => 'is_adjusted',
	writer => 'set_adjustment',
);

has 'default' => (
	is => 'ro',
	isa => CodeRef,
	predicate => 'has_default',
);

has 'message' => (
	is => 'ro',
	isa => StringLike,
	predicate => 'has_message',
);

has 'data' => (
	is => 'ro',
	writer => 'set_data',
	predicate => 'has_data',
);

sub BUILD
{
	my ($self, $args) = @_;

	if ($self->coerce && ref $self->coerce ne 'CODE') {

		# checks for coercion == 1
		my $t = $self->type;
		croak 'type doesn\'t provide coercion'
			if !$self->has_type
			|| !($t->can('coerce') && $t->can('has_coercion') && $t->has_coercion);
	}

	if ($self->has_default) {

		croak 'default value for an array field is unsupported'
			if scalar grep { $_ eq 'ARRAY' } @{$self->get_name_path->meta};
	}

	# special case for subforms - set automatic adjustments
	if ($self->is_subform && !$self->is_adjusted) {
		$self->set_adjustment(sub { $self->type->fields });
	}
}

sub is_subform
{
	my ($self) = @_;

	return $self->has_type && has_form_meta($self->type);
}

sub hard_required
{
	my ($self) = @_;

	return $self->required eq '1' || $self->required eq 'hard';
}

sub get_coerced
{
	my ($self, $form, $value) = @_;
	my $coerce = $self->coerce;

	if ($coerce) {
		my $error = try sub {
			if (ref $coerce eq 'CODE') {
				$value = $coerce->($form, $value);
			}
			else {
				$value = $self->type->coerce($value);
			}
		};

		if ($error) {
			$form->add_error(
				Form::Tiny::Error::DoesNotValidate->new(
					{
						field => $self->name,
						error => $self->has_message ? $self->message : $error,
					}
				)
			);
		}
	}

	return $value;
}

sub get_adjusted
{
	my $self = shift;

	return pop() unless $self->is_adjusted;

	return $self->adjust->(@_);
}

sub get_default
{
	my ($self, $form) = @_;

	croak 'no default value set but was requested'
		unless $self->has_default;

	my $default = $self->default->($form);
	if (!$self->has_type || $self->type->check($default)) {
		return $default;
	}

	croak 'invalid default value was set';
}

sub validate
{
	my ($self, $form, $value) = @_;

	my @errors;

	if ($self->has_type) {
		if ($self->has_message) {
			push @errors, $self->message
				if !$self->type->check($value);
		}
		else {
			push @errors, $self->type->validate($value) // ();
		}
	}

	if (@errors == 0) {
		for my $validator (@{$self->addons->{validators} // []}) {
			my ($message, $code) = @{$validator};

			if (!$code->($form, $value)) {
				push @errors, $message;
			}
		}
	}

	for my $error (@errors) {
		if (ref $error eq 'ARRAY' && $self->is_subform) {
			foreach my $exception (@$error) {
				if (defined blessed $exception && $exception->isa('Form::Tiny::Error')) {
					my $path = $self->get_name_path;
					$path = $path->clone->append(HASH => $exception->field)
						if defined $exception->field;

					$exception->set_field($path->join);
					$exception = Form::Tiny::Error::NestedFormError->new(
						field => $self->name,
						error => $exception,
					);
				}
				else {
					$exception = Form::Tiny::Error::DoesNotValidate->new(
						field => $self->name,
						error => $exception,
					);
				}

				$form->add_error($exception);
			}
		}
		else {
			$form->add_error(
				Form::Tiny::Error::DoesNotValidate->new(
					{
						field => $self->name,
						error => $error,
					}
				)
			);
		}
	}

	return @errors == 0;
}

1;

__END__

=head1 NAME

Form::Tiny::FieldDefinition - definition of a field to be validated

=head1 SYNOPSIS

	# you usually don't have to do this by hand, see examples in Form::Tiny::Manual
	# name is the only required attribute
	my $definition = Form::Tiny::FieldDefinition->new(
		name => 'something',
		type => Str,
		...
	);

=head1 DESCRIPTION

This class keeps all the data for a field definition and contains method that handle single field validation.

=head1 ATTRIBUTES

Each of the attributes can be accessed by calling its name as a function on Form::Tiny::FieldDefinition object. See L<Form::Tiny::Manual> for more examples.

=head2 name

The only required attribute for the constructor.

A string which should specify the hash structure path of the field.

Special characters are:

=over

=item * dot [.], which specifies nesting

=item * star [*], which specifies any number of array elements, but only if it is the only character on level, like a.*.b

=back

They both can be escaped by a backslash C<\> to lose their special meaning.

=head2 required

A field is not required by default (value C<0>), which means that its absence does not produce an error.

A field can also be soft required (C<'soft'>) or hard required (C<'hard'> or C<1>).

Soft required field produce errors only if it is undefined or not present in the input data.

Hard required field also checks if the field is not an empty string.

=head2 type

The type attribute is where you can plug in a Type::Tiny type object. It has to be an instance of a class that provider I<validate> and I<check> methods, just like Type::Tiny. This can also be a Form::Tiny form instance.

B<predicate:> I<has_type>

=head2 addons

Hash reference for internal use only - readable and writable under the C<addons> method. If you need additional data for a field definition that will be used in metaclasses (while extending Form::Tiny), put it here.

=head2 coerce

Coercions take place just before the validation. By default, values are not coerced. Specifying value I<1> will cause the field to use coercions from the type object.

It can also be a code reference which will be called to coerce the value, passing in a field value as its only argument.

=head2 adjust

Adjustments take place just after the validation. By default, values are not adjusted. You can specify a code reference which will be called to adjust the value (change the value after the validation).

B<predicate:> I<is_adjusted>

B<writer:> I<set_adjustment>

=head2 default

A coderef returning the default value for the field. Will be used when the field is not present in the input at all. Making the field hard-required will make the default value be used in place of undefined / empty value as well.

This coderef will be passed form instance as the only argument and is expected to return a scalar value.

B<predicate>: I<has_default>

B<writer>: I<set_default>

=head2 message

If type class error messages are not helpful enough, you can specify your own message string which will be inserted into form errors if the validation for the field fails.

B<predicate:> I<has_message>

=head2 data

Custom data for the field. Can be anything and will not be used by Form::Tiny system itself. It should be anything that will help user's own system use the form instance.

B<writer:> I<set_data>

B<predicate:> I<has_data>

=head1 METHODS

=head2 is_subform

Checks if the field definition's type is a form - whether it mixes in L<Form::Tiny::Form> role.

=head2 get_name_path

Parses and returns the name of the field as an object of L<Form::Tiny::Path> class.

=head2 hard_required

Checks if the field is hard-required (any of the two values which are allowed for this flag)

=head2 validate

Validates a scalar value. Arguments are C<$parent_form, $field_value>. Returns a boolean, whether the validation passed.

