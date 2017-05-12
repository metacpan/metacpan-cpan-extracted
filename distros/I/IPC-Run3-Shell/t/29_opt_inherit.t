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

use Test::More;

use IPC::Run3::Shell { __TEST_OPT_B=>'y' },
	[ f_a  => 'perl', '-e', 'print "FA"' ],
	[ f_b => { __TEST_OPT_A=>'r' }, 'perl', '-e', 'print "FB"' ],
	':make_cmd', ':run';
use warnings FATAL=>'IPC::Run3::Shell';

# test import with default opts and various overrides
is f_a, 'B=y', 'func, opt B/none';
is f_a({__TEST_OPT_A=>'z'}), 'A=z,B=y', 'func, opt B/A';
is f_a({__TEST_OPT_B=>'z'}), 'B=z', 'func, opt B/B';
is f_a({__TEST_OPT_A=>undef}), 'A=undef,B=y', 'func, opt B/A(undef)';
is f_a({__TEST_OPT_B=>undef}), 'B=undef', 'func, opt B/B(undef)';
is f_a({__TEST_OPT_B=>'z'},{__TEST_OPT_A=>'o'}), 'A=o,B=z', 'func, opt B/BA';
is f_a({__TEST_OPT_A=>'z'},{__TEST_OPT_A=>'o'}), 'A=o,B=y', 'func, opt B/AA';
is f_a({__TEST_OPT_B=>'z'},{__TEST_OPT_B=>'o'}), 'B=o', 'func, opt B/BB';
# same, just test opts at end of argument list
is f_a({__TEST_OPT_A=>'z'},'_'), 'A=z,B=y', 'func, opt B/A front';
is f_a({__TEST_OPT_B=>'z'},'_'), 'B=z', 'func, opt B/B front';
is f_a('_',{__TEST_OPT_A=>'z'}), 'A=z,B=y', 'func, opt B/A end';
is f_a('_',{__TEST_OPT_B=>'z'}), 'B=z', 'func, opt B/B end';
is f_a({__TEST_OPT_B=>'z'},'_',{__TEST_OPT_A=>'o'}), 'A=o,B=z', 'func, opt B/BA mixed';
is f_a({__TEST_OPT_A=>'z'},'_',{__TEST_OPT_A=>'o'}), 'A=o,B=y', 'func, opt B/AA mixed';
is f_a({__TEST_OPT_B=>'z'},'_',{__TEST_OPT_B=>'o'}), 'B=o', 'func, opt B/BB mixed';
is f_a('_',{__TEST_OPT_B=>'z'},{__TEST_OPT_A=>'o'}), 'A=o,B=z', 'func, opt B/BA end';
is f_a('_',{__TEST_OPT_A=>'z'},{__TEST_OPT_A=>'o'}), 'A=o,B=y', 'func, opt B/AA end';
is f_a('_',{__TEST_OPT_B=>'z'},{__TEST_OPT_B=>'o'}), 'B=o', 'func, opt B/BB end';
# test import + make_cmd opts and various overrides
is f_b, 'A=r,B=y', 'func, opt BA/none';
is f_b({__TEST_OPT_A=>'z'}), 'A=z,B=y', 'func, opt BA/A';
is f_b({__TEST_OPT_B=>'z'}), 'A=r,B=z', 'func, opt BA/B';
is f_b({__TEST_OPT_B=>'z'},{__TEST_OPT_A=>'o'}), 'A=o,B=z', 'func, opt BA/BA';
is f_b({__TEST_OPT_A=>'z'},{__TEST_OPT_A=>'o'}), 'A=o,B=y', 'func, opt BA/AA';
is f_b({__TEST_OPT_B=>'z'},{__TEST_OPT_B=>'o'}), 'A=r,B=o', 'func, opt BA/BB';
# test run
is run('perl','-e','print "R"'), 'B=y', 'func, opt run B/none';
is run({__TEST_OPT_A=>'z'},'perl','-e','print "R"'), 'A=z,B=y', 'func, opt run B/A';
is IPC::Run3::Shell::run('perl','-e','print "R"'), 'R', 'func, opt run none/none';
is IPC::Run3::Shell::run({__TEST_OPT_A=>'z'},'perl','-e','print "R"'), 'A=z', 'func, opt run none/A';
# test make_cmd
my $f_c = make_cmd('perl', '-e', 'print "FC"');
is $f_c->(), "FC", 'func, opt none/none';
is $f_c->({__TEST_OPT_B=>'y'}), 'B=y', 'func, opt none/B';
is $f_c->({__TEST_OPT_B=>'y'},{__TEST_OPT_A=>'x'}), 'A=x,B=y', 'func, opt none/BA';
my $f_d = make_cmd({__TEST_OPT_A=>'x'}, 'perl', '-e', 'print "FD"');
is $f_d->(), 'A=x', 'func, opt A/none';
is $f_d->({__TEST_OPT_B=>'y'}), 'A=x,B=y', 'func, opt A/B';
is $f_d->({__TEST_OPT_B=>'y'},{__TEST_OPT_A=>'r'}), 'A=r,B=y', 'func, opt A/BA';
# test multiple opts in import
use IPC::Run3::Shell { __TEST_OPT_B=>'y' }, { __TEST_OPT_A=>'r' },
	[ f_e  => 'perl', '-e', 'print "FE"' ];
