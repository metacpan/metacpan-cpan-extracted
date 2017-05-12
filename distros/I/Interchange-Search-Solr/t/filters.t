#!perl

use utf8;
use strict;
use warnings;

use Interchange::Search::Solr;
use Test::More;
use Data::Dumper;

my @localfields = (qw/sku
                      title
                      comment_en comment_fr
                      comment_nl comment_de
                      comment_se comment_es
                      description_en description_fr
                      description_nl description_de
                      description_se description_es/);
my $solr;

if ($ENV{SOLR_TEST_URL}) {
    $solr = Interchange::Search::Solr->new(solr_url => $ENV{SOLR_TEST_URL},
                                           search_fields => \@localfields,
                                          );
}
else {
    plan skip_all => "Please set environment variable SOLR_TEST_URL.";
}

ok($solr, "instance ok");
$solr->search('boot');
my $facets = $solr->facets_found;
is (ref($facets), 'HASH', "Facets is an hahsref");
# diag Dumper($facets);
$solr->facets([qw/manufacturer/]);
$solr->search('shirt');
is_deeply ($solr->facets, [qw/manufacturer/], "facets can be changed");
$facets = $solr->facets_found;
is (ref($facets), 'HASH', "and is an hashref again") or diag Dumper($facets);

# pick the first
my $filter = $facets->{manufacturer}->[0]->{name};
ok($filter, "Filter is $filter") or diag Dumper($filter);

done_testing;





