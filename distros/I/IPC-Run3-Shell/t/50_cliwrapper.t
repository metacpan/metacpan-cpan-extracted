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

use Test::More tests => 14;

BEGIN { use_ok 'IPC::Run3::Shell::CLIWrapper' }

{
	my $perl = new_ok 'IPC::Run3::Shell::CLIWrapper' =>
		[ 'perl', '-wMstrict', '-e', q{ print join "|", @ARGV }, '--' ];
	is $perl->foo([f=>undef,x=>"y"],"hello"), 'foo|--f|--x|y|hello', 'basic method';
	is $perl->("z",[a=>"b"],"r"), 'z|--a|b|r', 'basic coderef';
}
{
	my $perl = IPC::Run3::Shell::CLIWrapper->new( { val_sep=>'=' },
		 'perl', '-wMstrict', '-e', q{ print join "|", @ARGV }, '--' );
	is $perl->foo([x=>"y"],"hello"), 'foo|--x=y|hello', 'val_sep 1';
	is $perl->foo_bar([x_y=>"z"],"quz_baz"), 'foo-bar|--x-y=z|quz_baz', 'under2dash on method';
	is $perl->([x_y=>"z"],"quz_baz"), '--x-y=z|quz_baz', 'under2dash on coderef';
}
{
	my $perl = IPC::Run3::Shell::CLIWrapper->new( { opt_char=>'/' },
		 'perl', '-wMstrict', '-e', q{ print join "|", @ARGV }, '--' );
	is $perl->foo([f=>undef,x=>"y"],"hello"), 'foo|/f|/x|y|hello', 'opt_char';
}
{
	my $perl = IPC::Run3::Shell::CLIWrapper->new( { opt_char=>undef },
		 'perl', '-wMstrict', '-e', q{ print join "|", @ARGV }, '--' );
	is $perl->foo([f=>undef,x=>"y"],"hello"), 'foo|f|x|y|hello', 'opt_char empty';
}
{
	my $perl = IPC::Run3::Shell::CLIWrapper->new( { under2dash=>0 },
		 'perl', '-wMstrict', '-e', q{ print join "|", @ARGV }, '--' );
	is $perl->foo_bar([x_y=>"z"],"quz_baz"), 'foo_bar|--x_y|z|quz_baz', 'under2dash off method';
	is $perl->([x_y=>"z"],"quz_baz"), '--x_y|z|quz_baz', 'under2dash off coderef';
}
is grep({/\bOdd number of elements\b/i} warns {
	no warnings FATAL=>'all'; use warnings;  ## no critic (ProhibitNoWarnings)
	my $perl = new_ok 'IPC::Run3::Shell::CLIWrapper' =>
		[ 'perl', '-wMstrict', '-e', q{ print join "|", @ARGV }, '--' ];
	is $perl->foo([f=>undef,x=>"y",7],"hello"), 'foo|--f|--x|y|--7|hello', 'odd nr of args';
}), 1, 'warn count';
