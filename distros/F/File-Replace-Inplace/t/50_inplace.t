#!/usr/bin/env perl
use warnings;
use strict;

=head1 Synopsis

Tests for the Perl module File::Replace::Inplace.

These tests are based heavily on F<t/25_tie_handle_argv.t>.

=head1 Author, Copyright, and License

Copyright (c) 2018-2023 Hauke Daempfling (haukex@zero-g.net)
at the Leibniz Institute of Freshwater Ecology and Inland Fisheries (IGB),
Berlin, Germany, L<http://www.igb-berlin.de/>

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see L<http://www.gnu.org/licenses/>.

=cut

use FindBin ();
use lib $FindBin::Bin;
use File_Replace_Testlib;

use Test::More tests=>33;

use Cwd qw/getcwd/;
use File::Temp qw/tempdir/;

use File::Spec::Functions qw/catdir catfile/;
use IPC::Run3::Shell 0.56 ':FATAL', [ perl => { fail_on_stderr=>1,
	show_cmd=>Test::More->builder->output },
	$^X, '-wMstrict', '-I'.catdir($FindBin::Bin,'..','lib') ];

use warnings FATAL => qw/ io inplace /;
our $DEBUG = 0;
our $FE = $] ge '5.012' && $] lt '5.029007' ? !!0 : !!1; # FE="first eof", see https://github.com/Perl/perl5/issues/16786
our $CE; # CE="can't eof()", Perl <5.12 doesn't support eof() on tied filehandles (gets set below)
         # plus try to work around https://github.com/Perl/perl5/issues/20207 on >5.36
our $FL = undef; # FL="First Line"
# Apparently there are some versions of Perl on Win32 where the following two appear to work slightly differently.
# I've seen differing results on different systems and I'm not sure why, so I set it dynamically... not pretty, but this test isn't critical.
if ( $^O eq 'MSWin32' && $] ge '5.014' && $] lt '5.018' )
	{ $FL = $.; $FE = defined($.) }

diag "WARNING: Perl 5.16 or better is strongly recommended for File::Replace::Inplace\n\t"
	."(see documentation of Tie::Handle::Argv for details)" if $] lt '5.016';

BEGIN {
	use_ok 'File::Replace::Inplace';
	use_ok 'File::Replace', 'inplace';
}
use warnings FATAL => 'File::Replace';

## no critic (RequireCarping)

our $TESTMODE;
sub testboth {  ## no critic (RequireArgUnpacking)
	# test that both regular $^I and our tied class act the same
	die "bad nr of args" unless @_==2 || @_==3;
	my ($name, $sub, $args) = @_;
	my $stdin = delete $$args{stdin};
	{
		local $TESTMODE = 'Perl';
		local (*ARGV, *ARGVOUT, $., $^I);  ## no critic (RequireInitializationForLocalVars)
		$^I = $$args{backup}||'';  ## no critic (RequireLocalizedPunctuationVars)
		my $osi = defined($stdin) ? OverrideStdin->new($stdin) : undef;
		subtest "$name - Perl" =>
			$^O eq 'MSWin32' && $] lt '5.028' && !length($^I)
				? sub { plan skip_all=>'This test would fail on Win32 with Perls older then 5.28' }
					# see https://perldoc.pl/perldiag#Can't-do-inplace-edit-without-backup
					# and https://perldoc.pl/perl5280delta#In-place-editing-with-perl-i-is-now-safer
				: $sub;
		$osi and $osi->restore;
	}
	{
		local $TESTMODE = 'Inplace';
		local (*ARGV, *ARGVOUT, $., $^I);  ## no critic (RequireInitializationForLocalVars)
		local $CE = $] lt '5.012' || $] gt '5.036';
		my $inpl = File::Replace::Inplace->new(debug=>$DEBUG, %$args);
		my $osi = defined($stdin) ? OverrideStdin->new($stdin) : undef;
		subtest "$name - ::Inplace" => $sub;
		$osi and $osi->restore;
	}
	return;
}

testboth 'basic test' => sub { plan tests=>9;
	my @tf = (newtempfn("Foo\nBar\n"), newtempfn("Quz\nBaz"));
	@ARGV = @tf;  ## no critic (RequireLocalizedPunctuationVars)
	my @states;
	is select(), 'main::STDOUT', 'STDOUT is selected initially';
	push @states, [[@ARGV], $ARGV, defined(fileno ARGV), defined(fileno ARGVOUT), $., eof];
	while (<>) {
		print "$ARGV:$.: ".uc;
		isnt select(), 'main::STDOUT', 'STDOUT isn\'t selected in loop';
		push @states, [[@ARGV], $ARGV, defined(fileno ARGV), defined(fileno ARGVOUT), $., eof, $_];
	}
	push @states, [[@ARGV], $ARGV, defined(fileno ARGV), defined(fileno ARGVOUT), $., eof];
	is select(), 'main::STDOUT', 'STDOUT is selected again';
	is slurp($tf[0]), "$tf[0]:1: FOO\n$tf[0]:2: BAR\n", 'file 1 contents';
	is slurp($tf[1]), "$tf[1]:3: QUZ\n$tf[1]:4: BAZ", 'file 2 contents';
	is_deeply \@states, [
		[[@tf],    undef,  !!0, !!0, $FL, $FE         ],
		[[$tf[1]], $tf[0], !!1, !!1, 1,   !!0, "Foo\n"],
		[[$tf[1]], $tf[0], !!1, !!1, 2,   !!1, "Bar\n"],
		[[],       $tf[1], !!1, !!1, 3,   !!0, "Quz\n"],
		[[],       $tf[1], !!1, !!1, 4,   !!1, "Baz"  ],
		[[],       $tf[1], !!0, !!0, 4,   !!1         ],
	], 'states' or diag explain \@states;
};

