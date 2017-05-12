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

use Test::More tests => 7;

use IPC::Run3::Shell;
use warnings FATAL=>'IPC::Run3::Shell';

my $s = IPC::Run3::Shell->new;

is_deeply [$s->perl({irs=>'A'},'-e','print "fooAbarAquz"')], ['fooA','barA','quz'], 'irs 1';

is_deeply [$s->perl({irs=>undef},'-e','print "foo\nbar\nquz"')], ["foo\nbar\nquz"], 'irs 2';

my @o1;
is $s->perl({irs=>"\t",stdout=>\@o1},'-e','print "foo\tbar\tquz"'), 0, 'irs 3';
is_deeply \@o1, ["foo\t","bar\t",'quz'], 'irs 4';

# irs + stderr
my @e1;
is $s->perl({irs=>'B',stderr=>\@e1},'-e','print "foo\n";warn "barBquzBbaz\n"'), "foo\n", 'irs 5';
is_deeply \@e1, ["barB","quzB","baz\n"], 'irs 6';

# irs + chomp
is_deeply [$s->perl({irs=>'C',chomp=>1},'-e','print "fooCbarCquz\n"')], ["foo","bar","quz\n"], 'irs 7';

