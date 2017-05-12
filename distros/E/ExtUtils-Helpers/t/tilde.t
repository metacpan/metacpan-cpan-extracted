#!/usr/bin/perl -w

# Test ~ expansion from command line arguments.

use strict;
use lib 't/lib';
use Test::More tests => 9;

use ExtUtils::Helpers 'detildefy';

SKIP: {
	my $env_name = $^O eq 'MSWin32' ? 'USERPROFILE' : 'HOME';
	my $home = $ENV{$env_name};

	if ($^O eq 'VMS') {
		# Convert the path to UNIX format, trim off the trailing slash
		$home = VMS::Filespec::unixify($home);
		$home =~ s#/$##;
	}

	unless (defined $home) {
		my @info = eval { getpwuid $> };
		skip "No home directory for tilde-expansion tests", 8 if $@ or !defined $info[7];
		$home = $info[7];
	}

	is( detildefy('~'),	$home);

	is( detildefy('~/fooxzy'), "$home/fooxzy");

	is( detildefy('~/ fooxzy'), "$home/ fooxzy");

	is( detildefy('~/fo o'), "$home/fo o");

	is( detildefy('fooxzy~'), 'fooxzy~');

	# Test when HOME is different from getpwuid(), as in sudo.
	{
		local $ENV{HOME} = '/wibble/whomp';
		local $ENV{USERPROFILE} = $ENV{HOME};

		is( detildefy('~'), "/wibble/whomp");
	}

	skip "On OS/2 EMX all users are equal", 2 if $^O eq 'os2';
	is( detildefy('~~'), '~~' );
	is( detildefy('~ fooxzy'), '~ fooxzy' );
}

# Again, with named users
SKIP: {
	my @info = eval { getpwuid $> };
	skip "No home directory for tilde-expansion tests", 1 if $@ or !defined $info[7] or !defined $info[0];
	my ($me, $home) = @info[0,7];

	my $expected = "$home/fooxzy";

	if ($^O eq 'VMS') {
		# Convert the path to UNIX format and trim off the trailing slash
		$home = VMS::Filespec::unixify($home);
		$home =~ s#/$##;
		$expected = $home . '/../[^/]+' . '/fooxzy';
	}
	like( detildefy("~$me/fooxzy"), qr(\Q$expected\E)i );
}

