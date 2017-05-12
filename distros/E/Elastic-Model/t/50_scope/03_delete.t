#!/usr/bin/perl

use strict;
use warnings;
use Test::More 0.96;
use Test::Exception;
use Scalar::Util qw(refaddr weaken);

use lib 't/lib';

our $es;
do 'es.pl';

use_ok 'MyApp' || print 'Bail out';

my $model = new_ok( 'MyApp', [ es => $es ], 'Model' );

ok my $ns = $model->namespace('myapp'), 'Got ns';
ok $ns->index('myapp')->create, 'Create index myapp';
isa_ok my $domain = $model->domain('myapp'),
    'Elastic::Model::Domain',
    'Domain';

# delete ID in current scope
my $scope_1 = create_scope('Scope_1');

#my ($user_1,$scope_2,$user_2);

my $user_1 = create_user('U1');
isa_ok $domain->delete( user => 1 ), 'Elastic::Model::UID', 'Delete ID 1';
isa_ok $user_1, 'Elastic::Model::Deleted', 'U1';

# delete ID in different scope
$user_1 = create_user('U1');
my $scope_2 = create_scope('Scope_2');
my $user_2  = get_user('U2');

isa_ok $domain->delete( user => 1 ), 'Elastic::Model::UID', 'Delete ID 1';

isa_ok $user_2, 'Elastic::Model::Deleted', 'U2';
isa_ok $user_1, 'MyApp::User',             'U1';

throws_ok sub { $domain->get( user => 1 ) },
    qr/Missing/,
    'Get deleted throws missing';

ok !$domain->try_get( user => 1 ), 'Try get deleted doc';

# get old version with UID
my $uid = $user_1->uid;
isa_ok $model->get_doc( uid => $uid ),
    'Elastic::Model::Deleted',
    'Model get old version';

# overwrite deleted in higher scope, then get in lower scope
# is this correct? or should we return Deleted
my $scope_3 = create_scope('Scope_3');
$user_1->name('John');
ok $user_1->overwrite, 'Overwrote U1';

undef $scope_3;
isa_ok $model->get_doc( uid => $uid ),
    'MyApp::User',
    'U1 with higher version from scope with deleted';

# delete object while new scope active
undef $scope_2;
$user_1->delete;
$user_1  = create_user('U1');
$scope_2 = create_scope('Scope_2');
$user_2  = get_user('U2');
isa_ok $user_1->delete, 'Elastic::Model::Deleted', 'Delete U1';
isa_ok $user_1, 'Elastic::Model::Deleted', 'U1';
isa_ok $user_2, 'Elastic::Model::Deleted', 'U2';

# delete in scope without object
undef $scope_2;
$user_1  = create_user('U1');
$scope_2 = create_scope('Scope_2');
isa_ok $domain->delete( user => 1 ), 'Elastic::Model::UID', 'Delete ID 1';

throws_ok sub { $domain->get( user => 1 ) },
    qr/Missing/,
    'Get deleted throws missing';
undef $scope_2;
compare( 'U1 and get 1', $user_1, get_user('U1'), 'same_obj' );

# has_been_deleted on existing
$user_1 = create_user('U1');
is $user_1->has_been_deleted, '', 'UID has not been deleted';

# has_been_deleted should load _source if not already loaded
$uid = $user_1->uid;
undef $scope_1;
$scope_1 = create_scope('Scope_1');
isa_ok $user_1 = $model->get_doc( uid => $uid ), 'MyApp::User',
    'Model get U1';
is $user_1->has_been_deleted, '', 'UID has not been deleted';
my $source = $user_1->_source;

# object inflated with source should still work even though
# has_been_deleted is true
isa_ok $user_1->delete, 'Elastic::Model::Deleted', 'U1 deleted';

undef $scope_1;
$scope_1 = create_scope('Scope_1');

isa_ok $user_1 = $model->get_doc( uid => $uid, source => $source ),
    'MyApp::User', 'Model get U1 with source';
is $user_1->has_been_deleted, 1,       'U1 has been deleted';
is $user_1->name,             'Clint', 'Name works';

# deleted object without source should throw an error when accessing it
undef $scope_1;
$scope_1 = create_scope('Scope_1');

isa_ok $user_1 = $model->get_doc( uid => $uid ), 'MyApp::User',
    'Model get U1 without source';
is $user_1->has_been_deleted, 1, 'U1 has been deleted';
throws_ok sub { $user_1->name }, qr/has been deleted/,
    'Accessing deleted stub';

# Deleted
isa_ok $user_1, 'Elastic::Model::Deleted', 'U1';
is $user_1->_can_inflate,     0,     'Deleted U1 cannot be inflated';
is $user_1->_inflate_doc,     undef, 'Deleted U1 _inflate_doc is a noop';
is $user_1->has_been_deleted, 1,     'Deleted UI has been deleted';

# Done
done_testing;

#===================================
sub create_user {
#===================================
    my $name = shift;
    isa_ok my $user = $domain->create( user => { id => 1, name => 'Clint' } ),
        'MyApp::User', $name;
    return $user;
}

#===================================
sub get_user {
#===================================
    my $name = shift;
    isa_ok my $user = $domain->get( user => 1 ), 'MyApp::User', $name;
    return $user;
}

#===================================
sub create_scope {
#===================================
    my $name = shift;
    isa_ok my $scope = $model->new_scope, 'Elastic::Model::Scope', $name;
    return $scope;
}

#===================================
sub compare {
#===================================
    my ( $desc, $o1, $o2, $same_obj, $same_ver ) = @_;
    is $o1->uid->cache_key, $o2->uid->cache_key, "$desc have same cache key";
    if ($same_obj) {
        is refaddr $o1, refaddr $o2, "$desc are same object";
    }
    else {
        ok refaddr $o1 ne refaddr $o2, "$desc are different objects";
        if ($same_ver) {
            is $o1->uid->version, $o2->uid->version, "$desc are same version";
        }
        else {
            ok $o1->uid->version != $o2->uid->version,
                "$desc are different versions";
        }
    }
}
