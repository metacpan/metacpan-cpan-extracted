package Frost::Asylum;

#	LIBS
#
use Moose;

use Frost::Types;
use Frost::Util;

use Frost::Lock;
use Frost::Twilight;
use Frost::Necromancer;

#	CLASS VARS
#
our $VERSION	= 0.62;
our $AUTHORITY	= 'cpan:ERNESTO';

#	CLASS METHODS
#

#	PUBLIC ATTRIBUTES
#
has data_root		=> ( isa => 'Frost::FilePathMustExist',	is => 'ro',								required => true,		);
has cachesize		=> ( isa => 'Frost::Natural',					is => 'ro',	default => DEFAULT_CACHESIZE,					);

#	PRIVATE ATTRIBUTES
#
has _lock			=> ( isa => 'Frost::Lock',				is	=> 'ro',	init_arg => 'lock',	lazy_build => true,	);
has _twilight		=> ( isa => 'Frost::Twilight',		is	=> 'ro',	init_arg => undef,	lazy_build => true,	);
has _necromancer	=> ( isa => 'Frost::Necromancer',	is	=> 'ro',	init_arg => undef,	lazy_build => true,	);

#	CONSTRUCTORS
#
sub _build__lock
{
	my ( $self )	= @_;

	my $param	=
	{
		lock_filename	=> make_file_path ( $self->data_root, '.lock' ),
	};

	Frost::Lock->new ( $param );
}

sub _build__twilight
{
	my ( $self )	= @_;

	my $param	=
	{
#		data_root	=> $self->data_root,
#		cachesize	=> $self->cachesize,
		asylum		=> $self,
	};

	Frost::Twilight->new ( $param );
}

sub _build__necromancer
{
	my ( $self )	= @_;

	my $param	=
	{
		data_root	=> $self->data_root,
		cachesize	=> $self->cachesize,
	};

	Frost::Necromancer->new ( $param );
}

#	DESTRUCTORS
#
sub DEMOLISH
{
	#print STDERR __PACKAGE__ . "::DEMOLISH ( @_ )\n";

	$_[0]->{_lock}				= undef;
	$_[0]->{_twilight}		= undef;
	$_[0]->{_necromancer}	= undef;
}

#	PUBLIC METHODS
#
sub twilight_maxcount
{
	$_[0]->_twilight->maxcount ( $_[1] )	if @_ == 2;
	$_[0]->_twilight->maxcount();
}

sub twilight_count
{
	$_[0]->_twilight->count();
}

sub lock			{ $_[0]->_lock->lock;	}
sub unlock		{ $_[0]->_lock->unlock;	}
sub is_locked	{ $_[0]->_lock->is_locked;	}

sub open
{
	#IS_DEBUG and DEBUG "( @_ )";

	my ( $self )	= @_;

	return true		if $self->is_locked;

	my $success	= $self->lock();

	$self->_necromancer()->work()		if $success;

	return $success;
}

sub close
{
	#IS_DEBUG and DEBUG "( @_ )";

	my ( $self )	= @_;

	return true		unless $self->is_locked;

	$self->save();

	$self->_twilight()->clear();

	$self->_necromancer()->leisure();

	my $success	= $self->unlock();

	return $success;
}

sub save
{
	#IS_DEBUG and DEBUG "( @_ )";

	my ( $self )	= @_;

	$self->open();

	$self->_twilight()->save ( $self );		#	calls _absolve !!!

	$self->_necromancer()->save();

	return true;
}

sub clear
{
	#IS_DEBUG and DEBUG "( @_ )";

	my ( $self )	= @_;

	$self->open();

	$self->_twilight()->clear();

	$self->_necromancer()->clear();

	return true;
}

sub remove
{
	#IS_DEBUG and DEBUG "( @_ )";

	my ( $self )	= @_;

	$self->open();

	$self->_twilight()->clear();

	$self->_necromancer()->remove();

	return true;
}

sub autoincrement
{
	my ( $self, $class )	= @_;

	( defined $class )						or die 'Param class missing';

	$self->open();

	$self->_necromancer()->autoincrement ( $class );
}

sub silence
{
	my ( $self, $class, $id, @params )	= @_;

	( defined $class )						or die 'Param class missing';

	$self->open();

	my $params			= Moose::Object->BUILDARGS ( @params );

	$params->{asylum}	= $self;
	$params->{id}		= $id			if $id;	#	might be auto_id/inc

	$class->new ( $params );
}

