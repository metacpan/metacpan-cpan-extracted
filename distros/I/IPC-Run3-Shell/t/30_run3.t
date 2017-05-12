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

use Test::More tests => 6;
use Test::Fatal 'exception';

use IPC::Run3::Shell [foobar => 'perl','-e','print "foo\nbar\n"'];
use warnings FATAL=>'IPC::Run3::Shell';

# at the moment we're just checking our option pass-through
# for a few options and assuming IPC::Run3 is tested well enough

my $out='';
foobar({stdout=>\$out});
is $out, "foo\nbar\n", 'stdout 1';
foobar({stdout=>\$out});
is $out, "foo\nbar\n", 'stdout 2';
foobar({stdout=>\$out,append_stdout=>1});
is $out, "foo\nbar\nfoo\nbar\n", 'stdout append';

my @out;
my $cb = sub { push @out, @_ };
{
	# so Data::Dumper doesn't complain about code refs
	local $IPC::Run3::Shell::DEBUG = 0;
	foobar({stdout=>$cb});
	foobar({stdout=>$cb});
}
is_deeply \@out, ["foo\n", "bar\n", "foo\n", "bar\n"], "stdout callback";

{
	no warnings 'redefine';  ## no critic (ProhibitNoWarnings)
	# mock run3 for some failure tests
	local *IPC::Run3::run3 = sub { $?=128|99;  ## no critic (RequireLocalizedPunctuationVars)
		return $_[0][-1] eq 'MOCK' };
	like exception { foobar(); 1 },
		qr/run3 "perl" failed/, 'mock run3 failure';
	like exception { foobar("MOCK"); 1 },
		qr/signal 99, with coredump/, 'mock coredump'; # also helps code coverage
}

done_testing;

