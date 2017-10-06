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

use Test::More tests => 21;
use Test::Fatal 'exception';
## no critic (ProhibitComplexRegexes)

use IPC::Run3::Shell;
use warnings FATAL=>'IPC::Run3::Shell';

my $s = IPC::Run3::Shell->new();

$s->perl('-e',';'); is $?, 0, 'allow_exit 1';
$s->perl({allow_exit=>[0,123]},'-e','exit'); is $?, 0, 'allow_exit 2';
$s->perl({allow_exit=>[0,123]},'-e','exit 123'); is $?, 123<<8, 'allow_exit 3';
like exception { $s->perl({allow_exit=>[0,123]},'-e','exit 124'); 1 },
	qr/exit (status|value) 124\b/, "allow_exit 4";
$s->perl({allow_exit=>[23]},'-e','exit 23'); is $?, 23<<8, 'allow_exit 5';
$s->perl({allow_exit=>23},'-e','exit 23'); is $?, 23<<8, 'allow_exit 6';
like exception { $s->perl({allow_exit=>[123]},'-e','$x=1'); 1 },
	qr/exit (status|value) 0\b/, 'allow_exit 7';

$s->perl({allow_exit=>'ANY'},'-e','exit'); is $?, 0, 'allow_exit any 1';
$s->perl({allow_exit=>'ANY'},'-e','exit 1'); is $?, 1<<8, 'allow_exit any 2';
$s->perl({allow_exit=>'ANY'},'-e','exit 23'); is $?, 23<<8, 'allow_exit any 3';
$s->perl({allow_exit=>'ANY'},'-e','exit 123'); is $?, 123<<8, 'allow_exit any 4';

my @w1 = warns {
		# make warnings nonfatal in a way compatible with Perl v5.6, which didn't yet have "NONFATAL"
		no warnings FATAL=>'all'; use warnings;  ## no critic (ProhibitNoWarnings)
		$s->perl({allow_exit=>[]},'-e','exit');
		is $?, 0, 'allow_exit err 1';
	};
ok @w1>=2, "warnings on empty allow_exit 1";
is grep({/allow_exit is empty/} @w1), 1, "warnings on empty allow_exit 2";
is grep({/exit (status|value) 0\b/} @w1), 1, "warnings on empty allow_exit 3";
my @w2 = warns {
		# make warnings nonfatal in a way compatible with Perl v5.6, which didn't yet have "NONFATAL"
		no warnings FATAL=>'all'; use warnings;  ## no critic (ProhibitNoWarnings)
		use warnings FATAL=>'IPC::Run3::Shell';
		like exception { $s->perl({allow_exit=>'any'},'-e','exit 5'); 1 },
			qr/\bexit (status|value) 5\b/, 'allow_exit err 2';
		like exception { $s->perl({allow_exit=>[0,'A',123]},'-e','exit 5'); 1 },
			qr/\bexit (status|value) 5\b/, 'allow_exit err 3';
		like exception { $s->perl({allow_exit=>[0,undef,123]},'-e','exit 5'); 1 },
			qr/\bexit (status|value) 5\b/, 'allow_exit err 4';
	};
is grep({/\bisn't numeric\b.+\ballow_exit\b.+\bat (?:\Q${\__FILE__}\E|.*\bTest\/Fatal\.pm) line\b/} @w2), 3, "allow_exit numeric warns"
	or diag explain \@w2;

$s->perl({allow_exit=>[123]},{allow_exit=>undef},'-e','exit');
	is $?, 0, 'allow_exit unset 1';
like exception { $s->perl({allow_exit=>[123]},{allow_exit=>undef},'-e','exit 123'); 1 },
	qr/exit (status|value) 123\b/, 'allow_exit unset 2';

