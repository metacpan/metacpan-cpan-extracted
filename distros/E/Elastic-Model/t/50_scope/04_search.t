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
isa_ok my $index = $ns->index('myapp'), 'Elastic::Model::Index', 'Got index';
ok $index->create, 'Create index myapp';

isa_ok my $domain = $model->domain('myapp'), 'Elastic::Model::Domain',
    'Domain';

isa_ok my $v = $domain->view(), 'Elastic::Model::View', 'View';

my ( $scope_1, $scope_2,, $scope_3, $u, $r, $o, $r2 );

$scope_1 = create_scope('Scope 1');

isa_ok $u = $domain->create( user => { id => 1, name => 'Clint' } ),
    'MyApp::User', 'Create U1';
ok $index->refresh, 'Refresh index';

# same version, same scope;
$r = search('Same scope');
compare( 'Same version, same scope', $u, $r->first_object, 'same_obj' );

$scope_2 = create_scope('Scope 2');

# same version, higher scope;
$r = search('Higher scope');
compare( 'Same version, higher scope', $u, $r->first_object, 0, 'same_ver' );

# lower version, same scope
undef $scope_2;
$r       = search('Scope 1');
$r2      = search('Scope 1');
$scope_2 = create_scope('Scope 2');
$u       = get_user('Higher scope');

$u->name('John');
ok $u->save,        'Update user';
ok $index->refresh, 'Refresh index';
compare( 'lower version, same scope', $u, $r->first_object, 'same_obj' );

# lower version, higher scope
$scope_3 = create_scope('Scope 3');
compare( 'lower version, higher scope', $u, $r2->first_object, 0, 0 );

# higher version, higher scope
undef $scope_2;
undef $scope_3;
$u       = get_user('User scope 1');
$r       = search('Scope 1');
$r2      = search('Scope 1');
$scope_2 = create_scope('Scope 2');
compare( 'Higher version, higher scope', $u, $r->first_object, 0, 0 );

# higher version, same scope
undef $scope_2;
compare( 'higher version, same scope', $u, $r2->first_object, 0, 0 );

# tied to scope
undef $scope_1;
$scope_1 = create_scope('Scope 1');
$u       = get_user('User scope 1');
$r       = search('Scope 1');
$r2      = search('Scope 1');

ok $r->slice_objects, 'Slice R1';
$scope_2 = create_scope('Scope 2');
ok $r2->slice_objects, 'Slice R2';

compare( 'R1 tied to scope 1', $u, $r->first_object, 'same_obj' );
compare( 'R2 tied to scope 2', $u, $r2->first_object, 0, 'same_ver' );

compare( 'R1 first_object, first_result->object',
    $r->first_object, $r->first_result->object, 'same_obj' );
compare( 'R2 first_object, first_result->object',
    $r2->first_object, $r2->first_result->object, 'same_obj' );

done_testing;

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
sub search {
#===================================
    my $name = shift;
    isa_ok my $results = $v->search, 'Elastic::Model::Results',
        "$name search";
    return $results;
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