is f_e, 'A=r,B=y', 'func, opt BA';
# import calls should be independent, so the following shouldn't have B set
use IPC::Run3::Shell { __TEST_OPT_A=>'r' }, [ f_f  => 'perl', '-e', 'print "FE"' ];
is f_f, 'A=r', 'func, opt A';

# OO tests
my $o_a = IPC::Run3::Shell->new();
is $o_a->perl('-e','print "OA"'), "OA", 'OO, opts none/none';
is $o_a->perl({__TEST_OPT_A=>'x'},'-e','print "OA"'), 'A=x', 'OO, opts none/A';
is $o_a->perl({__TEST_OPT_A=>'x'},{__TEST_OPT_B=>'y'},'-e','print "OA"'), 'A=x,B=y', 'OO, opts none/AB';
my $o_b = IPC::Run3::Shell->new(__TEST_OPT_B=>'z');
is $o_b->perl('-e','print "OB"'), 'B=z', 'OO, opts B/none';
is $o_b->perl({__TEST_OPT_A=>'x'},'-e','print "OB"'), 'A=x,B=z', 'OO, opts B/A front';
is $o_b->perl('-e','print "OB"',{__TEST_OPT_A=>'x'}), 'A=x,B=z', 'OO, opts B/A end';
is $o_b->perl({__TEST_OPT_A=>'x'},{__TEST_OPT_B=>'y'},'-e','print "OB"'), 'A=x,B=y', 'OO, opts B/AB front';
is $o_b->perl({__TEST_OPT_A=>'x'},'-e','print "OB"',{__TEST_OPT_B=>'y'}), 'A=x,B=y', 'OO, opts B/AB mixed';
is $o_b->perl('-e','print "OB"',{__TEST_OPT_A=>'x'},{__TEST_OPT_B=>'y'}), 'A=x,B=y', 'OO, opts B/AB end';
my $o_c = IPC::Run3::Shell->new(__TEST_OPT_B=>'z',__TEST_OPT_A=>'i');
is $o_c->perl('-e','print "OC"'), 'A=i,B=z', 'OO, opts BA/none';
is $o_c->perl({__TEST_OPT_A=>'x'},'-e','print "OC"'), 'A=x,B=z', 'OO, opts BA/A';
is $o_c->perl({__TEST_OPT_A=>'x'},{__TEST_OPT_B=>'y'},'-e','print "OC"'), 'A=x,B=y', 'OO, opts BA/AB';


done_testing;

