#!/usr/bin/env perl
use warnings FATAL=>'all';
use strict;

# Tests for the Perl module IPC::Run3::Shell
# 
# Copyright (c) 2014 Hauke Daempfling (haukex@zero-g.net).
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

# Note: Run coverage tests via
# $ perl Makefile.PL
# $ make
# $ make test
# $ IPC_RUN3_SHELL_AUTHOR_TESTS=1 /opt/perl5.20/bin/cover -test -coverage default,-pod
# $ make distclean
# $ rm -rv cover_db

# These tests are only supposed to increase code coverage.

BEGIN {
	warn "# AUTHOR: Remember to look at code coverage once in a while (Devel::Cover)\n"
		if $AUTHOR_TESTS && !$DEVEL_COVER;
	warn "# Don't forget to enable author tests for Devel::Cover (set \$ENV{IPC_RUN3_SHELL_AUTHOR_TESTS})!\n"
		if $DEVEL_COVER && !$AUTHOR_TESTS;
}

use Test::More $AUTHOR_TESTS && $DEVEL_COVER ? (tests=>6)
	: (skip_all=>'only used in author coverage testing');
use Test::Fatal 'exception';

use OverloadTestClasses;

# fiddle with debug switch to get full code coverage there
BEGIN { $IPC::Run3::Shell::DEBUG = 0 }
use IPC::Run3::Shell;
use IPC::Run3::Shell::CLIWrapper;
output_is {
	IPC::Run3::Shell::debug("testing 123");
	IPC::Run3::Shell->import(':run',':make_cmd','perl');
	{ package FooBar; IPC::Run3::Shell->import(':AUTOLOAD'); }
	is perl('-e','print "foo"'), "foo", "dummy test";
	my $perl = IPC::Run3::Shell::CLIWrapper->new(
		'perl', '-wMstrict', '-e', '1', '--' );
	$perl->foo("bar");
	$perl->();
	my $s = IPC::Run3::Shell->new();
	is $s->perl('-e','print "foo"'), "foo", "dummy test";
	$IPC::Run3::Shell::DEBUG = 1;
	IPC::Run3::Shell::debug("testing 456");
} '', "# IPC::Run3::Shell Debug: testing 456\n", "debug output";

is IPC::Run3::Shell::_cmd2str("foo",undef,"bar"),  ## no critic (ProtectPrivateSubs)
	"foo  bar", "_cmd2str coverage";

IPC::Run3::Shell::Autoload::DESTROY();
IPC::Run3::Shell::CLIWrapper::DESTROY();

{ # cover the overload bug workaround code branch
	local $overload::VERSION='1.03';
	like exception { IPC::Run3::Shell::_strify( FakeNumberOnly->new(5) ) },  ## no critic (ProtectPrivateSubs)
		qr/\bdoesn't overload string/,  "older overload version dies normally 1";
	local $overload::VERSION=undef;
	like exception { IPC::Run3::Shell::_strify( NotStrOrNumish->new(9) ) },  ## no critic (ProtectPrivateSubs)
		qr/\bdoesn't overload string/,  "older overload version dies normally 2";
}


done_testing;

