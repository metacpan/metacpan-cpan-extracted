#!/usr/bin/perl

use warnings;
use strict;

use lib 't/lib', 'lib';

use Frost::Test;

use Test::More tests => 1;
#use Test::More 'no_plan';

ok(1);

#	This is not really a test - see below 'Uncomment...'

{
	package Asylum::Flow;

	use Moose;
	extends 'Frost::Asylum';

	has FLOW => ( is => 'ro', isa => 'ArrayRef', default => sub { [] } );

	around _exists				=> \&__record;
	around _count				=> \&__record;
	around _lookup				=> \&__record;
	around _silence			=> \&__record;
	around _evoke				=> \&__record;
	around _forget				=> \&__record;
	around _silence_slot		=> \&__record;
	around _silence_array	=> \&__record;
	around _silence_hash		=> \&__record;
	around _silence_locum	=> \&__record;
	around _silence_type		=> \&__record;
	around _evoke_slot		=> \&__record;
	around _evoke_array		=> \&__record;
	around _evoke_hash		=> \&__record;
	around _evoke_locum		=> \&__record;
	around _evoke_type		=> \&__record;
	around _absolve			=> \&__record;

	sub __record
	{
		my $next		= shift;
		my $self		= shift;

		my $caller	= (caller(2))[3];

		if ( wantarray )
		{
			my @result	= $self->$next ( @_ );

			push @ { $self->FLOW }, { caller => $caller, params => [ @_ ], result => \@result };

			return @result;
		}
		else
		{
			my $result	= $self->$next ( @_ );

			push @ { $self->FLOW }, { caller => $caller, params => [ @_ ], result => $result };

			return $result;
		}
	};

	no Moose;

	if ( $::MAKE_MUTABLE )	{ __PACKAGE__->meta->make_mutable	( debug => 0 );	}
	else							{ __PACKAGE__->meta->make_immutable	( debug => 0 );	}
}

{
	package Foo;

	use Frost;

	has num	=> ( is => 'rw', isa => 'Int' );

	no Frost;

	if ( $::MAKE_MUTABLE )	{ __PACKAGE__->meta->make_mutable	( debug => 0 );	}
	else							{ __PACKAGE__->meta->make_immutable	( debug => 0 );	}
}

my $ASYL	= Asylum::Flow->new ( data_root => $TMP_PATH );

my $foo	= Foo->new ( id => 'FOO', asylum => $ASYL );

$foo->num ( 42 );

$Data::Dumper::Deepcopy		= 1;

#	Uncomment this line to see the call-flow of Asylum's methods
#
#DEBUG Dumper $foo;