testboth 'basic test with eof()' => sub {
	if ($CE) { plan skip_all=>"eof() not supported on tied handles on Perl<5.12 or >5.36" }
	elsif ($^O eq 'MSWin32') { plan skip_all=>"eof() acts differently on Win32" }
	else { plan tests=>9 }
	my @tf = (newtempfn("Foo\nBar"), newtempfn("Quz\nBaz\n"));
	local @ARGV = @tf; # this also tests "local"ization after constructing the object
	my @states;
	is select(), 'main::STDOUT', 'STDOUT is selected initially';
	push @states, [[@ARGV], $ARGV, defined(fileno ARGV), defined(fileno ARGVOUT), $., eof], eof();
	# eof() will open the first file, so record the current state again:
	push @states, [[@ARGV], $ARGV, defined(fileno ARGV), defined(fileno ARGVOUT), $., eof], eof();
	while (<>) {
		print "$ARGV:$.: ".uc;
		isnt select(), 'main::STDOUT', 'STDOUT isn\'t selected in loop';
		push @states, [[@ARGV], $ARGV, defined(fileno ARGV), defined(fileno ARGVOUT), $., eof, $_], eof();
	}
	push @states, [[@ARGV], $ARGV, defined(fileno ARGV), defined(fileno ARGVOUT), $., eof];
	is select(), 'main::STDOUT', 'STDOUT is selected again';
	is slurp($tf[0]), "$tf[0]:1: FOO\n$tf[0]:2: BAR", 'file 1 contents';
	is slurp($tf[1]), "$tf[1]:3: QUZ\n$tf[1]:4: BAZ\n", 'file 2 contents';
	is_deeply \@states, [
		[[@tf],    undef,  !!0, !!0, $FL, $FE         ], !!0,
		[[$tf[1]], $tf[0], !!1, !!1, 0,   !!0         ], !!0,
		[[$tf[1]], $tf[0], !!1, !!1, 1,   !!0, "Foo\n"], !!0,
		[[$tf[1]], $tf[0], !!1, !!1, 2,   !!1, "Bar"  ], !!0,
		[[],       $tf[1], !!1, !!1, 3,   !!0, "Quz\n"], !!0,
		[[],       $tf[1], !!1, !!1, 4,   !!1, "Baz\n"], !!1,
		[[],       $tf[1], !!0, !!0, 4,   !!1         ],
	], 'states' or diag explain \@states;
};

subtest 'custom files & filename' => sub { plan tests=>9;
	local (*ARGV, *ARGVOUT, $., $^I);  ## no critic (RequireInitializationForLocalVars)
	my @testfiles1;
	my $testfilename1;
	my $inpl = File::Replace::Inplace->new(debug=>$DEBUG, files=>\@testfiles1, filename=>\$testfilename1);
	my @tf = (newtempfn("Foo\nBar"), newtempfn("Quz\nBaz"));
	my @states;
	@ARGV = ("qrs");  ## no critic (RequireLocalizedPunctuationVars)
	@testfiles1 = @tf;
	is select(), 'main::STDOUT', 'STDOUT is selected initially';
	push @states, [[@ARGV], $ARGV, [@testfiles1], $testfilename1, defined(fileno ARGV), defined(fileno ARGVOUT), $., eof];
	while (<>) {
		print "$testfilename1/$./".lc;
		isnt select(), 'main::STDOUT', 'STDOUT isn\'t selected in loop';
		push @states, [[@ARGV], $ARGV, [@testfiles1], $testfilename1, defined(fileno ARGV), defined(fileno ARGVOUT), $., eof, $_];
	}
	push @states, [[@ARGV], $ARGV, [@testfiles1], $testfilename1, defined(fileno ARGV), defined(fileno ARGVOUT), $., eof];
	is select(), 'main::STDOUT', 'STDOUT is selected again';
	is slurp($tf[0]), "$tf[0]/1/foo\n$tf[0]/2/bar", 'file 1 contents';
	is slurp($tf[1]), "$tf[1]/3/quz\n$tf[1]/4/baz", 'file 2 contents';
	is_deeply \@states, [
		[["qrs"], undef, [@tf],    undef,  !!0, !!0, $FL, $FE         ],
		[["qrs"], undef, [$tf[1]], $tf[0], !!1, !!1, 1,   !!0, "Foo\n"],
		[["qrs"], undef, [$tf[1]], $tf[0], !!1, !!1, 2,   !!1, "Bar"  ],
		[["qrs"], undef, [],       $tf[1], !!1, !!1, 3,   !!0, "Quz\n"],
		[["qrs"], undef, [],       $tf[1], !!1, !!1, 4,   !!1, "Baz"  ],
		[["qrs"], undef, [],       $tf[1], !!0, !!0, 4,   !!1         ],
	], 'states' or diag explain \@states;
	untie *ARGV;
};

