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
isa_ok my $domain = $model->domain('myapp'), 'Elastic::Model::Domain',
    'Domain';

isa_ok my $scope_1 = $model->new_scope, 'Elastic::Model::Scope', 'Scope_1';

# Create
isa_ok my $u1 = $domain->create( user => { id => 1, name => 'Clint' } ),
    'MyApp::User', 'U1';

# Get same scope
isa_ok my $u2 = $domain->get( user => 1 ), 'MyApp::User', 'U2';
compare( "U1 and U2", $u1, $u2, 'same_obj' );

# Update same scope
$u2->name('John');
ok $u2->save, 'U2 updated';
is $u1->name, $u2->name, 'U1 and U2 have same name';
compare( "U1 and U2", $u1, $u2, 'same_obj' );

# Save on older scope with un-inflated in newer scope
isa_ok my $scope_2 = $model->new_scope, 'Elastic::Model::Scope', 'Scope_2';
isa_ok $u2 = $domain->get( user => 1 ), 'MyApp::User', 'U2 in new scope';
compare( "U1 and U2-new-scope", $u1, $u2, 0, 'same_ver' );

$u1->name('Mary');
ok $u1->save, 'U1 updated';
compare( "U1-updated and U2-new-scope", $u1, $u2, 0, 'same_ver' );
is $u1->name, $u2->name, 'U1 and U2 have same name';

# Save on older scope with inflated in newer scope
undef $scope_2;
isa_ok $scope_2 = $model->new_scope, 'Elastic::Model::Scope',
    'Scope_2 renewed';
isa_ok $u2 = $domain->get( user => 1 ), 'MyApp::User', 'U2 in new scope';
is $u2->name, 'Mary', 'Force U2 inflation';
$u1->name('Felix');
ok $u1->save, 'U1 updated';
compare( "U1-updated and U2-inflate", $u1, $u2, 0, 0 );

# Older version still alive
weaken $u2;
ok $u2, 'Weakened U2 still exists';

# Newer version now current version
isa_ok $u2 = $domain->get( user => 1 ), 'MyApp::User', 'U2 in saved scope';
compare( "U1-saved and U2-same-scope", $u1, $u2, 'same_obj' );

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
