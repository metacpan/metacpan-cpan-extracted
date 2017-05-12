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

use Test::More tests => 17;
use Test::Fatal 'exception';

use IPC::Run3::Shell;
use warnings FATAL=>'IPC::Run3::Shell';

my $s = IPC::Run3::Shell->new;

# list context

is_deeply [$s->perl({both=>1},'-e','print "foo\n";warn "bar\n"')], ["foo\n","bar\n",0], "both list 1";
is_deeply [$s->perl({both=>1},'-e','print "foo\n";warn "quz\n";print "bar\n";warn "baz\n"')], ["foo\nbar\n","quz\nbaz\n",0], "both list 2";
is_deeply [$s->perl({both=>1,allow_exit=>[123]},'-e','warn "bar\n";exit 123')], ["","bar\n",123], "both list 3";

# scalar context

my $both1 = $s->perl({both=>1},'-e','print "foo\n";warn "bar\n"');
is $?, 0, 'both scalar 1a';
ok $both1 eq "foo\nbar\n" || $both1 eq "bar\nfoo\n", 'both scalar 1b';

my $both2 = $s->perl({both=>1},'-e','print "foo\n";warn "bar\n";warn "quz\n"');
is $?, 0, 'both scalar 2a';
ok $both2 eq "foo\nbar\nquz\n" || $both2 eq "bar\nfoo\nquz\n"
	|| $both2 eq "bar\nquz\nfoo\n", 'both scalar 2b';

my $both3 = $s->perl({both=>1,allow_exit=>[123]},'-e','warn "bar\n";exit 123');
is $?, 123<<8, 'both scalar 3a';
is $both3, "bar\n", 'both scalar 3b';

# void context

output_is { $s->perl({both=>1},'-e','warn "bar\n"; print "foo\n"'); 1 } "foo\n", "bar\n", "both void 1a";
is $?, 0, "both void 1b";

# check error messages

like exception { $s->perl({both=>1,stdout=>'/dev/null'},'-e','') },
	qr/can't use options both and stdout at the same time/, "both + stdout = error";
like exception { $s->perl({both=>1,stderr=>'/dev/null'},'-e','') },
	qr/can't use options both and stderr at the same time/, "both + stderr = error";
like exception { $s->perl({both=>1,fail_on_stderr=>1},'-e','') },
	qr/can't use options both and fail_on_stderr at the same time/, "both + fail_on_stderr = error";

# both + chomp

is_deeply [$s->perl({both=>1,chomp=>1},'-e','print "foo\n";warn "quz\n";print "bar\n";warn "baz\n"')], ["foo\nbar","quz\nbaz",0], "both chomp list";

my $both_chomp = $s->perl({both=>1,chomp=>1},'-e','print "foo\n";warn "bar\n";warn "quz\n"');
is $?, 0, 'both chomp scalar a';
ok $both_chomp eq "foo\nbar\nquz" || $both_chomp eq "bar\nfoo\nquz"
	|| $both_chomp eq "bar\nquz\nfoo", 'both chomp scalar b';

