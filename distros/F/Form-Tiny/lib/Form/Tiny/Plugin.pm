package Form::Tiny::Plugin;
$Form::Tiny::Plugin::VERSION = '2.21';
use v5.10;
use strict;
use warnings;
use Carp qw(croak);

sub use_context
{
	my ($class, $context) = @_;

	croak 'context using DSL keyword called without context'
		unless defined $$context;

	return $$context;
}

sub plugin
{
	my ($class, $caller, $context) = @_;

	croak 'Unimplemented!';
}

1;

__END__

=head1 NAME

Form::Tiny::Plugin - base class for Form::Tiny plugins

=head1 SYNOPSIS

	package Form::Tiny::Plugin::MyPlugin;

	use parent 'Form::Tiny::Plugin';

	sub plugin
	{
		my ($self, $caller, $context) = @_;

		return {
			subs => {
				subname => sub { ... },
			},
			roles => ['My::Role', ...],
			meta_roles => ['My::Meta::Role', ...],
		};
	}

=head1 DESCRIPTION

Plugins are interface and behavior definitions for Form::Tiny forms - they
determine how the form is built and can change how it behaves.

To use your plugin in a form, L<Form::Tiny> must be imported like this:

	use Form::Tiny plugins => [qw(MyPlugin +Full::Namespace::Plugin)];

Prepending the name with a plus sign will stop Form::Tiny from prepending the
given name with C<Form::Tiny::Plugin::>.

=head1 WRITING A PLUGIN

Plugin definition consists of:

=over

=item * subs which will be added to the namespace

These subs will be treated as new DSL keywords. They will be imported into the
package and take part in building the form, but they can also be cleaned away
with L<namespace::autoclean> (together with all other DSL keywords).

=item * roles which will be composed to the package

These roles and all roles from other plugins will be composed into the form
package in one operation, detecting method conflicts properly.

=item * meta roles which will be composed to the meta object

Same as roles, but for the package metaobject.

=back

You may specify all, any, or none of those in the resulting hashref of the
C<plugin> method. It will be called in class context:

	Form::Tiny::Plugin::MyPlugin->plugin($caller, $context);

Where:

=over

=item * C<$caller> will be the package that called C<use Form::Tiny> with your plugin

=item * C<$context> will be a scalar reference to the current field context of the form

The context may be referencing either L<Form::Tiny::FieldDefinition> or
L<Form::Tiny::FieldDefinitionBuilder> (depending on whether the field was
dynamic).

=back

Your plugin package must inherit from C<Form::Tiny::Plugin> and must
reintroduce the C<plugin> method (without calling C<SUPER::plugin>).

=head2 Accessing form metaobject

The C<$caller> variable will be a class name with C<form_meta> method. However,
since your plugin will take part in configuring the form, there will not yet be
a C<form_meta> method during execution of C<plugin>:

	sub plugin
	{
		my ($self, $caller, $context) = @_;

		# Bad - form is still being configured, and the meta method hasn't yet been generated
		$caller->form_meta;

		return {
			subs => {
				subname => sub {
					# Good - called after the package has been fully configured
					$caller->form_meta;
				}
			}
		};

If you wish to perform an action after the form is configured, consider
implementing a metaobject role that will have an C<after> method modifier on
C<setup> method.


=head2 Handling context

Context is passed into the C<plugin> method as a scalar reference. Your DSL
keywords can set or consume context, and it should always be a subclass of
L<Form::Tiny::FieldDefinition> or L<Form::Tiny::FieldDefinitionBuilder>. The
reference itself is guaranteed to be defined.

	sub plugin
	{
		my ($self, $caller, $context) = @_;

		return {
			subs => {
				# set field to required with a keyword
				is_required => sub {
					die 'no context'
						unless defined $$context;

					die 'field for rename must be static'
						unless $$context->isa('Form::Tiny::FieldDefinition');

					$$context->set_required(1);
				},
			},
		};
	}

=head2 Example plugins

All of L<Form::Tiny> importing functionality is based on plugins. See these
packages as a reference:

=over

=item * L<Form::Tiny::Plugin::Base>

=item * L<Form::Tiny::Plugin::Filtered>

=back

