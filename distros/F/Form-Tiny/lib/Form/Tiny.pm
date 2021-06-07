package Form::Tiny;

use v5.10;
use warnings;
use Carp qw(croak);
use Types::Standard qw(Str);
use Import::Into;

use Form::Tiny::Form;
use Form::Tiny::Utils qw(trim :meta_handlers);
require Moo;

our $VERSION = '2.01';

sub import
{
	my ($package, $caller) = (shift, scalar caller);

	my @wanted = @_;
	my @wanted_subs = qw(form_field form_cleaner form_hook);
	my @wanted_roles;

	my %subs = %{$package->_generate_helpers($caller)};
	my %behaviors = %{$package->_get_behaviors};

	unless (scalar grep { $_ eq -nomoo } @wanted) {
		Moo->import::into($caller);
	}

	require Moo::Role;
	Moo::Role->apply_roles_to_package(
		$caller, 'Form::Tiny::Form'
	);

	foreach my $type (@wanted) {
		croak "no Form::Tiny import behavior for: $type"
			unless exists $behaviors{$type};
		push @wanted_subs, @{$behaviors{$type}->{subs}};
		push @wanted_roles, @{$behaviors{$type}->{roles}};
	}

	create_form_meta($caller, @wanted_roles);

	{
		no strict 'refs';
		no warnings 'redefine';

		*{"${caller}::$_"} = $subs{$_} foreach @wanted_subs;
	}

	return;
}

sub _generate_helpers
{
	my ($package, $caller) = @_;

	my $field_context;
	return {
		form_field => sub {
			$field_context = ref $_[0] eq '' ? $_[0] : undef;
			$caller->form_meta->add_field(@_);
		},
		form_cleaner => sub {
			$field_context = undef;
			$caller->form_meta->add_hook(cleanup => @_);
		},
		form_hook => sub {
			$field_context = undef;
			$caller->form_meta->add_hook(@_);
		},
		form_filter => sub {
			$field_context = undef;
			$caller->form_meta->add_filter(@_);
		},
		field_filter => sub {
			if (@_ == 2) {
				croak 'field_filter called in invalid context'
					unless defined $field_context;
				unshift @_, $field_context;
			}
			$caller->form_meta->add_field_filter(@_);
		},
		form_trim_strings => sub {
			$field_context = undef;
			$caller->form_meta->add_filter(Str, \&trim);
		},
	};
}

sub _get_behaviors
{
	my $empty = {
		subs => [],
		roles => [],
	};

	return {
		-base => $empty,
		-nomoo => $empty,
		-strict => {
			subs => [],
			roles => [qw(Form::Tiny::Meta::Strict)],
		},
		-filtered => {
			subs => [qw(form_filter field_filter form_trim_strings)],
			roles => [qw(Form::Tiny::Meta::Filtered)],
		},
	};
}

1;

__END__

=head1 NAME

Form::Tiny - Input validator implementation centered around Type::Tiny

=head1 SYNOPSIS

	package MyForm;

	use Form::Tiny -base;
	use Types::Standard qw(Int);

	form_field 'my_field' => (
		required => 1,
	);

	form_field 'another_field' => (
		type => Int,
		default => sub { 0 },
	);

=head1 DESCRIPTION

Form::Tiny is a customizable hashref validator with DSL for form building.

=head1 DOCUMENTATION INDEX

=over

=item * L<Form::Tiny::Manual> - Main reference

=item * L<Form::Tiny::Manual::Compatibility> - See backwards compatibility notice

=item * L<Form::Tiny::Manual::Internals> - How to mess with Form::Tiny internals

=item * L<Form::Tiny::Form> - Form class added interface specification

=item * L<Form::Tiny::Error> - Form error class specification

=item * L<Form::Tiny::FieldDefinition> - Field definition class specification

=item * L<Form::Tiny::Hook> - Hook class specification

=item * L<Form::Tiny::Filter> - Filter class specification

=back

=head1 IMPORTING

When imported, Form::Tiny will turn a package it is imported into a Moo class that does the L<Form::Tiny::Form> role. It will also install helper functions in your package that act as a domain-specific language (DSL) for building your form.

	package MyForm;

	# imports only basic helpers
	use Form::Tiny;

	# fully-featured form:
	use Form::Tiny -filtered, -strict;

After C<use Form::Tiny> statement, your package gains all the Moo keywords, some Form::Tiny keywords (see L</"Available import flags">) and all L<Form::Tiny::Form> methods.

=head2 Available import flags

=over

=item * C<-base>

This flag is here only for backwards compatibility. It does not do anything particular on its own.

Installed functions: C<form_field form_cleaner form_hook>

=item * C<-nomoo>

This flag stops Form::Tiny from importing Moo into your namespace. Unless you use a different class system (like L<Moose>) will have to declare your own constructor.

Installed functions: same as C<-base>

=item * C<-filtered>

This flag enables filters in your form.

Installed functions: all of C<-base> plus C<form_filter field_filter form_trim_strings>

=item * C<-strict>

This flag makes your form check for strictness before the validation.

Installed functions: same as C<-base>

=back

=head2 Form domain-specific language

=head3 form_field

	form_field $name => %arguments;
	form_field $coderef;
	form_field $object;

This helper declares a new field for your form. Each style of calling this function should contain keys that meet the specification of L<Form::Tiny::FieldDefinition>, or an object of this class directly.

In the first (hash) version, C<%arguments> need to be a plain hash (not a hashref) and should B<not> include the name in the hash, as it will be overriden by the first argument C<$name>. This form also sets the context for the form being built: see L<Form::Tiny::Manual/"Context"> for details.

In the second (coderef) version, C<$coderef> gets passed the form instance as its only argument and should return a hashref or a constructed object of L<Form::Tiny::FieldDefinition>. A hashref must contain a C<name>. Note that this creates I<dynamic field>, which will be resolved repeatedly during form validation. As such, it should not contain any randomness.

If you need a subclass of the default implementation, and you don't need a dynamic field, you can use the third style of the call, which takes a constructed object of L<Form::Tiny::FieldDefinition> or its subclass.

=head3 form_hook

	form_hook $stage => $coderef;

This creates a new hook for C<$stage>. Each stage may have multiple hooks and each will pass different arguments to the C<$coderef>. Refer to L<Form::Tiny::Manual/Hooks> for details.

=head3 form_cleaner

	form_cleaner $coderef;

A shortcut for C<< form_hook cleanup => $coderef; >>.

=head3 form_filter

	form_filter $type, $coderef;

C<$type> should be a Type::Tiny (or compatible) type check. For each input field that passes that check, C<$coderef> will be ran. See L<Form::Tiny::Manual/"Filters"> for details on filters.

=head3 field_filter

	field_filter $type, $coderef; # uses current context
	field_filter $name => $type, $coderef;

Same as C<form_filter>, but is narrowed down to a single form field identified by its name. Name can be omitted and the current context will be used. See L<Form::Tiny::Manual/"Context"> for details on context.

=head3 form_trim_strings

	form_trim_strings;

This helper takes no arguments, but causes your form to filter string values by calling L<Form::Tiny::Utils::trim> on them.

This was enabled by default once. Refer to L<Form::Tiny::Manual::Compatibility/"Filtered forms no longer trim strings by default"> for details.

=head1 TODO

=over

=item * Document and test meta classes

=item * More tests for form inheritance

=item * More examples

=back

=head1 AUTHOR

Bartosz Jarzyna E<lt>brtastic.dev@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2020 - 2021 by Bartosz Jarzyna

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
