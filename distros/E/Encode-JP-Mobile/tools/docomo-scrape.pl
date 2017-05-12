#!/usr/bin/perl
use strict;
use warnings;
use HTML::Selector::XPath 0.03;
use Web::Scraper;
use URI;
use YAML;

my @url = (
    URI->new("http://www.nttdocomo.co.jp/service/imode/make/content/pictograph/basic/index.html"),
    URI->new("http://www.nttdocomo.co.jp/english/service/imode/make/content/pictograph/basic/index.html"),
    URI->new("http://www.nttdocomo.co.jp/service/imode/make/content/pictograph/extention/index.html"),
    URI->new("http://www.nttdocomo.co.jp/english/service/imode/make/content/pictograph/extention/index.html"),
);

my $res;
my $i;
my @prev;
for my $uri (@url) {
    my $scraper = scraper {
        process 'tr', 'characters[]', scraper {
            process 'td:nth-child(1)', 'number', 'TEXT';
            process 'td:nth-child(2) > img', 'image', [ '@src', sub { $_->as_string } ];
            process 'td:nth-child(3)', 'sjis', 'TEXT';
            process 'td:nth-child(5)', 'unicode', 'TEXT';
            process 'td:nth-child(6)', 'name',  'TEXT';
        };
    };
    my @chars = @{ $scraper->scrape($uri)->{characters} };

    # remove headers
    shift @chars; shift @chars;

    if (++$i % 2) {
        @prev = @chars;
    } else {
        @prev == @chars or die "ja/en count doesn't match";
        for my $c (0..$#prev) {
            $prev[$c]->{name_en} = $chars[$c]->{name};
        }
        push @$res, @prev;
    }
}

binmode STDOUT, ":utf8";
print Dump($res);

