#!perl
###########################################################################
#
#   file.t
#
#   Copyright (C) 1999 Raphael Manfredi.
#   Copyright (C) 2002-2015 Mark Rogaski, mrogaski@cpan.org;
#   all rights reserved.
#
#   See the README file included with the
#   distribution for license information.
#
##########################################################################

use Test::More;
use Log::Agent;
require Log::Agent::Driver::File;
require 't/common.pl';

BEGIN { plan tests => 38 }

my $driver = Log::Agent::Driver::File->make();        # take all defaults
logconfig(-driver => $driver);

open(ORIGOUT, ">&STDOUT")   or die "can't dup STDOUT: $!\n";
open(STDOUT, ">t/file.out") or die "can't redirect STDOUT: $!\n";
open(ORIGERR, ">&STDERR")   or die "can't dup STDERR: $!\n";
open(STDERR, ">t/file.err") or die "can't redirect STDERR: $!\n";
select(ORIGERR); $| = 1;
select(ORIGOUT); $| = 1;

logerr "error";
logsay "message";

close STDOUT;
open(STDOUT, ">&ORIGOUT") or die "can't restore STDOUT: $!\n";
close STDERR;
open(STDERR, ">&ORIGERR") or die "can't restore STDERR: $!\n";
select(STDOUT);

ok(contains("t/file.err", '\d Error$'));
ok(! contains("t/file.out", 'Error'));
ok(contains("t/file.err", '\d Message$'));
ok(! contains("t/file.out", 'Message'));

undef $Log::Agent::Driver;        # Cheat

$driver = Log::Agent::Driver::File->make(
    -prefix => 'me',
    -showpid => 1,
    -stampfmt => sub { 'DATE' },
    -channels => {
        'error' => 't/file.err',
        'output' => 't/file.out'
    },
    -duperr => 1,
);
logconfig(-driver => $driver);

open(ORIGOUT, ">&STDOUT")   or die "can't dup STDOUT: $!\n";
open(STDOUT, ">t/file.out") or die "can't redirect STDOUT: $!\n";
open(ORIGERR, ">&STDERR")   or die "can't dup STDERR: $!\n";
open(STDERR, ">t/file.err") or die "can't redirect STDERR: $!\n";
select(ORIGERR); $| = 1;
select(ORIGOUT); $| = 1;

logerr "error";
logsay "message";
logwarn "warning";
eval { logdie "die" };

close STDOUT;
open(STDOUT, ">&ORIGOUT") or die "can't restore STDOUT: $!\n";
close STDERR;
open(STDERR, ">&ORIGERR") or die "can't restore STDERR: $!\n";
select(STDOUT);

ok($@);

ok(contains("t/file.err", '^DATE me\[\d+\]: error$'));
ok(contains("t/file.out", 'ERROR: error'));
ok(contains("t/file.out", '^DATE me\[\d+\]: message$'));
ok(! contains("t/file.err", 'message'));
ok(contains("t/file.err", '^DATE me\[\d+\]: warning$'));
ok(contains("t/file.out", 'WARNING: warning'));
ok(contains("t/file.err", '^DATE me\[\d+\]: die$'));
ok(contains("t/file.out", 'FATAL: die'));

unlink 't/file.out', 't/file.err';

undef $Log::Agent::Driver;        # Cheat

$driver = Log::Agent::Driver::File->make(
    -prefix => 'me',
    -stampfmt => sub { 'DATE' },
    -channels => {
        'error' => 't/file2.err',
        'output' => 't/file2.out'
    },
);
logconfig(-driver => $driver);

logerr "error";
logsay "message";
logwarn "warning";
eval { logdie "die" };

ok($@);

ok(contains("t/file2.err", '^DATE me: error$'));
ok(! contains("t/file2.out", 'error'));
ok(contains("t/file2.out", '^DATE me: message$'));
ok(! contains("t/file2.err", 'message'));
ok(contains("t/file2.err", '^DATE me: warning$'));
ok(! contains("t/file2.out", 'warning'));
ok(contains("t/file2.err", '^DATE me: die$'));
ok(! contains("t/file2.out", 'die'));

