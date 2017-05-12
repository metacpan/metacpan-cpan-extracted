package Frost::Twilight;

#	LIBS
#
use Moose;

use Frost::Types;
use Frost::Util;

use Frost::Twilight::LRU;

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
has _asylum		=>
(
	isa			=> 'Frost::Asylum',
	is				=> 'ro',
	init_arg		=> 'asylum',
	required		=> true,
	weak_ref		=> true,		#	!!!
);

has _spirit		=> ( isa => 'HashRef',									is => 'ro',	init_arg => undef, default => sub { {} }	);
has _maxcount	=> ( isa => 'Frost::Whole',							is => 'ro',	init_arg => undef, lazy_build	=> true,		);
has _lru			=> ( isa => 'Frost::Twilight::LRU',	is => 'ro',	init_arg => undef, lazy_build	=> true,		);


#	CONSTRUCTORS
#
sub _build__maxcount
{
	#	This is a heuristic value, see t/500_speed/100_twilight_mem.t
	#
	int ( ( 20_000 / DEFAULT_CACHESIZE() ) * $_[0]->_asylum->cachesize );
}

sub _build__lru
{
	my ( $self )	= @_;

	my $spirit	= $self->_spirit;

	tie %$spirit, 'Frost::Twilight::LRU', $self->_maxcount, $self;
}

sub BUILD
{
	$_[0]->_lru();	#	trigger tie AFTER object creation (asylum valid!) but BEFORE first access to _spirit...
}

#	DESTRUCTORS
#
sub DEMOLISH
{
	#print STDERR __PACKAGE__ . "::DEMOLISH ( @_ )\n";

	my $spirit	= $_[0]->_spirit;

	$_[0]->{_lru}	= undef;

	untie %$spirit;
}

#	PUBLIC METHODS
#
sub maxcount	{ shift()->_lru()->max_size ( @_ ) }

sub count		{ $_[0]->_lru()->curr_size() }

sub exists		{ exists $_[0]->_spirit->{ $_[1] . '|' . $_[2] }; }

sub get			{ $_[0]->_spirit->{ $_[1] . '|' . $_[2] }; }

sub set			{ $_[0]->_spirit->{ $_[1] . '|' . $_[2] } = $_[3]; }

sub del			{ delete $_[0]->_spirit->{ $_[1] . '|' . $_[2] }; }

sub clear
{
	%{ $_[0]->_spirit }	= ();		#	That's the right way !
}

sub save
{
	#IS_DEBUG and DEBUG 'start', Dump [ $_[0]->_spirit ], [qw( _spirit )];

	while ( my ( $key, $spirit ) = each %{ $_[0]->_spirit() || {} } )
	{
		#my ( $class, $id )	= split /\|/, $key;
		#IS_DEBUG and DEBUG Dump [ $class, $id, $spirit ], [qw( class id spirit )];

#		if ( $spirit->{_dirty}->{ VALUE_TYPE() } )
		if ( $spirit->{_dirty} )
		{
#			$_[0]->_asylum->_absolve ( $class, $id, $spirit );
			$_[0]->_save ( $key, $spirit );
		}
	}
}

#	PRIVATE METHODS
#
sub _save
{
	#IS_DEBUG and DEBUG 'start', Dump [ $_[1], $_[2] ], [qw( key spirit )];

	my ( $class, $id )	= split /\|/, $_[1];

	$_[0]->_asylum->_absolve ( $class, $id, $_[2] );
}

#	CALLBACKS
#
sub _cull_callback
{
	my ( $key, $spirit )	= ( $_[1]->[0], $_[1]->[1] );

	#IS_DEBUG and DEBUG 'start', Dump [ $key, $spirit ], [qw( key spirit )];

	$_[0]->_save ( $key, $spirit );
}

#	IMMUTABLE
#
no Moose;

__PACKAGE__->meta->make_immutable ( debug => 0 );

1;

__END__


=head1 NAME

Frost::Twilight - Dimly lit back room

=head1 ABSTRACT

No documentation yet...

=head1 DESCRIPTION

No user maintainable parts inside ;-)

=for comment CLASS VARS

=for comment CLASS METHODS

=for comment PUBLIC ATTRIBUTES

=head1 PRIVATE ATTRIBUTES

=head2 _asylum

=head2 _spirit

=head2 _maxcount

=head2 _lru

=head1 CONSTRUCTORS

=head2 Frost::Twilight->new ( %params )

=head2 _build__maxcount

=head2 _build__lru

=head2 BUILD

=head1 DESTRUCTORS

=head2 DEMOLISH

=head1 PUBLIC METHODS

=head2 maxcount

=head2 count

=head2 exists

=head2 get

=head2 set

=head2 del

=head2 clear

=head2 save

=head1 PRIVATE METHODS

=head2 _save

=head1 CALLBACKS

=head2 _cull_callback

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