subtest 'basic test with inplace()' => sub { plan tests=>12;
	local (*ARGV, *ARGVOUT, $., $^I);  ## no critic (RequireInitializationForLocalVars)
	my @tf = (newtempfn("X\nY\nZ"), newtempfn("AA\nBB\nCC\n"));
	@ARGV = @tf;  ## no critic (RequireLocalizedPunctuationVars)
	my $inpl = inplace(debug=>$DEBUG);
	isa_ok $inpl, 'File::Replace::Inplace';
	my @states;
	is select(), 'main::STDOUT', 'STDOUT is selected initially';
	push @states, [[@ARGV], $ARGV, defined(fileno ARGV), defined(fileno ARGVOUT), $., eof];
	while (<>) {
		print "$ARGV:$.:".lc;
		isnt select(), 'main::STDOUT', 'STDOUT isn\'t selected in loop';
		push @states, [[@ARGV], $ARGV, defined(fileno ARGV), defined(fileno ARGVOUT), $., eof, $_];
	}
	push @states, [[@ARGV], $ARGV, defined(fileno ARGV), defined(fileno ARGVOUT), $., eof];
	is select(), 'main::STDOUT', 'STDOUT is selected again';
	is slurp($tf[0]), "$tf[0]:1:x\n$tf[0]:2:y\n$tf[0]:3:z", 'file 1 contents';
	is slurp($tf[1]), "$tf[1]:4:aa\n$tf[1]:5:bb\n$tf[1]:6:cc\n", 'file 2 contents';
	is_deeply \@states, [
		[[@tf],    undef,  !!0, !!0, $FL, $FE        ],
		[[$tf[1]], $tf[0], !!1, !!1, 1,   !!0, "X\n" ],
		[[$tf[1]], $tf[0], !!1, !!1, 2,   !!0, "Y\n" ],
		[[$tf[1]], $tf[0], !!1, !!1, 3,   !!1, "Z"   ],
		[[],       $tf[1], !!1, !!1, 4,   !!0, "AA\n"],
		[[],       $tf[1], !!1, !!1, 5,   !!0, "BB\n"],
		[[],       $tf[1], !!1, !!1, 6,   !!1, "CC\n"],
		[[],       $tf[1], !!0, !!0, 6,   !!1        ],
	], 'states' or diag explain \@states;
};

testboth 'backup' => sub { plan tests=>8;
	my $tfn = newtempfn("Foo\nBar");
	my $bfn = $tfn.'.bak';
	@ARGV = ($tfn);  ## no critic (RequireLocalizedPunctuationVars)
	ok !-e $bfn, 'backup file doesn\'t exist yet';
	my @states;
	is select(), 'main::STDOUT', 'STDOUT is selected initially';
	push @states, [[@ARGV], $ARGV, defined(fileno ARGV), defined(fileno ARGVOUT), $., eof];
	while (<>) {
		print "$ARGV+$.+$_";
		isnt select(), 'main::STDOUT', 'STDOUT isn\'t selected in loop';
		push @states, [[@ARGV], $ARGV, defined(fileno ARGV), defined(fileno ARGVOUT), $., eof, $_];
	}
	push @states, [[@ARGV], $ARGV, defined(fileno ARGV), defined(fileno ARGVOUT), $., eof];
	is select(), 'main::STDOUT', 'STDOUT is selected again';
	is slurp($tfn), "$tfn+1+Foo\n$tfn+2+Bar", 'file edited correctly';
	is slurp($bfn), "Foo\nBar", 'backup file correct';
	is_deeply \@states, [
		[[$tfn], undef, !!0, !!0, $FL, $FE         ],
		[[],     $tfn,  !!1, !!1, 1,   !!0, "Foo\n"],
		[[],     $tfn,  !!1, !!1, 2,   !!1, "Bar"  ],
		[[],     $tfn,  !!0, !!0, 2,   !!1         ],
	], 'states' or diag explain \@states;
}, { backup=>'.bak' };

testboth 'readline contexts' => sub { plan tests=>9;
	# we test scalar everywhere, need to test the others too
	my @tf = (newtempfn("Alpha"), newtempfn("Bravo\nCharlie\nDelta"), newtempfn("Echo\n!!!"));
	my @states;
	@ARGV = @tf;  ## no critic (RequireLocalizedPunctuationVars)
	is select(), 'main::STDOUT', 'STDOUT is selected initially';
	push @states, [[@ARGV], $ARGV, defined(fileno ARGV), defined(fileno ARGVOUT), $., eof];
	for (1..2) {
		<>; # void ctx
		print "<$_>";
		isnt select(), 'main::STDOUT', 'STDOUT isn\'t selected in loop';
		push @states, [[@ARGV], $ARGV, defined(fileno ARGV), defined(fileno ARGVOUT), $., eof];
	}
	print "Hi?\n";
	my @got = <>; # list ctx
	is select(), 'main::STDOUT', 'STDOUT is selected again';
	push @states, [[@ARGV], $ARGV, defined(fileno ARGV), defined(fileno ARGVOUT), $., eof];
	is_deeply \@got, ["Charlie\n","Delta","Echo\n","!!!"], 'list ctx'
		or diag explain \@got;
	is slurp($tf[0]), "<1>", 'file 1 correct';
	is slurp($tf[1]), "<2>Hi?\n", 'file 2 correct';
	is slurp($tf[2]), "", 'file 3 correct';
	is_deeply \@states, [
		[[@tf],      undef,  !!0, !!0, $FL, $FE],
		[[@tf[1,2]], $tf[0], !!1, !!1, 1,   !!1],
		[[$tf[2]],   $tf[1], !!1, !!1, 2,   !!0],
		[[],         $tf[2], !!0, !!0, 6,   !!1],
	], 'states' or diag explain \@states;
};

