package Form::Tiny::FieldDefinition;
$Form::Tiny::FieldDefinition::VERSION = '2.26';
use v5.10;
use strict;
use warnings;
use Moo;
use Types::Standard qw(Enum Bool HasMethods CodeRef InstanceOf HashRef);
use Types::Common::String qw(NonEmptySimpleStr);
use Types::TypeTiny qw(StringLike);
use Carp qw(croak);
use Scalar::Util qw(blessed);
use Data::Dumper;

use Form::Tiny::Utils qw(try has_form_meta);
use Form::Tiny::Error;
use Form::Tiny::Path;

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
	writer => 'set_required',
	default => sub { 0 },
);

has 'type' => (
	is => 'ro',
	isa => HasMethods ['validate', 'check'],
	writer => 'set_type',
	predicate => 'has_type',
);

has 'addons' => (
	is => 'ro',
	writer => 'set_addons',
	isa => HashRef,
	default => sub { {} },
	init_arg => undef,
);

has 'coerce' => (
	is => 'ro',
	isa => Bool | CodeRef,
	writer => 'set_coercion',
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
	writer => 'set_default',
	predicate => 'has_default',
);

has 'message' => (
	is => 'ro',
	isa => StringLike,
	writer => 'set_message',
	predicate => 'has_message',
);

has 'data' => (
	is => 'ro',
	writer => 'set_data',
	predicate => 'has_data',
);

has '_subform' => (
	is => 'ro',
	isa => Bool,
	reader => 'is_subform',
	lazy => 1,
	default => sub { $_[0]->has_type && has_form_meta($_[0]->type) },
	init_arg => undef,
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
			if scalar grep { $_ } @{$self->get_name_path->meta_arrays};
	}
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
						field_def => $self,
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
	my ($self, $form, $value) = @_;

	# NOTE: subform must be already validated at this stage
	$value = $self->type->fields
		if $self->is_subform;

	return $value unless $self->is_adjusted;
	return $self->adjust->($form, $value);
}

sub get_default
{
	my ($self, $form) = @_;

	croak 'no default value set but was requested'
		unless $self->has_default;

	my $default = $self->default->($form);
	if ($self->is_subform) {
		my $subform = $self->type;
		croak 'subform default input is not valid. ' . Data::Dumper->Dump([$subform->errors_hash], ['errors'])
			unless $subform->check($default);

		$default = $subform->fields;
	}

	return $default;
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
			my $error = $self->type->validate($value);
			push @errors, $error
				if defined $error;
		}
	}

	if (@errors == 0 && (my $validators = $self->addons->{validators})) {
		for my $validator (@{$validators}) {
			my ($message, $code) = @{$validator};

			if (!$code->($form, $value)) {
				push @errors, $message;
			}
		}
	}

	for my $error (@errors) {
		if (ref $error eq 'ARRAY' && $self->is_subform) {
			foreach my $exception (@$error) {
				my $class = 'Form::Tiny::Error::DoesNotValidate';
				if (defined blessed $exception && $exception->isa('Form::Tiny::Error')) {
					$class = 'Form::Tiny::Error::NestedFormError';

					my $path = $self->get_name_path;
					$path = $path->clone->append_path(Form::Tiny::Path->from_name($exception->field))
						if defined $exception->field;

					$exception->set_field($path->join);
				}

				$form->add_error(
					$class->new(
						field_def => $self,
						error => $exception,
					)
				);
			}
		}
		else {
			$form->add_error(
				Form::Tiny::Error::DoesNotValidate->new(
					{
						field_def => $self,
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

This class keeps all the data for a field definition and contains method that
handle single field validation.

=head1 ATTRIBUTES

Each of the attributes can be accessed by calling its name as a function on
Form::Tiny::FieldDefinition object. See L<Form::Tiny::Manual> for more
examples.

=head2 name

The only required attribute for the constructor.

A string which should specify the hash structure path of the field.

Special characters are:

=over

=item * dot [.], which specifies nesting

=item * star [*], which specifies any number of array elements, but only if it
is the only character on level, like a.*.b

=back

They both can be escaped by a backslash C<\> to lose their special meaning.

=head2 required

A field is not required by default (value C<0>), which means that its absence
does not produce an error.

A field can also be soft required (C<'soft'>) or hard required (C<'hard'> or C<1>).

Soft required field produce errors only if it is undefined or not present in
the input data.

Hard required field also checks if the field is not an empty string.

B<writer:> I<set_required>

=head2 type

The type attribute is where you can plug in a Type::Tiny type object. It has to
be an instance of a class that provider I<validate> and I<check> methods, just
like Type::Tiny. This can also be a Form::Tiny form instance.

B<writer:> I<set_type>

B<predicate:> I<has_type>

=head2 addons

Hash reference for internal use only - readable and writable under the
C<addons> method. If you need additional data for a field definition that will
be used in metaclasses (while extending Form::Tiny), put it here.

=head2 coerce

Coercions take place just before the validation. By default, values are not
coerced. Specifying value I<1> will cause the field to use coercions from the
type object.

It can also be a code reference which will be called to coerce the value,
passing in a field value as its only argument.

B<writer:> I<set_coercion>

=head2 adjust

Adjustments take place just after the validation. By default, values are not
adjusted. You can specify a code reference which will be called to adjust the
value (change the value after the validation).

B<writer:> I<set_adjustment>

B<predicate:> I<is_adjusted>

=head2 default

A coderef returning the default value for the field. Will be used when the
field is not present in the input at all. Making the field hard-required will
make the default value be used in place of undefined / empty value as well.

This coderef will be passed form instance as the only argument and is expected
to return a scalar value.

B<writer>: I<set_default>

B<predicate>: I<has_default>

=head2 message

If type class error messages are not helpful enough, you can specify your own
message string which will be inserted into form errors if the validation for
the field fails.

B<writer:> I<set_message>

B<predicate:> I<has_message>

=head2 data

Custom data for the field. Can be anything and will not be used by Form::Tiny
system itself. It should be anything that will help user's own system use the
form instance.

B<writer:> I<set_data>

B<predicate:> I<has_data>

=head1 METHODS

=head2 is_subform

Checks if the field definition's type is a form - whether it has its own
Form::Tiny metaobject.

=head2 get_name_path

Parses and returns the name of the field as an object of L<Form::Tiny::Path>
class.

=head2 hard_required

Checks if the field is hard-required (any of the two values which are allowed
for this flag)

=head2 validate

Validates a scalar value. Arguments are C<$parent_form, $field_value>. Returns
a boolean, whether the validation passed.

