#!/usr/bin/env perl
use warnings;
use strict;

use Jifty::Test::Dist tests => 55;

my $user = TestApp::Plugin::RecordHistory::Model::User->new;
$user->create(
    name => 'tester',
);
ok($user->id, 'created user');

my $current_user = TestApp::Plugin::RecordHistory::CurrentUser->new(id => $user->id);

my $ticket = TestApp::Plugin::RecordHistory::Model::Ticket->new(current_user => $current_user);
$ticket->create(
    subject => 'Hello world',
);
ok($ticket->id, 'created a ticket');

isa_ok($ticket->changes, 'Jifty::Plugin::RecordHistory::Model::ChangeCollection');
is($ticket->changes->count, 1, 'one change');
my $change = $ticket->changes->first;
is($change->record_id, $ticket->id, 'record id');
is($change->record_class, 'TestApp::Plugin::RecordHistory::Model::Ticket', 'record class');
is($change->type, 'create', 'change has type create');
is($change->record->subject, 'Hello world', 'change->record');
is($change->created_by->id, $user->id, 'correct creator');

is($change->current_user->id, $user->id, 'current user is the user not superuser');
ok(!$change->current_user->is_superuser, 'not superuser');

$ticket->set_subject('Konnichiwa sekai');

isa_ok($ticket->changes, 'Jifty::Plugin::RecordHistory::Model::ChangeCollection');
is($ticket->changes->count, 2, 'two changes');
is($ticket->changes->first->type, 'create', 'first change is the create');
$change = $ticket->changes->last;
is($change->type, 'update', 'second change is the update');
is($change->change_fields->count, 1, 'one field updated');
is($change->created_by->id, $user->id, 'correct creator');

is($change->current_user->id, $user->id, 'current user is the user not superuser');
ok(!$change->current_user->is_superuser, 'not superuser');

my $change_field = $change->change_fields->first;
is($change_field->change->id, $change->id, 'associated with the right change');
is($change_field->field, 'subject');
is($change_field->new_value, 'Konnichiwa sekai');
is($change_field->old_value, 'Hello world');

is($change_field->current_user->id, $user->id, 'current user is the user not superuser');
ok(!$change_field->current_user->is_superuser, 'not superuser');

$ticket->set_forced_updatable(0);

isa_ok($ticket->changes, 'Jifty::Plugin::RecordHistory::Model::ChangeCollection');
is($ticket->changes->count, 3, 'three changes');
$change = $ticket->changes->last;
is($change->type, 'update', 'last change is the update');
is($change->change_fields->count, 1, 'one field updated');
is($change->created_by->id, $user->id, 'correct creator');

is($change->current_user->id, $user->id, 'current user is the user not superuser');
ok(!$change->current_user->is_superuser, 'not superuser');

my $change_field = $change->change_fields->first;
is($change_field->change->id, $change->id, 'associated with the right change');
is($change_field->field, 'forced_updatable');
is($change_field->new_value, 0);
is($change_field->old_value, 1);

is($change_field->current_user->id, $user->id, 'current user is the user not superuser');
ok(!$change_field->current_user->is_superuser, 'not superuser');

# make sure we don't create spurious changes when a record couldn't be updated
$ticket->set_forced_updatable(1);
is($ticket->forced_updatable, 0, "ticket was not updated");
is($ticket->changes->count, 3, "still only three changes since we couldn't update the record");

$change = Jifty::Plugin::RecordHistory::Model::Change->new(current_user => $current_user);
$change->create(
    record_class => ref($ticket),
    record_id    => $ticket->id,
    type         => 'forged',
);
ok(!$change->id, "couldn't create a change as an ordinary user");

my $super_ticket = TestApp::Plugin::RecordHistory::Model::Ticket->new(current_user => Jifty::CurrentUser->superuser);
$super_ticket->load($ticket->id);
$super_ticket->set_forced_updatable(1);

# flush cache
$ticket->load($ticket->id);

is($ticket->forced_updatable, 1, "ticket was updated");
is($ticket->changes->count, 4, "now four changes since the superuser *could* update the record");

$ticket->set_forced_readable(0);
ok(!$ticket->current_user_can('read'), "can no longer read the ticket");
is($ticket->subject, undef, "can no longer read ticket fields");
isa_ok($ticket->changes, 'Jifty::Plugin::RecordHistory::Model::ChangeCollection');
is($ticket->changes->current_user->id, $user->id, 'current user is the user not superuser');
ok(!$ticket->changes->current_user->is_superuser, 'not superuser');
is($ticket->changes->first, undef, "no readable changes");

$super_ticket->load($ticket->id);
$super_ticket->set_forced_readable(1);

# flush cache
$ticket->load($ticket->id);

is($ticket->forced_readable, 1, "ticket was updated");
is($ticket->changes->count, 6, "all the changes");

$ticket->set_forced_deletable(0);
$ticket->delete;
$ticket->load($super_ticket->id);
ok($ticket->id, 'still have a record');

is($ticket->changes->count, 7, "a new change from updating the record, but we couldn't ");

$ticket->set_forced_deletable(1);
$ticket->delete;
$ticket->load($super_ticket->id);
ok(!$ticket->id, 'still have a record');

is($ticket->changes->count, 0, "all changes gone now");

