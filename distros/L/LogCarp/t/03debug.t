# Before `make install' is performed this script should run with `make test'.
# After `make install' it should work as `perl t/test2.t'

######################### We start with some black magic to print on failure.

# Change $tests in the begin block at the end.

use vars qw( $tests $finished );
$| = 1; print "1..$tests\n";
END { test($tests,$finished); }

use CGI::LogCarp qw( :STDBUG :STDERR );

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

my $debugout = $0;
$debugout =~ s/t$/bug/;
open(BUG,'>'.$debugout) or die;

# Assume streams_are_equal works ...
debugout \*BUG or die;
open(TEST,$debugout) or die;
test(1,CGI::LogCarp::streams_are_equal(\*BUG,\*TEST),"debugout");
close TEST;

test(2,($CGI::LogCarp::DEBUGLEVEL == 1),"default DEBUGLEVEL");

# We will test warn also, so carpout STDERR
my $errmsgout = $0;
$errmsgout =~ s/t$/err/;
open(ERR,'>'.$errmsgout) or die;
carpout \*ERR or die;

# Test level 1 -> 2
debug  "Some DEBUG schtuff 1 - DEBUGLEVEL=".DEBUGLEVEL;
trace  "Some TRACE schtuff 1 - DEBUGLEVEL=".DEBUGLEVEL;
DEBUGLEVEL 2;
debug  "Some DEBUG schtuff 2 - DEBUGLEVEL=".DEBUGLEVEL;
trace  "Some TRACE schtuff 2 - DEBUGLEVEL=".DEBUGLEVEL;
warn "WARNING: This goes to DEBUG too - DEBUGLEVEL=".DEBUGLEVEL;
test(3,($CGI::LogCarp::DEBUGLEVEL == 2),"DEBUGLEVEL 2");


# Test level 2 -> 1
DEBUGLEVEL 1;
trace  "Some INVALID TRACE schtuff 3 - DEBUGLEVEL=".DEBUGLEVEL;
debug  "Some DEBUG schtuff 3 - DEBUGLEVEL=".DEBUGLEVEL;
warn "WARNING: This goes to DEBUG too - DEBUGLEVEL=".DEBUGLEVEL;
test(4,($CGI::LogCarp::DEBUGLEVEL == 1),"DEBUGLEVEL 1");

# Test level 1 -> 0
DEBUGLEVEL 0;
trace  "Some INVALID TRACE schtuff 0 - DEBUGLEVEL=".DEBUGLEVEL;
debug  "Some INVALID DEBUG schtuff 0 - DEBUGLEVEL=".DEBUGLEVEL;
warn "WARNING: This goes to DEBUG too - DEBUGLEVEL=".DEBUGLEVEL;
test(5,($CGI::LogCarp::DEBUGLEVEL == 0),"DEBUGLEVEL 0");

debugout;
test(6,CGI::LogCarp::streams_are_equal(\*STDBUG,\*STDOUT),"reset debugout");

BEGIN { $tests = 6; $tests++; } # How many tests we run
$finished = 1; # We made it this far

1;
