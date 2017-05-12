#!/usr/bin/perl

use warnings;
use strict;

use lib 't/lib', 'lib';

use Frost::Test;

use Test::More;

#	equals t/500_speed/200_burial_speed.t, differences marked with NYTProf

BEGIN
{
#	$ENV{Frost_DEBUG}	= 0;

#	unless ( $ENV{Frost_SPEED} )
	unless ( eval { DB::disable_profile() } )		#	NYTProf	there should be a better way...
	{
#		plan skip_all => 'Set $ENV{Frost_SPEED} for speed tests';
		plan skip_all => 'This profile test must run under Devel::NYTProf';
	}
	else
	{
		plan tests => 2;
	}

	use_ok	'Time::HiRes';
	use_ok	'IO::File';
}

use Frost::TestSystem;

use Frost::Asylum;

#	config
#
our $DEFAULT_MAX_ID	= 20_000;
#$DEFAULT_MAX_ID		= 12_000;
$DEFAULT_MAX_ID		= 1000;		#	NYTProf enough for profiling...

our $CACHE_COUNT		= 20_000;	#	default
#$CACHE_COUNT			= 11_000;

our $EXP_CREATE	=  2_600;	#	objects / sec
our $EXP_LOAD		=  2_700;
our $EXP_CACHE		=  4_300;
#
#########

our $TITLE			= 'COMPARING CREATE, SAVE AND READ OBJECTS VIA Asylum/Twilight (DISK/CACHE)';
$TITLE				.= "\nPROFILING...";		#	NYTProf

our $MIN_ID			= 1;
our $MAX_ID			= $ARGV[0] || $DEFAULT_MAX_ID;

$MAX_ID				= $::MAKE_MUTABLE ? ( $MAX_ID / 2 ) : $MAX_ID;

our $MMTXT			= $::MAKE_MUTABLE ? 'Mutable  ' : 'Immutable';

our $KB	= 1024;
our $MB	= $KB * $KB;

{
	package Foo;
	use Frost;

	has 'foo'	=>
	(
		is			=> 'rw',
		isa		=> 'Str',
	);

	no Frost;

	__PACKAGE__->meta->make_immutable()		unless $::MAKE_MUTABLE;
}

diag "\n\n$TITLE";
diag "\nRunning Moose $Moose::VERSION, Frost $Frost::VERSION";
diag "\nUsing $MAX_ID objects in " . ( $::MAKE_MUTABLE ?  '' : 'im' ) . "mutable mode.";
diag "\nThis test can take 30 seconds or more to run.";
diag "It depends on your Perl version as well as on other activities on your machine.";
diag "Please be patient...";

our $MB_SEC	= TF_DISK_SPEED;

DB::enable_profile();			#	NYTProf

my $t0	= Time::HiRes::gettimeofday();
my $tc	= Time::HiRes::gettimeofday() - $t0;

diag sprintf ( "\n%7.3f ", $tc ) . "RUN...";

my ( $r1, $r2, $r3 );
my ( $t1, $t2, $t3 );

{
	my ( $twilight, $asylum );

	$asylum = Frost::Asylum->new ( data_root => $TMP_PATH );

	$asylum->twilight_maxcount ( $CACHE_COUNT );

	my $ts	= Time::HiRes::gettimeofday();

	for ( $MIN_ID .. $MAX_ID )
	{
		my $foo	= Foo->new ( id => $_, asylum => $asylum, foo => "With Frost::Natural $_" );
	}

	$t1	= Time::HiRes::gettimeofday() - $ts;
	$r1	= $MAX_ID / $t1;

	$tc	= Time::HiRes::gettimeofday() - $t0;

	diag sprintf ( "%7.3f $MMTXT Create %9d objects in %7.3f sec (%9d objects per sec)", $tc, $MAX_ID, $t1, $r1 );

	#DEBUG Dumper $asylum;

	$asylum->close;
}

my $asylum;

$asylum = Frost::Asylum->new ( data_root => $TMP_PATH );
$asylum->twilight_maxcount ( $CACHE_COUNT );

{
	my $ts	= Time::HiRes::gettimeofday();

	for ( $MIN_ID .. $MAX_ID )
	{
		my $foo		= Foo->new ( id => $_, asylum => $asylum );
		my $foo_foo	= $foo->foo;
	}

	$t2	= Time::HiRes::gettimeofday() - $ts;
	$r2	= $MAX_ID / $t2;
}

