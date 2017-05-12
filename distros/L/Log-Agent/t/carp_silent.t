#!./perl
###########################################################################
#
#   carp_silent.t
#
#   Copyright (C) 1999 Raphael Manfredi.
#   Copyright (C) 2002-2015 Mark Rogaski, mrogaski@cpan.org;
#   all rights reserved.
#
#   See the README file included with the
#   distribution for license information.
#
##########################################################################

print "1..2\n";

require 't/code.pl';
sub ok;

use Log::Agent;
require Log::Agent::Driver::Silent;

open(ORIG_STDOUT, ">&STDOUT") || die "can't dup STDOUT: $!\n";
select(ORIG_STDOUT);

open(STDOUT, ">t/file.out") || die "can't redirect STDOUT: $!\n";
open(STDERR, ">t/file.err") || die "can't redirect STDOUT: $!\n";

my $driver = Log::Agent::Driver::Silent->make();
logconfig(-driver => $driver);

sub test {
	logcarp "none";
	logcroak "test";
}

my $line = __LINE__ + 1;
test();

sub END {
	ok 1, !contains("t/file.err", "none");
	ok 2, contains("t/file.err", "test at t/carp_silent.t line $line");

	unlink 't/file.out', 't/file.err';
	exit 0;
}
