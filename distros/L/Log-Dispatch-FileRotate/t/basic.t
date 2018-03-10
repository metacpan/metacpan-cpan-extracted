#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More 0.88;
use Path::Tiny 0.018;

if ($^O eq 'cygwin') {
    # Date::Manip doesn't like Cygwin's TZ value.
    $ENV{TZ} = (split " ",(`date`)[0])[4];
}

use Log::Dispatch;
use Log::Dispatch::Screen;
use Log::Dispatch::FileRotate;
use Date::Manip;

my $tz;
eval {
    $tz = Date_TimeZone();
};
if($@) {
    diag 'Unable to determine timezone! Lets see if it matters..';

    my $start = DateCalc("now","+ 1 second");
    my @dates = ParseRecur('0:0:0:0:0:1*0', 'now', $start, '20 minutes later');

    # Should get about 20 in the array
    my @epochs = map { UnixDate($_,'%s') } @dates;
    shift @epochs while @epochs && $epochs[0] <= time;

    # If no epochs left then Timezone issue is going to bite us!
    # all bets are off.
    if (@epochs) {
        pass 'It looks like we can get by without a timezone. Lucky!';
    }
    else {
        fail '**** Time Zone problem: All bets are off. ****';
    }

    $tz = '';
}
else {
    pass "Your timezone is $tz";
}

my $tempdir = Path::Tiny->tempdir;

my $dispatcher = Log::Dispatch->new;
isa_ok $dispatcher, 'Log::Dispatch';

my $screen_logger = Log::Dispatch::Screen->new(min_level => 'emergency');
isa_ok $screen_logger, 'Log::Dispatch::Screen';
$dispatcher->add($screen_logger);

my $file_logger = Log::Dispatch::FileRotate->new(
    filename    => $tempdir->child('myerrs.log')->stringify,
    min_level   => 'debug',
    mode        => 'append',
    size        => 20000,
    max         => 5,
    newline     => 1,
    DatePattern => 'YYYY-dd-HH',
    TZ          => $tz);

isa_ok $file_logger, 'Log::Dispatch::FileRotate';

$dispatcher->add($file_logger);

note <<NOTE_END;
    while true; do clear;ls -ltr | grep myerrs; sleep 1; done

Type this in another terminal in this directory to see the logs changing. You
can also edit log.conf and change params to see what will happen to the log
files.

You can also run a number of 'make test' commands to see how we behave with
multiple writers to log files.

Edit t/basic.t and uncomment the 'sleep 1' line if you want to see time
rotation happening
NOTE_END

my @logged;
my $logged = '';

for (my $i = 4 ; $i <= 65 ; $i++) {
    for my $level (qw(debug info notice warning error critical alert)) {
        my $msg = "$$ this is a $level message";

        $dispatcher->log(level => $level, message => $msg);

        push @logged, $msg;
    }
    $i++;
#   sleep 1;
}

open my $logfile, '<', $tempdir->child('myerrs.log');

my @logfile_lines = <$logfile>;

cmp_ok scalar @logged, '==', scalar @logfile_lines,
    'Logfile has expected number of lines';

my $line_num = 1;
while (my $line = shift @logfile_lines) {
    chomp $line;
    my $expected = shift @logged;

    is $line, $expected, 'Logfile line '. $line_num++;
}

done_testing;
