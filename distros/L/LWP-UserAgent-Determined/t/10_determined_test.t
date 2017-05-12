
# Time-stamp: "0";
use strict;
use Test;
BEGIN { plan tests => 13 }

#use LWP::Debug ('+');

use LWP::UserAgent::Determined;
my $browser = LWP::UserAgent::Determined->new;

use HTTP::Headers;
use HTTP::Request;
use HTTP::Request::Common qw( GET );

sub set_response {
  my ($code) = @_;
  my $handler = sub {
    return HTTP::Response->new($code, undef, HTTP::Headers->new(), 'n/a');
  };
  if( LWP::UserAgent->can('set_my_handler') ){ # 5.815
    # forward compatible
    $browser->set_my_handler(request_send => $handler);
  }
  else {
    # backward compatible
    *LWP::UserAgent::simple_request = $handler;
  }
}

sub timings {
  my $self = $browser;
  # copied from module, line 20
  my(@timing_tries) = ( $self->timing() =~ m<(\d+(?:\.\d+)*)>g );
}

#$browser->agent('Mozilla/4.76 [en] (Win98; U)');

ok 1;
print "# Hello from ", __FILE__, "\n";
print "# LWP::UserAgent::Determined v$LWP::UserAgent::Determined::VERSION\n";
print "# LWP::UserAgent v$LWP::UserAgent::VERSION\n";
print "# LWP v$LWP::VERSION\n" if $LWP::VERSION;

my @error_codes = qw(408 500 502 503 504);
ok( @error_codes == keys %{$browser->codes_to_determinate} );
ok( @error_codes == grep { $browser->codes_to_determinate->{$_} } @error_codes );

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

set_response(503);

my $url = 'http://www.livejournal.com/~torgo_x/rss';
my $before_count = 0;
my  $after_count = 0;

$browser->before_determined_callback( sub {
  print "#  /Trying ", $_[4][0]->uri, " at ", scalar(localtime), "...\n";
  ++$before_count;
});
$browser->after_determined_callback( sub {
  print "#  \\Just tried ", $_[4][0]->uri, " at ", scalar(localtime), ".  ",
    ($after_count < scalar(timings) ? "Waiting " . (timings)[$after_count] . "s." : "Giving up."), "\n";
  ++$after_count;
});

my $resp = $browser->request( GET $url );
ok 1;

print "# That gave: ", $resp->status_line, "\n";
print "# Before_count: $before_count\n";
ok( $before_count > 1 );
print "# After_count: $after_count\n";
ok(  $after_count > 1 );

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

set_response(500);

$url = "http://www.aoeaoeaoeaoe.int:9876/sntstn";
$before_count = 0;
 $after_count = 0;

print "# Trying unknown host/port, $url\n";

$resp = $browser->request( GET $url );
ok 1;

$browser->timing('1,2,3');
print "# Timing: ", $browser->timing, "\n";

print "# That gave: ", $resp->status_line, "\n";
print "# Before_count: $before_count\n";
ok $before_count, 4;
print "# After_count: $after_count\n";
ok $after_count,  4;


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

set_response(404);

$url = "http://www.google.com/should-always-return-a-404";
$before_count = 0;
 $after_count = 0;

print "# Trying a nonexistent address, $url\n";

$resp = $browser->request( GET $url );
ok 1;

$browser->timing('1,2,3');
print "# Timing: ", $browser->timing, "\n";

print "# That gave: ", $resp->status_line, "\n";
print "# Before_count: $before_count\n";
ok $before_count, 1;
print "# After_count: $after_count\n";
ok $after_count,  1;


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
print "# Okay, bye from ", __FILE__, "\n";
ok 1;

