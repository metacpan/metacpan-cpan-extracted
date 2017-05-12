#!/usr/bin/perl

use lib "lib";
use HTML::Microformats;
use strict;
use JSON;
use LWP::Simple qw(get);
use Data::Dumper;
use RDF::TrineShortcuts;

my $uri  = 'http://csarven.ca/cv';
my $html = get($uri);
utf8::upgrade($html);

my $doc  = HTML::Microformats->new_document($html, $uri);
$doc->assume_all_profiles;

my @resumes = $doc->objects('hResume');
my $resume  = $resumes[0];

# print to_json($resume, {pretty=>1, convert_blessed=>1});
print rdf_string($resume->model, 'rdfxml');
