package Frost::Necromancer;

#	LIBS
#
use Moose;

use Frost::Types;
use Frost::Util;
use Frost::Lock;

use Frost::Mortician;

#	CLASS VARS
#
our $VERSION	= 0.62;
our $AUTHORITY	= 'cpan:ERNESTO';

#	CLASS METHODS
#

#	PUBLIC ATTRIBUTES
#
has data_root		=> ( isa => 'Frost::FilePathMustExist',	is => 'ro',								required => true,		);
has cachesize		=> ( isa => 'Frost::Natural',				is => 'ro',		default => DEFAULT_CACHESIZE,				);

#	PRIVATE ATTRIBUTES
#
has _assistant		=> ( isa => 'HashRef[Frost::Mortician]',	is	=> 'ro',	init_arg => undef,	default => sub { {} }	);

#	CONSTRUCTORS
#

#	DESTRUCTORS
#

#	PUBLIC METHODS
#
sub work		{ $_[0]->_dispatch ( 'work'		); }
sub leisure	{ $_[0]->_dispatch ( 'leisure'	); }
sub save		{ $_[0]->_dispatch ( 'save'		); }
sub clear	{ $_[0]->_dispatch ( 'clear'		); }
sub remove	{ $_[0]->_dispatch ( 'remove'		); }

sub autoincrement
{
	my ( $self, $class )	= @_;

	$self->_mortician($class)->autoincrement();
}

sub exists
{
	my ( $self, $class, $id, $slot )	= @_;

	$slot	||= 'id';

	my $found	= $self->_mortician($class)->exists ( $id, $slot );

	#IS_DEBUG and DEBUG Dump [ $class, $id, $slot, $found ], [qw( class id slot found )];

	return ( $found ? true : false );
}

sub silence
{
	#IS_DEBUG and DEBUG "( @_ )";

	my ( $self, $class, $id, $slot, $spirit )	= @_;

	$self->_mortician($class)->bury ( $id, $slot, $spirit );
}

sub evoke
{
	my ( $self, $class, $id, $slot )	= @_;

	$slot	||= 'id';

	my $spirit	= $self->_mortician($class)->grub ( $id, $slot );

	#IS_DEBUG and DEBUG Dump [ $class, $id, $slot, $spirit ], [qw( class id slot spirit )];

	return $spirit;
}

sub forget
{
	my ( $self, $class, $id, $slot, $spirit )	= @_;

	$self->_mortician($class)->forget ( $id, $slot, $spirit );
}

sub count
{
	my ( $self, $class, $id, $slot, $use_index )	= @_;

	$slot	||= 'id';

	$self->_mortician($class)->count ( $id, $slot, $use_index );
}

sub lookup
{
	my ( $self, $class, $key, $slot )	= @_;

	$self->_mortician($class)->lookup ( $key, $slot );
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
sub _mortician
{
	my ( $self, $class )	= @_;

	my $mortician;

	unless ( $mortician = $self->_assistant()->{$class} )
	{
		$mortician	= Frost::Mortician->new
		(
			classname	=> $class,
			data_root	=> $self->data_root,
			cachesize	=> $self->cachesize,
		);

		$self->_assistant()->{$class}	= $mortician;
	}

	( defined $mortician )	or die "No mortician found for class '$class'";

	return $mortician;
}

sub _dispatch
{
	my ( $self, $work )	= @_;

	while ( my ( $class, $mortician ) = each %{ $self->_assistant() || {} } )
	{
		$mortician->$work();
	}

	return true;
}

sub _search
{
	my ( $self, $method, $class, $key, $slot )	= @_;

	$self->_mortician($class)->$method ( $key, $slot );
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

Frost::Necromancer - The Wizard

=head1 ABSTRACT

No documentation yet...

=head1 DESCRIPTION

No user maintainable parts inside ;-)

=for comment CLASS VARS

=for comment CLASS METHODS

=head1 PUBLIC ATTRIBUTES

=head2 data_root

=head2 cachesize

=head1 PRIVATE ATTRIBUTES

=head2 _assistant

=head1 CONSTRUCTORS

=head2 Frost::Necromancer->new ( %params )

=for comment DESTRUCTORS

=head1 PUBLIC METHODS

=head2 work

=head2 leisure

=head2 save

=head2 clear

=head2 remove

=head2 autoincrement

=head2 exists

=head2 silence

=head2 evoke

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

=head2 _mortician

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