testboth 'restart argv' => sub { plan tests=>11;
	my $tfn = newtempfn("111\n222\n333\n");
	my @states;
	@ARGV = ($tfn);  ## no critic (RequireLocalizedPunctuationVars)
	is select(), 'main::STDOUT', 'STDOUT is selected initially';
	push @states, [[@ARGV], $ARGV, defined(fileno ARGV), defined(fileno ARGVOUT), $., eof];
	while (<>) {
		print "X/$.:$_";
		isnt select(), 'main::STDOUT', 'STDOUT isn\'t selected in loop';
		push @states, [[@ARGV], $ARGV, defined(fileno ARGV), defined(fileno ARGVOUT), $., eof, $_];
	}
	push @states, [[@ARGV], $ARGV, defined(fileno ARGV), defined(fileno ARGVOUT), $., eof];
	is select(), 'main::STDOUT', 'STDOUT is selected in between';
	@ARGV = ($tfn);  ## no critic (RequireLocalizedPunctuationVars)
	push @states, [[@ARGV], $ARGV, defined(fileno ARGV), defined(fileno ARGVOUT), $., eof];
	while (<>) {
		print "Y/$.:$_";
		isnt select(), 'main::STDOUT', 'STDOUT isn\'t selected in loop';
		push @states, [[@ARGV], $ARGV, defined(fileno ARGV), defined(fileno ARGVOUT), $., eof, $_];
	}
	push @states, [[@ARGV], $ARGV, defined(fileno ARGV), defined(fileno ARGVOUT), $., eof];
	is select(), 'main::STDOUT', 'STDOUT is selected again';
	is slurp($tfn), "Y/1:X/1:111\nY/2:X/2:222\nY/3:X/3:333\n", 'file correct';
	is_deeply \@states, [
		[[$tfn], undef, !!0, !!0, $FL, $FE             ],
		[[],     $tfn,  !!1, !!1, 1,   !!0, "111\n"    ],
		[[],     $tfn,  !!1, !!1, 2,   !!0, "222\n"    ],
		[[],     $tfn,  !!1, !!1, 3,   !!1, "333\n"    ],
		[[],     $tfn,  !!0, !!0, 3,   !!1             ],
		[[$tfn], $tfn,  !!0, !!0, 3,   !!1             ],
		[[],     $tfn,  !!1, !!1, 1,   !!0, "X/1:111\n"],
		[[],     $tfn,  !!1, !!1, 2,   !!0, "X/2:222\n"],
		[[],     $tfn,  !!1, !!1, 3,   !!1, "X/3:333\n"],
		[[],     $tfn,  !!0, !!0, 3,   !!1             ],
	], 'states' or diag explain \@states;
};

testboth 'close on eof to reset $.' => sub { plan tests=>15;
	my @tf = (newtempfn("One\nTwo\nThree\n"), newtempfn("Four\nFive\nSix"));
	my @states;
	@ARGV = @tf;  ## no critic (RequireLocalizedPunctuationVars)
	is select(), 'main::STDOUT', 'STDOUT is selected initially';
	push @states, [[@ARGV], $ARGV, defined(fileno ARGV), defined(fileno ARGVOUT), $., eof];
	while (<>) {
		print "($.)$_";
		isnt select(), 'main::STDOUT', 'STDOUT isn\'t selected in loop';
		push @states, [[@ARGV], $ARGV, defined(fileno ARGV), defined(fileno ARGVOUT), $., eof, $_];
	} continue {
		# the reason for the extra "close select" is documented
		if (eof) { close ARGV; close select if $TESTMODE eq 'Perl'; }  ## no critic (ProhibitOneArgSelect)
		push @states, [[@ARGV], $ARGV, defined(fileno ARGV), defined(fileno ARGVOUT), $., eof];
	}
	is select(), 'main::STDOUT', 'STDOUT is selected in between';
	@ARGV = ($tf[0]);  ## no critic (RequireLocalizedPunctuationVars)
	while (<>) {
		print "[$.]$_";
		isnt select(), 'main::STDOUT', 'STDOUT isn\'t selected in loop';
		push @states, [[@ARGV], $ARGV, defined(fileno ARGV), defined(fileno ARGVOUT), $., eof, $_];
	} continue {
		if (eof) { close ARGV; close select if $TESTMODE eq 'Perl'; }  ## no critic (ProhibitOneArgSelect)
		push @states, [[@ARGV], $ARGV, defined(fileno ARGV), defined(fileno ARGVOUT), $., eof];
	}
	is select(), 'main::STDOUT', 'STDOUT is selected again';
	is slurp($tf[0]), "[1](1)One\n[2](2)Two\n[3](3)Three\n", 'file 1 correct';
	is slurp($tf[1]), "(1)Four\n(2)Five\n(3)Six", 'file 2 correct';
	is_deeply \@states, [
		[[@tf],    undef,  !!0, !!0, $FL, $FE              ],
		[[$tf[1]], $tf[0], !!1, !!1, 1,   !!0, "One\n"     ],
		[[$tf[1]], $tf[0], !!1, !!1, 1,   !!0,             ],
		[[$tf[1]], $tf[0], !!1, !!1, 2,   !!0, "Two\n"     ],
		[[$tf[1]], $tf[0], !!1, !!1, 2,   !!0,             ],
		[[$tf[1]], $tf[0], !!1, !!1, 3,   !!1, "Three\n"   ],
		[[$tf[1]], $tf[0], !!0, !!0, 0,   !!1,             ],
		[[],       $tf[1], !!1, !!1, 1,   !!0, "Four\n"    ],
		[[],       $tf[1], !!1, !!1, 1,   !!0,             ],
		[[],       $tf[1], !!1, !!1, 2,   !!0, "Five\n"    ],
		[[],       $tf[1], !!1, !!1, 2,   !!0,             ],
		[[],       $tf[1], !!1, !!1, 3,   !!1, "Six"       ],
		[[],       $tf[1], !!0, !!0, 0,   !!1,             ],
		[[],       $tf[0], !!1, !!1, 1,   !!0, "(1)One\n"  ],
		[[],       $tf[0], !!1, !!1, 1,   !!0,             ],
		[[],       $tf[0], !!1, !!1, 2,   !!0, "(2)Two\n"  ],
		[[],       $tf[0], !!1, !!1, 2,   !!0,             ],
		[[],       $tf[0], !!1, !!1, 3,   !!1, "(3)Three\n"],
		[[],       $tf[0], !!0, !!0, 0,   !!1,             ],
	], 'states' or diag explain \@states;
};