$tc	= Time::HiRes::gettimeofday() - $t0;

diag sprintf ( "%7.3f $MMTXT Load   %9d objects in %7.3f sec (%9d objects per sec)", $tc, $MAX_ID, $t2, $r2 );

{
	my $ts	= Time::HiRes::gettimeofday();

	for ( $MIN_ID .. $MAX_ID )
	{
		my $foo		= Foo->new ( id => $_, asylum => $asylum );
		my $foo_foo	= $foo->foo;
	}

	$t3	= Time::HiRes::gettimeofday() - $ts;
	$r3	= $MAX_ID / $t3;
}

$tc	= Time::HiRes::gettimeofday() - $t0;

diag sprintf ( "%7.3f $MMTXT Cache  %9d objects in %7.3f sec (%9d objects per sec)", $tc, $MAX_ID, $t3, $r3 );

$asylum->close;

my $template	= 'Perl %-8s with %5s MB RAM, %4s MB/sec IO, on %5s GHz CPU (%s)';

my $s_expected	= sprintf $template, 'v5.8.8', 1011, 119, 2.2, 'AMD Athlon(tm) 64 Processor 3700+';
my $s_tested	= sprintf $template, TF_PERL_VERSION, TF_RAM_SIZE, $MB_SEC, TF_CPU_SPEED, TF_CPU_NAME;

diag "\nexpected $s_expected";
diag "tested   $s_tested";

diag sprintf ( "\n                   expected= Immutable      tested= $MMTXT" );

my ( $e1, $e2, $e3 );

$e1	= $EXP_CREATE;
$e2	= $EXP_LOAD;
$e3	= $EXP_CACHE;

my ( $p, $s, $rr, $ee );

$p	= ( ( $r1 - $e1 ) / $e1 ) * 100;
$s	= ( $p > 3.3333 )
		? 'faster'
		: ( $p < -3.3333 )
			? 'slower'
			: 'same';

diag sprintf ( "\n$MMTXT Create : expected=%9d /sec, tested=%9d /sec -> %7.1f %% (%s)", $e1, $r1, $p, $s );

$p	= ( ( $r2 - $e2 ) / $e2 ) * 100;
$s	= ( $p > 3.3333 )
		? 'faster'
		: ( $p < -3.3333 )
			? 'slower'
			: 'same';

diag sprintf ( "$MMTXT Load   : expected=%9d /sec, tested=%9d /sec -> %7.1f %% (%s)", $e2, $r2, $p, $s );

$p	= ( ( $r3 - $e3 ) / $e3 ) * 100;
$s	= ( $p > 3.3333 )
		? 'faster'
		: ( $p < -3.3333 )
			? 'slower'
			: 'same';

diag sprintf ( "$MMTXT Cache  : expected=%9d /sec, tested=%9d /sec -> %7.1f %% (%s)", $e3, $r3, $p, $s );

$rr	= $r2 / $r1;
$ee	= $e2 / $e1;

$p		= $rr - $ee;
$s	= ( $p > 0.3333 )
		? 'more'
		: ( $p < -0.3333 )
			? 'less'
			: 'same';

diag sprintf (	"\n$MMTXT Load/Create    ratio: expected=%7.1f, tested=%7.1f (%s)", $ee, $rr, $s );

$rr	= $r3 / $r2;
$ee	= $e3 / $e2;

$p		= $rr - $ee;
$s	= ( $p > 0.3333 )
		? 'more'
		: ( $p < -0.3333 )
			? 'less'
			: 'same';

diag sprintf (	"$MMTXT Load/Cache     ratio: expected=%7.1f, tested=%7.1f (%s)", $ee, $rr, $s );

$rr	= $r3 / $r1;
$ee	= $e3 / $e1;

$p		= $rr - $ee;
$s	= ( $p > 0.3333 )
		? 'more'
		: ( $p < -0.3333 )
			? 'less'
			: 'same';

diag sprintf (	"$MMTXT Create/Cache   ratio: expected=%7.1f, tested=%7.1f (%s)", $ee, $rr, $s );

diag "\n\n\n$TITLE DONE";


#DEBUG Dumper $asylum;
