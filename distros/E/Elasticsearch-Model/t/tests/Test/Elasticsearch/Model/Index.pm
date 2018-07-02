package Test::Elasticsearch::Model::Index;

use Test::Class::Most parent => 'Test';
use Data::Printer;

sub basics :Tests(no_plan) {
    my $self = shift;
    my $model = TestModel->new;
    for my $name (qw/a b c/) {
        my $index = $model->index($name);
        can_ok($index, qw/
            delete
            deployment_statement
            document_namespace
            es
            model
            name
            refresh
            refresh_interval
            replicas
            shards
            traits
            type
            type_meta
        /);
    }
}

sub document_namespace :Tests(no_plan) {
    my $self = shift;
    my $model = TestModel->new;
    for my $name (qw/a b c/) {
        my $index = $model->index($name);
        is($index->document_namespace, 'TestModel', "My document class namespace is correct");
    }
    my $model2 = TestModel->new(document_namespace => 'OtherTestModelClasses');
    for my $name (qw/a b c/) {
        my $index = $model2->index($name);
        is($index->document_namespace, 'OtherTestModelClasses', "A new document_namespace is passed to the index when changed in the model");
        is(scalar(keys %{$index->deployment_statement->{mappings}{_doc}{properties}}), 0, "There are no mappings for the class in the new namespace, because that class is empty");
    }
}

sub refresh :Tests(no_plan) {
    my $self = shift;
    SKIP: {
        skip "No live elasticsearch server" unless $self->live_testing_ok;
        my $model = TestModel->new;
        $model->deploy(delete => 1);
        for my $name (qw/a b c/) {
            my $index = $model->index($name);
            lives_ok { $index->refresh } "I can call refresh on my index";
        }
    };
}

sub delete :Tests(no_plan) {
    my $self = shift;
    SKIP: {
        skip "No live elasticsearch server" unless $self->live_testing_ok;
        my $model = TestModel->new;
        $model->deploy(delete => 1);
        for my $name (qw/a b c/) {
            my $index = $model->index($name);
            lives_ok { $index->delete } "I can call delete on my index";
        }
    };
}

sub deploy_to :Tests(no_plan) {
    my $self = shift;
    SKIP: {
        skip "No live elasticsearch server" unless $self->live_testing_ok;
        my $model = TestModel->new;
        for my $name (qw/a b c/) {
            my $index = $model->index($name);
            my $versioned_index_name = $name . "_" . time();
            lives_ok { $index->deploy_to(index_name => $versioned_index_name) } "I can call deploy_to with a specific index name on my index";
            lives_ok { $index->delete(index => $versioned_index_name) } "I can delete the index by giving the specific index name";
        }
    };
}

1;
