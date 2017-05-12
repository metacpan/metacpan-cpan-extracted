use Test::More;
# use Test::Synopsis::Expectation;

# % prove xt/004-synopsis.t ; prove xt/004-synopsis.t
# xt/004-synopsis.t .. ok   
# All tests successful.
# Files=1, Tests=7,  0 wallclock secs ( 0.03 usr  0.01 sys +  0.13 cusr  0.01 csys =  0.18 CPU)
# Result: PASS
# xt/004-synopsis.t .. All 2 subtests passed 
# 
# Test Summary Report
# -------------------
# xt/004-synopsis.t (Wstat: 11 Tests: 2 Failed: 0)
#   Non-zero wait status: 11
#   Parse errors: No plan found in TAP output
# Files=1, Tests=2,  1 wallclock secs ( 0.03 usr  0.01 sys +  0.12 cusr  0.01 csys =  0.17 CPU)
# Result: FAIL
#
my $f = [ qw|
    Default.pm
    HTTPD/Response.pm
    HTTPD/Router.pm
    JSON.pm
    Log.pm
| ];

# for my $e ( @$f ){ 
#    synopsis_ok( 'lib/Haineko/'.$e );
# }
is 1, 1;
done_testing;

