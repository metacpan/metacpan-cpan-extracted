#!/usr/bin/env perl
use warnings;
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

use Test::More tests => 12;

use IPC::Run3::Shell qw/ perl :run :make_cmd /, [ foo => 'perl', '-e', 'print "foo @ARGV"' ];
use warnings FATAL=>'IPC::Run3::Shell';

# basic functional interface test
output_is { perl('-e','print "foo bar"'); 1 } 'foo bar', '', 'functional, void ctx';
is perl('-e','print "foo bar"'), 'foo bar', 'functional, scalar ctx';
is_deeply [perl('-e','print "foo\nbar\n"')], ["foo\n","bar\n"], 'functional, list ctx';

# run, make_cmd, aliasing
is run('perl','-e','print "foo\tbar\n"'), "foo\tbar\n", 'run()';
my $x = make_cmd('perl');
is $x->('-e','print "foo bar\n"'), "foo bar\n", 'make_cmd()';
is foo('bar'), 'foo bar', 'aliasing';

# other documented ways to call subs
is IPC::Run3::Shell::run('perl','-e','print "foobar"'), "foobar", 'IPC::Run3::Shell::run()';
is IPC::Run3::Shell::make_cmd('perl','-e')->('print "foo"'), "foo", 'IPC::Run3::Shell::make_cmd()';
IPC::Run3::Shell->import([foo2=>'perl','-e']);
is foo2('print "bar"'), "bar", 'IPC::Run3::Shell->import()';

# shell metacharacter escaping
is perl('-e','print "@ARGV"','a >b'), 'a >b', 'shell metachar 1';
is perl('-e','$"="##"; print "@ARGV"','""', '$HOME', '1>&2', 'a b', ' ', "c\n", '!@#$%^&*()+={}[]\|;:?/<>,.`\'"-_'),
	"\"\"##\$HOME##1>&2##a b## ##c\n##!\@#\$%^&*()+={}[]\\|;:?/<>,.`'\"-_", 'shell metachar 2';
is perl('-e','$"="##"; print "@ARGV"',' "" \\ ; $HOME 1>&2 '),
	' "" \\ ; $HOME 1>&2 ', 'shell metachar 3'; # from the Synopsis

