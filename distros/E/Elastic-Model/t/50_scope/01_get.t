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

use Elastic::Model::Role::Store();
my $store_get = 0;
{

    package Elastic::Model::Role::Store;
    use Moose::Role;
    around 'get_doc' => sub {
        my $orig = shift;
        my $self = shift;
        $store_get++;
        $self->$orig(@_);

    };

    package main;
}

my $model = new_ok( 'MyApp', [ es => $es ], 'Model' );

ok my $ns = $model->namespace('myapp'), 'Got ns';
ok $ns->index('myapp')->create, 'Create index myapp';
isa_ok my $domain = $model->domain('myapp'), 'Elastic::Model::Domain',
    'Domain';

# Create without scope
isa_ok my $u1 = $domain->create( user => { id => 1, name => 'Clint' } ),
    'MyApp::User', 'U1';

# Get with scope
isa_ok my $scope_1 = $model->new_scope, 'Elastic::Model::Scope', 'Scope_1';
isa_ok my $u2 = $domain->get( user => 1 ), 'MyApp::User', 'U2';
compare( "U1 and U2", $u1, $u2, 0, 'same_ver' );

# Get in same scope
isa_ok my $u3 = $domain->get( user => 1 ), 'MyApp::User', 'U3';
compare( "U2 and U3", $u2, $u3, 'same_obj' );
is $store_get, 1, 'U3 came from scope';

# Get from parent scope
isa_ok my $scope_2 = $model->new_scope, 'Elastic::Model::Scope', 'Scope_2';
isa_ok my $u4 = $domain->get( user => 1 ), 'MyApp::User', 'U4';
compare( "U2 and U4", $u2, $u4, 0, 'same_ver' );
is $store_get, 1, 'U4 came from scope';

# Update in new scope
isa_ok my $scope_3 = $model->new_scope, 'Elastic::Model::Scope', 'Scope_3';

$u1->name('John');
ok $u1->save, 'U1 updated';

# Get updated from same scope
isa_ok $u4 = $domain->get( user => 1 ), 'MyApp::User', 'U4';
compare( "U1 and U4", $u1, $u4, 'same_obj' );
is $store_get, 1, 'U4 came from scope';

isa_ok my $uid = $u4->uid, 'Elastic::Model::UID', 'U4 UID';

# Expire scope
undef $scope_3;
is refaddr $scope_2, refaddr $model->current_scope,
    'Scope_2 is current scope';

# Get updated version not in scope
isa_ok $u4= $model->get_doc( uid => $uid ), 'MyApp::User', 'U4 via get_doc';
compare( "U1 and U4", $u1, $u4, 0, 'same_ver' );
is $store_get, 2, 'U4 came from store';

# Done
done_testing;

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
