#!/usr/bin/perl

use lib "lib";
use HTML::Microformats;
use LWP::Simple qw[get];
use RDF::TrineShortcuts;

print "## " . JSON::to_json([HTML::Microformats->formats]) . "\n";

my $uri  = 'http://microformats.org/profile/hcard';
my $html = get($uri);
my $doc  = HTML::Microformats->new_document($html, $uri);
$doc->assume_all_profiles;

my @xmdp_objects = $doc->objects('XMDP');

 foreach my $xo (@xmdp_objects)
 {
   print $xo->serialise_model(
       as         => 'Turtle',
       namespaces => {
           rdfs  => 'http://www.w3.org/2000/01/rdf-schema#',
           hcard => 'http://microformats.org/profile/hcard#',
           },
       );
   print "########\n\n";
 }

