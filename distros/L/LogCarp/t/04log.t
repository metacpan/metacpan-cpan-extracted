# Before `make install' is performed this script should run with `make test'.
# After `make install' it should work as `perl t/test2.t'

######################### We start with some black magic to print on failure.

# Change $tests in the begin block at the end.

use vars qw( $tests $finished );
$| = 1; print "1..$tests\n";
END { test($tests,$finished); }

use CGI::LogCarp qw( :STDLOG :STDERR );

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

sub test
{
    local $^W;
    my ($num,$ok,$msg) = @_;
    $ok = ($ok ? "ok" : "not ok");
    print "$ok $num $msg\n";
}

my $logmsgout = $0;
$logmsgout =~ s/t$/log/;
open(LOG,'>'.$logmsgout) or die;

# Assume streams_are_equal works ...
logmsgout \*LOG or die;
open(TEST,$logmsgout) or die;
test(1,CGI::LogCarp::streams_are_equal(\*LOG,\*TEST),"logmsgout");
close TEST;

test(2,($CGI::LogCarp::LOGLEVEL == 1),"default LOGLEVEL");

# We will test warn also, so carpout STDERR
my $errmsgout = $0;
$errmsgout =~ s/t$/err/;
open(ERR,'>'.$errmsgout) or die;
carpout \*ERR or die;

# Test level 1 -> 2
logmsg  "Some LOG schtuff 1 - LOGLEVEL=".LOGLEVEL;
LOGLEVEL 2;
logmsg  "Some LOG schtuff 1 - LOGLEVEL=".LOGLEVEL;
warn "WARNING: This goes to LOG too - LOGLEVEL=".LOGLEVEL;
test(3,($CGI::LogCarp::LOGLEVEL == 2),"LOGLEVEL 2");

# Test level 2 -> 1
LOGLEVEL 1;
logmsg  "Some LOG schtuff 2 - LOGLEVEL=".LOGLEVEL;
warn "WARNING: This goes to LOG too - LOGLEVEL=".LOGLEVEL;
test(4,($CGI::LogCarp::LOGLEVEL == 1),"LOGLEVEL 1");

# Test level 1 -> 0
LOGLEVEL 0;
logmsg  "Some INVALID LOG schtuff 3 - LOGLEVEL=".LOGLEVEL;
warn "WARNING: This goes to LOG too - LOGLEVEL=".LOGLEVEL;
test(5,($CGI::LogCarp::LOGLEVEL == 0),"LOGLEVEL 0");

logmsgout;
test(6,CGI::LogCarp::streams_are_equal(\*STDLOG,\*_STDERR),"reset logmsgout");

BEGIN { $tests = 6; $tests++; } # How many tests we run
$finished = 1; # We made it this far

1;
