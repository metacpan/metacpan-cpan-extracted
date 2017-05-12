#!/usr/bin/perl

use 5.010;
use strict;

use HTML::Microformats;
use LWP::Simple qw(get);

my $uri  = shift @ARGV or die "Please provide URI\n";
my $html = get($uri);
my $doc  = HTML::Microformats->new_document($html, $uri);
$doc->assume_all_profiles;

say $doc->json(pretty => 1, canonical => 1);
