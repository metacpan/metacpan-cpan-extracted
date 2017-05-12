#!perl

use strict;
use warnings;

use Interchange::Search::Solr;
use Data::Dumper;
use Test::More;

my $solr;

my @localfields = (qw/sku
                      title comment description
                     /);

if ($ENV{SOLR_TEST_URL}) {
    $solr = Interchange::Search::Solr->new(solr_url => $ENV{SOLR_TEST_URL},
                                           search_fields => \@localfields,
                                          );
    plan tests => 4;
}
else {
    plan skip_all => "Please set environment variable SOLR_TEST_URL.";
}

my $testurl = 'words/creepy/shiny/boot/suchbegriffe/xxxxx/yyyy/manufacturer/pikeur/page/2';

$solr->search_from_url($testurl);

is ($solr->current_search_to_url, $testurl);

is_deeply([$solr->breadcrumbs],
          [
           {
            uri => 'words/creepy',
            label => 'creepy',
           },
           {
            uri => 'words/creepy/shiny',
            label => 'shiny',
           },
           {
            uri => 'words/creepy/shiny/boot',
            label => 'boot',
           },
           {
            uri => 'words/creepy/shiny/boot/suchbegriffe/xxxxx',
            facet => 'suchbegriffe',
            label => 'xxxxx',
           },
           {
            uri => 'words/creepy/shiny/boot/suchbegriffe/xxxxx/yyyy',
            facet => 'suchbegriffe',
            label => 'yyyy',
           },
           {
            uri => 'words/creepy/shiny/boot/suchbegriffe/xxxxx/yyyy/manufacturer/pikeur',
            facet => 'manufacturer',
            label => 'pikeur',
           }
          ], "Breadcrumbs ok");

is_deeply([$solr->remove_word_links],
          [
           {
            uri => 'words/shiny/boot/suchbegriffe/xxxxx/yyyy/manufacturer/pikeur',
            label => 'creepy',
           },
           {
            uri => 'words/creepy/boot/suchbegriffe/xxxxx/yyyy/manufacturer/pikeur',
            label => 'shiny',
           },
           {
            uri => 'words/creepy/shiny/suchbegriffe/xxxxx/yyyy/manufacturer/pikeur',
            label => 'boot',
           },
          ], "Remove words links ok");

is $solr->clear_words_link, 'suchbegriffe/xxxxx/yyyy/manufacturer/pikeur',
  "Clear words link ok";

print Dumper($solr->filters, $solr->search_terms);
