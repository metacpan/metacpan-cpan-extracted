use strict;
use warnings;

use Test::More tests => 14;
use HTTP::Request;
use Data::Dumper;

use HTTP::Async::Polite;
my $q = HTTP::Async::Polite->new;

# Check that we can set and get the interval.
is $q->send_interval, 5, "default interval is 5 seconds";
ok $q->send_interval(3), "change interval to 3 seconds";
is $q->send_interval, 3, "new interval is 3 seconds";

use FindBin;
use lib "$FindBin::Bin";
require TestServer;

my @servers   = map { TestServer->new() } 1 .. 2;
my @url_roots = ();

foreach my $s (@servers) {
    push @url_roots, $s->started_ok("starting a test server");
}

# Fire off three requests to two different servers. Check that the correct
# interval is observed between each request and that the two different servers
# were scaped in parallel. Also add another request so that the lists are not
# balanced.
my @urls =
  map {
    my $url_root = $_;
    my ($port) = $url_root =~ m/\d+$/g;
    my $number = $_ eq $url_roots[0] ? 3 : 4;
    my @ret = map { "$url_root/?set_time=$port-$_" } 1 .. $number;
    @ret;
  } @url_roots;

my @requests = map { HTTP::Request->new( GET => $_ ) } @urls;
ok $q->add(@requests), "Add the requests";

is $q->to_send_count, 5, "Got correct to_send count";
is $q->total_count,   7, "Got correct total count";

# Get all the responses.
my @responses = ();
while ( my $res = $q->wait_for_next_response ) {
    push @responses, $res;
}

is scalar(@responses), 7, "got six responses back";

# Extract the url and the timestamp from the responses;
my %data = ();
foreach my $res (@responses) {
    my ( $id, $timestamp ) = split /\n/, $res->content, 2;
    my ( $port, $number ) = split /-/, $id, 2;
    
    # Skip if the number is greater than 3 - extra req to test unbalanced list
    next if $number > 3;

    s/\s+//g for $port, $number, $timestamp;
    $data{$port}{$number} = $timestamp;
}

# diag Dumper \%data;

# Check that the requests did not come too close together.
my @first_times = ();
foreach my $port ( sort keys %data ) {

    my @times = sort { $a <=> $b } values %{ $data{$port} };

    my $last_time = shift @times;
    push @first_times, $last_time;

    foreach my $time (@times) {

        cmp_ok $time - $last_time, ">", 3,
          "at least three seconds between requests to same domain";

        $last_time = $time;
    }
}

# check that the first two requests were near each other.
cmp_ok abs( $first_times[0] - $first_times[1] ), "<", 1,
  "at most 1 second between first two requests";
