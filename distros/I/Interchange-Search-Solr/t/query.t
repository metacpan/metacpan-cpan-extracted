#!perl

use strict;
use warnings;

use Interchange::Search::Solr;
use Data::Dumper;
use Test::More;

my $solr;

my @localfields = (qw/sku
                      title
                      comment description
                     /);

if ($ENV{SOLR_TEST_URL}) {
    $solr = Interchange::Search::Solr->new(solr_url => $ENV{SOLR_TEST_URL},
                                           search_fields => \@localfields,
                                          );
}
else {
    plan skip_all => "Please set environment variable SOLR_TEST_URL.";
}

$solr->search_from_url('/the/boot/i/like/suchbegriffe/xxxxx/yyyy/manufacturer/piko/page/2');

is_deeply($solr->search_terms, [qw/boot like/], "Search terms picked up ok");
is($solr->start, 10, "Start computed correctly"), # we have to start at 0
is($solr->page, 2, "Page picked up");
is_deeply($solr->filters, {
                           suchbegriffe => [qw/xxxxx yyyy/],
                           manufacturer => [qw/piko/],
                          });

is (scalar($solr->skus_found), 0, "No sku found with this query");

# reverse the order of facets
$solr->facets([qw/manufacturer suchbegriffe/]);

is $solr->current_search_to_url,
  'words/boot/like/manufacturer/piko/suchbegriffe/xxxxx/yyyy/page/2',
  "Url resolves correctly";


$solr->search_from_url('/boot');
my @skus = $solr->skus_found;
ok (scalar(@skus), "Found some results with /boot");

$solr->search('boot');
is_deeply([ $solr->skus_found] , \@skus, "same result");

$solr->rows(3);
$solr->search_from_url('/shirt/manufacturer/piko');
@skus = $solr->skus_found;
ok (scalar(@skus), "Found some results with /shirt/manufacturer/piko")
  or die "Search is broken";
diag "Found " . scalar(@skus) . " skus";
ok ($solr->has_more, "And has more");
ok ($solr->num_found, "Total: " . $solr->num_found);

$solr->search_from_url('/shirt');

my @links = map { $_->[0]->{query_url} }  values %{ $solr->facets_found };

like $links[0], qr{words/shirt/.+/.+}, "Found the filter link $links[0]"
  or diag Dumper($solr->response);


$solr->permit_empty_search(1);
$solr->search_from_url('/');

@links = map { $_->[0]->{query_url} }  values %{ $solr->facets_found };

like $links[0], qr{.+/.+}, "Found the filter link $links[0]";

$solr->search_from_url('/manufacturer/piko');

# this test is fragile because it depends on the db

my %paginator = %{$solr->paginator};

my $lastpage = delete $paginator{last};

like $lastpage, qr{manufacturer/piko/page/\d+}, "Found last page";



is_deeply(\%paginator,
          {
           next => 'manufacturer/piko/page/2',
           next_page => 2,
           last_page => 4,
           'items' => [
                       {
                        'current' => 1,
                        name => 1,
                        'url' => 'manufacturer/piko'
                       },
                       {
                        'url' => 'manufacturer/piko/page/2',
                        name => 2,
                       },
                       {
                        'url' => 'manufacturer/piko/page/3',
                        name => 3,
                       },
                       {
                        'url' => 'manufacturer/piko/page/4',
                        name => 4,
                       },
                      ],
           total_pages => 4,
          });


is($solr->facets_found->{manufacturer}->[0]->{query_url}, '',
   "After querying a manufacturer, removing the bit would reset the search");
is($solr->facets_found->{manufacturer}->[0]->{active}, 1,
   "The filter is active") or diag Dumper($solr->facets_found);

like ($solr->facets_found->{suchbegriffe}->[0]->{query_url},
      qr/suchbegriffe/, "Found the suchbegriffe keyword in the url")
  or diag $solr->facets_found->{suchbegriffe}->[0]->{query_url};

$solr->rows(1000);
$solr->search_from_url('/shirt/manufacturer/piko');
@skus = $solr->skus_found;
is (scalar(@skus), $solr->num_found, "Skus reported and returned match");
# print Dumper($solr);

$solr->search_from_url('/words/shirt/fashion/manufacturer/piko');

ok (scalar($solr->skus_found), "Found some results");

is_deeply($solr->terms_found, {
                               reset => 'manufacturer/piko',
                               terms => [
                                         {
                                          term => 'shirt',
                                          url => 'words/fashion/manufacturer/piko',
                                         },
                                         {
                                          term => 'fashion',
                                          url => 'words/shirt/manufacturer/piko',
                                         },
                                        ],
                              }, "struct ok");


$solr->search_from_url('/words/shirt/fashion');

ok (scalar($solr->skus_found), "Found some results");

is_deeply($solr->terms_found, {
                               reset => '',
                               terms => [
                                         {
                                          term => 'shirt',
                                          url => 'words/fashion',
                                         },
                                         {
                                          term => 'fashion',
                                          url => 'words/shirt',
                                         },
                                        ],
                              }, "struct ok");


is ($solr->add_terms_to_url('words/pippo', qw/pluto paperino  ciccia/),
    "words/pippo/pluto/paperino/ciccia");

done_testing;

