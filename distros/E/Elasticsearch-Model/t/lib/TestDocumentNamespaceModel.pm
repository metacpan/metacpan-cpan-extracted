package TestDocumentNamespaceModel;

use Moose;
use Elasticsearch::Model;

my $document_types = {
    book => 'DocumentTypeA',
    magazine => 'DocumentTypeB',
};

for my $document_type (keys %$document_types) {
    index $document_type => (
        type => $document_types->{$document_type},
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

