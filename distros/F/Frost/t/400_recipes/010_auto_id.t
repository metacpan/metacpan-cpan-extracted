#!/usr/bin/perl

use warnings;
use strict;

use lib 't/lib', 'lib';

use Frost::Test;

use Test::More tests => 106;
#use Test::More 'no_plan';

use Frost::Asylum;

{
	package Good;
	use Frost;
	use Frost::Util;

	::lives_ok { has '+id'	=> ( auto_id => true ); }		'can use "+id" or "id"';

	has num	=> ( is => 'ro', isa => 'Int' );

	no Frost;

	__PACKAGE__->meta->make_immutable()		unless $::MAKE_MUTABLE;
}

{
	package Bad;
	use Frost;
	use Frost::Util;

	for ( qw( id +id ) )
	{
		::throws_ok { has $_	=> ( auto_id => true, isa => 'Int' ); }
			qr/Auto-Id: Illegal inherited options => \(isa\)/,				"Error: has $_ auto_id + isa";

		::throws_ok { has $_	=> ( auto_id => true, lazy => true ); }
			qr/Auto-Id: Illegal inherited options => \(lazy\)/,			"Error: has $_ auto_id + lazy";

		::throws_ok { has $_	=> ( auto_id => true, lazy_build => true ); }
			qr/Auto-Id: Illegal inherited options => \(lazy_build\)/,	"Error: has $_ auto_id + lazy_build";

		::throws_ok { has $_	=> ( auto_id => true, default => sub { UUID } ); }
			qr/Auto-Id: Illegal inherited options => \(default\)/,		"Error: has $_ auto_id + default";

		::throws_ok { has $_	=> ( auto_id => true, default => UUID ); }
			qr/Auto-Id: Illegal inherited options => \(default\)/,		"Error: has $_ auto_id + default";

		::throws_ok { has $_	=> ( auto_inc => true, auto_id => true, ); }
			qr/Attribute .+ can not be auto_id and auto_inc/,		"Error: has $_ auto_inc + auto_id";
	}

	::throws_ok { has num	=> ( auto_id => true ); }
		qr/Attribute num can not be auto_id/,		"Error: has num auto_id";

	::throws_ok { has '+num'	=> ( auto_id => true ); }
		qr/Attribute num can not be auto_id/,		"Error: has +num auto_id";
}

{
	package Ugly;
	use Moose;

	extends 'Good';

	use Frost::Util;

	::throws_ok { has num	=> ( auto_id => true ); }
		qr/Attribute num can not be auto_id/,		"Error: has num auto_id";

	::throws_ok { has '+num'	=> ( auto_id => true ); }
		qr/Attribute num can not be auto_id/,		"Error: has +num auto_id";
}


{
	package Foo;
	use Frost;
	use Frost::Util;

	has id	=> ( auto_id => true );
	has num	=> ( is => 'ro', isa => 'Int' );

	no Frost;

	__PACKAGE__->meta->make_immutable()		unless $::MAKE_MUTABLE;
}

ok	( Foo->meta->is_auto_id ( 'id' ), 'registered auto_id' );

foreach my $uuid_flag ( reverse ( 0..1 ) )
{
	$Frost::Util::UUID_CLEAR	= $uuid_flag;		#	= 1: delivers simple 'UUIDs' A-A-A-A-1, -2, -3... for testing
	$Frost::Util::UUID_OBJ	= undef;				#	Don't try this at home!

	my @IDS	= ();

	{
		my $ASYL;

		lives_ok		{ $ASYL = Frost::Asylum->new ( data_root => $TMP_PATH ) }	'Asylum constructed';

		foreach my $num ( 1..10 )
		{
			my $foo	= Foo->new ( asylum => $ASYL, num => $num );

			is check_type_constraint_manuel ( 'Foo', 'id', $foo->id ), true, 'got a correct UUID ' . $foo->id;
			is $foo->num, $num, 'got correct num ' . $num;

			push @IDS, $foo->id;
		}

		lives_ok	{ $ASYL->close;	}	'Asylum closed and saved';
	}

	{
		my $ASYL;

		lives_ok		{ $ASYL = Frost::Asylum->new ( data_root => $TMP_PATH ) }	'Asylum constructed';

		my $num	= 1;

		foreach my $id ( @IDS )
		{
			my $foo	= Foo->new ( id => $id, asylum => $ASYL );

			is check_type_constraint_manuel ( 'Foo', 'id', $foo->id ), true, 'got correct UUID ' . $foo->id;
			is $foo->num, $num, 'got correct num ' . $num;

			$num++;
		}

		lives_ok	{ $ASYL->close;	}	'Asylum closed and saved';
	}
}
