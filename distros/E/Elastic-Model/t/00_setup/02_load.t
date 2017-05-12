#!/usr/bin/perl

use strict;
use warnings;
use Test::More 0.96;
use Test::Moose;

use lib 't/lib';

BEGIN {
    use_ok 'Foo' || print 'Bail out';
}

my $model = new_ok 'Foo';
does_ok $model, 'Elastic::Model::Role::Model';

my $model_2 = new_ok 'Foo';
ok $model ne $model_2, 'Model instances separate';
note '';

note "Core classes";

my %classes = (
    typemap                => 'Elastic::Model::TypeMap::Default',
    namespace_class        => 'Elastic::Model::Namespace',
    domain_class           => 'Elastic::Model::Domain',
    store_class            => 'Elastic::Model::Store',
    view_class             => 'Elastic::Model::View',
    scope_class            => 'Elastic::Model::Scope',
    results_class          => 'Elastic::Model::Results',
    scrolled_results_class => 'Elastic::Model::Results::Scrolled',
    result_class           => 'Elastic::Model::Result',
);

for my $m ( $model, $model_2 ) {
    for ( sort keys %classes ) {
        ok my $class = $m->$_, "Has $_";
        isa_ok $class, $classes{$_}, $_;
        is $class->model, $m, "$_ has correct model";
        is $class->original_class, $classes{$_}, "$_ has original_class";
    }
}
note '';

note "Doc classes";
for my $m ( $model, $model_2 ) {
    for ( 'Foo::User', 'Foo::Post' ) {
        ok my $class = $m->class_for($_), "Has $_";
        isa_ok $class, $_, "class_for($_)";
        does_ok $class, 'Elastic::Model::Role::Doc',
            "class_for($_) is a doc class";
        is $class->model,          $m, "$_ has correct model";
        is $class->original_class, $_, "class_for($_) has original_class";
    }
}
note '';

note "Namespaces";
isa_ok $model->namespace('foo'), 'Elastic::Model::Namespace', 'Namespace foo';
isa_ok $model->namespace('bar'), 'Elastic::Model::Namespace', 'Namespace bar';
note '';

note 'View';
isa_ok $model->view, 'Elastic::Model::View', 'View';

note 'Other';
isa_ok $model->store, 'Elastic::Model::Store', 'store';
isa_ok $model->es, 'Search::Elasticsearch::Client::1_0::Direct', 'es';

done_testing;

__END__

