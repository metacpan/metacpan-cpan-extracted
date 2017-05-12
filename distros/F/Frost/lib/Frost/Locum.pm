package Frost::Locum;

#	LIBS
#
use Moose;

use Frost::Types;
use Frost::Util;

use Moose::Util::MetaRole;

#	CLASS VARS
#
our $VERSION	= 0.65;
our $AUTHORITY	= 'cpan:ERNESTO';

#	CLASS METHODS
#

#Moose::Util::MetaRole::apply_metaclass_roles
#(
#	for_class						=> __PACKAGE__,
#	metaclass_roles				=> [ 'Frost::Meta::Class'			],
#	attribute_metaclass_roles	=> [ 'Frost::Meta::Attribute'		],
#	instance_metaclass_roles	=> [ 'Frost::Meta::Instance'		],
#	constructor_class_roles		=> [ 'Frost::Meta::Constructor'	],
#);

Moose::Util::MetaRole::apply_metaroles
(
	for						=> __PACKAGE__,
	class_metaroles		=>
	{
		class					=> [ 'Frost::Meta::Class' ],
		attribute			=> [ 'Frost::Meta::Attribute' ],
#		method
#		wrapped_method
		instance				=> [ 'Frost::Meta::Instance' ],
		constructor			=> [ 'Frost::Meta::Constructor' ],
#		destructor
#		error
	}
);

sub get_auto_inc
{
	my ( $class, $asylum )	= @_;

	$asylum->autoincrement ( $class );
}

#	CLASS INIT
#

#	PUBLIC ATTRIBUTES
#
has id				=> ( 							isa => 'Frost::UniqueId',						is	=> 'ro',	required => true		);
has asylum			=> ( transient => true,	isa => 'Frost::Asylum',						required => true		);

#	PRIVATE ATTRIBUTES
#
has _status			=> ( transient => true,	isa => 'Frost::Status',		init_arg => undef,	default => STATUS_MISSING	);
has _dirty			=> ( virtual	=> true,	isa => 'Bool',			init_arg => undef,	default => true				);

#	CONSTRUCTORS
#
sub BUILDARGS
{
	my $class	= shift;

	my $params	= Moose::Object->BUILDARGS ( @_ );

	( defined $params->{asylum} )			or die 'Attribute (asylum) is required';

	$params->{id}	||= UUID														if $class->meta->is_auto_id ( 'id' );
	$params->{id}	||= $class->get_auto_inc ( $params->{asylum} ) 	if $class->meta->is_auto_inc ( 'id' );

	return $params;
}

#	DESTRUCTORS
#

#	PUBLIC METHODS
#

#	PRIVATE METHODS
#
sub _sanctify
{
	#IS_DEBUG and DEBUG "( $_[0]->{id}, $_[1] )";

	if ( $_[1] ne '_dirty' )
	{
		$_[0]->{asylum}->_silence ( ref ( $_[0] ), $_[0]->{id}, '_dirty', false );
	}
}

sub _curse
{
	#IS_DEBUG and DEBUG "( $_[0]->{id}, $_[1] )";

	if ( $_[1] ne '_dirty' )
	{
		$_[0]->{asylum}->_silence ( ref ( $_[0] ), $_[0]->{id}, '_dirty', true );
	}
}

sub _exists
{
	#IS_DEBUG and DEBUG "( @_ )";

	my ( $self, $slot_name )	= @_;

	my $result	= 0;

	if		( $slot_name eq 'id' )
	{
		$result	= exists $self->{$slot_name};
	}
	elsif	( $self->meta->is_transient ( $slot_name ) )
	{
		$result	= exists $self->{$slot_name};
	}
	else
	{
		my $class	= ref $self;

		$result	= $self->{asylum}->_exists ( $class, $self->{id}, $slot_name );
	}

	return $result;
}