testboth 'restart with emptied @ARGV (STDIN)' => sub {
	plan $^O eq 'MSWin32' ? (skip_all => 'STDIN tests don\'t work yet on Windows') : (tests=>15); #TODO: OverrideStdin doesn't seem to work everywhere
	my @tf = (newtempfn("Fo\nBr"), newtempfn("Qz\nBz\n"));
	my @states;
	@ARGV = @tf;  ## no critic (RequireLocalizedPunctuationVars)
	is select(), 'main::STDOUT', 'STDOUT is selected initially';
	push @states, [[@ARGV], $ARGV, defined(fileno ARGV), defined(fileno ARGVOUT), $., eof];
	while (<>) {
		print "$ARGV:$.: ".uc;
		isnt select(), 'main::STDOUT', 'STDOUT isn\'t selected in loop';
		push @states, [[@ARGV], $ARGV, defined(fileno ARGV), defined(fileno ARGVOUT), $., eof, $_];
	}
	push @states, [[@ARGV], $ARGV, defined(fileno ARGV), defined(fileno ARGVOUT), $., eof];
	is select(), 'main::STDOUT', 'STDOUT is selected in between';
	SKIP: {
		skip "eof() not supported on tied handles on Perl<5.12 or >5.36", 2 if $CE;
		ok !eof(), 'eof() is false';
		is select(), 'main::STDOUT', 'STDOUT is still selected';
	}
	# At this point, eof becomes really unreliable depending on Perl versions etc.
	#TODO Later: Determine if it's a bug in File::Replace::Inplace, OverrideStdin, or Perl
	# (is documented for now)
	push @states, [[@ARGV], $ARGV, defined(fileno ARGV), defined(fileno ARGVOUT), $.];
	my @out;
	while (<>) {
		push @out, "2/$ARGV:$.: ".uc;
		is select(), 'main::STDOUT', 'STDOUT *is* selected in loop';
		push @states, [[@ARGV], $ARGV, defined(fileno ARGV), defined(fileno ARGVOUT), $., $_];
	}
	push @states, [[@ARGV], $ARGV, defined(fileno ARGV), defined(fileno ARGVOUT), $.];
	is select(), 'main::STDOUT', 'STDOUT is selected again';
	is_deeply \@out, ["2/-:1: HELLO\n", "2/-:2: WORLD"], 'stdin/out looks ok';
	is slurp($tf[0]), "$tf[0]:1: FO\n$tf[0]:2: BR", 'file 1 correct';
	is slurp($tf[1]), "$tf[1]:3: QZ\n$tf[1]:4: BZ\n", 'file 2 correct';
	is_deeply \@states, [
		[[@tf],    undef,  !!0, !!0, $FL, $FE           ],
		[[$tf[1]], $tf[0], !!1, !!1, 1,   !!0, "Fo\n"   ],
		[[$tf[1]], $tf[0], !!1, !!1, 2,   !!1, "Br"     ],
		[[],       $tf[1], !!1, !!1, 3,   !!0, "Qz\n"   ],
		[[],       $tf[1], !!1, !!1, 4,   !!1, "Bz\n"   ],
		[[],       $tf[1], !!0, !!0, 4,   !!1           ],
		$CE ? [[], $tf[1], !!0, !!0, 4                  ]
		    : [[], '-',    !!1, !!0, 0                  ],
		[[],       '-',    !!1, !!0, 1,        "Hello\n"],
		[[],       '-',    !!1, !!0, 2,        "World"  ],
		[[],       '-',    !!0, !!0, 2,                 ],
	], 'states' or diag explain \@states;
}, { stdin=>"Hello\nWorld" };

