use Test::More tests => 3;
use LWP::Simple;
use LWP::Simple::WithCache;
use Data::Dumper;
use strict;

my $url = 'http://www.example.com';

$LWP::Simple::ua->{cache}->remove($url);
is(undef, $LWP::Simple::ua->{cache}->get($url), 'cache miss');
ok(get($url) =~ /Example Domain/, 'LWP::Simple::get');
ok($LWP::Simple::ua->{cache}->get($url)->{as_string} =~ /Example Domain/, 'cache hit:' . Dumper($LWP::Simple::ua->{cache}->get($url)->{as_string}));
