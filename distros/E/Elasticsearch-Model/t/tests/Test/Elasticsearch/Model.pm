package Test::Elasticsearch::Model;

use Test::Class::Most parent => 'Test';
use Data::Printer;
use Test::Moose;

sub metaclass_methods : Tests(no_plan) {
    my $self = shift;

    for my $method (qw/index analyzer tokenizer normalizer filter/) {
        can_ok("TestModel", $method);
    }
}

sub es :Tests(no_plan) {
    my $self = shift;
    my $model = TestModel->new;
    does_ok($model->es, "Search::Elasticsearch::Role::Client::Direct");
}

sub document_namespace : Tests(no_plan) {
    my $self               = shift;
    my $model              = TestModel->new;
    my $document_namespace = $model->document_namespace;
    is(
        $document_namespace, 'TestModel',
        "My default document_namespace is what it should be"
    );
    my $model2 = TestModel->new(document_namespace => 'Moonbeam');
    my $document_namespace2 = $model2->document_namespace;
    is($document_namespace2, 'Moonbeam', "But I can also set it");
}

sub has_document_namespace :Tests(no_plan) {
    my $self = shift;
    my $model3 = TestDocumentNamespaceModel->new;
    is($model3->document_namespace, 'TestModel', "I can set namespace declaratively in model class");
}

sub document_types : Tests(no_plan) {
    my $self           = shift;
    my $model          = TestModel->new;
    my $document_types = [sort @{$model->document_types}];
    my $expected       = [
        "TestModel::DocumentTypeA",
        "TestModel::DocumentTypeB",
        "TestModel::DocumentTypeC",
    ];

    is_deeply($document_types, $expected, "I have the expected document types");
}

sub filters : Tests(no_plan) {
    my $self     = shift;
    my @filters  = TestModel->meta->get_filters;
    my $expected = [
        {
            max_gram => 24,
            min_gram => 1,
            type     => "edge_ngram"
        }
    ];
    is_deeply(\@filters, $expected, "My filter is as expected");
    my @filter_list = TestModel->meta->get_filter_list;
    is($filter_list[0], 'filtration', "My filter name is as expected");
}

sub normalizers : Tests(no_plan) {
    my $self        = shift;
    my @normalizers = TestModel->meta->get_normalizers;
    my $expected    = [
        {
            type   => 'custom',
            filter => ["lowercase"],
        }
    ];
    is_deeply(\@normalizers, $expected, "My normalizer is as expected");
    my @normalizer_list = TestModel->meta->get_normalizer_list;
    is($normalizer_list[0], "normie", "My normalizer name is as expected");
}

sub analyzers : Tests(no_plan) {
    my $self      = shift;
    my @analyzers = TestModel->meta->get_analyzers;
    my $expected  = [
        {
            type      => 'custom',
            filter    => ["lowercase", "filtration"],
            tokenizer => "standard",
        }
    ];
    is_deeply(\@analyzers, $expected, "My analyzer is as expected");
    my @analyzer_list = TestModel->meta->get_analyzer_list;
    is($analyzer_list[0], "electro", "My analyzer name is as expected");
}

sub tokenizers : Tests(no_plan) {
    my $self      = shift;
    my @tokenizers = TestModel->meta->get_tokenizers;
    my $expected  = [
        {
            type      => 'simple_pattern',
            pattern => "[0123456789]{3}"
        }
    ];
    is_deeply(\@tokenizers, $expected, "My tokenizer is as expected");
    my @tokenizer_list = TestModel->meta->get_tokenizer_list;
    is($tokenizer_list[0], "splat", "My tokenizer name is as expected");
}

sub deploy :Tests(no_plan) {
    my $self = shift;
    SKIP: {
        skip "No live elasticsearch server" unless $self->live_testing_ok;
        my $model = TestModel->new;
        lives_ok { $model->deploy(delete => 1) } "I can deploy my model";
    };
}

1;
