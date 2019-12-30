#!perl

use strict;
use warnings;

use Interchange::Search::Solr;
use Test::More;
use Test::Exception;

my $solr;

my @localfields = (qw/sku
                      title
                      comment
                     /);

if ($ENV{SOLR_TEST_URL}) {
    $solr = Interchange::Search::Solr->new(solr_url => $ENV{SOLR_TEST_URL},
                                           search_fields => \@localfields,
                                          );
}
else {
    plan skip_all => "Please set environment variable SOLR_TEST_URL.";
}

my ($response, $doc_count_start, $doc_count);

my $doc = {
    sku => '0815',
    title => 'boring',
};

# Do a commit
$response = $solr->commit;
ok ( $response->success, "Testing commit" ) || diag $response->exception_message;

# Count currently indexed documents
ok ( $solr->num_docs, "Number of documents: " . $solr->num_found );

# Add a document
$response = $solr->add([$doc]);
ok ( $response->success, "Testing add" ) || diag $response->exception_message;

# Count documents after add
ok ( $solr->num_docs, "Number of documents: " . $solr->num_found );

# Remove document
$response = $solr->delete(['sku:0815']);
ok ( $response->success, "Testing delete" ) || diag $response->exception_message;

# Count documents after delete
ok ( $solr->num_docs, "Number of documents: " . $solr->num_found );

done_testing;
