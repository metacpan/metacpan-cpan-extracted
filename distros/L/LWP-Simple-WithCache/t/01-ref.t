use Test::More tests => 2;
use LWP::Simple::WithCache;
is(ref($LWP::Simple::ua), 'LWP::UserAgent::WithCache', '$LWP::Simple::ua is LWP::UserAgent::WithCache');
is(ref($LWP::Simple::ua->{cache}), 'Cache::FileCache', '$LWP::Simple::ua->{cache} is Cache::FileCache');