unlink 't/file2.out', 't/file2.err';

undef $Log::Agent::Driver;  # Cheat
open(FILE, '>>t/file.err'); # Needs appending, for OpenBSD

$driver = Log::Agent::Driver::File->make(
    -prefix => 'me',
    -magic_open => 1,
    -channels => {
        'error' => '>>t/file3.err',
    },
);
logconfig(-driver => $driver);

logerr "error";
logsay "should go to error";

close FILE;

ok(! -e '>&main::FILE');
ok(-e 't/file3.err');
ok(contains("t/file3.err", 'me: error$'));
ok(contains("t/file3.err", 'me: should go to'));

unlink 't/file3.err';

#
# Test file permissions
#

SKIP: {

    skip "file mode not supported on Win32.", 12 if $^O eq 'MSWin32';

    $driver = Log::Agent::Driver::File->make(
        -file => 't/file4.out',
        -perm => 0666
    );
    logconfig(-driver => $driver);
    logsay "HONK HONK!";

    ok(perm_ok('t/file4.out', 0666));

    unlink 't/file4.out';

    $driver = Log::Agent::Driver::File->make(
        -file => 't/file5.out',
        -perm => 0644
    );
    logconfig(-driver => $driver);
    logsay "HONK HONK!";

    ok(perm_ok('t/file5.out', 0644));

    unlink 't/file5.out';

    $driver = Log::Agent::Driver::File->make(
        -file => 't/file6.out',
        -perm => 0640
    );
    logconfig(-driver => $driver);
    logsay "HONK HONK!";

    ok(perm_ok('t/file6.out', 0640));

    unlink 't/file6.out';

    #
    # and with magic_open
    #

    $driver = Log::Agent::Driver::File->make(
        -file       => 't/file7.out',
        -perm       => 0666,
        -magic_open => 1
    );
    logconfig(-driver => $driver);
    logsay "HONK HONK!";

    ok(perm_ok('t/file7.out', 0666));

    unlink 't/file7.out';

    $driver = Log::Agent::Driver::File->make(
        -file       => 't/file8.out',
        -perm       => 0644,
        -magic_open => 1
    );
    logconfig(-driver => $driver);
    logsay "HONK HONK!";

    ok(perm_ok('t/file8.out', 0644));

    unlink 't/file8.out';

    $driver = Log::Agent::Driver::File->make(
        -file       => 't/file9.out',
        -perm       => 0640,
        -magic_open => 1
    );
    logconfig(-driver => $driver);
    logsay "HONK HONK!";

    ok(perm_ok('t/file9.out', 0640));

    unlink 't/file9.out';

    #
    # Test file permissions with multiple channels
    #

    $driver = Log::Agent::Driver::File->make(
        -channels => {
            output => 't/file10.out',
            error  => 't/file10.err',
            debug  => 't/file10.dbg'
        },
        -chanperm => {
            output => 0666,
            error  => 0644,
            debug  => 0640
        }
    );
    logconfig(-driver => $driver, -debug => 10);
    logsay "HONK HONK!";
    logerr "HONK HONK!";
    logdbg 'debug', "HONK HONK!";

    ok(perm_ok('t/file10.out', 0666));
    ok(perm_ok('t/file10.err', 0644));
    ok(perm_ok('t/file10.dbg', 0640));

    unlink 't/file10.out', 't/file10.err', 't/file10.dbg';

    #
    # and, again, with magic_open
    #

    $driver = Log::Agent::Driver::File->make(
        -channels => {
            output => 't/file11.out',
            error  => 't/file11.err',
            debug  => 't/file11.dbg'
        },
        -chanperm => {
            output => 0666,
            error  => 0644,
            debug  => 0640
        },
        -magic_open => 1
    );
    logconfig(-driver => $driver, -debug => 10);
    logsay "HONK HONK!";
    logerr "HONK HONK!";
    logdbg 'debug', "HONK HONK!";

    ok(perm_ok('t/file11.out', 0666));
    ok(perm_ok('t/file11.err', 0644));
    ok(perm_ok('t/file11.dbg', 0640));

    unlink 't/file11.out', 't/file11.err', 't/file11.dbg';

}
