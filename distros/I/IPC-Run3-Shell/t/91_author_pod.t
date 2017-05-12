#!/usr/bin/env perl
use warnings FATAL=>'all';
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

use File::Spec::Functions qw/catfile/;
our @PODFILES;
BEGIN {
	@PODFILES = (
		catfile($FindBin::Bin,qw/ .. lib IPC Run3 Shell.pod /),
	);
}

use Test::More $AUTHOR_TESTS && !$DEVEL_COVER ? (tests=>2*@PODFILES)
	: (skip_all=>$DEVEL_COVER?'skipping during Devel::Cover tests':'author POD tests');

use Test::Pod;
use IO::String;
use Test_Pod_Verbatim_Parser;

diag "Some output is normal here (show_cmd)";
for my $podfile (@PODFILES) {
	pod_file_ok($podfile);
	Test_Pod_Verbatim_Parser->new->parse_from_file($podfile, IO::String->new(my $out));
	subtest "tests generated from POD in '$podfile'" => sub {
		eval $out or fail "eval error: $@";  ## no critic (ProhibitStringyEval)
	};
}

