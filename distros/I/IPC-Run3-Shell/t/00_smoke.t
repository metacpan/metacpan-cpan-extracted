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

use Test::More tests=>14;
use Test::Fatal 'exception';

BEGIN {
	use_ok 'IPC::Run3';
	use_ok 'IPC::Run3::Shell';
}
is $IPC::Run3::Shell::VERSION, '0.54', 'version matches tests';
use warnings FATAL=>'IPC::Run3::Shell';

# Note that for testing, we're basically only calling an external perl process.
# This is because:
# - Calling an external perl should be relatively platform-independent
# - The point of these tests is primarily to test this module, not IPC::Run3

# We're not using an absolute path to perl because most users of this module
# will not be using absolute paths either, instead doing the equivalent of
# "use IPC::Run3::Shell qw/perl/;", which requires "perl" to be in the $PATH.
# perl being in $PATH is a documented requirement and experience with CPAN
# Testers has shown this works just about everywhere.

# check warns() and output_is() from our test lib
is_deeply [ warns { warn "I am a warning\n"; } ], ["I am a warning\n"], 'test warns()';
output_is { warn "I am warn\n"; print "I am output" } "I am output", "I am warn\n", 'test output_is()';

if ($AUTHOR_TESTS)
	{ ok exception { my $foo = 0 + undef }, "warnings are fatal during author tests" }
else
	{ ok warns { my $foo = 0 + undef }, "warnings aren't fatal (not running author tests)" }

# see if we can exec perl
system('perl','-e','exit 0')==0
	or BAIL_OUT("perl didn't exec properly (maybe it's not in \$PATH?)");

# Check run3()
ok run3(['perl','-e','warn "warn0\n";print <STDIN>."beep".<STDIN>; print STDERR "err";'], \"foo\nbar\n", \my $r3out, \my @r3err), 'run3';
is $?, 0, 'run3 $?';
is $r3out, "foo\nbeepbar\n", 'run3 stdout';
is_deeply \@r3err, ["warn0\n","err"], 'run3 stderr';

# Simple test
my $s = IPC::Run3::Shell->new();
output_is { $s->perl('-e','print "foo bar"'); 1 } 'foo bar', '', "simple void ctx";
my @sout = $s->perl('-e','warn "warn0\n";print <STDIN>."beep".<STDIN>; print STDERR "err";',{chomp=>1, stdin=>\"foo\nbar\n", stderr=>\my $serr});
is $?, 0, 'simple test $?';
is_deeply \@sout, ["foo","beepbar"], 'simple test stdout';
is $serr, "warn0\nerr", 'simple test stderr';

