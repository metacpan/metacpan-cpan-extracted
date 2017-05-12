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

create_users($model);

isa_ok my $view = $model->view( domain => 'myapp' ), 'Elastic::Model::View',
    'View';
isa_ok my $search = $view->filterb( -ids => 1 )->search,
    'Elastic::Model::Results', 'Search';

## Basic result ##
isa_ok
    my $result = $search->first,
    'Elastic::Model::Result',
    'Result';

cmp_deeply
    [ keys %{ $result->result } ],
    bag(qw(_id _index _score _source _type _version)),
    'Result->result';

is $result->score, 1, 'Result->score';

cmp_deeply
    [ keys %{ $result->source } ],
    bag( 'name', 'timestamp' ),
    'Result->source';

isa_ok my $uid = $result->uid, 'Elastic::Model::UID', 'Result->uid';
is $uid->index,      'myapp2', 'uid->index';
is $uid->type,       'user',   'uid->type';
is $uid->id,         1,        'uid->id';
is $uid->version,    1,        'uid->version';
is $uid->from_store, 1,        'uid->from_store';
is $uid->routing,    undef,    'uid->routing';

isa_ok my $object = $result->object, 'MyApp::User', 'Result->object';
does_ok $object, 'Elastic::Model::Role::Doc', 'Result->object';
cmp_deeply $object->uid, $uid, 'Object->uid';

cmp_deeply $result->fields,     {}, 'Result->fields';
cmp_deeply $result->highlights, {}, 'Result->highlights';
cmp_deeply
    [ $result->highlight('foo') ],
    [],
    'Result->highlight(foo)';
throws_ok
    sub { $result->highlight },
    qr/Missing/,
    'Result->highlight';

like $result->explain, qr/No explanation/, 'Result->explain';

## Advanced result ##
isa_ok $result = $view->queryb( { name => 'Aardwolf' } )    #
    ->filterb( -ids => 1 )                                  #
    ->fields('name')                                        #
    ->highlight('name')                                     #
    ->explain(1)                                            #
    ->first(), 'Elastic::Model::Result', 'AdvResults';

cmp_deeply [ keys %{ $result->result } ], bag(
    qw(_id _index _score _type _version fields highlight
        _explanation _node _shard)
    ),
    'AdvResult->result';

ok $result->score > 0, 'AdvResult->score';
is $result->source, undef, 'AdvResult->source';

isa_ok $uid = $result->uid, 'Elastic::Model::UID', 'AdvResult->uid';
is $uid->index,      'myapp2', 'uid->index';
is $uid->type,       'user',   'uid->type';
is $uid->id,         1,        'uid->id';
is $uid->version,    1,        'uid->version';
is $uid->from_store, 1,        'uid->from_store';
is $uid->routing,    undef,    'uid->routing';

isa_ok $object = $result->object, 'MyApp::User', 'AdvResult->object';
does_ok $object, 'Elastic::Model::Role::Doc', 'AdvResult->object';
cmp_deeply $object->uid, $uid, 'AdvObject->uid';

cmp_deeply
    [ keys %{ $result->fields } ],
    bag('name'),
    'AdvResult->fields';
cmp_deeply
    [ keys %{ $result->highlights } ],
    ['name'],
    'AdvResult->highlights';
cmp_deeply
    [ $result->highlight('foo') ],
    [],
    'AdvResult->highlight(foo)';

is $result->field('name')->[0], $object->name, 'AdvResult->field(name)';
is
    join( '', $result->highlight('name') ),
    '<em>Aardwolf</em>',
    'AdvResult->highlight(name)';

like $result->explain, qr/product of:/, 'AdvResult->explain';

# Partial docs #

isa_ok $result = $view->queryb( { name => 'Aardwolf' } )    #
    ->include_paths('name')                                 #
    ->first(), 'Elastic::Model::Result', 'Partial';

isa_ok my $doc = $result->partial, 'MyApp::User', 'Partial->partial';
ok $doc->{name}, 'Partial has name';
SKIP: {
    skip "Partials not supported in 0.90", 1
        if $es->isa('Search::Elasticsearch::Client::0_90::Direct');
    ok !$doc->{timestamp}, 'Partial has no timestamp';
}

ok $doc->uid->is_partial, 'Partial UID is partial';

isa_ok $doc = $result->object, 'MyApp::User', 'Partial->object';
ok $doc->{name},      'Object has name';
ok $doc->{timestamp}, 'Object has timestamp';
ok !$doc->uid->is_partial, 'Object UID is not partial';

done_testing;

__END__
