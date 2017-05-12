#!/usr/bin/perl

use strict;
use warnings;

use HTML::Grabber;
use LWP::Simple;

my $dom = HTML::Grabber->new( html => get('http://twitter.com/ned0r') );

$dom->find('.tweet-content')->each(sub {
    my $body = $_->find('.tweet-text')->text;
    my $when = $_->find('.js-tweet-timestamp')->attr('data-time');
    my $link = $_->find('.js-permalink')->attr('href');
    print "$body $when (link: $link)\n";
});