testboth 'nonexistent and empty files' => sub { plan tests=>17;
	my @tf = (newtempfn(""), newtempfn("Hullo"), newtempfn, newtempfn(""), newtempfn, newtempfn("World!\nFoo!"), newtempfn(""));
	ok !-e $tf[$_], "file ".($_+1)." doesn't exist" for 2,4;
	my @states;
	@ARGV = @tf;  ## no critic (RequireLocalizedPunctuationVars)
	use warnings NONFATAL => 'inplace';
	my $warncount=0;
	local $SIG{__WARN__} = sub {
		if ( $_[0]=~/\bCan't open (?:\Q$tf[2]\E|\Q$tf[4]\E): / )
			{ $warncount++ }
		else { die @_ } };
	is select(), 'main::STDOUT', 'STDOUT is selected initially';
	push @states, [[@ARGV], $ARGV, defined(fileno ARGV), defined(fileno ARGVOUT), $., eof];
	while (<>) {
		print "$ARGV'$.'$_";
		isnt select(), 'main::STDOUT', 'STDOUT isn\'t selected in loop';
		push @states, [[@ARGV], $ARGV, defined(fileno ARGV), defined(fileno ARGVOUT), $., eof, $_];
	}
	push @states, [[@ARGV], $ARGV, defined(fileno ARGV), defined(fileno ARGVOUT), $., eof];
	is select(), 'main::STDOUT', 'STDOUT is selected again';
	@ARGV = @tf;  ## no critic (RequireLocalizedPunctuationVars)
	push @states, [[@ARGV], $ARGV, defined(fileno ARGV), defined(fileno ARGVOUT), $., eof];
	is_deeply [<>], ["$tf[1]'1'Hullo","$tf[5]'2'World!\n","$tf[5]'3'Foo!"], '<> in list ctx';
	push @states, [[@ARGV], $ARGV, defined(fileno ARGV), defined(fileno ARGVOUT), $., eof];
	is slurp($tf[$_]), "", 'file '.($_+1).' correct' for 0,1,3,5,6;
	# NOTE: difference to Perl's -i - File::Replace will create the files
	if ($TESTMODE eq 'Perl')
		{ ok !-e $tf[$_],  "file ".($_+1)." doesn't exist" for 2,4 }
	else
		{ is slurp($tf[$_]), "", 'file '.($_+1).' correct' for 2,4 }
	is_deeply \@states, [
		[[@tf],       undef,  !!0, !!0, $FL, $FE            ],
		[[@tf[2..6]], $tf[1], !!1, !!1, 1,   !!1, "Hullo"   ],
		[[$tf[6]],    $tf[5], !!1, !!1, 2,   !!0, "World!\n"],
		[[$tf[6]],    $tf[5], !!1, !!1, 3,   !!1, "Foo!"    ],
		[[],          $tf[6], !!0, !!0, 3,   !!1            ],
		[[@tf],       $tf[6], !!0, !!0, 3,   !!1            ],
		[[],          $tf[6], !!0, !!0, 3,   !!1            ],
	], 'states' or diag explain \@states;
	is $warncount, $TESTMODE eq 'Perl' ? 4 : 0, 'warning count';
};

subtest 'create option' => sub { plan tests=>9;
	local (*ARGV, *ARGVOUT, $., $^I);  ## no critic (RequireInitializationForLocalVars)
	{
		my @tf = (newtempfn("Hi"), newtempfn, newtempfn("There"));
		ok !-e $tf[1], 'file doesn\'t exist yet';
		@ARGV = @tf;  ## no critic (RequireLocalizedPunctuationVars)
		my $inpl = File::Replace::Inplace->new( debug=>$DEBUG, create=>'now' );
		is <>, "Hi", 'file 1 read ok';
		print "Bingo1";
		is <>, "There", 'file 3 read ok';
		is slurp($tf[0]), "Bingo1", 'file 1 contents ok';
		print "Bingo2";
		is slurp($tf[1]), "", 'file created ok';
		is <>, undef, 'finished reading ok';
		is slurp($tf[2]), "Bingo2", 'file 3 contents ok';
	}
	{
		my $tfn = newtempfn;
		ok !-e $tfn, 'file doesn\'t exist';
		@ARGV = ($tfn);  ## no critic (RequireLocalizedPunctuationVars)
		my $inpl = File::Replace::Inplace->new( debug=>$DEBUG, create=>'off' );
		like exception { <>; 1 }, qr/\bfailed to open '\Q$tfn\E'/, 'read dies ok';
	}
};

subtest 'premature destroy' => sub { plan tests=>7;
	local (*ARGV, *ARGVOUT, $., $^I);  ## no critic (RequireInitializationForLocalVars)
	local $CE = $] lt '5.012' || $] gt '5.036';
	is grep( {/\bunclosed file\b.+\bnot replaced\b/i} warns {
		my $tfn = newtempfn("IJK\nMNO");
		@ARGV = ($tfn);  ## no critic (RequireLocalizedPunctuationVars)
		my @states;
		my $inpl = inplace(debug=>$DEBUG);
		is select(), 'main::STDOUT', 'STDOUT is selected initially';
		push @states, [[@ARGV], $ARGV, defined(fileno ARGV), defined(fileno ARGVOUT), $., eof];
		is <>, "IJK\n", 'read ok';
		isnt select(), 'main::STDOUT', 'STDOUT isn\'t selected after read';
		push @states, [[@ARGV], $ARGV, defined(fileno ARGV), defined(fileno ARGVOUT), $., eof];
		$inpl = undef;
		push @states, [[@ARGV], $ARGV, defined(fileno ARGV), defined(fileno ARGVOUT), $., eof];
		is select(), 'main::STDOUT', 'STDOUT is selected again';
		is slurp($tfn), "IJK\nMNO", 'file contents';
		is_deeply \@states, [
			[[$tfn], undef, !!0, !!0, $FL, $FE        ],
			[[],     $tfn,  !!1, !!1, 1,   !!0        ],
			[[],     $tfn,  !!0, !!0, 1,   $CE?!!1:$FE],
		], 'states' or diag explain \@states;
	} ), 1, 'warning about unclosed file';
};

