#!perl

use strict;
use warnings;
use utf8;
use Interchange::Search::Solr;
use Data::Dumper;
use Test::More;
use Encode;

my $solr_url;
my $solr_enc = 'iso-8859-1';

my @localfields = (qw/sku
                      title
                      comment
                      description
                     /);

if ($ENV{SOLR_TEST_URL}) {
    $solr_url = $ENV{SOLR_TEST_URL};
}
else {
    plan skip_all => "Please set environment variable SOLR_TEST_URL.";
}

my $solr = Interchange::Search::Solr->new(solr_url => $solr_url,
                                          search_fields => \@localfields,
                                          input_encoding => $solr_enc);

my $url = encode($solr_enc, 'words/Ärmelbündchen');
$solr->search_from_url($url);

ok(scalar($solr->skus_found), "Found products");

done_testing;


