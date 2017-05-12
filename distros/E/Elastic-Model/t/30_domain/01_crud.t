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

ok $ns->index('myapp2')->create, 'Create index myapp2';
ok $ns->index('myapp3')->create, 'Create index myapp3';

ok $ns->alias->to('myapp2'), 'Alias myapp to myapp2';
ok $ns->alias('routed')->to( myapp2 => { routing => 'foo' } ),
    'Alias routed to myapp2 with routing';
ok $ns->alias('multi')->to( 'myapp2', 'myapp3' );

## Basics - myapp ##
isa_ok my $domain = $model->domain('myapp'), 'Elastic::Model::Domain',
    'Got domain myapp';

is $domain->name, 'myapp', 'myapp has name';
is $domain->namespace->name, 'myapp', 'myapp has namespace:myapp';

## Basics - routed ##
isa_ok my $routed = $model->domain('routed'), 'Elastic::Model::Domain',
    'Got domain routed';
is $routed->name, 'routed', 'routed has name';
is $routed->namespace->name, 'myapp', 'routed has namespace:myapp';

## Default routing ##
is $domain->_default_routing, '', 'myapp has no default routing';
is $model->domain('myapp2')->_default_routing, '', 'Routing for index domain';
is $routed->_default_routing, 'foo', 'routed has default routing';
throws_ok sub { $model->domain('myapp1_fixed')->_default_routing },
    qr/doesn't exist/, 'Non-existent domain';
throws_ok sub { $model->domain('multi')->_default_routing },
    qr/more than one index/, 'Multi-index alias';

## new_doc - myapp ##
throws_ok sub { $domain->new_doc }, qr/No type/, 'new_doc no type';
throws_ok sub { $domain->new_doc('foo') }, qr/Unknown type/,
    'new_doc Unknown type';

isa_ok my $user = $domain->new_doc(
    user => {
        id    => 1,
        name  => 'Clint',
        email => 'clint@foo.com'
    }
    ),
    'MyApp::User', 'User';

## UID pre-save ##
test_uid(
    $user->uid,
    'Pre-save UID',
    {   index      => 'myapp',
        type       => 'user',
        id         => 1,
        routing    => '',
        version    => undef,
        from_store => undef,
        cache_key  => 'user;1'
    }
);

ok $user->save, 'User saved';

test_uid(
    $user->uid,
    'Saved UID',
    {   index      => 'myapp2',
        type       => 'user',
        id         => 1,
        routing    => '',
        version    => 1,
        from_store => 1,
        cache_key  => 'user;1'
    }
);

## create - routed ##
isa_ok $user = $routed->create(
    user => (
        id    => 2,
        name  => 'John',
        email => 'john@foo.com'
    )
    ),
    'MyApp::User', 'Routed user';

## UID post save ##
test_uid(
    $user->uid,
    'Routed UID',
    {   index      => 'myapp2',
        type       => 'user',
        id         => 2,
        routing    => 'foo',
        version    => 1,
        from_store => 1,
        cache_key  => 'user;2'
    }
);

## Get - myapp - user##
throws_ok sub { $domain->get() }, qr/No type/, 'Get no type';
throws_ok sub { $domain->get('user') }, qr/No id/, 'Get no ID';
isa_ok $user= $domain->get( user => 1 ), 'MyApp::User', 'Get user myapp';

test_uid(
    $user->uid,
    'Retrieved UID',
    {   index      => 'myapp2',
        type       => 'user',
        id         => 1,
        routing    => '',
        version    => 1,
        from_store => 1,
        cache_key  => 'user;1'
    }
);

throws_ok sub { $domain->get( user => 2 ) }, qr/Missing/,
    'Myapp without routing';

is $domain->get( user => 2, routing => 'foo' )->uid->id, 2,
    'Myapp with routing';

## Get - routed ##
isa_ok $user = $routed->get( user => 2 ), 'MyApp::User', 'Get user routed';

test_uid(
    $user->uid,
    'Retrieved routed UID',
    {   index      => 'myapp2',
        type       => 'user',
        id         => 2,
        routing    => 'foo',
        version    => 1,
        from_store => 1,
        cache_key  => 'user;2'
    }
);

throws_ok sub { $routed->get( user => 1 ) }, qr/Missing/,
    'Routed without routing';

## Try get ##
isa_ok $user = $routed->get( user => 2 ), 'MyApp::User', 'try_get existing';
is $domain->try_get( user => 3 ), undef, 'try_get missing';

## Change and save ##
is $user->name('James'), 'James', 'Field updated';
ok $user->save, 'User saved';
test_uid(
    $user->uid,
    'Updated UID',
    {   index      => 'myapp2',
        type       => 'user',
        id         => 2,
        routing    => 'foo',
        version    => 2,
        from_store => 1,
        cache_key  => 'user;2'
    }
);

## Exists ##
is $domain->exists( user => 1 ), '1', 'User exists';
is $domain->exists( user => 5 ), '',  'User does not exist';

## Delete ##
throws_ok sub { $domain->delete }, qr/No type/, 'Delete no type';
throws_ok sub { $domain->delete('foo') }, qr/No id/, 'Delete no id';
throws_ok sub { $domain->delete( user => 2 ) }, qr/Missing/,
    'Delete missing doc';
throws_ok sub { $domain->delete( user => 1, routing => 'foo' ) }, qr/Missing/,
    'Delete missing with routing';
is $routed->try_delete( user => 1 ), undef, 'Delete maybe';
ok my $uid = $domain->try_delete( user => 2, routing => 'foo' ),
    'Delete with routing';

test_uid(
    $uid,
    'Deleted UID',
    {   index      => 'myapp2',
        type       => 'user',
        id         => 2,
        routing    => 'foo',
        version    => 3,
        from_store => 1,
        cache_key  => 'user;2'
    }
);

# Terms_indexed_for_field
$ns->index('myapp2')->refresh;
isa_ok $user = $domain->get( user => 1 ), 'MyApp::User', 'User';

is_deeply $user->terms_indexed_for_field('email'),
    {
    _type   => "terms",
    missing => 0,
    other   => 0,
    terms   => [
        { count => 1, term => "foo.com" },
        { count => 1, term => "clint" },
    ],
    total => 2,
    },
    'Terms indexed for field';

## DONE ##

done_testing;

sub test_uid {
    my ( $uid, $name, $vals ) = @_;
    isa_ok $uid , 'Elastic::Model::UID', $name;
    for my $t (qw(index type id routing version from_store cache_key)) {
        is $uid->$t, $vals->{$t}, "$name $t";
    }
}

__END__
