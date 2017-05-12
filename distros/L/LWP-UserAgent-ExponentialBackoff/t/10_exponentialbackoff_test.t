
# Time-stamp: "0";
use strict;
use Test;
BEGIN { plan tests => 15 }

#use LWP::Debug ('+');

use LWP::UserAgent::ExponentialBackoff;
# test 1
ok 1;

print "# Hello from ", __FILE__, "\n";
print "# LWP::UserAgent::ExponentialBackoff v$LWP::UserAgent::ExponentialBackoff::VERSION\n";
print "# LWP::UserAgent v$LWP::UserAgent::VERSION\n";
print "# LWP v$LWP::VERSION\n" if $LWP::VERSION;

my $before_count = 0;
my $after_count = 0;
my $sum = 0;
my $before_request = sub {
  print "# /Trying ", $_[1][0]->uri, " in ", $_[2], " seconds\n";
  ++$before_count;
  $sum+=$_[2];
};

my $after_request = sub {
  print "# \\Just tried ", $_[1][0]->uri, " and got a ", $_[3]->code, "\n";
  ++$after_count;
};

my %options = (minBackoff   => 3, before_request => $before_request, after_request => $after_request);

my $browser = LWP::UserAgent::ExponentialBackoff->new(%options);

my @error_codes = qw(408 500 502 503 504);
# test 2
ok( @error_codes == keys %{$browser->failCodes} );
# test 3
ok( @error_codes == grep { $browser->failCodes->{$_} } @error_codes );
print "# Set to retry only the following errors: @error_codes \n";

# test 4
ok( $browser->sum(21) );

my $url = 'http://www.livejournal.com/~torgo_x/rss';
print "# Trying a redirects, not really a retry, $url\n";
my $resp = $browser->get( $url );
# test 5
ok 1;

print "# That gave: ", $resp->status_line, "\n";
print "# Before_count: $before_count\n";
# test 6
ok( $before_count > 1 );
print "# After_count: $after_count\n";
# test 7
ok(  $after_count > 1 );

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

$url = "http://www.aoeaoeaoeaoe.int:9876/sntstn";
$sum = 0;
$before_count = 0;
$after_count = 0;

print "# Trying a nonexistent address, $url\n";
$browser->timeout(2);
$browser->sum(19);
$browser->tolerance(0);
$resp = $browser->get( $url );
# test 8
ok 1;

print "# MaxBackoff: ", $browser->{maxBackoff}, "\n";
print "# DeltaBackoff: ", $browser->{deltaBackoff}, "\n";
print "# RetryCount: ", $browser->{retryCount}, "\n";

print "# That gave: ", $resp->status_line, "\n";
print "# Sum: ", $browser->{sum}, "\n";
print "# Slept: ", $sum, "\n";
# test 9
ok ($sum >= $browser->{sum} and $sum < $browser->{sum}**2);
print "# Before_count: $before_count\n";
# test 10
ok $before_count, 4;
print "# After_count: $after_count\n";
# test 11
ok $after_count,  4;


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

$url = "http://www.interglacial.com/always404alicious/";
$sum=0;
$before_count = 0;
$after_count = 0;

print "# Trying a nonexistent address, $url\n";

$resp = $browser->get( $url );
# test 12
ok 1;

$browser->sum(120);
print "# Sum: ", $browser->{sum}, "\n";

print "# That gave: ", $resp->status_line, "\n";

print "# Before_count: $before_count\n";
# test 13
ok $before_count, 1;
print "# After_count: $after_count\n";
# test 14
ok $after_count,  1;


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
print "# Okay, bye from ", __FILE__, "\n";
# test 15
ok 1;

