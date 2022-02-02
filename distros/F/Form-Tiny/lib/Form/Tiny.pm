package Form::Tiny;

use v5.10;
use strict;
use warnings;
use Carp qw(croak carp);
use Types::Standard qw(Str);
use Import::Into;
use Scalar::Util qw(blessed);

use Form::Tiny::Form;
use Form::Tiny::Utils qw(trim :meta_handlers);
require Moo;

our $VERSION = '2.09';

sub import
{
	my ($package, $caller) = (shift, scalar caller);

	my @wanted = @_;

	# special case - we want to always have -base flag, but just once
	@wanted = (-base, grep { $_ ne -base } @wanted);

	# very special case - do something UNLESS -nomoo was passed
	unless ($package->_get_flag(\@wanted, -nomoo)) {
		Moo->import::into($caller);
	}

	$package->ft_install($caller, @wanted);
	return;
}

sub ft_install
{
	my ($self, $caller, @import_flags) = @_;

	my $context;
	my $wanted = {
		subs => {},
		roles => [],
		meta_roles => [],
	};

	my $plugins = $self->_get_flag(\@import_flags, 'plugins', 1);

	$self->_select_behaviors(
		$wanted, \@import_flags,
		$self->_get_behaviors($self->_generate_helpers($caller, \$context))
	);

	foreach my $plugin (@$plugins) {
		$plugin = "Form::Tiny::Plugin::$plugin";
		$plugin =~ s/^.+\+//;
		my $success = eval "use $plugin; 1";

		croak "could not load plugin $plugin: $@"
			unless $success;
		croak "$plugin is not a Form::Tiny::Plugin"
			unless $plugin->isa('Form::Tiny::Plugin');

		$self->_select_behaviors($wanted, [$plugin], {$plugin => $plugin->plugin($caller, \$context)});
	}

	# create metapackage with roles
	my $meta = create_form_meta($caller, @{$wanted->{meta_roles}});
	$meta->set_form_roles($wanted->{roles});

	# install DSL
	{
		no strict 'refs';
		no warnings 'redefine';

		*{"${caller}::$_"} = $wanted->{subs}{$_}
			foreach keys %{$wanted->{subs}};
	}

	return \$context;
}

sub _generate_helpers
{
	my ($self, $caller, $field_context) = @_;

	my $use_context = sub {
		croak 'context using DSL keyword called without context'
			unless defined $$field_context;
		unshift @_, $$field_context;
		return @_;
	};

	return {
		form_field => sub {
			$$field_context = $caller->form_meta->add_field(@_);
		},
		form_cleaner => sub {
			$$field_context = undef;
			$caller->form_meta->add_hook(cleanup => @_);
		},
		form_hook => sub {
			$$field_context = undef;
			$caller->form_meta->add_hook(@_);
		},
		form_filter => sub {
			$$field_context = undef;
			$caller->form_meta->add_filter(@_);
		},
		field_filter => sub {
			$caller->form_meta->add_field_filter($use_context->(@_));
		},
		field_validator => sub {
			$caller->form_meta->add_field_validator($use_context->(@_));
		},
		form_trim_strings => sub {
			$$field_context = undef;
			$caller->form_meta->add_filter(Str, sub { trim $_[1] });
		},
		form_message => sub {
			$$field_context = undef;
			my %params = @_;
			for my $key (keys %params) {
				$caller->form_meta->add_message($key, $params{$key});
			}
		},
	};
}

sub _get_behaviors
{
	my ($self, $subs) = @_;

	return {
		-base => {
			subs => {
				map { $_ => $subs->{$_} }
					qw(
					form_field field_validator
					form_cleaner form_hook
					form_message
					)
			},
			roles => ['Form::Tiny::Form'],
		},
		-strict => {
			meta_roles => [qw(Form::Tiny::Meta::Strict)],
		},
		-filtered => {
			subs => {
				map { $_ => $subs->{$_} }
					qw(
					form_filter field_filter
					form_trim_strings
					)
			},
			meta_roles => [qw(Form::Tiny::Meta::Filtered)],
		},

		# legacy no-op flags
		-consistent => {},
	};
}

