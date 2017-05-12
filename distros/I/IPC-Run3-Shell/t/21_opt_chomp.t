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

use Test::More tests => 26;

use IPC::Run3::Shell;
use warnings FATAL=>'IPC::Run3::Shell';

my $s = IPC::Run3::Shell->new;

is $s->perl('-e','print "foo"'), "foo", 'chomp 1';
is $s->perl('-e','print "foo\n"'), "foo\n", 'chomp 2';
is $s->perl('-e','print "foo\nbar\n"'), "foo\nbar\n", 'chomp 3';
is $s->perl({chomp=>1},'-e','print "foo"'), "foo", 'chomp 4';
is $s->perl({chomp=>1},'-e','print "foo\n"'), "foo", 'chomp 5';
is $s->perl({chomp=>1},'-e','print "foo\nbar\n"'), "foo\nbar", 'chomp 6';
is_deeply [$s->perl('-e','print "foo\nbar"')], ["foo\n","bar"], 'chomp 7';
is_deeply [$s->perl('-e','print "foo\nbar\n"')], ["foo\n","bar\n"], 'chomp 8';
is_deeply [$s->perl({chomp=>1},'-e','print "foo\nbar"')], ["foo","bar"], 'chomp 9';
is_deeply [$s->perl({chomp=>1},'-e','print "foo\nbar\n"')], ["foo","bar"], 'chomp 10';

# chomp+stdout
my $cso;
is $s->perl({chomp=>1},'-e','print "foo"',{stdout=>\$cso}), 0, 'chomp+stdout 1A';
is $cso, "foo", 'chomp+stdout 1B';
is $s->perl({chomp=>1},'-e','print "foo\n"',{stdout=>\$cso}), 0, 'chomp+stdout 2A';
is $cso, "foo\n", 'chomp+stdout 2B';
is $s->perl({chomp=>1},'-e','print "foo\nbar\n"',{stdout=>\$cso}), 0, 'chomp+stdout 3A';
is $cso, "foo\nbar\n", 'chomp+stdout 3B';
my @cso;
is $s->perl('-e','print "foo\nbar"',{stdout=>\@cso}), 0, 'chomp+stdout 4A';
is_deeply \@cso, ["foo\n","bar"], 'chomp+stdout 4B';
is $s->perl('-e','print "foo\nbar\n"',{stdout=>\@cso}), 0, 'chomp+stdout 5A';
is_deeply \@cso, ["foo\n","bar\n"], 'chomp+stdout 5B';
is $s->perl({chomp=>1},'-e','print "foo\nbar"',{stdout=>\@cso}), 0, 'chomp+stdout 6A';
is_deeply \@cso, ["foo\n","bar"], 'chomp+stdout 6B';
is $s->perl({chomp=>1},'-e','print "foo\nbar\n"',{stdout=>\@cso}), 0, 'chomp+stdout 7A';
is_deeply \@cso, ["foo\n","bar\n"], 'chomp+stdout 7B';

# chomp+stderr
my @cse;
is $s->perl({chomp=>1},'-e','print "quz"; print STDERR "foo\nbar\n"',{stderr=>\@cse}), 'quz', 'chomp+stderr 1A';
is_deeply \@cse, ["foo\n","bar\n"], 'chomp+stderr 1B';

