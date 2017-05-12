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
isa_ok my $index = $model->namespace('myapp')->index, 'Elastic::Model::Index';
ok $index->create, 'Create index myapp';
isa_ok my $domain = $model->domain('myapp'), 'Elastic::Model::Domain';

my $i     = 0;
my @users = users();
#===================================
sub success {
#===================================
    my $doc = shift;
    is $doc->name, $users[ $i++ ]->name, "Success user $i";
}

isa_ok my $bulk = $model->bulk( size => 10, on_success => \&success ),
    'Elastic::Model::Bulk';
is $bulk->size, 10, 'Bulk size set correctly';

is 0 + @users, 196, 'Have 196 users';

$bulk->save($_) for @users;

## COMMIT

ok $index->refresh, 'Refresh index';
is $domain->view->search->total, 190, '190 users auto-indexed';

ok $bulk->commit,   'Commit bulk';
ok $index->refresh, 'Refresh index';
is $domain->view->search->total, 196, '196 users auto-indexed';
is $i, 196, 'on_success called 196 times';

## CLEAR

ok $index->delete, 'Delete index';
ok $index->create, 'Create index myapp';

$bulk = $model->bulk( size => 10 );
$bulk->save($_) for users();

ok $bulk->clear,    'Clear bulk';
ok $index->refresh, 'Refresh index';
is $domain->view->search->total, 190, '190 users auto-indexed';

## SCOPE

ok $index->delete, 'Delete index';
ok $index->create, 'Create index myapp';
$bulk->save($_) for users();

ok !undef($bulk), 'Bulk out of scope';
ok $index->refresh, 'Refresh index';
is $domain->view->search->total, 196, '196 users auto-indexed';

## DONE ##

done_testing;

#===================================
sub users {
#===================================
    my $i = 1;
    map { $domain->new_doc( user => { id => $i++, name => $_ } ) } names();
}
__END__