testboth 'premature close' => sub { plan tests=>9;
	my @tf = (newtempfn("foo\nBAR\n"), newtempfn("quZ\nBaz"));
	my @states;
	@ARGV = @tf;  ## no critic (RequireLocalizedPunctuationVars)
	is select(), 'main::STDOUT', 'STDOUT is selected initially';
	push @states, [[@ARGV], $ARGV, defined(fileno ARGV), defined(fileno ARGVOUT), $., eof];
	my $l=<>;
	print "$ARGV<$.>".ucfirst($l);
	isnt select(), 'main::STDOUT', 'STDOUT isn\'t selected';
	push @states, [[@ARGV], $ARGV, defined(fileno ARGV), defined(fileno ARGVOUT), $., eof, $l];
	close ARGV; close select if $TESTMODE eq 'Perl';  ## no critic (ProhibitOneArgSelect)
	isnt select(), 'main::STDOUT', 'STDOUT still isn\'t selected';
	push @states, [[@ARGV], $ARGV, defined(fileno ARGV), defined(fileno ARGVOUT), $., eof];
	while (<>) {
		print "$ARGV<$.>".ucfirst;
		isnt select(), 'main::STDOUT', 'STDOUT isn\'t selected in loop';
		push @states, [[@ARGV], $ARGV, defined(fileno ARGV), defined(fileno ARGVOUT), $., eof, $_];
	}
	push @states, [[@ARGV], $ARGV, defined(fileno ARGV), defined(fileno ARGVOUT), $., eof];
	is select(), 'main::STDOUT', 'STDOUT is selected again';
	is slurp($tf[0]), "$tf[0]<1>Foo\n", 'file 1 contents';
	is slurp($tf[1]), "$tf[1]<1>QuZ\n$tf[1]<2>Baz", 'file 2 contents';
	is_deeply \@states, [
		[[@tf],    undef,  !!0, !!0, $FL, $FE         ],
		[[$tf[1]], $tf[0], !!1, !!1, 1,   !!0, "foo\n"],
		[[$tf[1]], $tf[0], !!0, !!0, 0,   !!1         ],
		[[],       $tf[1], !!1, !!1, 1,   !!0, "quZ\n"],
		[[],       $tf[1], !!1, !!1, 2,   !!1, "Baz"  ],
		[[],       $tf[1], !!0, !!0, 2,   !!1         ],
	], 'states' or diag explain \@states;
};

my $prevdir = getcwd;
my $tmpdir = tempdir(DIR=>$TEMPDIR,CLEANUP=>1);
chdir($tmpdir) or die "chdir $tmpdir: $!";
testboth 'diamond' => sub {
	plan $^O eq 'MSWin32' ? (skip_all => 'special filenames won\'t work on Windows') : (tests=>1);
	spew("foo","I am foo\nbar");
	spew("<foo","I am <foo!\nquz");
	my @states;
	@ARGV = ("<foo");  ## no critic (RequireLocalizedPunctuationVars)
	push @states, [[@ARGV], $ARGV, defined(fileno ARGV), $., eof];
	push @states, [[@ARGV], $ARGV, defined(fileno ARGV), $., eof, $_] while <>;
	push @states, [[@ARGV], $ARGV, defined(fileno ARGV), $., eof];
	is_deeply \@states, [
		[["<foo"], undef,  !!0, undef, $FE                ],
		[[],       "<foo", !!1, 1,     !!0, "I am <foo!\n"],
		[[],       "<foo", !!1, 2,     !!1, "quz"         ],
		[[],       "<foo", !!0, 2,     !!1                ],
	], 'states for double-diamond';
};
testboth 'double-diamond' => sub {
	if ($] lt '5.022') { plan skip_all => 'need Perl >=5.22 for double-diamond' }
	elsif ($^O eq 'MSWin32') { plan skip_all => 'special filenames won\'t work on Windows' }
	else { plan tests=>1 }
	spew("foo","I am foo\nbar");
	spew("<foo","I am <foo!\nquz");
	my @states;
	@ARGV = ("<foo");  ## no critic (RequireLocalizedPunctuationVars)
	push @states, [[@ARGV], $ARGV, defined(fileno ARGV), $., eof];
	my $code = <<'    ENDCODE';  # need to eval this because otherwise <<>> is a syntax error on older Perls
		push @states, [[@ARGV], $ARGV, defined(fileno ARGV), $., eof, $_] while <<>>;
	; 1
    ENDCODE
	eval $code or die $@||"unknown error";  ## no critic (ProhibitStringyEval, ProhibitMixedBooleanOperators)
	push @states, [[@ARGV], $ARGV, defined(fileno ARGV), $., eof];
	is_deeply \@states, [
		[["<foo"], undef,  !!0, undef, $FE                ],
		[[],       "<foo", !!1, 1,     !!0, "I am <foo!\n"],
		[[],       "<foo", !!1, 2,     !!1, "quz"         ],
		[[],       "<foo", !!0, 2,     !!1                ],
	], 'states for double-diamond';
};
chdir($prevdir) or warn "chdir $prevdir: $!";

