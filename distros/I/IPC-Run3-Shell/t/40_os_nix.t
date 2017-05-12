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

# ### NOTE ###
# These tests are meant to be really simple sanity tests to check if some
# OS-specific commands other than "perl" work. If any of these tests fail,
# but all other tests pass, then it's probably just due to that specific
# external command not being available or working differently on your OS.
# It is usually fine to force an install of the module anway. Please report
# any such failures as bugs.

# Possible To-Do for Later: This test should run on lots of other *NIX systems.
# I just haven't gotten around to making a longer list.
our @TESTS_RUN_ON;
BEGIN { @TESTS_RUN_ON = qw/ linux / }
use Test::More (grep {$^O eq $_} @TESTS_RUN_ON) ? (tests=>4)
	: (skip_all=>"these tests run on: @TESTS_RUN_ON, this is $^O");

use IPC::Run3::Shell;
use warnings FATAL=>'IPC::Run3::Shell';

my $s = IPC::Run3::Shell->new;

is $s->echo('-n',"Hello, World!"), "Hello, World!", 'echo output';
is $?, 0, 'echo ran ok';

my $exp_time = time;
my $got_time = $s->date('+%s',{chomp=>1});
is $?, 0, "date ran ok: $got_time (exp $exp_time)";

# assuming $got_time and $exp_time will have a max difference of 20 secs...
# I hope that's realistic even under a heavy load :-)
ok abs($exp_time-$got_time)<20, 'date matches';

