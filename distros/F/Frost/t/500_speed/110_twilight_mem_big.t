#!/usr/bin/perl

use strict;
use warnings;

use lib 't/lib', 'lib';

use Frost::Test;

use Test::More;

BEGIN
{
	$ENV{Frost_DEBUG}	= 0;

	unless ( $ENV{Frost_SPEED} )
	{
		plan skip_all => 'Set $ENV{Frost_SPEED} for speed tests';
	}
	else
	{
		eval 'use Devel::Size 0.71; use Sys::MemInfo 0.91;';
		if ($@)
		{
			plan skip_all => 'Devel::Size 0.71 & Sys::MemInfo 0.91 required for this test';
		}
		else
		{
			plan tests => 4;
		}
	}
}

#	CONFIG
#
our $MAX_ID		= 20_000;
$MAX_ID		= 10_000;
#
#########

use Frost::Asylum;

our $KB	= 1024;
our $MB	= $KB * $KB;

our $FREE_START	= Sys::MemInfo::get ( "freemem" ) / $MB;

our $CLASSNAME		= 'Foo';

our $ASYL;

our $NEW_COUNT;
our $NEW_THRESH;


{
	package Foo;
	use Frost;

	has 's'	=>
	(
		is			=> 'rw',
		isa		=> 'Str',
	);

	no Frost;

	__PACKAGE__->meta->make_immutable()		unless $::MAKE_MUTABLE;
}

lives_ok { $ASYL = Frost::Asylum->new ( data_root => $TMP_PATH ); }	'Asylum->new';

$NEW_COUNT	= 20_000;
$NEW_THRESH	= $NEW_COUNT * 2;

is			$ASYL->cachesize,				2 * $MB,						'cachesize 2 MB default';
is			$ASYL->twilight_maxcount,	$NEW_COUNT,					"twilight_maxcount $NEW_COUNT spirits";
is			$ASYL->twilight_count,		0,								"twilight_count 0 spirits";

my $format_string	= "%7s %12s %12s %12s %12s %12s %4s";
my $format_data	= "%7d %12.3f %12.3f %12.3f %12.3f %12.3f %4s";

my $header_1	= sprintf ( $format_string, ( '', 'single   ', 'count*spirit', '', '', '', '' ) );
my $header_2	= sprintf ( $format_string, ( 'count', 'spirit KB', 'spirits MB', 'twilight MB', 'free MB', 'used MB', 'LRU' ) );

diag "\n\nThis test shows the usage of RAM by Frost::Twilight";

diag "\n\nCreating $MAX_ID spirits in a default twilight ($NEW_COUNT)...";
diag "The columns '* MB' should grow.";
diag $header_1;
diag $header_2;

run();

#$NEW_COUNT	= int ( $MAX_ID / 3.333333333333333333333333 );
#$NEW_THRESH	= $NEW_COUNT * 2;
##
#lives_ok { $ASYL->twilight_maxcount ( $NEW_COUNT ) }		'can change twilight_maxcount';
#is			$ASYL->twilight_maxcount,		$NEW_COUNT,			"twilight_maxcount $NEW_COUNT spirits";
#is			$ASYL->twilight_count,		0,							"twilight_count 0 spirits";
#
#diag "\n\nCreating $MAX_ID spirits in a reduced twilight ($NEW_COUNT)...";
#diag "At count > $NEW_THRESH the column 'twilight MB' should stay nearly constant";
#diag "(LRU triggered '***') and the test becomes very slow, because the cache has";
#diag "to be saved and reordered on every new entry.";
#diag $header_1;
#diag $header_2;
#
#run();

diag "\nDone...";

sub run
{
	$ASYL->clear;

	report_mem ( 0 );

	my $s			= 'A' x 128;
	my $thresh	= int ( $MAX_ID / 10 );

	foreach ( my $id = 1; $id <= $MAX_ID; $id++ )
	{
		my $foo		= $CLASSNAME->new ( asylum => $ASYL, id => $id, s => $s++ );

		report_mem ( $id )			unless ( $id % $thresh );
	}

	$ASYL->clear;
}

sub report_mem
{
	my ( $count )	= @_;

	my $id	= $count;

	my $twilight	= $ASYL->_twilight;								#	DON'T TRY THIS AT HOME
	my $spirit		= $twilight->get ( $CLASSNAME, $id );		#

	my ( $spi, $spiS, $twi );

	$spi	= Devel::Size::total_size ( $spirit )		/ $KB;
	$spiS	= ( ( $spi * $KB ) * $count )					/ $MB;

	$twi	= Devel::Size::total_size ( $twilight )	/ $MB;

	my $free	= Sys::MemInfo::get ( "freemem" )		/ $MB;
	my $used	= $FREE_START - $free;

	my $LRU_TRIGGERED	= $id >= $NEW_THRESH ? '***' : '';

	diag sprintf ( $format_data, ( $count, $spi, $spiS, $twi, $free, $used, $LRU_TRIGGERED ) );
}

1;

__END__
