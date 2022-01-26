package Form::Tiny::Hook;

use v5.10;
use strict;
use warnings;
use Moo;
use Types::Standard qw(Enum CodeRef Bool);

use namespace::clean;

our $VERSION = '2.04';

use constant {
	HOOK_REFORMAT => 'reformat',
	HOOK_BEFORE_MANGLE => 'before_mangle',
	HOOK_BEFORE_VALIDATE => 'before_validate',
	HOOK_AFTER_VALIDATE => 'after_validate',
	HOOK_CLEANUP => 'cleanup',
	HOOK_AFTER_ERROR => 'after_error',
};

my @hooks = (
	HOOK_REFORMAT,
	HOOK_BEFORE_MANGLE,
	HOOK_BEFORE_VALIDATE,
	HOOK_AFTER_VALIDATE,
	HOOK_CLEANUP,
	HOOK_AFTER_ERROR,
);

has "hook" => (
	is => "ro",
	isa => Enum [@hooks],
	required => 1,
);

has "code" => (
	is => "ro",
	isa => CodeRef,
	required => 1,
);

has 'inherited' => (
	is => 'ro',
	isa => Bool,
	default => sub { 1 },
);

sub is_modifying
{
	my ($self) = @_;

	# whether a hook type will modify the input data
	# with return statements
	my %modifying = map { $_ => 1 } (
		HOOK_BEFORE_MANGLE,
		HOOK_REFORMAT
	);
	return exists $modifying{$self->hook};

}

1;

__END__

=head1 NAME

Form::Tiny::Hook - a representation of a hook

=head1 SYNOPSIS

	# in your form class

	# the following will be coerced into Form::Tiny::Filter
	form_hook before_validation => $coderef;

=head1 DESCRIPTION

This is a simple class which stores a hook type together with a code reference which will be fired on that stage. See L<Form::Tiny::Manual/"Hooks"> for details.

=head1 ATTRIBUTES

=head2 hook

A hook type. Currently available types are: C<reformat before_mangle before_validate after_validate cleanup after_error>.

Required.

=head2 code

A code reference accepting varying arguments depending on hook type.

Required.

=head2 inherited

A boolean - whether the hook should be inherited to child forms. True by default.

=head1 METHODS

=head2 is_modifying

Given a hook object, this method will return a boolean value which indicates whether the hook is meant to be modifying the passed in value. If false, we should discard the return value of that hook's code reference.