subtest 'perl -MFile::Replace=-i' => sub { plan tests=>10;
	my @tf = (newtempfn("One\nTwo\n"), newtempfn("Three\nFour"));
	is perl('-MFile::Replace=-i','-pe','s/[aeiou]/_/gi', @tf), '', 'no output';
	is slurp($tf[0]), "_n_\nTw_\n", 'file 1 correct';
	is slurp($tf[1]), "Thr__\nF__r", 'file 2 correct';
	my @bf = map { "$_.bak" } @tf;
	ok !-e $bf[0], 'backup 1 doesn\'t exist';
	ok !-e $bf[1], 'backup 2 doesn\'t exist';
	is perl('-MFile::Replace=-i.bak','-nle','print "$ARGV:$.: $_"', @tf), '', 'no output (2)';
	is slurp($tf[0]), "$tf[0]:1: _n_\n$tf[0]:2: Tw_\n", 'file 1 correct (2)';
	is slurp($tf[1]), "$tf[1]:3: Thr__\n$tf[1]:4: F__r\n", 'file 2 correct (2)';
	is slurp($bf[0]), "_n_\nTw_\n", 'backup file 1 correct';
	is slurp($bf[1]), "Thr__\nF__r", 'backup file 2 correct';
};

subtest '-i in import list' => sub { plan tests=>7;
	local (*ARGV, *ARGVOUT, $., $^I);  ## no critic (RequireInitializationForLocalVars)
	my @tf = (newtempfn("XX\nYY\n"), newtempfn("ABC\nDEF\nGHI"));
	@ARGV = @tf;  ## no critic (RequireLocalizedPunctuationVars)
	ok !defined $File::Replace::Inplace::GlobalInplace, 'GlobalInplace not set yet';  ## no critic (ProhibitPackageVars)
	File::Replace->import('-i');
	ok  defined $File::Replace::Inplace::GlobalInplace, 'GlobalInplace is now set';  ## no critic (ProhibitPackageVars)
	while (<>) {
		print "$ARGV:$.:".lc;
	}
	is slurp($tf[0]), "$tf[0]:1:xx\n$tf[0]:2:yy\n", 'file 1 correct';
	is slurp($tf[1]), "$tf[1]:3:abc\n$tf[1]:4:def\n$tf[1]:5:ghi", 'file 2 correct';
	$File::Replace::Inplace::GlobalInplace = undef;  ## no critic (ProhibitPackageVars)
	is @ARGV, 0, '@ARGV empty';
	# a couple more checks for code coverage
	File::Replace->import('-D');
	is undef, $File::Replace::Inplace::GlobalInplace, 'lone debug flag has no effect';  ## no critic (ProhibitPackageVars)
	like exception {File::Replace->import('-i','-D','-i.bak')},
		qr/\bmore than one -i\b/, 'multiple -i\'s fails';
	$File::Replace::Inplace::GlobalInplace = undef;  ## no critic (ProhibitPackageVars)
};

subtest 'cleanup' => sub { plan tests=>1; # mostly just to make code coverage happy
	local (*ARGV, *ARGVOUT, $., $^I);  ## no critic (RequireInitializationForLocalVars)
	my $tmpfile = newtempfn("Yay\nHooray");
	@ARGV = ($tmpfile);  ## no critic (RequireLocalizedPunctuationVars)
	{
		my $inpl = inplace(debug=>$DEBUG);
		print "<$.>$_" while <>;
		$inpl->cleanup; # explicit cleanup call
	}
	{
		my $inpl = inplace(debug=>$DEBUG);
		tie *ARGV, 'Tie::Handle::Base'; # cleanup should only untie if tied to File::Replace::Inplace
		$inpl->cleanup;
		untie *ARGV;
	}
	{
		my $inpl = inplace(debug=>$DEBUG);
		untie *ARGV;
		$inpl->cleanup; # cleanup when already untied
	}
	is slurp($tmpfile), "<1>Yay\n<2>Hooray", 'file correct';
};

subtest 'debug' => sub { plan tests=>2;
	note "Expect some debug output here:";
	my $db = Test::More->builder->output;
	ok( do { my $x=File::Replace::Inplace->new(debug=>$db); 1 }, 'debug w/ handle' );
	local *STDERR = $db;
	ok( do { my $x=File::Replace::Inplace->new(debug=>1); 1 }, 'debug w/o handle' );
};

subtest 'misc failures' => sub { plan tests=>7;
	like exception { inplace(); 1 },
		qr/\bUseless use of .*->new in void context\b/, 'inplace in void ctx';
	like exception { my $x=inplace('foo') },
		qr/\bnew: bad number of args\b/, 'bad nr of args 1';
	like exception { File::Replace::Inplace::TiedArgv::TIEHANDLE() },
		qr/\bTIEHANDLE: bad number of args\b/, 'bad nr of args 2';
	like exception { File::Replace::Inplace::TiedArgv::TIEHANDLE('x','y') },
		qr/\bTIEHANDLE: bad number of args\b/, 'bad nr of args 3';
	like exception { my $x=inplace(badarg=>1) },
		qr/\bunknown option\b/, 'unknown arg';
	{
		my $x = inplace(debug=>$DEBUG);
		like exception { open ARGV; },  ## no critic (ProhibitBarewordFileHandles, RequireCheckedOpen, RequireBriefOpen)
			qr/\bbad number of arguments to open\b/, 'bad nr of args to open 1';
		like exception { open ARGV, '<', 'foo'; },  ## no critic (ProhibitBarewordFileHandles, RequireCheckedOpen, RequireBriefOpen)
			qr/\bbad number of arguments to open\b/, 'bad nr of args to open 2';
	}
};
