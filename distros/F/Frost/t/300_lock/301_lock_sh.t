#!/usr/bin/perl

use warnings;
use strict;

use lib 't/lib', 'lib';

use Frost::Test;

use Test::More;

BEGIN
{
	unless ( $ENV{Frost_LOCK} )
	{
		plan skip_all => 'Set $ENV{Frost_LOCK} for shared lock tests';
	}
	else
	{
		plan tests => 5;
	}

	use_ok	'Time::HiRes';
	use_ok	'IO::File';
	use_ok	'Frost::Util';
}

local $SIG{__DIE__};
local $SIG{__WARN__};

diag "\nThis test will take 15 seconds. Please be patient...";
diag "Testing SHARED locks...";

my $t0	= Time::HiRes::gettimeofday();
my $t1;

my $child_pid;

my $filename	= $TMP_PATH . '/.Frost_lock';

lives_ok	{ touch ( $filename )		}	"$filename touched";
BAIL_OUT ( "No write access to $filename" )		unless -e $filename;

my $how			= O_RDONLY;
my $wait			= 5;		#	seconds

defined ( $child_pid = fork )		or die "Cannot fork: $!\n";

if ( ! $child_pid )
{
	#	Child runs this block
	#
	#	Don't run tests here....
	#
	my $fh	= new IO::File $filename, $how;

	lock_fh $fh, $how, $wait;

	$t1	= Time::HiRes::gettimeofday() - $t0;
	diag sprintf ( "\n%7.3f sec Child $filename opened and locked shared", $t1 );

	sleep ( 15 );

	unlock_fh $fh;

	$fh->close;

	$t1	= Time::HiRes::gettimeofday() - $t0;
	diag sprintf ( "\n%7.3f sec Child $filename closed and unlocked", $t1 );

	CORE::exit(0);
}

{
	#	Parent runs this block
	#
	sleep ( 5 );

	my $fh	= new IO::File $filename, $how;

	is		lock_fh		( $fh, $how, $wait ),	true,		"Parent $filename locked";

	$t1	= Time::HiRes::gettimeofday() - $t0;
	diag sprintf ( "\n%7.3f sec Parent $filename opened and locked shared", $t1 );

	unlock_fh $fh;

	$fh->close;

	$t1	= Time::HiRes::gettimeofday() - $t0;
	diag sprintf ( "\n%7.3f sec Parent $filename closed and unlocked", $t1 );

	$t1	= Time::HiRes::gettimeofday() - $t0;
	diag sprintf ( "\n%7.3f sec Cleanup...", $t1 );

	waitpid $child_pid, 0;

	unlink $filename;

	$t1	= Time::HiRes::gettimeofday() - $t0;
	diag sprintf ( "\n%7.3f sec Done", $t1 );
}
