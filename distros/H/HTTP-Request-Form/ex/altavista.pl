#!/usr/bin/perl -w

use strict;
use HTML::TreeBuilder;
use URI::URL;
use LWP::UserAgent;
use HTTP::Request;
use HTTP::Request::Common;
use HTTP::Request::Form;

my $ua = LWP::UserAgent->new;
my $url = url 'http://www.altavista.com/';
my $res = $ua->request(GET $url);
my $tb = HTML::TreeBuilder->new;
$tb->parse($res->content);
my @forms = @{$tb->extract_links(qw(FORM))};
my $f = HTTP::Request::Form->new($forms[0][1], $url);
$f->field("q", "perl");
my $response = $ua->request($f->press("search"));
print $response->content if ($response->is_success);