sub evoke
{
	my ( $self, $class, $id )	= @_;

	( defined $class )						or die 'Param class missing';
	( defined $id )							or die 'Param id missing';

	$self->open();

	( $self->exists ( $class, $id ) )	or die "Can not evoke un-silenced $class\->$id";

	my $params			= {};

	$params->{asylum}	= $self;
	$params->{id}		= $id;

	$class->new ( $params );
}

sub absolve
{
	my ( $self, $class, $id )	= @_;

	( defined $class )						or die 'Param class missing';
	( defined $id )							or die 'Param id missing';

	$self->open();

	my $spirit	= $self->_twilight->get ( $class, $id );

	( defined $spirit )						or die "Can not absolve un-evoked $class\->$id";

	$self->_absolve ( $class, $id, $spirit );
}

sub excommunicate
{
	my ( $self, $class, $id )	= @_;

	( defined $class )						or die 'Param class missing';
	( defined $id )							or die 'Param id missing';

	$self->open();

	#IS_DEBUG and DEBUG 'start', Dump [ $class, $id ], [qw( class id )];

	( $self->exists ( $class, $id ) )	or die "Can not excommunicate un-absolved $class\->$id";

	#	we have to update illuminators too, so evoke all first...
	#
	my @attributes	= $class->meta->get_all_attributes;

	foreach my $attr ( @attributes )
	{
		next	if $attr->is_virtual;
		next	if $attr->is_transient;

		my $slot_name		= $attr->name;

		$self->_evoke ( $class, $id, $slot_name );
	}

	my $spirit	= $self->_twilight->get ( $class, $id );	#	now complete

	foreach my $attr ( @attributes )
	{
		next	if $attr->is_virtual;
		next	if $attr->is_transient;

		my $slot_name		= $attr->name;

		if ( exists $spirit->{$slot_name} and defined $spirit->{$slot_name} )
		{
			my $slot_spirit	= $spirit->{$slot_name};

			$self->_necromancer()->forget ( $class, $id, $slot_name, $slot_spirit );
		}
	}

	$self->_twilight->del ( $class, $id );
}

sub exists
{
	my ( $self, $class, $id )	= @_;

	( defined $class )						or die 'Param class missing';
	( defined $id )							or die 'Param id missing';

	#	we have to check this early, otherwise Mortician->new etc. will die...
	#
	return false	unless check_type_manuel 'ClassName', $class, true;	#	silent

	#	see also Frost::Burial::_check_key

	my $slot	= 'id';

	$self->_exists ( $class, $id, $slot );
}

sub count
{
	my ( $self, $class, $id, $slot, $use_index )	= @_;

	( defined $class )						or die 'Param class missing';
#	( defined $id )							or die 'Param id missing';

	return false	unless check_type_manuel 'ClassName', $class, true;	#	silent

	$slot	||= 'id';

	$self->_count ( $class, $id, $slot, $use_index );
}

