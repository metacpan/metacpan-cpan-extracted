package Test::Elasticsearch::Model::Document::Role::Metaclass;

use Test::Class::Most parent => 'Test';


sub basics : Tests(no_plan) {
    my $self          = shift;
    my $document_meta = TestModel::DocumentTypeA->meta;
    can_ok($document_meta, qw/
        _all_properties
        _build_all_properties
        _build_isa_arrayref
        _build_shortname
        _caller_info
        _isa_arrayref
        add_property
        mapping
        shortname
    /);
}

sub shortname : Tests(no_plan) {
    my $self = shift;
    for my $name (qw/A B C/) {
        my $document_class = "TestModel::DocumentType" . $name;
        (my $expected = $document_class) =~ s/TestModel:://g;
        is($document_class->meta->shortname, lc $expected, "My lazy built shortname is what I expect");
    }
}

1;
