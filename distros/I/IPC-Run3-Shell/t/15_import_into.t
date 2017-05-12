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

use Test::More tests => 3;

use IPC::Run3::Shell;
use warnings FATAL=>'IPC::Run3::Shell';

IPC::Run3::Shell->import_into('Foo::Bar','perl',[ foo => 'perl', '-e', 'print "foo @ARGV"' ],':run');

{
	package Foo::Bar;
	use warnings;
	use strict;
	use warnings FATAL=>'IPC::Run3::Shell';
	use Test::More import=>['is'];
	is perl('-e','print "x @ARGV y"','a >b'), 'x a >b y', 'import_into 1';
	is foo('bar'), 'foo bar', 'import_into 2';
	is run('perl','-e','print "foo\tbar\n"'), "foo\tbar\n", 'import_into 3';
}

