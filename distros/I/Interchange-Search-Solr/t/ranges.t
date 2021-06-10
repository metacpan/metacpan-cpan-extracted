#!perl

use utf8;
use strict;
use warnings;
use Interchange::Search::Solr;
use Test::More;
use Data::Dumper;
my $solr;
if ($ENV{SOLR_TEST_URL}) {
    $solr = Interchange::Search::Solr->new(
                                           solr_url => $ENV{SOLR_TEST_URL},
                                           search_fields => [qw/sku title category/],
                                           facets => [qw/color/],
                                           facet_ranges => [
                                                            {
                                                             name => 'price',
                                                             start => 0,
                                                             end => 1000,
                                                             gap => 10,
                                                            }
                                                           ],
                                          );
    plan tests => 9;
}
else {
    plan skip_all => "Please set environment variable SOLR_TEST_URL.";
}
$solr->search_from_url('color/blue');
diag Dumper($solr->facets_found);
is $solr->num_found, 16, "color/blue";
diag Dumper($solr->facet_ranges_found);
$solr->search_from_url('color/blue/price/1/11');
my $res = $solr->results;
is $solr->num_found, 2, "color/blue/price/1/11";

is_deeply($solr->facet_ranges_found, { price => [ { count => 2, name => '10' } ], },
          "facet ranges found ok");
is $solr->current_search_to_url, "color/blue/price/1/11", "current url ok";
is_deeply($solr->facets_found,
          {
           color => [
                      { 
                       'query_url' => 'price/1/11',
                       'name' => 'blue',
                       'active' => 1,
                       'count' => 2
                      }
                    ]
          }, "facets found ok") or diag(Dumper($solr->facets_found));
is_deeply(($solr->breadcrumbs)[1],
          { facet => 'price', label => '1-11', uri => 'words/color/blue/price/1/11' },
          "breadcrumbs ok"
         );
is $solr->reset_facet_url('price'), 'color/blue', "Reset facet url works for price";
is $solr->reset_facet_url('color'), 'price/1/11', "Reset facet url works for color";

ok $solr->search_from_url('price/asdf/asdf'), "No crash with invalid range";


