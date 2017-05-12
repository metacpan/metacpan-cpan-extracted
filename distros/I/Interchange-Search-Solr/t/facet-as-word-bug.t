#!perl

use strict;
use warnings;

use Interchange::Search::Solr;
use Data::Dumper;
use Test::More;
use Test::Exception;
use WebService::Solr::Query;

my $solr;

my @localfields = (qw/sku
                      title comment description
                      inactive
                     /);

if ($ENV{SOLR_TEST_URL}) {
    $solr = Interchange::Search::Solr->new(solr_url => $ENV{SOLR_TEST_URL},
                                           search_fields => \@localfields,
                                           facets => [qw/color size/]
                                          );
    plan tests => 28;
}
else {
    plan skip_all => "Please set environment variable SOLR_TEST_URL.";
}

$solr->search_from_url('/words/colors');
ok ($solr->num_found, "Results found for words/colors");
is ($solr->current_search_to_url, 'words/colors', "url correctly built");

my $res = $solr->search_from_url('/words/color/size');
is $solr->current_search_to_url, 'words/color/size', "uri built correctly";
is_deeply ($solr->search_terms, [qw/color size/], "Found color and size as terms");
ok ($res->ok, "Search ok") or diag Dumper($res);
ok ($solr->num_found, "Found some results");

$res = $solr->search_from_url("/words/color/size/XL/XXL/color/blue/yellow");
is_deeply ($solr->search_terms, [qw/color/], "Found color as term");
is_deeply ($solr->filters, {
                            size => [qw/XL XXL/],
                            color => [qw/blue yellow/],
                           }, "Filters found");
is ($solr->current_search_to_url, "words/color/color/blue/yellow/size/XL/XXL",
   "Built uri is predictable and keeps the ordering of the facets constructor");

foreach my $kw (qw/color size/) {
    $solr->search_from_url("/$kw");
    ok $solr->response->ok, "Response ok for /$kw";
    ok $solr->num_found, "Results found for /$kw";
    is_deeply $solr->search_terms, [$kw], "Found $kw as search term";
    is_deeply $solr->filters, {}, "No filters";
}

$solr->search_from_url('/words/size/XL/color/banana');
$solr->response->ok;
is_deeply $solr->search_terms, [qw/size/], "words prefix skip size as keyword and xl is too short";
is_deeply $solr->filters, { color => [qw/banana/] }, "color set the filter";
is $solr->current_search_to_url, "words/size/color/banana",
  "url built correctly";

$solr->search_from_url('/size/XL/color/banana');
$solr->response->ok;
is_deeply $solr->search_terms, [], "no words, only filters";
is_deeply $solr->filters, { color => [qw/banana/],
                            size => [qw/XL/],
                          }, "color and size with now /words set the filter";
is $solr->current_search_to_url, "color/banana/size/XL", "url built correctly";


$solr->search_from_url('/words/size/XL/color/banana/size');
ok $solr->response->ok, "response ok";
is_deeply $solr->search_terms, [qw/size/], "words prefix skip size as keyword and xl is too short";
is_deeply $solr->filters, { color => [qw/banana
                                         size/] },
  "color set the filter";
is $solr->current_search_to_url, "words/size/color/banana/size",
  "url built correctly";

$solr->response->ok;

$solr->facets(['nevairbe']);
throws_ok { $solr->search_from_url('/nevairbe/test') } qr/Solr failure: Bad Request/, "get exception with bad request";

