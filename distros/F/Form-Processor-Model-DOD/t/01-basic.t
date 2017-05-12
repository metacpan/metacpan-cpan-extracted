use strict;

use lib 'lib';
use lib 't/lib';
require 't/lib/db-common.pl';

use Test::More;
use Test::Exception;

BEGIN {
    unless (eval { require DBD::SQLite }) {
        plan skip_all => 'Tests require DBD::SQLite';
    }
}

plan tests => 18;

setup_dbs({ testdb => [ qw( user ) ], });

use Model::User;
use_ok 'Form::User';
my $form = Form::User->new;
ok $form;
isa_ok $form, 'Form::User';
isa_ok $form, 'Form::Processor::Model';

my $params = { 
    name => "Yann",
    married_on => '2006-08-04 17:00:00',
    state => 'drunk',
};
ok $form->update_from_form( $params );
is $form->updated_or_created, "created";
my $user = $form->item;
ok my $id = $user->id;
is $user->state, 'drunk';

my $form2 = Form::User->new( $user->id );
ok $form2->update_from_form( { %$params, state => 'sober' } );
is $form2->updated_or_created, "updated";
is $form2->item->id, $id;
is $form2->item->state, 'sober';
$form2->clear;
ok !  $form2->update_from_form( { %$params, state => 'high' } );
ok $form2->has_error;

$user->refresh;
is $user->state, 'sober', "form didn't validate so no update";

my $form3 = Form::User->new( $user );
ok $form3->update_from_form( $params );
is $form3->item->state, 'drunk';
$user->refresh;
is $user->state, 'drunk', "form with whole item object passed in new()";

teardown_dbs(qw( testdb ));
