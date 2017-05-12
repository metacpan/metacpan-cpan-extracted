#!/usr/bin/perl

use warnings;
use strict;

use lib 't/lib', 'lib';

use Frost::Test;

use Test::More;

our $WIDTH;
our $HEIGHT;
our $MAX_ID;

BEGIN
{
	$WIDTH	= 4;	#	min 2
	$HEIGHT	= 3;	#	min 2

	$MAX_ID	= $WIDTH * $HEIGHT;

	{
		my ( $W, $H, $C )	= ( $WIDTH, $HEIGHT, 0 );

		while (	$W > 1	and	$H > 1	)	{	$W--;	$H--;	$C++;	}		#	NW
		while (	$H > 1	)						{	$H--;			$C++;	}		#	N
		while (	$W > 1	)						{	$W--;			$C++;	}		#	W

		plan tests => 6 + $C;
	}
}

use Frost::Asylum;

# O--O--O--O--O--O--O--O--O--O--O
# |\/|\/|\/|\/|\/|\/|\/|\/|\/|\/|
# |/\|/\|/\|/\|/\|/\|/\|/\|/\|/\|
# O--O--O--O--O--O--O--O--O--O--O
# |\/|\/|\/|\/|\/|\/|\/|\/|\/|\/|
# |/\|/\|/\|/\|/\|/\|/\|/\|/\|/\|
# O--O--O--O--O--O--O--O--O--O--O
# |\/|\/|\/|\/|\/|\/|\/|\/|\/|\/|
# |/\|/\|/\|/\|/\|/\|/\|/\|/\|/\|
# O--O--O--O--O--O--O--O--O--O--O
#
#        N
#    NW  |  NE
#       \|/
#   W----O----E
#       /|\
#    SW  |  SE
#        W
#
{
	package Mesh;
	use Frost;
	use Frost::Util;

	has [ qw( N NE E SE S SW W NW ) ]	=>
	(
		is				=> 'rw',
		isa			=> 'Mesh',

		weak_ref		=> false,		#	weak refs are VERBOTEN
	);

	has 'pos'	=>
	(
		is				=> 'rw',
		isa			=> 'Str',
	);

	no Frost;

	__PACKAGE__->meta->make_immutable()		unless $::MAKE_MUTABLE;
}

diag '### Create mesh ###';

our $ID			= 0;

diag "### About to create and store $MAX_ID mesh(es)...";

{
	my $ASYL;

	lives_ok		{ $ASYL = Frost::Asylum->new ( data_root => $TMP_PATH ) }	'Asylum constructed';

	my $CONTROL	= {};

	for my $w ( 1 .. $WIDTH )
	{
		for my $h ( 1 .. $HEIGHT )
		{
			$ID++;

			$CONTROL->{$w}->{$h}	= Mesh->new ( asylum => $ASYL, id => "MESH_$ID", pos => "$w-$h" );
		}
	}

	for my $w ( 1 .. $WIDTH )
	{
		for my $h ( 1 .. $HEIGHT )
		{
			my $mesh  = $CONTROL->{$w    }->{$h    };

			my $others	=
				{
					N	=> $CONTROL->{$w    }->{$h - 1},
					NE	=> $CONTROL->{$w + 1}->{$h - 1},
					E	=> $CONTROL->{$w + 1}->{$h    },
					SE	=> $CONTROL->{$w + 1}->{$h + 1},
					S	=> $CONTROL->{$w    }->{$h + 1},
					SW	=> $CONTROL->{$w - 1}->{$h + 1},
					W	=> $CONTROL->{$w - 1}->{$h    },
					NW	=> $CONTROL->{$w - 1}->{$h - 1},
				};

			for my $key ( keys %$others )
			{
				next		unless $others->{$key};

				$mesh->$key ( $others->{$key} );
			}
		}
	}

	lives_ok	{ $ASYL->close;	}	'Asylum closed and saved';
}

diag "### $ID of $MAX_ID mesh(es) created and stored ###";

{
	my $ASYL;

	lives_ok		{ $ASYL = Frost::Asylum->new ( data_root => $TMP_PATH ) }	'Asylum constructed';

	my $curr	= Mesh->new ( asylum => $ASYL, id => "MESH_$ID" );

	is		( $curr->pos,	"$WIDTH-$HEIGHT",		".. got South-East $WIDTH-$HEIGHT (start)" );

	my ( $W, $H )	= ( $WIDTH, $HEIGHT );

	while ( my $nw	= $curr->NW )
	{
		$curr	= $nw;

		$W--;
		$H--;

		is		( $curr->pos,	"$W-$H",				".. got North-West $W-$H" );
	}

	while ( my $n	= $curr->N )
	{
		$H--;

		$curr	= $n;

		is		( $curr->pos,	"$W-$H",				".. got North      $W-$H" );
	}

	while ( my $w	= $curr->W )
	{
		$W--;

		$curr	= $w;

		is		( $curr->pos,	"$W-$H",				".. got West       $W-$H" );
	}

	is		( $curr->pos,	"1-1",					".. got North-West 1-1 (end)" );

	lives_ok	{ $ASYL->close;	}	'Asylum closed and saved';
}
