use strict;
use Embedix::ECD;

print "1..1\n";
my $test = 1;

my $ecd = Embedix::ECD->newFromFile('t/data/build_vars.ecd');
my $x = $ecd->toString(shiftwidth => 4, indent => 8);
my $y = <<ECD_TEXT;

        <OPTION enable-bb-feature-autowidth>
            <HELP>
                This feature enables the calculation of terminal and
                column widths (for more and ls).
            </HELP>
            PROMPT=Enable BB_FEATURE_AUTOWIDTH?
            <BUILD_VARS>
                BB_FEATURE_AUTOWIDTH=BB_FEATURE_AUTOWIDTH
            </BUILD_VARS>
            TYPE=bool
            DEFAULT_VALUE=1
            STATIC_SIZE=0
            MIN_DYNAMIC_SIZE=0
            STORAGE_SIZE=0
            STARTUP_TIME=0
        </OPTION>
ECD_TEXT
print "not " if ($x ne $y);
print "ok $test\n";
$test++;

# vim:syntax=perl
