#!/usr/bin/perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib/";
use Web::Scraper;
use URI;
use Benchmark 'cmpthese';
use LWP::UserAgent;
use HTML::TreeBuilder::LibXML;

my $html = get_content();
my $scraper = scraper {
    process 'a > img', 'image[]' => '@src';
};

print "Web::Scraper: $Web::Scraper::VERSION\n";
print "HTML::TreeBuilder::XPath: $HTML::TreeBuilder::XPath::VERSION\n";
print "HTML::TreeBuilder::LibXML: $HTML::TreeBuilder::LibXML::VERSION\n";
cmpthese(50, {
    no_libxml  => \&no_libxml,
    use_libxml => \&use_libxml,
});

sub no_libxml {
    my $res = $scraper->scrape($html);
}

sub use_libxml {
    local *HTML::TreeBuilder::XPath::new = sub {
        HTML::TreeBuilder::LibXML->new();
    };
    my $res = $scraper->scrape($html);
}

sub get_content {
    my $ua = LWP::UserAgent->new;
    my $res = $ua->get('http://www.nicovideo.jp/');
    $res->is_success or die 'cannot get html';
    $res->content;
}

