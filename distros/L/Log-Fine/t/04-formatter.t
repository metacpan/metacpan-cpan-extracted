#!perl -T

use Test::More tests => 25;

use Log::Fine;
use Log::Fine::Formatter;
use Log::Fine::Formatter::Basic;
use Log::Fine::Formatter::Detailed;
use Log::Fine::Formatter::Syslog;
use Log::Fine::Levels::Syslog;

{

        # Create a basic formatter
        my $basic = Log::Fine::Formatter::Basic->new();

        isa_ok($basic, "Log::Fine::Formatter::Basic");
        can_ok($basic, "name");
        can_ok($basic, "timeStamp");

        # All objects should have names
        ok($basic->name() =~ /\w\d+$/);
        ok($basic->timeStamp() eq Log::Fine::Formatter->LOG_TIMESTAMP_FORMAT);

        # See if our levels are properly defined
        ok($basic->can("levelMap"));

        my $lvls = $basic->levelMap();

        isa_ok($lvls, "Log::Fine::Levels");

        # Format a message
        my $msg = "Stop by this disaster town";
        my $log0 = $basic->format(INFO, $msg, 1);

        # See if the format is correct
        ok($log0 =~ /^\[.*?\] \w+ $msg/);

        # Make sure we can change the timestamp format
        $basic->timeStamp("%Y%m%d%H%M%S");

        my $log1 = $basic->format(INFO, $msg, 1);

        # See if the format is correct
        ok($log1 =~ /^\[\d{14,14}\] \w+ $msg/);

        # Now create a detailed formatter
        my $detailed = Log::Fine::Formatter::Detailed->new();

        isa_ok($detailed, "Log::Fine::Formatter::Detailed");
        can_ok($detailed, "name");
        can_ok($detailed, "timeStamp");
        can_ok($detailed, "testFormat");

        ok($detailed->name() =~ /\w\d+$/);
        ok($detailed->timeStamp() eq Log::Fine::Formatter->LOG_TIMESTAMP_FORMAT);

        # Format a message
        my $log2 = $detailed->format(INFO, $msg, 1);

        ok($log2 =~ /^\[.*?\] \w+ \(.*?\) $msg/);

        #print STDERR "\n$log2\n";

        my $log3 = myfunc($detailed, $msg);

        ok($log3 =~ /^\[.*?\] \w+ \(.*?\:\d+\) $msg/);

        #print STDERR "\n$log3\n";

        my $log4 = $detailed->testFormat(INFO, $msg);

        ok($log4 =~ /^\[.*?\] \w+ \(Log\:\:Fine\:\:Formatter\:\:testFormat\(\)\:\d+\) $msg/);

        #print STDERR "\n$log4\n";

        # Now create a syslog formatter
        my $syslog = Log::Fine::Formatter::Syslog->new();

        isa_ok($syslog, "Log::Fine::Formatter::Syslog");
        can_ok($syslog, "name");
        can_ok($syslog, "timeStamp");

        ok($syslog->name() =~ /\w\d+$/);
        ok($syslog->timeStamp() eq Log::Fine::Formatter::Syslog->LOG_TIMESTAMP_FORMAT);

        # Format a message
        my $log5 = $syslog->format(INFO, $msg, 1);

        # Uncomment to deliberately fail the next test
        # $log5 = "BARFME $log5";

        # Note: This regex is designed to catch non-English month
        # representations found in other locales.  This has been
        # tested against:
        #
        #  * ar_AE.utf8
        #  * cs_CZ.utf8
        #  * de_DE.utf8
        #  * es_ES.utf8
        #  * hi_IN.utf8
        #  * ja_JP.utf8
        #  * ko_KR.utf8
        #  * zh_TW.UTF-8
        #
        # This list is by no means comprehensive.  Also, since there
        # is a wide variety of different interpretations of various
        # locales on different operating systems, handle our own error
        # reporting.

        if ($log5 =~ /^\s*([ 1]\d\S+|[^ ]+) [ 0-3][0-9] \d{2}:\d{2}:\d{2} [0-9a-zA-Z\-]+ .*?\[\d+\]: $msg/)
        {
                ok(1);
        } else {
                print STDERR "\n----------------------------------------\n";
                print STDERR "Test failed on the following line:\n\n";
                print STDERR "${log5}";
                print STDERR "----------------------------------------\n";
                ok(0);
        }

        eval {
                my $badformatter = Log::Fine::Formatter->new();

                $badformatter->format(INFO, $msg, 1);
        };

        ok($@ =~ /direct call to abstract method/);

}

# this subroutine is for testing the detailed formatter

sub myfunc
{

        my $formatter = shift;
        my $msg       = shift;

        return $formatter->format(INFO, $msg, 1);

}
