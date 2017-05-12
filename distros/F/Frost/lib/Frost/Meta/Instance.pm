package Frost::Meta::Instance;

#	LIBS
#
use Moose::Role;

use Moose::Util::TypeConstraints;

use Frost::Types;
use Frost::Util;

#	CLASS VARS
#
our $VERSION	= 0.62;
our $AUTHORITY	= 'cpan:ERNESTO';

#	CLASS METHODS
#

#	PUBLIC ATTRIBUTES
#

#	PRIVATE ATTRIBUTES
#

#	CONSTRUCTORS
#

#	DESTRUCTORS
#

#	PUBLIC METHODS
#
sub bless_instance_structure
{
	die 'bless_instance_structure is deprecated';
}

#	Is there a REAL use case?
#
sub clone_instance
{
	die 'cloning is VERBOTEN (mutable)';
}

#	operations on created instances

sub get_slot_value
{
	die "mutable is VERBOTEN";
}

sub set_slot_value
{
	die "mutable is VERBOTEN";
}

sub initialize_slot
{
	die "mutable is VERBOTEN";
}

sub deinitialize_slot
{
	die "mutable is VERBOTEN";
}

##	= Class::MOP::Instance
##
##	sub initialize_all_slots
##	sub deinitialize_all_slots

sub is_slot_initialized
{
	die "mutable is VERBOTEN";
}

sub weaken_slot_value
{
	my ( $self, $instance, $slot_name )	= @_;

	die "weak refs for '$slot_name' are VERBOTEN (mutable)";
}

sub strengthen_slot_value
{
	my ( $self, $instance, $slot_name )	= @_;

	die "weak refs for '$slot_name' are VERBOTEN (mutable)";
}

#	Is there a use case beside the esoteric example in
#	Moose-1.14/t/000_recipes/moose_cookbook_roles_recipe3.t	?
#
sub rebless_instance_structure
{
	die "reblessing is VERBOTEN (mutable)";
}

#	inlinable operation snippets

##	sub is_dependent_on_superclasses
##	sub is_inlinable
##	sub inline_create_instance

sub inline_slot_access
{
	die "inline_slot_access should not have been used";
}

sub inline_get_slot_value
{
	my ( $self, $invar, $slot ) = @_;

	"$invar\->_evoke ( \"$slot\" )";
}

sub inline_set_slot_value
{
	my ( $self, $invar, $slot, $valexp ) = @_;

	"$invar\->_silence ( \"$slot\", $valexp )";
}

##	sub inline_initialize_slot

sub inline_deinitialize_slot
{
	my ( $self, $invar, $slot ) = @_;

	"$invar\->_forget ( \"$slot\" )";
}

sub inline_is_slot_initialized
{
	my ( $self, $invar, $slot ) = @_;

	"$invar\->_exists ( \"$slot\" )"
}

sub inline_weaken_slot_value
{
	my ( $self, $invar, $slot ) = @_;

	die "weak refs for '$slot' are VERBOTEN (immutable)";
}

sub inline_strengthen_slot_value
{
	my ( $self, $invar, $slot ) = @_;

	die "weak refs for '$slot' are VERBOTEN (immutable)";
}

#	Is there a use case beside the esoteric example in
#	Moose-1.14/t/000_recipes/moose_cookbook_roles_recipe3.t	?
#
sub inline_rebless_instance_structure
{
	die "reblessing is VERBOTEN (immutable)";
}

#	PRIVATE METHODS
#

#	CALLBACKS
#

#	IMMUTABLE
#
no Moose::Role;

#	__PACKAGE__->meta->make_immutable ( debug => 0 );

1;

__END__

=head1 NAME

Frost::Meta::Instance - The Runner

=head1 ABSTRACT

No documentation yet...

=head1 DESCRIPTION

No user maintainable parts inside ;-)

=for comment CLASS VARS

=for comment CLASS METHODS

=for comment PUBLIC ATTRIBUTES

=for comment PRIVATE ATTRIBUTES

=for comment CONSTRUCTORS

=for comment DESTRUCTORS

=head1 PUBLIC METHODS

=head2 bless_instance_structure

=head2 clone_instance

=head2 get_slot_value

=head2 set_slot_value

=head2 initialize_slot

=head2 deinitialize_slot

=head2 is_slot_initialized

=head2 weaken_slot_value

=head2 strengthen_slot_value

=head2 rebless_instance_structure

=head2 inline_slot_access

=head2 inline_get_slot_value

=head2 inline_set_slot_value

=head2 inline_deinitialize_slot

=head2 inline_is_slot_initialized

=head2 inline_weaken_slot_value

=head2 inline_strengthen_slot_value

=head2 inline_rebless_instance_structure

=for comment PRIVATE METHODS

=for comment CALLBACKS

=for comment IMMUTABLE

=head1 GETTING HELP

I'm reading the Moose mailing list frequently, so please ask your
questions there.

The mailing list is L<moose@perl.org>. You must be subscribed to send
a message. To subscribe, send an empty message to
L<moose-subscribe@perl.org>

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception.

Please report any bugs to me or the mailing list.

=head1 AUTHOR

Ernesto L<ernesto@dienstleistung-kultur.de>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Dienstleistung Kultur Ltd. & Co. KG

L<http://dienstleistung-kultur.de/frost/>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
