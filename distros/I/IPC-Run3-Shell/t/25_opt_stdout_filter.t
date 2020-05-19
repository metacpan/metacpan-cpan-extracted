#!/usr/bin/env perl
use warnings;
use strict;

# Tests for the Perl module IPC::Run3::Shell
# 
# Copyright (c) 2020 Hauke Daempfling (haukex@zero-g.net).
# 
# This library is free software; you can redistribute it and/or modify
# it under the same terms as Perl 5 itself.
# 
# For more information see the "Perl Artistic License",
# which should have been distributed with your copy of Perl.
# Try the command "perldoc perlartistic" or see
# http://perldoc.perl.org/perlartistic.html .

use FindBin ();
use lib $FindBin::Bin;
use IPC_Run3_Shell_Testlib;

use Test::More tests => 19;
use Test::Fatal 'exception';

use IPC::Run3::Shell;
use warnings FATAL=>'IPC::Run3::Shell';

my $s = IPC::Run3::Shell->new;

my $opt = { stdout_filter=>sub { $_="[[$_]]" } };

is $s->perl($opt,'-e','print "foo"'), "[[foo]]", 'filter 1';
is $s->perl($opt,'-e','print "foo\n"'), "[[foo\n]]", 'filter 2';
is $s->perl($opt,'-e','print "foo\nbar\n"'), "[[foo\nbar\n]]", 'filter 3';
is_deeply [$s->perl($opt,'-e','print "foo\nbar"')], ["[[foo\n]]","[[bar]]"], 'filter 4';
is_deeply [$s->perl($opt,'-e','print "foo\nbar\n"')], ["[[foo\n]]","[[bar\n]]"], 'filter 5';

# with chomp
my $optc = { %$opt, chomp=>1 };
is $s->perl($optc,'-e','print "foo"'), "[[foo]]", 'filter+chomp 1';
is $s->perl($optc,'-e','print "foo\n"'), "[[foo]]", 'filter+chomp 2';
is $s->perl($optc,'-e','print "foo\nbar\n"'), "[[foo\nbar]]", 'filter+chomp 3';
is_deeply [$s->perl($optc,'-e','print "foo\nbar"')], ["[[foo]]","[[bar]]"], 'filter+chomp 4';
is_deeply [$s->perl($optc,'-e','print "foo\nbar\n"')], ["[[foo]]","[[bar]]"], 'filter+chomp 5';

# with stdout
my $cso;
is $s->perl($opt,'-e','print "foo\nbar\n"',{stdout=>\$cso}), 0, 'filter+stdout 1A';
is $cso, "foo\nbar\n", 'filter+stdout 1B';
my @cso;
is $s->perl($opt,'-e','print "foo\nbar\n"',{stdout=>\@cso}), 0, 'filter+stdout 2A';
is_deeply \@cso, ["foo\n","bar\n"], 'filter+stdout 2B';

# with stderr
my @cse;
is $s->perl($opt,'-e','print "quz"; print STDERR "foo\nbar\n"',{stderr=>\@cse}), '[[quz]]', 'filter+stderr';
is_deeply \@cse, ["foo\n","bar\n"], 'filter+stderr';

# with both
subtest 'filter+both' => sub { plan tests=>3;
	my ($o,$e,$c) = $s->perl({ %$opt, both=>1 },'-e','print "foo\nbar\n"; print STDERR "quz\nbaz\n"');
	is $o, "[[foo\nbar\n]]", 'stdout';
	is $e, "quz\nbaz\n", 'stderr';
	is $c, 0, 'exit code';
};

# fails
like exception { is $s->perl({stdout_filter=>1},'-e','print "foo"'), "foo", "bad opt" },
	qr/\bmust be a coderef\b/i, "bad value for stdout_filter 1";
like exception { is $s->perl({stdout_filter=>[]},'-e','print "foo"'), "foo", "bad opt" },
	qr/\bmust be a coderef\b/i, "bad value for stdout_filter 2";
