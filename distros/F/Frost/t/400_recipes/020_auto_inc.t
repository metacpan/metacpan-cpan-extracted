#!/usr/bin/perl

use warnings;
use strict;

use lib 't/lib', 'lib';

use Frost::Test;

#use Test::More tests => 56;
use Test::More 'no_plan';

use Frost::Asylum;

{
	package Good;
	use Frost;
	use Frost::Util;

	::lives_ok { has '+id'	=> ( auto_inc => true ); }		'can use "+id" or "id"';

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
		::throws_ok { has $_	=> ( auto_inc => true, isa => 'Int' ); }
			qr/Auto-Inc: Illegal inherited options => \(isa\)/,				"Error: has $_ auto_inc + isa";

		::throws_ok { has $_	=> ( auto_inc => true, lazy => true ); }
			qr/Auto-Inc: Illegal inherited options => \(lazy\)/,			"Error: has $_ auto_inc + lazy";

		::throws_ok { has $_	=> ( auto_inc => true, lazy_build => true ); }
			qr/Auto-Inc: Illegal inherited options => \(lazy_build\)/,	"Error: has $_ auto_inc + lazy_build";

		::throws_ok { has $_	=> ( auto_inc => true, default => sub { UUID } ); }
			qr/Auto-Inc: Illegal inherited options => \(default\)/,		"Error: has $_ auto_inc + default";

		::throws_ok { has $_	=> ( auto_inc => true, default => UUID ); }
			qr/Auto-Inc: Illegal inherited options => \(default\)/,		"Error: has $_ auto_inc + default";

		::throws_ok { has $_	=> ( auto_inc => true, auto_id => true, ); }
			qr/Attribute .+ can not be auto_id and auto_inc/,		"Error: has $_ auto_inc + auto_id";
	}

	::throws_ok { has num	=> ( auto_inc => true ); }
		qr/Attribute num can not be auto_inc/,		"Error: has num auto_inc";

	::throws_ok { has '+num'	=> ( auto_inc => true ); }
		qr/Attribute num can not be auto_inc/,		"Error: has +num auto_inc";
}

{
	package Ugly;
	use Moose;

	extends 'Good';

	use Frost::Util;

	::throws_ok { has num	=> ( auto_inc => true ); }
		qr/Attribute num can not be auto_inc/,		"Error: has num auto_inc";

	::throws_ok { has '+num'	=> ( auto_inc => true ); }
		qr/Attribute num can not be auto_inc/,		"Error: has +num auto_inc";
}

{
	package Foo;
	use Frost;
	use Frost::Util;

	has id	=> ( auto_inc => true );
	has num	=> ( is => 'ro', isa => 'Int', required => true );

	no Frost;

	__PACKAGE__->meta->make_immutable()		unless $::MAKE_MUTABLE;
}

ok	( Foo->meta->is_auto_inc ( 'id' ), 'registered auto_inc' );

my $MAX_ID	= 5;

my @IDS		= ();

my $filename_id	= make_file_path $TMP_PATH, 'Foo', 'id.cem';
my $filename_num	= make_file_path $TMP_PATH, 'Foo', 'num.cem';
my $filename_vlt	= make_file_path $TMP_PATH, 'Foo', 'burial.vlt';

{
	my $ASYL;

	lives_ok		{ $ASYL = Frost::Asylum->new ( data_root => $TMP_PATH ) }	'Asylum constructed';

	foreach ( 1..$MAX_ID )
	{
		my $foo	= Foo->new ( asylum => $ASYL, num => $_ * 1000 );

		is $foo->id,	$_ ,			"got the right foo->id $_";
		is $foo->num,	$_ * 1000,	"got the right foo->num for $_";

		push @IDS, $foo->id;
	}

	lives_ok	{ $ASYL->close;	}	'Asylum closed and saved';
}

{
	my $ASYL;

	lives_ok		{ $ASYL = Frost::Asylum->new ( data_root => $TMP_PATH ) }	'Asylum constructed';

	foreach my $id ( @IDS )
	{
		my $foo	= Foo->new ( id => $id, asylum => $ASYL );

		is $foo->id,	$id,			"got the right foo->id $id";
		is $foo->num,	$id * 1000,	"got the right foo->num for $id";
	}

	lives_ok	{ $ASYL->excommunicate ( 'Foo', 1 ); }			"excommunicated the spirit 1";
	lives_ok	{ $ASYL->excommunicate ( 'Foo', $MAX_ID ); }	"excommunicated the spirit $MAX_ID";

	lives_ok	{ $ASYL->close;	}	'Asylum closed and saved';
}

{
	my $ASYL;

	lives_ok		{ $ASYL = Frost::Asylum->new ( data_root => $TMP_PATH ) }	'Asylum constructed';

	foreach my $id ( @IDS )
	{
		if ( ( $id == 1 ) or ( $id == $MAX_ID ) )
		{
			isnt	$ASYL->exists ( 'Foo', $id ), true,	"spirit $id burns in hell";
		}
		else
		{
			my $foo	= Foo->new ( id => $id, asylum => $ASYL );

			is $foo->id,	$id,			"got the right foo->id $id";
			is $foo->num,	$id * 1000,	"got the right foo->num for $id";
		}
	}

	my $exp_id	= $MAX_ID + 1;

	my $foo	= Foo->new ( asylum => $ASYL, num => $exp_id * 1000 );

	is		$foo->id,	$exp_id,				"new foo->id is $exp_id";

	is		$foo->num,	$exp_id * 1000,	"got the right new foo->num";

	ok		-e $filename_id,	"$filename_id exists";
	ok		-e $filename_num,	"$filename_num exists";
	ok		-e $filename_vlt,	"$filename_vlt exists";

	lives_ok	{ $ASYL->remove;	}	'Asylum removed';

	ok	!	-e $filename_id,	"$filename_id is gone now";
	ok	!	-e $filename_num,	"$filename_num is gone now";
	ok		-e $filename_vlt,	"$filename_vlt still exists";		#	!!!
}

{
	my $ASYL;

	lives_ok		{ $ASYL = Frost::Asylum->new ( data_root => $TMP_PATH ) }	'Asylum constructed';

	my $exp_id	= $MAX_ID + 2;

	my $foo	= Foo->new ( asylum => $ASYL, num => $exp_id * 1000 );

	is		$foo->id,	$exp_id,				"new foo->id is $exp_id";

	is		$foo->num,	$exp_id * 1000,	"got the right new foo->num";

	lives_ok	{ $ASYL->close;	}	'Asylum closed and saved';
}
