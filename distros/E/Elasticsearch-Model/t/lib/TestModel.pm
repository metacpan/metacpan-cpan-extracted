package TestModel;

use Moose;
use Elasticsearch::Model;

my $document_types = {
    a => 'DocumentTypeA',
    b => 'DocumentTypeB',
    c => 'DocumentTypeC',
};

my $index_settings = {
    number_of_shards   => 2,
    number_of_replicas => 2,
    refresh_interval   => '2s',
    blocks => {
        read_only_allow_delete => 'false',
    },
    max_result_window => 100000,
};
for my $document_type (keys %$document_types) {
    index $document_type => (
        namespace => 'test_elasticsearch_model',
        type => $document_types->{$document_type},
        shards   => 1,
        replicas => 1,
        refresh_interval   => '1s',
        blocks => {
            read_only_allow_delete => 'false',
        },
        index_settings => $index_settings,
    );
}

normalizer normie => (
    type   => "custom",
    filter => ["lowercase"],
);

filter filtration => (
    type     => "edge_ngram",
    min_gram => 1,
    max_gram => 24,
);

analyzer electro => (
    type      => "custom",
    tokenizer => "standard",
    filter    => ["lowercase", "filtration"],
);

tokenizer splat => (
    type    => "simple_pattern",
    pattern => "[0123456789]{3}",
);

__PACKAGE__->meta->make_immutable;

1;
