#!usr/bin/env perl
use strict;
use Test::More;

use HTTP::Thin::UserAgent;
use Test::Requires::Env qw(
  LIVE_HTTP_TESTS
);


{
    my $uri = 'http://www.imdb.com/find?q=Kevin+Bacon';
    ok my $data = http( GET $uri )->find('.findResult'), 'found .findResult';
}
done_testing;
