package Form::Tiny::Plugin::Diva;

use v5.10;
use strict;
use warnings;

our $VERSION = '1.01';

use Form::Tiny::Plugin::Diva::Adapter;
use Form::Tiny::Plugin::Diva::MetaRole;

use parent 'Form::Tiny::Plugin';

sub plugin
{
	my ($self, $caller, $context) = @_;

	return {
		subs => {
			diva_config => sub {
				$$context = undef;
				$caller->form_meta->add_diva_config(@_);
			},
		},

		roles => [__PACKAGE__],
		meta_roles => ['Form::Tiny::Plugin::Diva::MetaRole'],
	};
}

use Scalar::Util qw(weaken);
use Moo::Role;

has 'diva' => (
	is => 'ro',
	builder => '_build_diva',
	lazy => 1,
	init_arg => undef,
);

sub _build_diva
{
	my ($self) = @_;
	my %config = %{$self->form_meta->diva_config};

	my @fields;
	my @hidden;

	for my $field (@{$self->field_defs}) {
		my %field_data = (
			%{$field->data // {type => 'hidden'}},
			name => $field->name,
		);

		if ($field->has_default && !exists $field_data{d} && !exists $field_data{default}) {
			$field_data{default} = $field->default->($self);
		}

		my $type = $field_data{type} // $field_data{t};
		my $push_to = lc $type eq 'hidden' ? \@hidden : \@fields;
		push @$push_to, {%field_data, comment => \%field_data};
	}

	weaken $self;
	return Form::Tiny::Plugin::Diva::Adapter->new(
		%config,
		form => \@fields,
		hidden => \@hidden,

		form_instance => $self,
	);
}

1;

__END__

=head1 NAME

Form::Tiny::Plugin::Diva - Form::Diva integration for Form::Tiny

=head1 SYNOPSIS

	### Form configuration

	use Form::Tiny plugins => ['Diva'];

	# Form::Diva configuration can be passed using diva_config
	diva_config label_class => 'my-label-class';

	# data of fields is used as an input to Form::Diva
	# note: name is added automatically from field name
	form_field 'normal_edit' => (
		data => {type => 'text'},
	);

	# passing type => 'hidden' will make the field hidden in diva
	form_field 'hidden' => (
		data => {type => 'hidden'},
	);

	# if there is no data section at all, the field is also treated as hidden
	# default value in form is used
	form_field 'also_hidden' => (
		default => sub { 55 },
	);


	### Using Form::Diva

	my $form = MyFormPackage->new;
	$form->set_input({normal_edit => 'edited!'});

	# Form::Diva adapter - see Form::Diva docs
	my $diva = $form->diva;

	# no need to pass the data in first argument to functions that need it
	print Dumper($form->generated);

=head1 DESCRIPTION

This plugin adds some HTML outputting capabilities to L<Form::Tiny> forms using L<Form::Diva>.

=head1 CONFIGURATION

This plugin can be added to Form::Tiny with the following line:

	use Form::Tiny plugins => ['Diva'];

=head2 Form::Diva form scope configuration

By default, these values will be passed to Form::Diva constructor:

	id_base => 'form-field-',
	label_class => 'form-label',
	input_class => 'form-control',
	error_class => 'invalid-feedback',

These can be changed by a call to a new C<diva_config> DSL keyword:

	# one or more at a time
	diva_config
		label_class => 'form-label',
		input_class => 'form-control';

=head2 Form::Diva field scope configuration

All fields defined in the form will be passed into Form::Diva constructor:

=over

=item * fields with no C<data> attribute will be used as hidden fields

=item * fields with C<data> attribute must have it as a hash reference and will be used as regular fields, unless C<< type => 'hidden' >> is specified

=back

Contents of C<data> are documented in L<Form::Diva/"form">. A couple of notes:

=over

=item * C<name> will be automatically copied over from Form::Tiny field name, so there's no need to write it out loud

=item * C<default> will be copied over from Form::Tiny default, but only if not explicitly passed

=item * C<comment> is reserved for internal use

=back

=head2 Printing out the form

You can get a preconfigured diva object by calling C<diva> method on your form instance:

	my $diva = $form_instance->diva;

This is a subclass of Form::Diva, and it behaves slightly differently. The main difference is that you no longer need to pass the data explicitly into methods like C<generate> or C<prefill>, as the form input will be used by default:

	# no arguments, yet will use $form_instance->input
	my $generated = $diva->generated;

Additionally, all generated fields will have an extra hash key, C<errors> which will contain the string with errors ready to be put into HTML:

	my $errors = $generated->[0]{errors};

When there are no errors, this value will be empty (but never undefined). You can reliably use it with your template engine to print errors. Note that no form scope errors are included - for those you will have to call another method C<form_errors> on diva adapter:

	my $global_errors = $diva->form_errors;

You can configure the HTML class of error containers with C<error_class> configuration field (see above).

=head1 LIMITATIONS

=over

=item * No support for nesting - neither nested arrays nor hashes

Form should print without problems, but will not accept the data back from HTML without modification.

=item * Occupies 'comment' field from Form::Diva

Comment field is needed to pass metadata through the generation mechanism. Contents of this field explicitly configured in forms will be discarded.

=back

=head1 SEE ALSO

L<Form::Tiny>

L<Form::Diva>

=head1 AUTHOR

Bartosz Jarzyna, E<lt>bbrtj.pro@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2022 by Bartosz Jarzyna

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.34.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
