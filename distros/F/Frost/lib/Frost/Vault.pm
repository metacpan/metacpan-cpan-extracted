package Frost::Vault;

#	LIBS
#
use Moose;

extends 'Frost::Burial';

use Frost::Util;

#	CLASS VARS
#
our $VERSION	= 0.62;
our $AUTHORITY	= 'cpan:ERNESTO';

#	CLASS METHODS
#
sub suffix { '.vlt' }

#	PUBLIC ATTRIBUTES
#

#	PRIVATE ATTRIBUTES
#

#	CONSTRUCTORS
#
sub _build_numeric	{ false; }																	#	always
sub _build_unique		{ true; }																	#	always

sub BUILDARGS			#	Burial::BUILDARGS is NOT called
{
	my $class	= shift;

	my $params	= Moose::Object->BUILDARGS ( @_ );

	( defined $params->{data_root} )		or die 'Attribute (data_root) is required';
	( defined $params->{classname} )		or die 'Attribute (classname) is required';

	$params->{slotname}	= 'burial';

	return $params;
}

#	DESTRUCTORS
#

#	PUBLIC METHODS
#
sub autoincrement
{
	my ( $self )	= @_;

	my $last	= $self->exhume ( 'autoincrement' );

	$last	||= 0;

	$last++;

	$self->entomb ( 'autoincrement', $last );

	$last;
}

#	PRIVATE METHODS
#

#	CALLBACKS
#

#	IMMUTABLE
#
no Moose;

__PACKAGE__->meta->make_immutable ( debug => 0 );

1;

__END__

=head1 NAME

Frost::Vault - Don't look back

=head1 ABSTRACT

No documentation yet...

=head1 DESCRIPTION

No user maintainable parts inside ;-)

=for comment CLASS VARS

=head1 CLASS METHODS

=head2 Frost::Vault->suffix()

Returns '.vlt'

=for comment PUBLIC ATTRIBUTES

=for comment PRIVATE ATTRIBUTES

=head1 CONSTRUCTORS

=head2 Frost::Vault->new ( %params )

=head2 _build_numeric

=head2 _build_unique

=head2 BUILDARGS

=for comment DESTRUCTORS

=head1 PUBLIC METHODS

=head2 autoincrement

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