sub lookup
{
	my ( $self, $class, $key, $slot )	= @_;

	( defined $class )						or die 'Param class missing';
#	( defined $key )							or die 'Param key missing';

	return false	unless check_type_manuel 'ClassName', $class, true;	#	silent

	$slot	||= 'id';

	$self->_lookup ( $class, $key, $slot );
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
sub _search
{
	my ( $self, $method, $class, $key, $slot_name )	= @_;

	( defined $class )						or die 'Param class missing';
#	( defined $key )							or die 'Param key missing';

	#IS_DEBUG and DEBUG 'start', Dump [ $method, $class, $key, $slot_name ], [qw( method class key slot_name )];

#	return false	unless check_type_manuel 'ClassName', $class;			#	kill
	return false	unless check_type_manuel 'ClassName', $class, true;	#	silent

	$self->open();

	$self->_necromancer()->$method ( $class, $key, $slot_name );
}

sub _exists
{
	my ( $self, $class, $id, $slot_name )	= @_;

	$self->open();

	$slot_name	||= 'id';

	my $spirit	= $self->_twilight->get ( $class, $id );

	my $found;

	if ( defined $spirit )
	{
		$found	= ( exists $spirit->{$slot_name} and defined $spirit->{$slot_name} );
	}

	unless ( $found )		#	not evoked yet...
	{
		$found	= $self->_necromancer()->exists ( $class, $id, $slot_name );
	}

	#IS_DEBUG and DEBUG 'done', Dump [ $class, $id, $slot_name, $found ], [qw( class id slot_name found )];

	return ( $found ? true : false );
}

sub _count
{
	my ( $self, $class, $id, $slot_name, $use_index )	= @_;

#	my $count	= $self->_necromancer()->count ( $class, $id, $slot_name, $use_index );
#
#	#IS_DEBUG and DEBUG 'done', Dump [ $class, $id, $slot_name, $use_index, $self ], [qw( class id slot_name found use_index self )];
#
#	return $count;

	$self->open();

	$self->_necromancer()->count ( $class, $id, $slot_name, $use_index );
}

sub _lookup
{
	my ( $self, $class, $key, $slot_name )	= @_;

	$self->open();

	$self->_necromancer()->lookup ( $class, $key, $slot_name );
}

#	following methods are only called from Frost::Locum
#
sub _silence
{
	my ( $self, $class, $id, $slot_name, $value )	= @_;

	$self->open();

	my $spirit	= $self->_twilight->get ( $class, $id );

	#IS_DEBUG and DEBUG 'start', Dump [ $class, $id, $slot_name, $value, $spirit ], [qw( class id slot_name value spirit )];

	unless ( defined $spirit )
	{
	#	$spirit	= { id => { VALUE_TYPE() => $id } };
		$spirit	= { id => $id };

		$self->_twilight->set ( $class, $id, $spirit );
	}

	my $is_index			= $class->meta->is_index ( $slot_name );

	if ( $is_index )
	{
		my $old_spirit		= $self->_necromancer()->evoke ( $class, $id, $slot_name );

		if ( $old_spirit )		#	defined?
		{
			$self->_necromancer()->forget ( $class, $id, $slot_name, $old_spirit );
		}
	}

	my $new_spirit		= $self->_silence_slot ( $value );

	$spirit->{$slot_name}	= $new_spirit;

	if ( $is_index )
	{
		$self->_necromancer()->silence ( $class, $id, $slot_name, $new_spirit );
	}

	#IS_DEBUG and DEBUG 'done', Dump [ $class, $id, $slot_name, $value, $spirit, $is_index ], [qw( class id slot_name value spirit is_index )];

	return true;
}

sub _evoke
{
	my ( $self, $class, $id, $slot_name )	= @_;

	$self->open();

	$slot_name	||= 'id';

	my $spirit	= $self->_twilight->get ( $class, $id );

	#IS_DEBUG and DEBUG 'start', Dump [ $class, $id, $slot_name, $spirit ], [qw( class id slot_name spirit )];

	unless ( defined $spirit )
	{
		$self->_silence ( $class, $id, 'id', $id );		#	create base twilight entry

		$spirit	= $self->_twilight->get ( $class, $id );
	}

	my $slot_spirit	= $spirit->{$slot_name};

	unless ( defined $slot_spirit )
	{
		$slot_spirit	= $self->_necromancer()->evoke ( $class, $id, $slot_name );

		$spirit->{$slot_name}	= $slot_spirit;
	}

	my $value	= $self->_evoke_slot ( $slot_spirit );

	#IS_DEBUG and DEBUG 'done', Dump [ $class, $id, $slot_name, $spirit, $slot_spirit, $value ], [qw( class id slot_name spirit slot_spirit value )];

	return $value;
}

sub _forget
{
	my ( $self, $class, $id, $slot_name )	= @_;

	$self->open();

	$slot_name	||= 'id';

	my $spirit	= $self->_twilight->get ( $class, $id );

	#IS_DEBUG and DEBUG 'start', Dump [ $class, $id, $slot_name, $spirit ], [qw( class id slot_name spirit )];

	if ( defined $spirit )
	{
		my $slot_spirit	= delete $spirit->{$slot_name};

		$self->_necromancer()->forget ( $class, $id, $slot_name, $slot_spirit );
	}
}

#	following methods are only called internally
#
sub _silence_slot
{
	my ( $self, $value )	= @_;

	my ( $type, $class, $ref )	= $self->_silence_type ( $value );

	my $content;

	if		( $type eq VALUE_TYPE )
	{
		$content	= $value;
	}
	elsif	( $type eq ARRAY_TYPE )
	{
		$content	= $self->_silence_array ( $value );
	}
	elsif	( $type eq HASH_TYPE )
	{
		$content	= $self->_silence_hash ( $value );
	}
	elsif	( $type eq CLASS_TYPE )
	{
		$content		= $self->_silence_locum ( $class, $ref, $value );
	}
	else
	{
		die 'Unknown type of value' . Dump ( [ $value ], [qw( value )] );
	}

#	my $slot_spirit	= { $type => $content };
	my $slot_spirit	= $type eq CLASS_TYPE ? { $type => $content } : $content;

	##IS_DEBUG and DEBUG 'done', Dump [ $slot_spirit ], [qw( slot_spirit )];

	return $slot_spirit;
}

sub _silence_array
{
	my ( $self, $aValues )		= @_;

	my $array	= [];

	foreach my $value ( @{ $aValues || [] } )
	{
		my $content	= $self->_silence_slot ( $value );

		push @$array, $content;
	}

	return $array;
}

sub _silence_hash
{
	my ( $self, $hValues )		= @_;

	my $hash	= {};

	while ( my ( $key, $value ) = each %{ $hValues || {} } )
	{
		my $content	= $self->_silence_slot ( $value );

		$hash->{$key}	= $content;
	}

	return $hash;
}

sub _silence_locum
{
	my ( $self, $class, $ref, $oValue )		= @_;

	##IS_DEBUG and DEBUG 'start', Dump [ $class, $ref, $oValue ], [qw( class ref oValue )];
	#IS_DEBUG and DEBUG 'start', blessed ( $oValue ), '->', $oValue->{id};

#	$oValue->save()		if $oValue->_dirty;			#	the opposite of new...

	$self->absolve ( $class, $ref ) 					if $oValue->_dirty;			#	the opposite of new...

	my $spirit	=	{ TYPE_ATTR() => $class, REF_ATTR() => $ref };

	#IS_DEBUG and DEBUG 'done', Dump [ $spirit ], [qw( spirit )];

	return $spirit;
}

sub _silence_type
{
	my ( $self, $value )		= @_;

	my ( $type, $class, $ref );

	if ( ref ( $value ) )
	{
		if		( blessed $value )
		{
			die "Cannot save $value as locum" . Dumper ( $value )
						unless $value->isa ( 'Frost::Locum' );

			$type 	= CLASS_TYPE;

			$class	= ref $value;
		#	$class	= $value->real_class;

			$ref		= $value->{id};
		}
		elsif	( ref ( $value ) eq 'ARRAY' )	{ $type 	= ARRAY_TYPE;	}
		elsif	( ref ( $value ) eq 'HASH' )	{ $type 	= HASH_TYPE;	}
		else	{ die 'Unknown reference ' . ref ( $value ) . ' for' . ( Dump [ $value ], [qw( value )] ) }
	}
	else	{ $type 	= VALUE_TYPE;	}

	return ( $type, $class, $ref );
}

sub _evoke_slot
{
	my ( $self, $slot_spirit )	= @_;

	return undef	unless defined $slot_spirit;

	my ( $type, $class, $ref, $value )	= $self->_evoke_type ( $slot_spirit );

	##IS_DEBUG and DEBUG 'start', Dump [ $type, $class, $ref, $value ], [qw( type class ref value )];

	my $content;

	if		( $type eq VALUE_TYPE )
	{
		$content		= $value;
	}
	elsif	( $type eq ARRAY_TYPE )
	{
		$content		= $self->_evoke_array ( $value );
	}
	elsif	( $type eq HASH_TYPE )
	{
		$content		= $self->_evoke_hash ( $value );
	}
	elsif	( $type eq CLASS_TYPE )
	{
		$content		= $self->_evoke_locum ( $class, $ref );
	}
	else
	{
		die 'Unknown type in spirit' . Dump ( [ $slot_spirit ], [qw( slot_spirit )] );
	}

	##IS_DEBUG and DEBUG 'done', Dump [ $content ], [qw( content )];

	return $content;
}

sub _evoke_array
{
	my ( $self, $aValues )		= @_;

	my $array	= [];

	foreach my $slot_spirit ( @{ $aValues || [] } )
	{
		my $content	= $self->_evoke_slot ( $slot_spirit );

		push @$array, $content;
	}

	return $array;
}

sub _evoke_hash
{
	my ( $self, $hValues )		= @_;

	my $hash	= {};

	while ( my ( $key, $slot_spirit ) = each %{ $hValues || {} } )
	{
		my $content	= $self->_evoke_slot ( $slot_spirit );

		$hash->{$key}	= $content;
	}

	return $hash;
}

sub _evoke_locum
{
	my ( $self, $class, $ref )		= @_;

	#IS_DEBUG and DEBUG 'start', Dump [ $class, $ref ], [qw( class ref )];

	my $locum	= $class->new ( id => $ref, asylum => $self );	#	every time a new Locum, so no weak refs needed!

	##IS_DEBUG and DEBUG 'done', Dump [ $locum ], [qw( locum )];
	#IS_DEBUG and DEBUG 'done ', blessed ( $locum ), '->', $locum->{id};

	return $locum;
}

sub _evoke_type
{
	my ( $self, $slot_spirit )		= @_;

	my ( $type, $class, $ref, $value );

#	if ( my $h = $slot_spirit->{ CLASS_TYPE() } )

	if ( ref ( $slot_spirit ) eq 'HASH' and my $h = $slot_spirit->{ CLASS_TYPE() } )
	{
		$type		= CLASS_TYPE();
		$class	= $h->{ TYPE_ATTR() };
		$ref		= $h->{ REF_ATTR() };
	}
	else
	{
#		( $type, $value )	= ( %$slot_spirit );

		$type		= ARRAY_TYPE()		if ref ( $slot_spirit ) eq 'ARRAY';
		$type		= HASH_TYPE()		if ref ( $slot_spirit ) eq 'HASH';
		$type		= VALUE_TYPE()		unless ref ( $slot_spirit );

		$value	= $slot_spirit;
	}

	( defined $type )		or die 'Cannot find type in spirit' . Dump ( [ $slot_spirit ], [qw( slot_spirit )] );

	return ( $type, $class, $ref, $value );
}

#	CALLBACKS
#
sub _absolve
{
	my ( $self, $class, $id, $spirit )	= @_;

	$self->open();

	#IS_DEBUG and DEBUG 'start', Dump [ $class, $id, $spirit ], [qw( class id spirit )];

	( defined $class )						or die 'Param class missing';
	( defined $id )							or die 'Param id missing';
	( defined $spirit )						or die 'Param spirit missing';

	$self->_silence ( $class, $id, '_dirty', false );

	foreach my $attr ( $class->meta->get_all_attributes )
	{
		next	if $attr->is_virtual;
		next	if $attr->is_transient;
		next	if $attr->is_index;			#	see _silence !!!

		my $slot_name	= $attr->name;

		if ( exists $spirit->{$slot_name} and defined $spirit->{$slot_name} )
		{
			my $slot_spirit	= $spirit->{$slot_name};

			$self->_necromancer()->silence ( $class, $id, $slot_name, $slot_spirit );
		}
	}
}

#	IMMUTABLE
#
no Moose;

__PACKAGE__->meta->make_immutable ( debug => 0 );

1;

__END__

=head1 NAME

Frost::Asylum - Home of the Locum

=head1 SYNOPSIS

   use Frost::Asylum;
   use Foo;

   my $asylum = Frost::Asylum->new ( data_root => '/existing/path/for/my/data' );

   # Create and silence via class:
   #
   my $foo = Foo->new ( id => 'a_unique_id', asylum => $asylum, an_attr => ..., another_attr => ... );

   my $remembered_id = $foo->id;

   # Evoke via class:
   #
   my $foo = Foo->new ( id => $remembered_id, asylum => $asylum );   # other params ignored

   $asylum->remove();  # delete all entries

   #################

   # Silence and create via API:
   #
   my $remembered_id = 'a_unique_id';

   my $foo = $asylum->silence ( 'Foo', $remembered_id, an_attr => ..., another_attr => ... );

   $asylum->close();   # and auto-save

   # Evoke via API:
   #
   my $foo = $asylum->evoke ( 'Foo', $remembered_id );               # other params ignored

=head1 ABSTRACT

No documentation yet...

=head1 DESCRIPTION

=for comment CLASS VARS

=for comment CLASS METHODS

=head1 PUBLIC ATTRIBUTES

=head2 data_root

=head2 cachesize

=head1 PRIVATE ATTRIBUTES

=head2 _lock

=head2 _twilight

=head2 _necromancer

=head1 CONSTRUCTORS

=head2 Frost::Asylum->new ( %params )

=head2 _build__lock

=head2 _build__twilight

=head2 _build__necromancer

=head1 DESTRUCTORS

=head2 DEMOLISH

=head1 PUBLIC METHODS

=head2 twilight_maxcount

=head2 twilight_count

=head2 lock

=head2 unlock

=head2 is_locked

=head2 open

=head2 close

=head2 save

=head2 clear

=head2 remove

=head2 autoincrement

=head2 silence

=head2 evoke

=head2 absolve

=head2 excommunicate

=head2 exists

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

=head2 _search

=head2 _exists

=head2 _count

=head2 _lookup

=head2 _silence

=head2 _evoke

=head2 _forget

=head2 _silence_slot

=head2 _silence_array

=head2 _silence_hash

=head2 _silence_locum

=head2 _silence_type

=head2 _evoke_slot

=head2 _evoke_array

=head2 _evoke_hash

=head2 _evoke_locum

=head2 _evoke_type

=head1 CALLBACKS

=head2 _absolve

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
