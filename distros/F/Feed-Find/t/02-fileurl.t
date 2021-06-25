use strict;
use warnings;

use Test::More;

use FindBin '$RealBin';

use Feed::Find;

use constant BASE => "file://$RealBin/data/";

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
  is($feeds[0], "http://example.com/$test->{feed}", "find [$test->{label}]: It's the right feed");
}

