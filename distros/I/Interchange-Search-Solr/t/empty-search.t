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

if ($ENV{SOLR_TEST_URL}) {
    $solr = Interchange::Search::Solr->new(
                                           solr_url => $ENV{SOLR_TEST_URL},
                                          );
}
else {
    plan skip_all => "Please set environment variable SOLR_TEST_URL.";
}

ok($solr->stop_words);
ok($solr->stop_words->{the}, "stopwords found");

foreach my $term (qw/the ours bb aa 1 c..b/) {
    ok(!$solr->_term_is_good($term), "$term is not good");
}
foreach my $term (qw/aaa bbb xlxl t.c.t/) {
    ok($solr->_term_is_good($term), "$term is good");
}


done_testing;
