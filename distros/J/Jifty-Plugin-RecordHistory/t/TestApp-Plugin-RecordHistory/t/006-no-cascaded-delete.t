#!/usr/bin/env perl
use warnings;
use strict;

use Jifty::Test::Dist tests => 27;

my $cd = TestApp::Plugin::RecordHistory::Model::CD->new;
$cd->create(
    title => 'The King of Limbs',
);
ok($cd->id, 'created a cd');

isa_ok($cd->changes, 'Jifty::Plugin::RecordHistory::Model::ChangeCollection');
is($cd->changes->count, 1, 'one change');
my $change = $cd->changes->first;
is($change->record_id, $cd->id, 'record id');
is($change->record_class, 'TestApp::Plugin::RecordHistory::Model::CD', 'record class');
is($change->type, 'create', 'change has type create');
is($change->record->title, 'The King of Limbs', 'change->record');

isa_ok($change->change_fields, 'Jifty::Plugin::RecordHistory::Model::ChangeFieldCollection', 'change field collection');
is($change->change_fields->count, 0, 'generate no ChangeFields for create');

$cd->set_title('OK Computer');

isa_ok($cd->changes, 'Jifty::Plugin::RecordHistory::Model::ChangeCollection');
is($cd->changes->count, 2, 'two changes');
is($cd->changes->first->type, 'create', 'first change is the create');
$change = $cd->changes->last;
is($change->type, 'update', 'second change is the update');
is($change->change_fields->count, 1, 'one field updated');

my $change_field = $change->change_fields->first;
is($change_field->change->id, $change->id, 'associated with the right change');
is($change_field->field, 'title');
is($change_field->new_value, 'OK Computer');
is($change_field->old_value, 'The King of Limbs');

$cd->delete;

my $changes = Jifty::Plugin::RecordHistory::Model::ChangeCollection->new;
$changes->unlimit;
is($changes->count, 2, 'two changes');
is($changes->first->type, 'create', 'first change is the create');
$change = $changes->last;
is($change->type, 'update', 'second change is the update');
is($change->change_fields->count, 1, 'one field updated');

my $change_fields = Jifty::Plugin::RecordHistory::Model::ChangeFieldCollection->new;
$change_fields->unlimit;
is($change_fields->count, 1);
$change_field = $change->change_fields->first;
is($change_field->change->id, $change->id, 'associated with the right change');
is($change_field->field, 'title');
is($change_field->new_value, 'OK Computer');
is($change_field->old_value, 'The King of Limbs');

