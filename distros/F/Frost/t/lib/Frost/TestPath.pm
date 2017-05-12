package Frost::TestPath;

use strict;
use warnings;

our @ISA;
our @EXPORT;

use File::Path ();

use Exporter;
@ISA = qw( Exporter );

@EXPORT =
(
	qw(
		$TMP_PATH
		$TMP_PATH_COPY
		$TMP_PATH_1
		$TMP_PATH_2
		$TMP_PATH_3
		$TMP_PATH_4
		$TMP_PATH_ERROR
		$TMP_PATH_NIX
		test_read
		test_write
	),
);

our $TMP_PATH;
our $TMP_PATH_COPY;
our $TMP_PATH_1;
our $TMP_PATH_2;
our $TMP_PATH_3;
our $TMP_PATH_4;
our $TMP_PATH_ERROR;
our $TMP_PATH_NIX;

sub clean ($)
{
	my ( $path )	= shift;

	if ( -d $path )
	{
		File::Path::rmtree ( $path, { keep_root => 1 } );
	}
}

sub make ($)
{
	my ( $path )	= shift;

	File::Path::mkpath ( $path, 0, 0700 );		#	$paths, $verbose, $mode

	clean $path;
}

sub remove ($)
{
	my ( $path )	= shift;

	if ( -d $path )
	{
		clean $path;
		rmdir $path;
	}
}

sub test_read ($)
{
	my ( $file )	= shift;

	local *FH;
	local $/;
	open FH, "< $file" or die "Cannot read $file: $!";
	<FH>;
}

sub test_write ($$)
{
	my ( $file, $content )	= @_;

	local *FH;
	local $/;
	open FH, "> $file" or die "Cannot write $file: $!";
	print FH $content;
}

BEGIN
{
	$TMP_PATH			= '/tmp/frost';
	$TMP_PATH_COPY		= '/tmp/frost_copy';
	$TMP_PATH_1			= '/tmp/frost_1';
	$TMP_PATH_2			= '/tmp/frost_2';
	$TMP_PATH_3			= '/tmp/frost_3';
	$TMP_PATH_4			= '/tmp/frost_4';
	$TMP_PATH_ERROR	= '/tmp/frost_bad_chars_ÄÖÜ';
	$TMP_PATH_NIX		= '/tmp/frost_nix_exist';

	remove ( $TMP_PATH );
	remove ( $TMP_PATH_COPY );
	remove ( $TMP_PATH_1 );
	remove ( $TMP_PATH_2 );
	remove ( $TMP_PATH_3 );
	remove ( $TMP_PATH_4 );
	remove ( $TMP_PATH_ERROR );
	remove ( $TMP_PATH_NIX );

	make ( $TMP_PATH );
}

END
{
	unless ( $ENV{Frost_DEBUG} )
	{
		remove ( $TMP_PATH );
		remove ( $TMP_PATH_COPY );
		remove ( $TMP_PATH_1 );
		remove ( $TMP_PATH_2 );
		remove ( $TMP_PATH_3 );
		remove ( $TMP_PATH_4 );
		remove ( $TMP_PATH_ERROR );
		remove ( $TMP_PATH_NIX );
	}
}

1;

__END__
