#!./perl
###########################################################################
#
# t/hole.t
#
# Copyright (c) 2000 Raphael Manfredi.
# Copyright (c) 2002-2015 Mark Rogaski, mrogaski@cpan.org;
# all rights reserved.
#
# See the README file included with the
# distribution for license information.
#
###########################################################################

#
# Check behaviour when archived logfiles are externally removed
#
print "1..21\n";

require 't/code.pl';
sub ok;

sub cleanlog() {
	unlink <t/logfile*>;
}

use Log::Agent;
require Log::Agent::Driver::File;
require Log::Agent::Rotate;

cleanlog;
my $rotate_dflt = Log::Agent::Rotate->make(
	-backlog     => 7,
	-unzipped    => 2,
	-is_alone    => 0,
    -max_size    => 100,
);

my $driver = Log::Agent::Driver::File->make(
	-channels => {
		'error'  => 't/logfile_err',
		'output' => ['t/logfile', $rotate_dflt],
	},
);
logconfig(-driver => $driver);

my $message = "this is a message whose size is exactly 53 characters";

logsay $message;
logsay $message;		# rotates

logsay $message;
logsay $message;		# rotates again

logsay $message;
logsay $message;		# rotates again

logsay $message;
logsay $message;		# rotates again

ok 1, -e("t/logfile.0");
ok 2, -e("t/logfile.1");
ok 3, -e("t/logfile.2.gz");
ok 4, -e("t/logfile.3.gz");
ok 5, !-e("t/logfile.4.gz");

ok 6, unlink "t/logfile.0";
ok 7, unlink "t/logfile.2.gz";

logsay $message;
logsay $message;		# rotates again

ok 8, -e("t/logfile.0");
ok 9, !-e("t/logfile.1");
ok 10, -e("t/logfile.2.gz");
ok 11, !-e("t/logfile.3.gz");
ok 12, -e("t/logfile.4.gz");
ok 13, !-e("t/logfile.5.gz");

ok 14, unlink "t/logfile.2.gz";

logsay $message;
logsay $message;		# rotates again

ok 15, -e("t/logfile.0");
ok 16, -e("t/logfile.1");
ok 17, !-e("t/logfile.2.gz");
ok 18, !-e("t/logfile.3.gz");
ok 19, !-e("t/logfile.4.gz");
ok 20, -e("t/logfile.5.gz");
ok 21, !-e("t/logfile.6.gz");

cleanlog;
