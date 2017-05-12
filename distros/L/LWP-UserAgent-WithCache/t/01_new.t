use strict;
use Test::More tests => 5;

use LWP::UserAgent::WithCache;
{
my $ua = LWP::UserAgent::WithCache->new(namespace => 'other_cache_namespace', timeout => 99);
is $ua->{cache}->get_namespace, 'other_cache_namespace';
is $ua->timeout, 99;
}

{
my $ua = LWP::UserAgent::WithCache->new({namespace => 'other_cache_namespace'}, timeout => 99);
is $ua->{cache}->get_namespace, 'other_cache_namespace';
is $ua->timeout, 99;
}

{
my $ua = LWP::UserAgent::WithCache->new(agent => 'Web::Scraper');
is $ua->{cache}->get_namespace, 'lwp-cache';
}

