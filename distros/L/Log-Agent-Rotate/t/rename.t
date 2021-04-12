#!./perl
###########################################################################
#
# t/rename.t
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
# Check normal behaviour, with 2 non-compressed files
#
use Test::More tests => 10;
use File::Copy 'move';

sub cleanlog() {
	unlink <t/logfile*>;
}

use Log::Agent;
require Log::Agent::Driver::File;
require Log::Agent::Rotate;

SKIP: {

    skip "file rename not supported on Win32.", 10 if $^O eq 'MSWin32';

    cleanlog;
    my $rotate_dflt = Log::Agent::Rotate->make(
        -backlog     => 7,
        -unzipped    => 2,
        -is_alone    => 0,
        -max_size    => 100,
    );

    my $driver = Log::Agent::Driver::File->make(
        -rotate   => $rotate_dflt,
        -channels => {
            'error'  => 't/logfileR',
            'output' => 't/logfileR',
        },
    );
    logconfig(-driver => $driver);

    my $message = "this is a message whose size is exactly 53 characters";

    logsay $message;
    logwarn $message;		# will bring logsize size > 100 chars
    logerr "new $message";	# not enough to rotate again

    ok(-e("t/logfileR"));
    ok(-e("t/logfileR.0"));
    ok(!-e("t/logfileR.1"));

    ok(move("t/logfileR", "t/logfileR.0"));

    logsay $message;		# does not rotate, since we renamed above

    ok(-e("t/logfileR"));
    ok(-e("t/logfileR.0"));
    ok(!-e("t/logfileR.1"));

    ok(move("t/logfileR", "t/logfileR.0"));

    logsay $message;
    ok(!-e("t/logfileR.1"));
    logsay $message;		# finally rotates
    ok(-e("t/logfileR.1"));

    cleanlog;

}
