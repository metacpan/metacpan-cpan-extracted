use strict;
use warnings;

my @global_time;
BEGIN {
    # we need to override this builtin before loading modules that use it.

    # 2013-01-01 (in UTC, this is 1356998400)
    @global_time = (0, 0, 0, 1, 0, 113, 2, 0, 0);
    *CORE::GLOBAL::localtime = sub() { return @global_time };
    my $time = 0;
    *CORE::GLOBAL::time = sub() { return ++$time }; # cache buster: returns a fresh value every time
}

use Test::More 0.88;
use Path::Tiny;
use File::Spec::Functions qw(catfile splitdir);
use Log::Dispatch;

my $tempdir = Path::Tiny->tempdir;

# test that the same handle is returned if close_after_write is not set and the
# stamp hasn't changed.
# we override the system clock to test all four cases:
#
# same stamp, no CAW            same handle
# same stamp, CAW               NEW HANDLE
# different stamp, no CAW       NEW HANDLE
# different stamp, CAW          NEW HANDLE

{
    my $logger = Log::Dispatch->new(
        outputs => [
            [
                'File::Stamped',
                min_level => 'debug',
                newline => 1,
                name => 'no_caw',
                filename => $tempdir->child('no_caw.log')->stringify,
                close_after_write => 0,
            ],
            [
                'File::Stamped',
                min_level => 'debug',
                newline => 1,
                name => 'caw',
                filename => $tempdir->child('caw.log')->stringify,
                close_after_write => 1,
            ],
        ],
    );

    note "the simulated time is: ", POSIX::strftime('%Y%m%d-%T', localtime), "\n";

    is(
        $logger->output('no_caw')->{filename},
        catfile(splitdir($tempdir->child('no_caw-20130101.log')->stringify)),
        'properly calculated initial filename (no CAW)',
    );
    is(
        $logger->output('caw')->{filename},
        catfile(splitdir($tempdir->child('caw-20130101.log')->stringify)),
        'properly calculated initial filename (CAW)',
    );

    ok($logger->output('no_caw')->{fh}, 'no_caw output has created a fh before first write');
    ok(!$logger->output('caw')->{fh}, 'caw output has not created a fh before first write');

    # write the first message...
    $logger->log(level => 'info', message => 'first message');
    is(path($logger->output('no_caw')->{filename})->slurp, "first message\n", 'first line from no_caw output');
    is(path($logger->output('caw')->{filename})->slurp, "first message\n", 'first line from caw output');

    my %handle = (
        no_caw => $logger->output('no_caw')->{fh},
        caw => $logger->output('caw')->{fh},
    );

    # now write another message...
    $logger->log(level => 'info', message => 'second message');

    is(path($logger->output('no_caw')->{filename})->slurp, "first message\nsecond message\n", 'full content from no_caw output');
    is(path($logger->output('caw')->{filename})->slurp, "first message\nsecond message\n", 'full content from caw output');

    # check the filehandles again...
    is($logger->output('no_caw')->{fh}, $handle{no_caw}, 'handle has not changed when not using CAW');
    fhs_differ($logger->output('caw')->{fh}, $handle{caw}, 'handle has changed when using CAW');

    $handle{caw_2} = $logger->output('caw')->{fh};


    # now pretend a day has passed...
    $global_time[$_]++ foreach (3,6,7); # mday, wday, yday

    note "\nthe simulated time is: ", POSIX::strftime('%Y%m%d-%T', localtime);

    # write another message
    $logger->log(level => 'info', message => 'third message');

    is(
        $logger->output('no_caw')->{filename},
        catfile(splitdir($tempdir->child('no_caw-20130102.log')->stringify)),
        'properly calculated new filename (no CAW)',
    );
    is(
        $logger->output('caw')->{filename},
        catfile(splitdir($tempdir->child('caw-20130102.log')->stringify)),
        'properly calculated new filename (CAW)',
    );

    is(path($logger->output('no_caw')->{filename})->slurp, "third message\n", 'third line from no_caw output');
    is(path($logger->output('caw')->{filename})->slurp, "third message\n", 'third line from caw output');

    isnt($logger->output('no_caw')->{fh}, $handle{no_caw}, 'handle has changed when not using CAW, for new day');
    fhs_differ($logger->output('caw')->{fh}, $handle{caw_2}, 'handle has changed when using CAW, for new day');
}

sub fhs_differ
{
    my ($fh1, $fh2, $test_name) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    ok(
        ((defined $fh1 and defined $fh2 and $fh1 != $fh2) or (not defined $fh1 and not defined $fh2)),
        $test_name,
    )
    or do {
        no warnings 'uninitialized';
        diag "original fh was $fh1; new fh is $fh2";
    };
}

done_testing;
