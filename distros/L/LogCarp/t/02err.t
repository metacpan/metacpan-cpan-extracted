# Before `make install' is performed this script should run with `make test'.
# After `make install' it should work as `perl t/test2.t'

######################### We start with some black magic to print on failure.

# Change $tests in the begin block at the end.

use vars qw( $tests $finished );
$| = 1; print "1..$tests\n";
END { test($tests,$finished); }

use CGI::LogCarp qw( :STDERR );

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

my $carpout = $0;
$carpout =~ s/t$/err/;
open(ERR,'>'.$carpout) or die;

# Assume streams_are_equal works ...
carpout \*ERR or die;
open(TEST,$carpout) or die;
test(1,CGI::LogCarp::streams_are_equal(\*ERR,\*TEST),"carpout");
close TEST;

warn "a WARN message";

carpout;
test(2,CGI::LogCarp::streams_are_equal(\*STDERR,\*_STDERR),"reset carpout");

BEGIN { $tests = 2; $tests++; } # How many tests we run
$finished = 1; # We made it this far

1;
