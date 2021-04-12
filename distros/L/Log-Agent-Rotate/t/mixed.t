#!./perl
###########################################################################
#
# t/mixed.t
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
# Check behaviour when mixed compressing policies are used in sequence
#
print "1..50\n";

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
	-is_alone    => 1,
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
logsay $message;		# will bring logsize size > 100 chars
logsay $message;
logsay $message;		# rotates again, creates logfile.1
logsay $message;
logsay $message;		# rotates again, now has logfile.2.gz

ok 1, !-e("t/logfile");
ok 2, -e("t/logfile.0");
ok 3, -e("t/logfile.1");
ok 4, -e("t/logfile.2.gz");
ok 5, !-e("t/logfile.3.gz");

undef $Log::Agent::Driver;		# Cheat

$rotate_dflt = Log::Agent::Rotate->make(
	-backlog     => 7,
	-unzipped    => 4,
	-is_alone    => 1,
    -max_size    => 100,
);
$driver = Log::Agent::Driver::File->make(
	-channels => {
		'error'  => 't/logfile_err',
		'output' => ['t/logfile', $rotate_dflt],
	},
);
logconfig(-driver => $driver);

logsay $message;
logsay $message;		# rotate, logfile.2.gz not uncompresed

ok 6, !-e("t/logfile");
ok 7, -e("t/logfile.0");
ok 8, -e("t/logfile.1");
ok 9, -e("t/logfile.2");
ok 10, -e("t/logfile.3.gz");
ok 11, !-e("t/logfile.4.gz");

logsay $message;
logsay $message;		# rotate, logfile.3.gz not uncompresed

ok 12, !-e("t/logfile");
ok 13, -e("t/logfile.0");
ok 14, -e("t/logfile.1");
ok 15, -e("t/logfile.2");
ok 16, -e("t/logfile.3");
ok 17, -e("t/logfile.4.gz");
ok 18, !-e("t/logfile.5.gz");

undef $Log::Agent::Driver;		# Cheat

$rotate_dflt = Log::Agent::Rotate->make(
	-backlog     => 7,
	-unzipped    => 1,
	-is_alone    => 1,
    -max_size    => 100,
);
$driver = Log::Agent::Driver::File->make(
	-channels => {
		'error'  => 't/logfile_err',
		'output' => ['t/logfile', $rotate_dflt],
	},
);
logconfig(-driver => $driver);

logsay $message;
logsay $message;		# rotate, re-compresses up to logfile.1.gz

ok 19, !-e("t/logfile");
ok 20, -e("t/logfile.0");
ok 21, -e("t/logfile.1.gz");
ok 22, -e("t/logfile.2.gz");
ok 23, -e("t/logfile.3.gz");
ok 24, -e("t/logfile.4.gz");
ok 25, -e("t/logfile.5.gz");
ok 26, !-e("t/logfile.6.gz");

undef $Log::Agent::Driver;		# Cheat

$rotate_dflt = Log::Agent::Rotate->make(
	-backlog     => 4,
	-unzipped    => 1,
	-is_alone    => 1,
    -max_size    => 100,
);
$driver = Log::Agent::Driver::File->make(
	-channels => {
		'error'  => 't/logfile_err',
		'output' => ['t/logfile', $rotate_dflt],
	},
);
logconfig(-driver => $driver);

logsay $message;
logsay $message;		# rotate, keeps only from .0 to .3.gz

ok 27, !-e("t/logfile");
ok 28, -e("t/logfile.0");
ok 29, -e("t/logfile.1.gz");
ok 30, -e("t/logfile.2.gz");
ok 31, -e("t/logfile.3.gz");
ok 32, !-e("t/logfile.4.gz");
ok 33, !-e("t/logfile.5.gz");
ok 34, !-e("t/logfile.6.gz");

undef $Log::Agent::Driver;		# Cheat

$rotate_dflt = Log::Agent::Rotate->make(
	-backlog     => 4,
	-unzipped    => 4,
	-is_alone    => 1,
    -max_size    => 100,
);
$driver = Log::Agent::Driver::File->make(
	-channels => {
		'error'  => 't/logfile_err',
		'output' => ['t/logfile', $rotate_dflt],
	},
);
logconfig(-driver => $driver);

logsay $message;
logsay $message;		# rotate, no compression at all

ok 35, !-e("t/logfile");
ok 36, -e("t/logfile.0");
ok 37, -e("t/logfile.1");
ok 38, -e("t/logfile.2.gz");
ok 39, -e("t/logfile.3.gz");
ok 40, !-e("t/logfile.4.gz");

logsay $message;
logsay $message;		# rotate, no compression at all
logsay $message;
logsay $message;		# rotate, no compression at all

ok 41, !-e("t/logfile");
ok 42, -e("t/logfile.0");
ok 43, -e("t/logfile.1");
ok 44, -e("t/logfile.2");
ok 45, -e("t/logfile.3");
ok 46, !-e("t/logfile.4");
ok 47, !-e("t/logfile.3.gz");
ok 48, !-e("t/logfile.2.gz");
ok 49, !-e("t/logfile.1.gz");
ok 50, !-e("t/logfile.0.gz");

cleanlog;
