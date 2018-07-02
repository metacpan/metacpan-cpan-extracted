package Test::Elasticsearch::Model::Document;

use Test::Class::Most parent => 'Test';
use Data::Printer;
use Test::Moose;

sub basics : Tests(no_plan) {
    my $self          = shift;
    for my $name (qw/A B C/) {
        my $doc_type_class = "TestModel::DocumentType" . $name;
        my $doc_type_meta = $doc_type_class->meta;
        does_ok(
            $doc_type_meta, "Elasticsearch::Model::Document::Role::Metaclass",
            "The document type's meta class consumes the Elasticsearch::Model::Document::Role::Metaclass role"
        );

        ok(
            $doc_type_meta->does_role("Elasticsearch::Model::Document::Role"),
            "The document type's initialized meta class consumes the Elasticsearch::Model::Document::Role"
        );

    }
}

1;
