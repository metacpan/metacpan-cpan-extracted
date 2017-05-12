#!/usr/bin/env perl

use strict;
use warnings;

# VERSION

use lib qw{../lib lib};
use HTML::ExtractText;
use Mojo::UserAgent;

@ARGV or die "Usage: $0 www.example.com\n";

my $ua = Mojo::UserAgent->new->get( shift );

my $extractor = HTML::ExtractText->new;
$extractor->extract(
    {
        title => 'title',
        external_links => 'a:not([href~="example.com"])[href^="http"]',
    },
    $ua->res->body,
) or die "Extraction error: $extractor";

print "Title is: $extractor->{title}\n\n",
    "External links: $extractor->{external_links}\n";
