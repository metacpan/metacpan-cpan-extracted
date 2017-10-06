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
use Test::Fatal 'exception';
## no critic (ProhibitComplexRegexes)

use IPC::Run3::Shell ':run', [ perl1 => 'perl', '-e', 'print "foo @ARGV"' ];
use warnings FATAL=>'IPC::Run3::Shell';

my $s = IPC::Run3::Shell->new();

# NOTE I'm not yet sure why the following differences in the platforms exist,
# this is just based on results from CPAN Testers.
my $SIG9_RETURNCODE = 9;
my $SIG9_ERROR_RE = qr/signal 9, without coredump|\Qsignal "KILL" (9)\E/;
if ($^O eq 'MSWin32') {
	$SIG9_RETURNCODE = 9<<8;
	$SIG9_ERROR_RE = qr/exit status 9\b/;
}
elsif ($^O eq 'haiku') {
	$SIG9_RETURNCODE = 21;
	$SIG9_ERROR_RE = qr/signal 21, without coredump/;
}

# test some simple error cases
like exception { run(); 1 },
	qr/empty command/, "error checking 1";
{
	use warnings FATAL=>'uninitialized';
	like exception { perl1('x',undef,'',0,'0E0',undef,'z'); 1 },
		qr/\bUse of uninitialized value in argument list\b/, "undefs";
}
like exception { run('perl','-e',[1,2]); 1 },
	qr/contains?.+references/, "error checking 2";
like exception { run('perl','-e',{a=>2},'--'); 1 },
	qr/contains?.+references/, "error checking 3";
like exception { run('perl','-e',sub {}); 1 },
	qr/contains?.+references/, "error checking 4";
like exception { run('perl','-e',IPC::Run3::Shell->new()); 1 },
	qr/contains?.+references/, "error checking 5";
like exception { IPC::Run3::Shell->import({},'perl',{}); 1 },
	qr/\bargument list contains references\b/, "import error checking 1";
{
	use warnings FATAL=>'uninitialized';
	like exception { IPC::Run3::Shell->import({},undef,'perl'); 1 },
		qr/\bUse of uninitialized value\b/, "import error checking 2";
}
like exception { IPC::Run3::Shell->import(':BAD_SYMBOL'); 1 },
	qr/can't export "BAD_SYMBOL"/, "import error checking 3";
like exception { IPC::Run3::Shell->import([]); 1 },
	qr/no function name/, "import error checking 4";
like exception { IPC::Run3::Shell->import(['']); 1 },
	qr/no function name/, "import error checking 5";
like exception { IPC::Run3::Shell->import(''); 1 },
	qr/no function name/, "import error checking 5b";
like exception { IPC::Run3::Shell->import(['x']); 1 },
	qr/empty command/, "import error checking 6";
like exception { IPC::Run3::Shell->make_cmd(); 1 },
	qr/called as a method/, "make_cmd as a method";
# this one checks some logic for the OO interface
like exception {
		IPC::Run3::Shell::make_cmd()->(bless {}, 'IPC_Run3_Shell_Testlib::FooBar'); 1
	}, qr/contains?.+references/, "blessed ref as first arg";

# failure tests
like exception { $s->perl('-e','exit 1'); 1 },
	qr/exit (status|value) 1\b/, "fail 1";
like exception { $s->ignore_this_error_it_is_intentional; 1 },
	qr/\QCommand "ignore_this_error_it_is_intentional" failed/, "fail 2";
like exception { $s->perl('-e','exit 123'); 1 },
	qr/exit (status|value) 123\b/, "fail 3";
like exception { is $s->perl({_BAD_OPT=>1},'-e','print "foo"'), "foo", "unknown opt 1A" },
	qr/\Qunknown option "_BAD_OPT"/, "unknown opt 1B";
like exception { $s->perl('-e','kill 9, $$'); 1 }, $SIG9_ERROR_RE, "fail 4";