sub _select_behaviors
{
	my ($self, $wanted, $types, $behaviors) = @_;

	foreach my $type (@$types) {
		croak "no Form::Tiny import behavior for: $type"
			unless exists $behaviors->{$type};

		%{$wanted->{subs}} = (%{$wanted->{subs}}, %{$behaviors->{$type}{subs} // {}});
		push @{$wanted->{roles}}, @{$behaviors->{$type}{roles} // []};
		push @{$wanted->{meta_roles}}, @{$behaviors->{$type}{meta_roles} // []};
	}
}

sub _get_flag
{
	my ($self, $flags, $wanted, $with_param) = @_;
	$with_param //= 0;

	for my $n (0 .. $#$flags) {
		if ($flags->[$n] eq $wanted) {
			my $param = 1;
			if ($with_param) {
				croak "Form::Tiny flag $wanted needs a parameter"
					if $n == $#$flags;
				$param = $flags->[$n + 1];
			}

			splice @$flags, $n, 1 + $with_param;
			return $param;
		}
	}

	return;
}

1;

__END__

=head1 NAME

Form::Tiny - Input validator implementation centered around Type::Tiny

=head1 SYNOPSIS

	package MyForm;

	use Form::Tiny;
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

=item * L<Form::Tiny::Manual::Cookbook> - Common tasks performed with Form::Tiny

=item * L<Form::Tiny::Manual::Performance> - How to get the most speed out of the module

=item * L<Form::Tiny::Manual::Compatibility> - See backwards compatibility notice

=item * L<Form::Tiny::Manual::Internals> - How to mess with Form::Tiny internals

=item * L<Form::Tiny::Form> - Form class added interface specification

=item * L<Form::Tiny::Error> - Form error class specification

=item * L<Form::Tiny::FieldDefinition> - Field definition class specification

=item * L<Form::Tiny::Hook> - Hook class specification

=item * L<Form::Tiny::Filter> - Filter class specification

=item * L<Form::Tiny::Plugin> - How to write your own plugin?

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

No matter which flag was used in import, using C<Form::Tiny> always installs these functions: C<form_field form_cleaner form_hook>

=over

=item * C<-nomoo>

This flag stops Form::Tiny from importing Moo into your namespace. Unless you use a different class system (like L<Moose>) will have to declare your own constructor.

=item * C<-filtered>

This flag enables filters in your form.

Additional installed functions: C<form_filter field_filter form_trim_strings>

=item * C<-strict>

This flag makes your form check for strictness before the validation.

=item * C<< plugins => ['Plugin1', '+Full::Namespace::To::Plugin2'] >>

Load plugins into Form::Tiny. Plugins may introduce additional keywords, mix in roles or add metaclass roles. See L<Form::Tiny::Plugin> for details on how to implement a plugin.

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

=head3 form_message

	form_message
		$type1 => $message1,
		$type2 => $message2;

Override form default error messages, possibly multiple at a time. Types can be any of C<Required> (when a mandatory field is missing), C<IsntStrict> (when form is strict and the check for it fails) and C<InvalidFormat> (when passed input format is not a hash reference) - currently only those types have their own dedicated error message.

=head3 form_hook

	form_hook $stage => $coderef;

This creates a new hook for C<$stage>. Each stage may have multiple hooks and each will pass different arguments to the C<$coderef>. Refer to L<Form::Tiny::Manual/Hooks> for details.

=head3 form_cleaner

	form_cleaner $coderef;

A shortcut for C<< form_hook cleanup => $coderef; >>.

=head3 field_validator

	# uses current context
	field_validator $message => $coderef;

Adds an additional custom validator, ran after the type of the field is validated. C<$message> should be something that can present itself as a string. If for a given input parameter C<$coderef> returns false, that message will be added to form errors for that field. See L<Form::Tiny::Manual/"Additional validators"> for details.

See L<Form::Tiny::Manual/"Context"> for details on context.

=head3 form_filter

	form_filter $type, $coderef;

Filters the input value before the validation. C<$type> should be a Type::Tiny (or compatible) type check. For each input field that passes that check, C<$coderef> will be ran.

See L<Form::Tiny::Manual/"Filters"> for details on filters.

=head3 field_filter

	# uses current context
	field_filter $type, $coderef;
	field_filter Form::Tiny::Filter->new(...);

Same as C<form_filter>, but is narrowed down to a single form field.

See L<Form::Tiny::Manual/"Context"> for details on context.

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

Bartosz Jarzyna E<lt>bbrtj.pro@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2020 - 2021 by Bartosz Jarzyna

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
