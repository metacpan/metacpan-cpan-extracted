package Test::Elasticsearch::Model::Role::Metaclass;

use Test::Class::Most parent => 'Test';
use Test::Moose;


sub basics : Tests(no_plan) {
    my $self       = shift;
    my $model_meta = TestModel->meta;
    does_ok($model_meta, "Elasticsearch::Model::Role::Metaclass");

    my %features = (
        analyzer   => 'analyzers',
        tokenizer  => 'tokenizers',
        filter     => 'filters',
        normalizer => 'normalizers',
        index      => 'indices',
    );

    my @generated_methods = ();
    while (my ($feature, $plural) = each %features) {
        push @generated_methods, (
            "get_$feature",
            "get_$plural",
            "get_${feature}_list",
            "remove_$feature",
            "add_$feature",
        );
    }
    can_ok($model_meta, @generated_methods);
}

sub namespaced_name_for_original_name :Tests(no_plan) {
    my $self = shift;
    my $model_meta = TestModel->meta;
    my $expected = {
        a  => "test_elasticsearch_model_a",
        b  => "test_elasticsearch_model_b",
        c  => "test_elasticsearch_model_c"
    };
    is_deeply($model_meta->namespaced_name_for_original_name, $expected, "My namespaced indexes hash is what I expect");
}

1;
