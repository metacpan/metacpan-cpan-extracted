#!/usr/bin/env perl
use warnings;
use strict;

use Jifty::Test::Dist tests => 22;

my $dvd = TestApp::Plugin::RecordHistory::Model::DVD->new;
$dvd->create(
    title => 'Silence of the Lambs',
);
ok($dvd->id, 'created a dvd');

isa_ok($dvd->changes, 'Jifty::Plugin::RecordHistory::Model::ChangeCollection');
is($dvd->changes->count, 1, 'one change');
my $change = $dvd->changes->first;
is($change->record_id, $dvd->id, 'record id');
is($change->record_class, 'TestApp::Plugin::RecordHistory::Model::DVD', 'record class');
is($change->type, 'create', 'change has type create');
is($change->record->title, 'Silence of the Lambs', 'change->record');

isa_ok($change->change_fields, 'Jifty::Plugin::RecordHistory::Model::ChangeFieldCollection', 'change field collection');
is($change->change_fields->count, 0, 'generate no ChangeFields for create');

$dvd->set_title('That Hannibal Movie');

isa_ok($dvd->changes, 'Jifty::Plugin::RecordHistory::Model::ChangeCollection');
is($dvd->changes->count, 2, 'two changes');
is($dvd->changes->first->type, 'create', 'first change is the create');
$change = $dvd->changes->last;
is($change->type, 'update', 'second change is the update');
is($change->change_fields->count, 1, 'one field updated');

my $change_field = $change->change_fields->first;
is($change_field->change->id, $change->id, 'associated with the right change');
is($change_field->field, 'title');
is($change_field->new_value, 'That Hannibal Movie');
is($change_field->old_value, 'Silence of the Lambs');

$dvd->delete;

my $changes = Jifty::Plugin::RecordHistory::Model::ChangeCollection->new;
$changes->unlimit;
is($changes->count, 1, 'one change');
my $first = $changes->first;
is($first->type, 'delete', 'only change is a delete');
is($first->__raw_value('created_by'), $dvd->current_user->id, 'delete change created by record current user');

my $change_fields = Jifty::Plugin::RecordHistory::Model::ChangeFieldCollection->new;
$change_fields->unlimit;
is($change_fields->count, 0, 'deleted all change fields');

