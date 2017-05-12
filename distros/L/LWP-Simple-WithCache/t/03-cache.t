use Test::More tests => 3;
use LWP::Simple;
use LWP::Simple::WithCache;
use strict;

my $url = 'http://www.google.com';

$LWP::Simple::ua->{cache}->remove($url);
is(undef, $LWP::Simple::ua->{cache}->get($url), 'cache miss');
isnt(undef, get($url), 'LWP::Simple::get');
isnt(undef, $LWP::Simple::ua->{cache}->get($url), 'cache hit');
