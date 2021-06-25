use strict;
use warnings;

use Test::LWP::UserAgent;
use Test::More;

use HTTP::Response;
use FindBin '$RealBin';

use Feed::Find;

my %html = map {
  $_ => get_file("$_.html")
} qw[ link href ];

use constant BASE => 'http://example.com/';

my $ua = Test::LWP::UserAgent->new;
$Feed::Find::ua = $ua;

$ua->map_response(qr[example\.com/link],
  HTTP::Response->new(200, 'OK', [ 'Content-type' => 'text/html' ], $html{link}));
$ua->map_response(qr[example\.com/href],
  HTTP::Response->new(200, 'OK', [ 'Content-type' => 'text/html' ], $html{href}));

my @tests = ({
  label => 'link',
  feed  => 'feed/',
}, {
  label => 'href',
  feed  => 'feed.atom',
});

test_one($_) for @tests;

done_testing;

sub test_one {
  my ($test) = @_;

  my @feeds;

  @feeds = Feed::Find->find(BASE . "$test->{label}.html");
  is(scalar @feeds, 1, "find [$test->{label}]: Got 1 feed");
  is($feeds[0], BASE . $test->{feed}, "find [$test->{label}]: It's the right feed");

  @feeds = Feed::Find->find_in_html(\$html{$test->{label}}, BASE . "$test->{label}.html");
  is(scalar @feeds, 1, "find_in_html [$test->{label}]: Got 1 feed");
  is($feeds[0], BASE . $test->{feed}, "find_in_html [$test->{label}]: It's the right feed");
}

sub get_file {
  my ($fname) = @_;

  open my $fh, '<', "$RealBin/data/$fname" or die "$fname: $!\n";

  return do { local $/; <$fh> };
}