{ # warning tests
	# make warnings nonfatal in a way compatible with Perl v5.6, which didn't yet have "NONFATAL"
	no warnings FATAL=>'all'; use warnings;  ## no critic (ProhibitNoWarnings)
	# the following is a workaround for Perl v5.6 not yet having the NONFATAL keyword;
	# note we check below that this block does not produce any extra warnings even in v5.6
	use warnings ($]<=5.008) ? (FATAL=>'uninitialized','numeric') : (FATAL=>'all', NONFATAL=>'IPC::Run3::Shell');
	ok exception { my $x = 0 + undef; }, 'double-check warning fatality 1';
	my @w1 = warns {
			is $s->perl('-e','print "foo"; exit 1'), "foo", "warning test 1A"; is $?, 1<<8, "warning test 1B";
			ok !$s->ignore_this_error_it_is_intentional(), "warning test 2A"; is $?, $^O eq 'MSWin32' ? 0xFF00 : -1, "warning test 2B";
			is $s->perl({stdout=>\my $x},'-e','print "foo"; exit 123'), 123, "warning test 3A"; is $?, 123<<8, "warning test 3B";
			is $x, "foo", "warning test 3C";
			is $s->perl('-e','kill 9, $$'), '', "warning test 4A"; is $?, $SIG9_RETURNCODE, "warning test 4B";
		};
	# on some Windows systems, there is an extra warning like the following
	# (seen on some CPAN Testers results for v0.51)
	# /\QCan't spawn "cmd.exe"/
	# but we can just ignore that here, since we're just looking for our custom warnings
	ok @w1>=4, "warning test count";
	is grep({/exit (status|value) 1\b/} @w1), 1, "warning test 1C";
	is grep({/\QCommand "ignore_this_error_it_is_intentional" failed/} @w1), 1, "warning test 2C";
	is grep({/exit (status|value) 123\b/} @w1), 1, "warning test 3D";
	is grep({/$SIG9_ERROR_RE/} @w1), 1, "warning test 4C";
	# make sure fail_on_stderr is still fatal
	like exception { $s->perl({fail_on_stderr=>1},'-e','print STDERR "bang"') },
		qr/\Qwrote to STDERR: "bang"/, "fail_on_stderr with nonfatal warnings";
	# 'uninitialized' warnings should also be fatal
	like exception { $s->perl('-e','print ">>@ARGV<<"','--','x',undef,0,undef,'y') },
		qr/^Use of uninitialized value in argument list\b/, "undef fatal";
	# we test for exceptions in several places, here we check that those are actually just fatal warnings
	my @w3 = warns {
			like $s->perl('-e','print ">>@ARGV<<"','--','x',[1,2],'y'), qr/^>>x ARRAY\(0x[0-9a-fA-F]+\) y<<$/, "undef/ref warn 1B";
			is $s->perl({_BAD_OPT=>1},'-e','print "foo"'), "foo", "unknown opt 2A";
		};
	ok @w3>=2, "warn count";
	is grep({/contains?.+references/} @w3), 1, "undef/ref warn 1E";
	is grep({/\Qunknown option "_BAD_OPT"/} @w3), 1, "unknown opt 2B";
	# the numeric category should still be fatal
	like exception { $s->perl({allow_exit=>'A'},'-e','print "foo"') },
		qr/\bisn't numeric\b.+\ballow_exit\b.+\bat (?:\Q${\__FILE__}\E|.*\bTest\/Fatal\.pm) line\b/, "allow_exit warn 1C";
}

{ # disable warnings
	use warnings FATAL=>'all';
	no warnings 'IPC::Run3::Shell';  ## no critic (ProhibitNoWarnings)
	ok exception { my $x = 0 + undef; }, 'double-check warning fatality 2';
	my @w4 = warns {
			# note these are just copied from the "warnings tests" above
			is $s->perl('-e','print "foo"; exit 1'), "foo", "no warn 1A"; is $?, 1<<8, "no warn 1B";
			ok !$s->ignore_this_error_it_is_intentional(), "no warn 2A"; is $?, $^O eq 'MSWin32' ? 0xFF00 : -1, "no warn 2B";
			is $s->perl({stdout=>\my $x},'-e','print "foo"; exit 123'), 123, "no warn 3A"; is $?, 123<<8, "no warn 3B";
			is $x, "foo", "no warn 3C";
			is $s->perl('-e','kill 9, $$'), '', "no warn 4A"; is $?, $SIG9_RETURNCODE, "no warn 4B";
			
			like $s->perl('-e','print ">>@ARGV<<"','--','x',[1,2],'y'), qr/^>>x ARRAY\(0x[0-9a-fA-F]+\) y<<$/, "no warn 7";
			is $s->perl({_BAD_OPT=>1},'-e','print "foo"'), "foo", "unknown opt 3";
		};
	# regexen copied and adapted from above
	is grep({/\QCan't spawn "cmd.exe"\E|exit (status|value)\b|\QCommand "ignore_this_error_it_is_intentional" failed\E|$SIG9_ERROR_RE/} @w4), 0, "no warnings";
	# the uninitialized category should still be fatal too
	like exception { $s->perl('-e','print ">>@ARGV<<"','--','x',undef,0,undef,'y') },
		qr/^Use of uninitialized value in argument list\b/, "uninizialized still fatal here";
	# the numeric category should still be fatal
	like exception { $s->perl({allow_exit=>'A'},'-e','print "foo"') },
		qr/\bisn't numeric\b.+\ballow_exit\b.+\bat (?:\Q${\__FILE__}\E|.*\bTest\/Fatal\.pm) line\b/, "numeric still fatal here";
	# make sure fail_on_stderr is still fatal
	like exception { $s->perl({fail_on_stderr=>1},'-e','print STDERR "bang"') },
		qr/\Qwrote to STDERR: "bang"/, "fail_on_stderr without warnings";
}

# only IPC::Run3::Shell warnings enabled
{
	no warnings;  ## no critic (ProhibitNoWarnings)
	use warnings FATAL=>'IPC::Run3::Shell';
	is warns { my $xyz = 5 + undef }, 0, "check warnings disabled";
	like exception { $s->perl('-e','exit 123'); 1 }, qr/exit (status|value) 123\b/, "module warn only";
}

{ # warning only tests (i.e. all warnings enabled but nonfatal)
	no warnings FATAL=>'all'; use warnings;  ## no critic (ProhibitNoWarnings)
	my @w5 = warns { IPC::Run3::Shell->import(undef) };
	ok @w5>=1, "warning count";
	is grep({/\bUse of uninitialized value in import\b/} @w5), 1, "undef in import warn";
}


done_testing;

