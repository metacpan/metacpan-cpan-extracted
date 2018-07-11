package Test::Elasticsearch::Model::Document::Role;

use Test::Class::Most parent => 'Test';


sub basics :Tests(no_plan) {
    my $self = shift;
    my $doc_type_object = TestModel::DocumentTypeA->new;
    ok($doc_type_object->can("index"), "My document type object can use methods composed with Elasticsearch::Model::Document::Role");
}

1;

