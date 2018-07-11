package Test::Elasticsearch::Model::Role;

use Test::Class::Most parent => 'Test';
use Test::Moose;



sub basics :Tests(no_plan) {
    my $self = shift;
    my $class = "TestModel";
    does_ok($class, "Elasticsearch::Model::Role", "My model class does Elasticsearch::Model::Role");
}

1;
