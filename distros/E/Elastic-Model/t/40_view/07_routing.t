#!/usr/bin/perl

use strict;
use warnings;
use Test::More 0.96;
use Test::Exception;
use Test::Deep;
use Test::Moose;

use lib 't/lib';

our ( $es, $store );
do 'es.pl';

use_ok 'MyApp' || print 'Bail out';

my $model = new_ok( 'MyApp', [ es => $es ], 'Model' );
ok my $ns = $model->namespace('myapp'), 'Got ns';

ok $ns->index('myapp2')->create, 'Create index myapp2';
ok $ns->alias()->to('myapp2'), 'Add index to ns';
ok $ns->alias('myapp3')->to( myapp2 => { routing => 'foo' } ),
    'Create alias myapp3';

ok my $doc = $model->domain('myapp3')->create( user => { name => 'John' } ),
    'Create routed doc';
ok $ns->index('myapp2')->refresh, 'Refresh index';

note "Routing from main alias";

is $model->view->domain('myapp')->search->first_result->uid->routing, 'foo',
    'search myapp/result';
is $model->view->domain('myapp')->search->first_object->uid->routing, 'foo',
    'search myapp/object';
is $model->view->domain('myapp')->include_paths('*')
    ->search->first_object->uid->routing, 'foo', 'search myapp/partial';

is $model->view->domain('myapp')->scroll->first_result->uid->routing, 'foo',
    'scroll myapp/result';
is $model->view->domain('myapp')->scroll->first_object->uid->routing, 'foo',
    'scroll myapp/object';
is $model->view->domain('myapp')->include_paths('*')
    ->scroll->first_object->uid->routing, 'foo', 'scroll myapp/partial';

is $model->view->domain('myapp')->scan->first_result->uid->routing, 'foo',
    'scan myapp/result';
is $model->view->domain('myapp')->scan->first_object->uid->routing, 'foo',
    'scan myapp/object';
is $model->view->domain('myapp')->include_paths('*')
    ->scan->first_object->uid->routing, 'foo', 'scan myapp/partial';

note "Routing from real index";

is $model->view->domain('myapp2')->search->first_result->uid->routing, 'foo',
    'search myapp2/result';
is $model->view->domain('myapp2')->search->first_object->uid->routing, 'foo',
    'search myapp2/object';
is $model->view->domain('myapp2')->include_paths('*')
    ->search->first_object->uid->routing, 'foo', 'search myapp2/partial';

is $model->view->domain('myapp2')->scroll->first_result->uid->routing, 'foo',
    'scroll myapp2/result';
is $model->view->domain('myapp2')->scroll->first_object->uid->routing, 'foo',
    'scroll myapp2/object';
is $model->view->domain('myapp2')->include_paths('*')
    ->scroll->first_object->uid->routing, 'foo', 'scroll myapp2/partial';

is $model->view->domain('myapp2')->scan->first_result->uid->routing, 'foo',
    'scan myapp2/result';
is $model->view->domain('myapp2')->scan->first_object->uid->routing, 'foo',
    'scan myapp2/object';
is $model->view->domain('myapp2')->include_paths('*')
    ->scan->first_object->uid->routing, 'foo', 'scan myapp2/partial';

note "Routing from filtered alias";

is $model->view->domain('myapp3')->search->first_result->uid->routing, 'foo',
    'search myapp3/result';
is $model->view->domain('myapp3')->search->first_object->uid->routing, 'foo',
    'search myapp3/object';
is $model->view->domain('myapp3')->include_paths('*')
    ->search->first_object->uid->routing, 'foo', 'search myapp3/partial';

is $model->view->domain('myapp3')->scroll->first_result->uid->routing, 'foo',
    'scroll myapp3/result';
is $model->view->domain('myapp3')->scroll->first_object->uid->routing, 'foo',
    'scroll myapp3/object';
is $model->view->domain('myapp3')->include_paths('*')
    ->scroll->first_object->uid->routing, 'foo', 'scroll myapp3/partial';

is $model->view->domain('myapp3')->scan->first_result->uid->routing, 'foo',
    'scan myapp3/result';
is $model->view->domain('myapp3')->scan->first_object->uid->routing, 'foo',
    'scan myapp3/object';
is $model->view->domain('myapp3')->include_paths('*')
    ->scan->first_object->uid->routing, 'foo', 'scan myapp3/partial';

done_testing;

__END__
