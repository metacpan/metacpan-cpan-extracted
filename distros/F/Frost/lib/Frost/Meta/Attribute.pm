package Frost::Meta::Attribute;

#	LIBS
#
use Moose::Role;

use Frost::Util;

#	CLASS VARS
#
our $VERSION	= 0.65;
our $AUTHORITY	= 'cpan:ERNESTO';

#	CLASS METHODS
#

#around legal_options_for_inheritance => sub
#{
#	return (shift->(@_), qw/derived virtual index transient auto_id auto_inc/);
#};

#	PUBLIC ATTRIBUTES
#
has transient =>
(
	isa		=> 'Bool',
	reader	=> 'is_transient',
	default	=> false,
);

has derived =>
(
	isa		=> 'Bool',
	reader	=> 'is_derived',
	default	=> false,
);

has virtual =>
(
	isa		=> 'Bool',
	reader	=> 'is_virtual',
	default	=> false,
);

has index =>
(
	isa		=> 'Bool|Str',
	reader	=> 'is_index',
	default	=> false,
);

has auto_id =>
(
	isa		=> 'Bool',
	reader	=> 'is_auto_id',
	default	=> false,
);

has auto_inc =>
(
	isa		=> 'Bool',
	reader	=> 'is_auto_inc',
	default	=> false,
);

#	PRIVATE ATTRIBUTES
#

#	CONSTRUCTORS
#

#	DESTRUCTORS
#

#	PUBLIC METHODS
#
sub is_readonly
{
	( $_[0]->_is_metadata() eq 'ro' ) ? true : false;
}

sub is_unique
{
	( $_[0]->is_index() and $_[0]->is_index() eq 'unique' ) ? true : false;
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

Frost::Meta::Attribute - Sweets for my sweet, sugar for my honey

=head1 SYNOPSIS

               Locum  Twilight  Cemetery  Illuminator
   Feature                                             Access (default)

   transient   X      -         -         -            r/w   (ro)
   virtual     -      X         -         -            r/w   (ro)
   derived     -      X         -         -            ro    (ro)
   index       -      X         X         X            r/w   (--)
   (none)      -      X         X         -            r/w   (--)

   Attr "id"   X      X         X         -            ro    (ro)

   A transient attribute lives at run-time and is "local":
   It becomes undef, when the Locum object goes out of scope,
   and it is not stored.

   A virtual attribute lives at run-time and is "global":
   It is still present, when the Locum object goes out of scope,
   but it is not stored.

   The definition

      has deri_att => ( derived => 1, isa => 'Str' );

   is a shortcut for:

      has deri_att => ( virtual => 1, isa => 'Str', is => 'ro', lazy_build => 1 );

   which becomes:

      has deri_att =>
      (
         virtual   => 1,
         is        => 'ro',
         isa       => 'Str',
         lazy      => 1,                   # lazy_build...
         builder   => '_build_deri_att',	 #
         clearer   => 'clear_deri_att',	 #
         predicate => 'has_deri_att',		 #
      );

=head1 ABSTRACT

No documentation yet...

=head1 DESCRIPTION

No user maintainable parts inside ;-)

=for comment CLASS VARS

=head1 CLASS METHODS

=head2 Frost::Meta::Attribute->legal_options_for_inheritance ( @_ )

=head1 PUBLIC ATTRIBUTES

=head2 transient

=head2 derived

=head2 virtual

=head2 index

=head2 auto_id

=head2 auto_inc

=for comment PRIVATE ATTRIBUTES

=for comment CONSTRUCTORS

=for comment DESTRUCTORS

=head1 PUBLIC METHODS

=head2 is_readonly

=head2 is_unique

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
cut
