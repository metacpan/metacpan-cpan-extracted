#!/usr/bin/env perl

# The databases that Makefile.PL downloads are what most of this distribution is
# built on, and a download that doesn't happen is invisible in the build: the
# make runs, the tests are started, and the failure turns up as a database that
# isn't there.  That is how "gunzip: cities.csv.gz: No such file or directory"
# reached CPAN - the install reported success and then failed in the tests.
#
# LWP::Simple::WithCache is what caused it.  It swaps in a caching user agent
# whose request($request, $file) answers a cache hit, or a 304, out of the cache
# and never writes $file, so getstore() answers 200 and leaves nothing behind:
# on a machine whose cache was warm, no database was fetched at all.  This test
# holds Makefile.PL to the three things that keep that from coming back - ask
# LWP::Simple for the file, wait for the children that fetch it, and look at the
# file that arrived rather than at the status code.

use strict;
use warnings;

use Test::Most;

my $makefile_pl;

if(open(my $fh, '<', 'Makefile.PL')) {
	local $/;
	$makefile_pl = <$fh>;
	close $fh or warn "Can't close Makefile.PL: $!";
} else {
	plan(skip_all => "Can't read Makefile.PL: $!");
}

plan(tests => 4);

unlike($makefile_pl, qr/LWP::Simple::WithCache\s*(::|->)/,
	'the downloads are not asked of LWP::Simple::WithCache, which answers 200 without writing the file');

like($makefile_pl, qr/require LWP::Simple;/,
	'they are asked of LWP::Simple, which writes the file it downloads');

like($makefile_pl, qr/wait_all_children/,
	'the forked downloads are waited for, so the files can be checked after them');

like($makefile_pl, qr/Couldn't download/,
	'and a download that never arrived is reported rather than left to fail a test later');
