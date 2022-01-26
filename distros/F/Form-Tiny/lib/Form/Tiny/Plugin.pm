package Form::Tiny::Plugin;

use v5.10;
use strict;
use warnings;
use Carp qw(croak);

sub plugin
{
	my ($class, $caller, $context) = @_;

	croak 'Unimplemented!';
}

1;

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

If you wish to extend Form::Tiny, plugins system is your best bet. It allows you to specify:

=over

=item * subs which will be added to the namespace

=item * roles which will be composed to the package

=item * meta roles which will be composed to the meta object

=back

You may specify all, any, or none of those in the resulting hashref of the C<plugin> method. It will be called in class context:

	Form::Tiny::Plugin::MyPlugin->($caller, $context);

Where:

=over

=item * C<$caller> will be the package that called C<use Form::Tiny> with your plugin

=item * C<$context> will be a scalar reference to the current field context of the form

The context may be referencing either L<Form::Tiny::FieldDefinition> or L<Form::Tiny::FieldDefinitionBuilder> (depending on whether the field was dynamic).

=back

To use your plugin in a form, L<Form::Tiny> must be imported like this:

	use Form::Tiny plugins => [qw(MyPlugin +Full::Namespace::Plugin)];

Prepending the name with a plus sign will stop Form::Tiny from prepending the given name with C<Form::Tiny::Plugin::>.

Your plugin package must inherit from C<Form::Tiny::Plugin> and must reintroduce the C<plugin> method (without calling C<SUPER::plugin>).

