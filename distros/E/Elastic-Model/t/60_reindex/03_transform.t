#!/usr/bin/perl

use strict;
use warnings;
use Test::More 0.96;
use Test::Exception;
use Test::Deep;

use lib 't/lib';

our $es;
do 'es.pl';

use_ok 'MyApp' || print 'Bail out';

my $model = new_ok( 'MyApp', [ es => $es ], 'Model' );
ok my $ns = $model->namespace('myapp'), 'Got ns';

my @users = create_users($model);

# Reindex, transforming timestamp
isa_ok my $new = $ns->index('myapp4'), 'Elastic::Model::Index', 'New index';

ok $new->reindex(
    'myapp',
    transform => sub {
        my $doc = shift;
        $doc->{_source}{timestamp} += 1000;
        return $doc;
    },
    ),
    'Reindexed myapp to myapp4';
$new->refresh;

my $view = $model->view->facets(
    timestamp => { statistical => { field => 'timestamp' } } )->size(0);
my $old_facet = $view->domain('myapp')->search->facet('timestamp');
my $new_facet = $view->domain('myapp4')->search->facet('timestamp');

is $new_facet->{min}, $old_facet->{min} + 1000, 'Min timestamp changed';
is $new_facet->{max}, $old_facet->{max} + 1000, 'Max timestamp changed';

done_testing;
