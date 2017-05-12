#!/usr/bin/env perl
use warnings;
use strict;

# Tests for the Perl module IPC::Run3::Shell
# 
# Copyright (c) 2015 Hauke Daempfling (haukex@zero-g.net).
# 
# This library is free software; you can redistribute it and/or modify
# it under the same terms as Perl 5 itself.
# 
# For more information see the "Perl Artistic License",
# which should have been distributed with your copy of Perl.
# Try the command "perldoc perlartistic" or see
# http://perldoc.perl.org/perlartistic.html .

# These tests are for IPC::Run3::Shell::_strify()
## no critic (ProtectPrivateSubs)

use FindBin ();
use lib $FindBin::Bin;
use IPC_Run3_Shell_Testlib;

use Test::More tests=>7;
use Test::Fatal 'exception';

use OverloadTestClasses;
use IPC::Run3::Shell ();

# make warnings nonfatal in a way compatible with Perl v5.6, which didn't yet have "NONFATAL"
no warnings FATAL=>'all'; use warnings;  ## no critic (ProhibitNoWarnings)
# but we also don't expect any extra warnings
local $SIG{__WARN__} = sub { fail "unexpected warning: ".shift };

subtest Undef => sub { plan tests=>3;
	my @w = warns {
		is IPC::Run3::Shell::_strify( undef ), "", "_strify undef";
	};
	is @w, 1, "warn count";
	like $w[0], qr/^Use of uninitialized value in argument list\b/, "_strify undef warn";
};

subtest Normal => sub { plan tests=>3;
	is warns {
		is IPC::Run3::Shell::_strify( "foo" ), "foo", "_strify plain string";
		is IPC::Run3::Shell::_strify( 123 ), "123", "_strify plain number";
	}, 0, "no warnings";
};

subtest Ref => sub { plan tests=>3;
	my @w = warns {
		like IPC::Run3::Shell::_strify( {foo=>'bar'} ),
			qr/^HASH\(0x[a-fA-F0-9]+\)$/, "_strify hashref";
	};
	is @w, 1, "warn count";
	like $w[0], qr/\bargument list contains ref/, "_strify ref warn";
};

subtest NormalStrify => sub { plan tests=>6;
	is warns {
		is IPC::Run3::Shell::_strify( FakeStringFallback->new("4") ), "149",  "_strify FakeStringFallback";
		is IPC::Run3::Shell::_strify( FakeStringDefault->new("5") ), "258",  "_strify FakeStringDefault";
		is IPC::Run3::Shell::_strify( FakeStringOnly->new("6") ), "367",  "_strify FakeStringOnly";
		is IPC::Run3::Shell::_strify( FakeNumberFallback->new(3) ), "5",  "_strify FakeNumberFallback";
		is IPC::Run3::Shell::_strify( FakeNumberDefault->new(4) ), "8",  "_strify FakeNumberDefault";
	}, 0, "no warnings";
};

subtest OverloadErrs => sub { plan tests=>5;
	is warns {
		like exception { IPC::Run3::Shell::_strify( FakeNumberOnly->new(5) ) },
			qr/\bdoesn't overload string/,  "_strify FakeNumberOnly fails";
		like exception { IPC::Run3::Shell::_strify( NotStrOrNumish->new(9) ) },
			qr/\bdoesn't overload string/,  "_strify NotStrOrNumish fails";
		like exception { IPC::Run3::Shell::_strify( DiesOnStringify->new("1") ) },
			qr/\bARRRGH\b/,  "_strify DiesOnStringify fails";
		like exception { IPC::Run3::Shell::_strify( DiesOnNumify->new(1) ) },
			qr/\bBLAMMO\b/,  "_strify DiesOnNumify fails";
	}, 0, "no warnings";
};

subtest Object => sub { plan tests=>3;
	my @w = warns {
		like IPC::Run3::Shell::_strify( NotOverloaded->new("foo") ),
			qr/^NotOverloaded=SCALAR\(0x[a-fA-F0-9]+\)$/,  "_strify NotOverloaded";
	};
	is @w, 1, "warn count";
	like $w[0], qr/\bargument list contains ref/, "_strify ref warn";
};

our $HAVE_PATH_CLASS;
BEGIN { $HAVE_PATH_CLASS = eval q{ use Path::Class (); 1 } };  ## no critic (ProhibitStringyEval)
subtest PathClass => sub {
	plan $HAVE_PATH_CLASS || $AUTHOR_TESTS ? (tests=>2) : (skip_all=>"don't have Path::Class");
	my $f = Path::Class::File->new('testfile.txt');
	my $sh = IPC::Run3::Shell->new();
	is warns {
		is $sh->perl('-e','print "$_\n" for @ARGV','--',$f), "$f\n", "stringifies correctly";
	}, 0, "no warnings";
};


done_testing;

