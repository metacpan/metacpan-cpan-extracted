#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';

use ok 'Log::Dispatch::Binlog::File';
use ok 'Log::Dispatch::Binlog::Handle';

use Test::TempDir;

use Storable qw(fd_retrieve);

{
	my $tmp = temp_root->file("log1");

	my $file = Log::Dispatch::Binlog::File->new(
		min_level => "debug",
		name => "file",
		filename => $tmp->stringify,
	);

	isa_ok( $file, "Log::Dispatch::File" );

	$file->log_message( my %p = ( level => "warn", message => "blah", name => "file" ) );

	my $fh = $tmp->open;

	is_deeply(
		fd_retrieve($fh),
		\%p,
		"stored to file",
	);
}

{
	my $tmp = temp_root->file("log2");

	my $wh = $tmp->open("w");
	$wh->autoflush(1);

	my $file = Log::Dispatch::Binlog::Handle->new(
		min_level => "debug",
		name => "handle",
		handle => $wh,
	);

	isa_ok( $file, "Log::Dispatch::Handle" );

	$file->log_message( my %p = ( level => "warn", message => "blah", name => "handle" ) );

	my $fh = $tmp->open;

	is_deeply(
		fd_retrieve($fh),
		\%p,
		"stored to file",
	);
}
