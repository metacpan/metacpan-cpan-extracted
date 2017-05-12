#!/usr/bin/perl

use strict;
use warnings;
use Test::More 0.96;
use Test::Exception;
use Test::Deep;

use lib 't/lib';

our ( $es, $store );
do 'es.pl';

use_ok 'MyApp' || print 'Bail out';

use Elastic::Model::Role::Store();
my $store_search = 0;
{

    package Elastic::Model::Role::Store;
    use Moose::Role;
    around 'search' => sub {
        my $orig = shift;
        my $self = shift;
        $store_search++;
        $self->$orig(@_);

    };

    package main;
}

my $model = new_ok( 'MyApp', [ es => $es ], 'Model' );
ok my $ns = $model->namespace('myapp'), 'Got ns';

create_users($model);

isa_ok my $domain = $model->domain('myapp'), 'Elastic::Model::Domain',
    'Domain';
isa_ok my $view = $domain->view, 'Elastic::Model::View', 'View';

isa_ok my $results = $view->cached_search, 'Elastic::Model::Results';

SKIP: {
    $store_search = 0;
    skip "CHI not available for testing", 26
        unless eval { require CHI };
    isa_ok my $cache = CHI->new( driver => 'Memory', global => 1 ),
        'CHI::Driver';
    ok $view = $view->cache($cache), 'Set cache';
    ok $view = $view->cache_opts( expire_in => '30 sec' ), 'Set cache opts';

    isa_ok $results = $view->cached_search, 'Elastic::Model::Results::Cached';
    is $results->total, 196, 'Total is OK';
    is $store_search, 1, 'From index';

    isa_ok $results = $view->cached_search, 'Elastic::Model::Results::Cached';
    is $results->total, 196, 'Total is OK';
    is $store_search, 1, 'From cache';

    ok $model->view->domain('myapp2')->delete, 'Delete users in myapp2';
    is $domain->view->search->total, '65', 'Total now 65';
    is $store_search, 2, 'From index';

    isa_ok $results = $view->cached_search, 'Elastic::Model::Results::Cached';
    is $results->total, 196, 'Total is cached';
    is $store_search, 2, 'From cache';

    isa_ok $results
        = $view->cached_search( force_set => 1, expires_in => '2 sec' ),
        'Elastic::Model::Results::Cached';
    is $results->total, 65, 'Total is refreshed';
    is $store_search, 3, 'From index';

    ok $domain->view->delete, 'Deleted all';

    isa_ok $results = $view->cached_search, 'Elastic::Model::Results::Cached';
    is $results->total, 65, 'Total is cached';
    is $store_search, 3, 'From cache';

    sleep 2;

    isa_ok $results = $view->cached_search, 'Elastic::Model::Results::Cached';
    is $results->total, 0, 'Total is refreshed';
    is $store_search, 4, 'From cache';

}

done_testing;

__END__
