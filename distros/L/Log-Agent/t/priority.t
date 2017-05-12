#!perl
###########################################################################
#
#   priority.t
#
#   Copyright (C) 1999 Raphael Manfredi.
#   Copyright (C) 2002-2015 Mark Rogaski, mrogaski@cpan.org;
#   all rights reserved.
#
#   See the README file included with the
#   distribution for license information.
#
##########################################################################

print "1..5\n";

require 't/code.pl';
sub ok;

use Log::Agent;
require Log::Agent::Driver::File;

unlink 't/file.out', 't/file.err';

my $driver = Log::Agent::Driver::File->make(
	-prefix => 'me',
	-channels => {
		'error' => 't/file.err',
		'output' => 't/file.out'
	},
);
logconfig(
	-driver		=> $driver,
	-priority	=> [ -display => '<$priority/$level>', -prefix => 1 ],
	-level		=> 12,
);

logerr "error string";
logsay "notice string";
logcarp "carp string";
logdbg 'info:12', "info string";

ok 1, contains("t/file.err", "<error/3> error string");
ok 2, !contains("t/file.err", "notice string");
ok 3, contains("t/file.err", "<warning/4> carp string");
ok 4, contains("t/file.out", "<notice/6> notice string");
ok 5, contains("t/file.err", "<info/12> info string");

unlink 't/file.out', 't/file.err';
