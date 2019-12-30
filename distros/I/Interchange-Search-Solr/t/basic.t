#!perl

use utf8;
use strict;
use warnings;

use Interchange::Search::Solr;
use Test::More;
use Data::Dumper;

my $solr;

# given that we test against a specific database/instance, we have to
# set the fields

my @localfields = (qw/sku
                      title
                      comment
                      description
                     /);

if ($ENV{SOLR_TEST_URL}) {
    $solr = Interchange::Search::Solr->new(
                                           solr_url => $ENV{SOLR_TEST_URL},
                                           search_fields => \@localfields,
                                          );
}
else {
    plan skip_all => "Please set environment variable SOLR_TEST_URL.";
}

ok($solr, "Object created");
ok($solr->solr_object, "Internal Solr instance ok");
$solr->start(3);
$solr->rows(2);
$solr->permit_empty_search(1);
$solr->search();
is ($solr->search_string, '*', "Empty search returns everything");
is ($solr->permit_empty_search, 0, "permit empty search reset");
ok ($solr->num_found, "Found results") and diag "Results: " . $solr->num_found;

my $res = $solr->search();
is ($solr->search_string, '*', "Empty search string");
is ($solr->permit_empty_search, 0, "permit empty search reset");
ok (!$solr->num_found, "No results found") and diag "Results: " . $solr->num_found;
ok ($res->is_empty_search);


$solr->search("desc hat");
ok ($solr->response->ok);
ok (!$solr->response->error, "No error found");
ok ($solr->response->isa('Interchange::Search::Solr::Response'),
    "response is Interchange::Search::Solr::Response");

like $solr->search_string, qr/\(desc\* AND hat\*\)/,
  "Search string interpolated" . $solr->search_string;

is_deeply ($solr->search_terms, [qw/desc hat/], "Search terms saved");

diag "Calling response->docs\n";
ok ($solr->response->ok, "Response is ok");
my @results = @{$solr->results};
# print Dumper(\@results);
is (scalar(@results), 2, "Found 2 results");

$solr->rows(3);
$solr->search("hat");
my @skus = $solr->skus_found;

diag $solr->num_found;
ok ($solr->num_found > 6, "Found more than 10 results");
ok ($solr->has_more, "Has more products");
# print Dumper(\@skus);

is (scalar(@skus), 3, "Found 3 skus");

foreach my $sku (@skus) {
    is (ref($sku), '', "$sku is a scalar");
}

$solr->start($solr->num_found);
$solr->search("hat");
ok (!$solr->has_more, "No more products starting at " .  $solr->start);

$solr->start('pippo');
$solr->rows('ciccia');
$solr->search("hat");
ok $solr->num_found, "Found results with messed up start/rows";
ok $solr->has_more, "And has more";

done_testing;
