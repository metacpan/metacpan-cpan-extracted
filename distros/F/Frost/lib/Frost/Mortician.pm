package Frost::Mortician;

#	LIBS
#
use Moose;

use Storable 2.21 ();

use Frost::Types;
use Frost::Util;
use Frost::Lock;

use Frost::Vault;
use Frost::Cemetery;
use Frost::Illuminator;

#	CLASS VARS
#
our $VERSION	= 0.62;
our $AUTHORITY	= 'cpan:ERNESTO';

#	CLASS METHODS
#

#	PUBLIC ATTRIBUTES
#
has classname		=> ( isa => 'ClassName',			is => 'ro',								required => true,		);
has data_root		=> ( isa => 'Frost::FilePathMustExist',	is => 'ro',								required => true,		);
has cachesize		=> ( isa => 'Frost::Natural',					is => 'ro',	default => DEFAULT_CACHESIZE,					);

#	PRIVATE ATTRIBUTES
#
has _vault			=> ( isa => 'Frost::Vault',						is	=> 'ro',	init_arg => undef,	lazy_build	=> 1,	);
has _cemetery		=> ( isa => 'HashRef[Frost::Cemetery]',		is	=> 'ro',	init_arg => undef,	lazy_build	=> 1,	);
has _illuminator	=> ( isa => 'HashRef[Frost::Illuminator]',	is	=> 'ro',	init_arg => undef,	lazy_build	=> 1,	);

#	CONSTRUCTORS
#
sub _build__vault
{
	my $self	= shift;

	Frost::Vault->new
		(
			data_root	=> $self->data_root,
			classname	=> $self->classname,
			cachesize	=> $self->cachesize,
		);
}

sub _build__cemetery
{
	my $self	= shift;

	my $cemetery	= {};

	foreach my $attr ( $self->classname->meta->get_all_attributes() )
	{
		next	if $attr->is_virtual;
		next	if $attr->is_transient;

		my $name		= $attr->name;

		$cemetery->{$name}	= Frost::Cemetery->new
										(
											data_root	=> $self->data_root,
											classname	=> $self->classname,
											slotname		=> $name,
											cachesize	=> $self->cachesize,
										);
	}

	return $cemetery;
}

sub _build__illuminator
{
	my $self	= shift;

	my $illuminator	= {};

	foreach my $attr ( $self->classname->meta->get_all_attributes() )
	{
		next	unless $attr->is_index;

		my $name		= $attr->name;

		$illuminator->{$name}	= Frost::Illuminator->new
										(
											data_root	=> $self->data_root,
											classname	=> $self->classname,
											slotname		=> $name,
											cachesize	=> $self->cachesize,
										);
	}

	return $illuminator;
}

#	DESTRUCTORS
#

#	PUBLIC METHODS
#
sub work		{ $_[0]->_dispatch ( 'open'	);	}
sub leisure	{ $_[0]->_dispatch ( 'close'	);	}
sub save		{ $_[0]->_dispatch ( 'save'	);	}
sub clear	{ $_[0]->_dispatch ( 'clear'	);	}
sub remove	{ $_[0]->_dispatch ( 'remove'	);	}

sub autoincrement
{
	my ( $self )	= @_;

	$self->_vault()->autoincrement();
}

sub exists
{
	my ( $self, $id, $slot )	= @_;

	my $count	= $self->count ( $id, $slot );

	return ( $count ? true : false );
}

sub bury
{
	my ( $self, $id, $slot, $spirit )	= @_;

	my $cemetery	= $self->_cemetery->{$slot};

	##IS_DEBUG and DEBUG Dump [ $id, $slot, $spirit, $cemetery ], [qw( id slot spirit cemetery )];

	return false	unless defined $cemetery;

#	my $essence	= Storable::nfreeze ( $spirit );
	my $essence	= ref ( $spirit ) ? Storable::nfreeze ( $spirit ) : $spirit;

	my $success	= $cemetery->entomb ( $id, $essence );

	#IS_DEBUG and DEBUG 'CEM', Dump [ $slot, $id, $essence, $success ], [qw( slot id essence success )];

	if ( $success and my $illuminator = $self->_illuminator->{$slot} )
	{
	#	my $key	= $spirit->{ VALUE_TYPE() };
		my $key	= $spirit;

		$success	= $illuminator->collect ( $key, $id );

		#IS_DEBUG and DEBUG 'ILL', Dump [ $key, $id, $success ], [qw( key id success )];
	}

	return $success;
}

sub grub
{
	my ( $self, $id, $slot )	= @_;

	$slot	||= 'id';

	my $cemetery	= $self->_cemetery->{$slot};

	return undef	unless defined $cemetery;

	my $essence	= $cemetery->exhume ( $id );

	return undef	unless $essence;

	my $spirit	= Storable::read_magic ( $essence ) ? Storable::thaw ( $essence ) : $essence;

	return $spirit;
}