sub _silence
{
	#IS_DEBUG and DEBUG "( @_ )";

	my ( $self, $slot_name, $value )	= @_;

	unless ( defined $value )					#	was checked by Moose!
	{
		$self->_forget ( $slot_name );

		return true;
	}

	if		( $slot_name eq 'id' )
	{
		unless ( $self->{id} )
		{
			my $class	= ref $self;

			$self->{id}	= $value;				#	was checked by Moose!

			if ( $self->{asylum}->_exists ( $class, $self->{id} ) )
			{
				$self->{_status}	= STATUS_EXISTS;

				#	only on re-load !!!
				#
				$self->_sanctify ( $slot_name )	unless $self->{asylum}->_exists ( $class, $self->{id}, '_dirty' );
			}
			else
			{
				$self->{_status}	= STATUS_MISSING;

				$self->{asylum}->_silence ( $class, $self->{id}, $slot_name, $self->{id} );

				$self->_curse ( $slot_name );
			}
		}
	}
	elsif	( $self->meta->is_transient ( $slot_name ) )
	{
		$self->{$slot_name}	= $value;		#	was checked by Moose!

	#	NO!
	#	$self->_curse ( $slot_name );
	}
	else
	{
		my $class	= ref $self;

		$self->{asylum}->_silence ( $class, $self->{id}, $slot_name, $value );

		$self->_curse ( $slot_name );
	}

	return true;
}

sub _evoke
{
	#IS_DEBUG and DEBUG "( @_ )";

	my ( $self, $slot_name )	= @_;

	my $value;

	if		( $slot_name eq 'id' )
	{
		$value	= $self->{$slot_name};
	}
	elsif	( $self->meta->is_transient ( $slot_name ) )
	{
		$value	= $self->{$slot_name};
	}
	else
	{
		my $class	= ref $self;

		$value	= $self->{asylum}->_evoke ( $class, $self->{id}, $slot_name );
	}

	return $value;
}

sub _forget
{
	#IS_DEBUG and DEBUG "( @_ )";

	my ( $self, $slot_name )	= @_;

	if		( $slot_name eq 'id' )
	{
		delete $self->{$slot_name};

		my $class	= ref $self;

		$self->{asylum}->_forget ( $class, $self->{id} );

		$self->_curse ( $slot_name );
	}
	elsif	( $self->meta->is_transient ( $slot_name ) )
	{
		delete $self->{$slot_name};

	#	NO!
	#	$self->_curse ( $slot_name );
	}
	else
	{
		my $class	= ref $self;

		$self->{asylum}->_forget ( $class, $self->{id}, $slot_name );

		$self->_curse ( $slot_name );
	}
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

Frost::Locum - Only the semblance is immaculate

=head1 ABSTRACT

No documentation yet...

=head1 DESCRIPTION

This class is the default base class for all Frost-using classes. When
you C<use Frost> in a class, your class will inherit from this
class.

=head1 CLASS METHODS

=head2 Frost::Locum->get_auto_inc ( $asylum )

=head1 PUBLIC ATTRIBUTES

=head2 id

=head2 asylum

=head1 PRIVATE ATTRIBUTES

=head2 _status

=head2 _dirty

=head1 CONSTRUCTORS

=head2 Frost::Locum->new ( %params )

This method calls the C<< $class->BUILDARGS ( @_ ) >>, and then creates a new
instance of the appropriate class.

If the spirit of the instance was not saved, the method calls
C<< $instance->BUILD ( $params ) >>, if provided.

Otherwise no initialization takes place.

In the end always a new instance blessed in the appropriate class is returned.

=head2 $class->BUILDARGS ( @_ )

Prepares C<auto_id> resp. C<auto_inc> if necessary.

=for comment DESTRUCTORS

=for comment PUBLIC METHODS

=head1 PRIVATE METHODS

=head2 $instance->_sanctify ( $slot_name )

=head2 $instance->_curse ( $slot_name )

=head2 $instance->_exists ( $slot_name )

=head2 $instance->_silence ( $slot_name, $value )

=head2 $instance->_evoke ( $slot_name )

=head2 $instance->_forget ( $slot_name )

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
