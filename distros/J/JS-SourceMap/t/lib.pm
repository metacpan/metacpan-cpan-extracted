#! perl

# t::lib is a convention I've adoted in my Perl test suites that seems
# to work out okay.  The idea is that every test starts with:
#
#    use t::lib;
#
# which sticks stuff into the main package and arranges to set up
# whatever environment the tests need: output directory, output files,
# working dir, blah blah.  Whatever.  The END {} block cleans up
# anything we do automatically when a test dies or wins.

# Copyright (C) 2017 by attila <attila@stalphonsos.com>
# 
# Permission to use, copy, modify, and distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
# 
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL
# WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE
# AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL
# DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR
# PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER
# TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
# PERFORMANCE OF THIS SOFTWARE.

package main;
use strict;
use warnings;

sub setup_testing_env {}

sub cleanup_testing_env {}

sub slurp {
	my($fn) = @_;
	open(F, $fn) or die("$fn: $!");
	local($/);
	$/ = undef;
	my $contents = <F>;
	close(F);
	return $contents;
}

sub get_fixture {
	my($name) = @_;
	die("where are my fixtures?") unless -d "t/fixtures";
	return map { slurp("t/fixtures/${name}.$_") } qw(js min.js min.map);
}

sub assert { my($cond,$msg) = @_; die("ASSERTION FAILED: $msg") unless $cond; }

END {
	cleanup_testing_env unless $ENV{'JS_SOURCEMAP_KEEP_TEST_ENV'};
}

setup_testing_env unless $ENV{'JS_SOURCEMAP_TEST_NO_SETUP'};

1;

##
# Local variables:
# mode: perl
# tab-width: 8
# perl-indent-level: 8
# cperl-indent-level: 8
# cperl-continued-statement-offset: 8
# indent-tabs-mode: t
# comment-column: 40
# End:
##