sub forget
{
	my ( $self, $id, $slot, $spirit )	= @_;

	my $cemetery	= $self->_cemetery->{$slot};

	##IS_DEBUG and DEBUG Dump [ $id, $slot, $spirit, $cemetery ], [qw( id slot spirit cemetery )];

	return false	unless defined $cemetery;

	my $success	= $cemetery->forget ( $id );

	#IS_DEBUG and DEBUG 'CEM', Dump [ $slot, $id, $success ], [qw( slot id success )];

	if ( $success and my $illuminator = $self->_illuminator->{$slot} )
	{
	#	my $key	= $spirit->{ VALUE_TYPE() };
		my $key	= $spirit;

		$success	= $illuminator->forget ( $key, $id );

		#IS_DEBUG and DEBUG 'ILL', Dump [ $key, $id, $success ], [qw( key id success )];
	}

	return $success;
}

sub count
{
	my ( $self, $id, $slot, $use_index )	= @_;

	$slot	||= 'id';

	if ( $use_index )
	{
		my $illuminator	= $self->_illuminator->{$slot};

		return undef		unless defined $illuminator;

		return $illuminator->count ( $id );		#	key !!!
	}
	else
	{
		my $cemetery	= $self->_cemetery->{$slot};

		return undef		unless defined $cemetery;

		return $cemetery->count ( $id );
	}
}

sub lookup
{
	my ( $self, $key, $slot )	= @_;

	$slot	||= 'id';

	my @list	= ();
	my $id	= '';

	if ( $slot eq 'id' )
	{
		@list	= ( $key )	if $self->exists ( $key );
	}
	else
	{
		my $illuminator = $self->_illuminator->{$slot};

		return ( wantarray ? () : '' )		unless defined $illuminator;

		@list	= $illuminator->lookup ( $key );
	}

	$id	= $list[0]		if @list;

	return wantarray ? @list : $id;
}

sub match		{ shift()->_search ( 'match',			@_	);	}
sub match_last	{ shift()->_search ( 'match_last',	@_	);	}
sub match_next	{ shift()->_search ( 'match_next',	@_	);	}
sub match_prev	{ shift()->_search ( 'match_prev',	@_	);	}
sub find			{ shift()->_search ( 'find',			@_	);	}
sub find_last	{ shift()->_search ( 'find_last',	@_	);	}
sub find_next	{ shift()->_search ( 'find_next',	@_	);	}
sub find_prev	{ shift()->_search ( 'find_prev',	@_	);	}
sub first		{ shift()->_search ( 'first',			@_	);	}
sub last			{ shift()->_search ( 'last',			@_	);	}
sub next			{ shift()->_search ( 'next',			@_	);	}
sub prev			{ shift()->_search ( 'prev',			@_	);	}

#	PRIVATE METHODS
#
sub _dispatch
{
	my ( $self, $work )	= @_;

	while ( my ( $slot, $cemetery ) = each %{ $self->_cemetery() || {} } )
	{
		$cemetery->$work();
	}

	while ( my ( $slot, $illuminator ) = each %{ $self->_illuminator() || {} } )
	{
		$illuminator->$work();
	}

	return true;
}

sub _search
{
	my ( $self, $method, $key, $slot )	= @_;

	$slot	||= 'id';

	my ( $burial, $id );

	if ( $slot eq 'id' )	{ $burial	= $self->_cemetery->{$slot};		}
	else						{ $burial	= $self->_illuminator->{$slot};	}

	return ( wantarray ? () : '' )		unless defined $burial;

	$burial->$method ( $key );
}

#	CALLBACKS
#

#	IMMUTABLE
#
no Moose;

__PACKAGE__->meta->make_immutable ( debug => 0 );

1;

__END__


=head1 NAME

Frost::Mortician - Clandestine helper

=head1 ABSTRACT

No documentation yet...

=head1 DESCRIPTION

No user maintainable parts inside ;-)

=for comment CLASS VARS

=for comment CLASS METHODS

=head1 PUBLIC ATTRIBUTES

=head2 classname

=head2 data_root

=head2 cachesize

=head1 PRIVATE ATTRIBUTES

=head2 _vault

=head2 _cemetery

=head2 _illuminator

=head1 CONSTRUCTORS

=head2 Frost::Mortician->new ( %params )

=head2 _build__vault

=head2 _build__cemetery

=head2 _build__illuminator

=for comment DESTRUCTORS

=head1 PUBLIC METHODS

=head2 work

=head2 leisure

=head2 save

=head2 clear

=head2 remove

=head2 autoincrement

=head2 exists

=head2 bury

=head2 grub

=head2 forget

=head2 count

=head2 lookup

=head2 match

=head2 match_last

=head2 match_next

=head2 match_prev

=head2 find

=head2 find_last

=head2 find_next

=head2 find_prev

=head2 first

=head2 last

=head2 next

=head2 prev

=head1 PRIVATE METHODS

=head2 _dispatch

=head2 _search

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
