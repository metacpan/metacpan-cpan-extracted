package Frost::Test;

use strict;
use warnings;

BEGIN
{
	my $odef = select STDERR;
	$| = 1;
	select STDOUT;
	$| = 1;
	select $odef;
}

package main;

use strict;
use warnings;

use Test::More 0.88;		#	done_testing...
use Test::Exception;
use Test::Deep;

use Frost::Util;

use Frost::TestPath;

#	ok, works!
#
#	use DB_File;
#
#	BEGIN
#	{
#		plan skip_all => 'Need BerkeleyDB version 4.0, this is only ' . $DB_File::db_version		if $DB_File::db_version < 44;
#	}

our $MAKE_MUTABLE	= $ENV{Frost_MAKE_MUTABLE};

diag ( "\n>>>>>>>>>>>>>>> MUTABLE TEST! <<<<<<<<<<<<<<<\n" )		if $MAKE_MUTABLE;

#	stolen from Test::More 0.78 and changed (#X):
#
sub ISA_NOT ($$;$)
{
	my ( $object, $class, $obj_name )	= @_;

	my $tb		= Test::More->builder;
	my $diag;
	$obj_name	= 'The object'		unless defined $obj_name;
#X	my $name		= "$obj_name isa $class";
	my $name		= "$obj_name is NOT a $class";

	if		( !defined $object )
	{
		$diag = "$obj_name isn't defined";
	}
	elsif	( !ref $object )
	{
		$diag = "$obj_name isn't a reference";
	}
	else
	{
		# We can't use UNIVERSAL::isa because we want to honor isa() overrides
		my ( $rslt, $error )	= $tb->_try ( sub { $object->isa ( $class ) } );

		if		( $error )
		{
			if ( $error =~ /^Can\'t call method "isa" on unblessed reference/ )
			{
				# Its an unblessed reference
				if ( !UNIVERSAL::isa($object, $class) )
				{
					my $ref = ref $object;
					$diag = "$obj_name isn't a '$class' it's a '$ref'";
				}
			}
			else
			{
				die <<WHOA;
WHOA! I tried to call ->isa on your object and got some weird error.
Here\'s the error.
$error
WHOA

			}
		}
#X		elsif	( ! $rslt )
#X		{
#X			my $ref = ref $object;
#X			$diag = "$obj_name isn't a '$class' it's a '$ref'";
#X		}
#X	NEW
#X
		elsif	( ! $rslt )
		{
			#	ok	!
		}
		elsif	( $rslt )
		{
			$diag = "$obj_name isa '$class', but shouldn't";
		}
#X
#X	####
	}

	my $ok;

	if ( $diag )
	{
		$ok	= $tb->ok ( 0, $name );
		$tb->diag ("    $diag\n" );
	}
	else
	{
		$ok	= $tb->ok ( 1, $name );
	}

	return $ok;
}

sub CAN_NOT ($@)
{
	my ( $proto, @methods ) = @_;

	my $class = ref $proto || $proto;

	my $tb = Test::More->builder;

	unless ( $class )
	{
#X		my $ok = $tb->ok( 0, "->can(...)" );
		my $ok = $tb->ok( 0, "->can NOT (...)" );
#X		$tb->diag('    can_ok() called with empty class or reference');
		$tb->diag('    CAN_NOT() called with empty class or reference');
		return $ok;
	}

	unless ( @methods )
	{
#X		my $ok = $tb->ok( 0, "$class->can(...)" );
		my $ok = $tb->ok( 0, "$class->can NOT (...)" );
#X		$tb->diag('    can_ok() called with no methods');
		$tb->diag('    CAN_NOT() called with no methods');
		return $ok;
	}

	my @nok = ();

	foreach my $method (@methods)
	{
#X		$tb->_try(sub { $proto->can($method) }) or push @nok, $method;
		$tb->_try(sub { $proto->can($method) }) and push @nok, $method;
	}

	my $name;

#X	$name = @methods == 1 ? "$class->can('$methods[0]')" : "$class->can(...)";
	$name = @methods == 1 ? "$class->can NOT ('$methods[0]')" : "$class->can NOT (...)";

	my $ok = $tb->ok( !@nok, $name );

#X	$tb->diag(map "    $class->can('$_') failed\n", @nok);
	$tb->diag(map "    $class->can('$_') but shouldn't\n", @nok);

	return $ok;
}

1;

__END__

