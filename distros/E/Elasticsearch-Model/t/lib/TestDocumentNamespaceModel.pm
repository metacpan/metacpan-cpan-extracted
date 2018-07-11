package TestDocumentNamespaceModel;

use Moose;
use Elasticsearch::Model;

my $document_types = {
    book => 'DocumentTypeA',
    magazine => 'DocumentTypeB',
};

my $index_settings = {
    number_of_shards   => 1,
    number_of_replicas => 1,
    refresh_interval   => '1s',
    blocks => {
        read_only_allow_delete => 'false',
    },
    max_result_window => 100000,
};

for my $document_type (keys %$document_types) {
    index $document_type => (
        type => $document_types->{$document_type},
        index_settings => $index_settings,
    );
}

filter filtration => (
    type     => "edge_ngram",
    min_gram => 1,
    max_gram => 24,
);

has_document_namespace "TestModel";

__PACKAGE__->meta->make_immutable;

1;

