#!./perl
###########################################################################
#
# t/badconf.t
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
# Ensure possible incorrect rotation is detected whith bad Log::Agent config
#
print "1..6\n";

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

my $rotate_other = Log::Agent::Rotate->make(
	-backlog     => 7,
	-unzipped    => 1,
	-is_alone    => 1,
    -max_size    => 100,
);

my $driver = Log::Agent::Driver::File->make(
	-rotate   => $rotate_dflt,
	-channels => {
		'error'  => ['t/logfileA', $rotate_other],
		'output' => 't/logfileA',
	},
);
logconfig(-driver => $driver);

my $message = "this is a message whose size is exactly 53 characters";

logsay $message;
logwarn $message;		# will bring logsize size > 100 chars

ok 1, -e("t/logfileA");
ok 2, -e("t/logfileA.0");
ok 3, contains("t/logfileA.0", "Rotation for 't/logfileA' may be wrong");

cleanlog;
undef $Log::Agent::Driver;		# Cheat

$driver = Log::Agent::Driver::File->make(
	-rotate   => $rotate_dflt,
	-channels => {
		'error'  => ['t/logfileB', $rotate_dflt],
		'output' => 't/logfileB',
	},
);
logconfig(-driver => $driver);

logsay $message;
logwarn $message;		# will bring logsize size > 100 chars

ok 4, !-e("t/logfileB");
ok 5, -e("t/logfileB.0");
ok 6, !contains("t/logfileB.0", "Rotation for 'error' may be wrong");

cleanlog;
