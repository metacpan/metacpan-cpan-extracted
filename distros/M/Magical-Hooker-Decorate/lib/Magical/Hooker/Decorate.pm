package Magical::Hooker::Decorate;

use strict;
use warnings;

require 5.008001;
use parent qw(DynaLoader);

our $VERSION = '0.03';
$VERSION = eval $VERSION;

sub dl_load_flags { 0x01 }

__PACKAGE__->bootstrap($VERSION);


sub new { bless {}, shift };

__PACKAGE__

__END__

=head1 NAME

Magical::Hooker::Decorate - Decorate an SV using magic hooks

=head1 SYNOPSIS

=head2 From Perl

	# this object serves as a namespace, you can only get values that were set
	# by it, so you probably want to have a single instance for your module in
	# some global variable
	my $hooker = Magical::Hooker::Decorate->new;

	# associate an SV like this
	$hooker->set(\$var, $decoration);

	# get the associate value like this:
	my $decoration = $hooker->get(\$var);

=head2 From C

	magical_hooker_decoration_set(target_sv, decoration_sv, (void *)self);

	decoration_sv = magical_hooker_decoration_get(target_sv, (void *)self);

=head1 DESCRIPTION

This module provides a C api and a thin Perl wrapper that lets you associate a
value with any SV, much like L<Hash::Util::FieldHash> does.

The decoration will be reference counted, so C<DESTROY> will be called when
C<target> disappears.

This lets you do things like:

	$hooker->set($object, Scope::Guard->new(sub {
		warn "object just died";
	});

and of course also access the value of the decoration.

The code was used to associate code references created with C<newXS> with their
associated objects in L<Moose>'s experimental XS branch.

=head1 METHODS

=over 4

=item new

Takes no arguments, and returns a handle.

All the association methods use storage that is private to the handle.

=item set $target, $value

Note that C<$target> is dereferenced before casting magic.

=item get $target

Returns the value.

=item clear

Removes the value.

=back

=head1 C API

=over 4

=item MAGIC *magical_hooker_decoration_set (pTHX_ SV *sv, SV *obj, void *ptr)

Creates a new C<MAGIC> entry on C<sv> and stores C<obj> in the C<mg_obj>.
C<mg_ptr> is set to C<ptr>, which allows for namespacing.

In the OO api C<sv> is the dereferenced target, and C<ptr> is the dereferenced C<$self>.

C<ptr> can be C<NULL> but then you're limited to one decoration per SV.

=item SV *magical_hooker_decoration_get (pTHX_ SV *sv, void *ptr)

Get the C<mg_obj>.

=item SV *magical_hooker_decoration_clear (pTHX_ SV *sv, void *ptr)

Removes the C<MAGIC> and returns the C<mg_obj> (after mortalizing it).

=item MAGIC *magical_hooker_decoration_get_mg (pTHX_ SV *sv, void *ptr = NULL)

Get the C<MAGIC> entry in which the decoration is stored.

=back

=head1 THANKS

Shawn M Moore (he knows why)

=head1 VERSION CONTROL

L<http://github.com/nothingmuch/magical-hooker-decorate>

=head1 AUTHOR

Yuval Kogman

=head1 COPYRIGHT & LICENSE

	Copyright (c) 2008, 2009 Yuval Kogman. All rights reserved
	This program is free software; you can redistribute
	it and/or modify it under the same terms as Perl itself.

=cut

