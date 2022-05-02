#!/usr/bin/env perl

use warnings;
use strict;

use lib 't/lib';
use TestCommon;

use File::KDBX::Entry;
use File::KDBX::Util qw(:uuid);
use File::KDBX;
use Test::Deep;
use Test::More;

subtest 'Cloning' => sub {
    my $kdbx = File::KDBX->new;
    my $entry = File::KDBX::Entry->new;

    my $copy = $entry->clone;
    like exception { $copy->kdbx }, qr/disconnected/, 'Disconnected entry copy is also disconnectedisconnected';
    cmp_deeply $copy, $entry, 'Disconnected entry and its clone are identical';

    $entry->kdbx($kdbx);
    $copy = $entry->clone;
    is $entry->kdbx, $copy->kdbx, 'Connected entry copy is also connected';
    cmp_deeply $copy, $entry, 'Connected entry and its clone are identical';

    my $txn = $entry->begin_work;
    $entry->title('foo');
    $entry->username('bar');
    $entry->password('baz');
    $txn->commit;

    $copy = $entry->clone;
    is @{$copy->history}, 1, 'Copy has a historical entry' or dumper $copy->history;
    cmp_deeply $copy, $entry, 'Entry with history and its clone are identical';

    $copy = $entry->clone(history => 0);
    is @{$copy->history}, 0, 'Copy excluding history has no history';

    $copy = $entry->clone(new_uuid => 1);
    isnt $copy->uuid, $entry->uuid, 'Entry copy with new UUID has a different UUID';

    $copy = $entry->clone(reference_username => 1);
    my $ref = sprintf('{REF:U@I:%s}', format_uuid($entry->uuid));
    is $copy->username, $ref, 'Copy has username reference';
    is $copy->expand_username, $ref, 'Entry copy does not expand username because entry is not in database';

    my $group = $kdbx->add_group(label => 'Passwords');
    $group->add_entry($entry);
    is $copy->expand_username, $entry->username,
        'Entry in database and its copy with username ref have same expanded username';

    $copy = $entry->clone;
    is $kdbx->entries->size, 1, 'Still only one entry after cloning';

    $copy = $entry->clone(parent => 1);
    is $kdbx->entries->size, 2, 'New copy added to database if clone with parent option';
    my ($e1, $e2) = $kdbx->entries->each;
    isnt $e1, $e2, 'Entry and its copy in the database are different objects';
    is $e1->title, $e2->title, 'Entry copy has the same title as the original entry';

    $copy = $entry->clone(parent => 1, relabel => 1);
    is $kdbx->entries->size, 3, 'New copy added to database if clone with parent option';
    my $e3 = $kdbx->entries->skip(2)->next;
    is $e3, $copy, 'New copy and new entry in the database match';
    is $e3->title, 'foo - Copy', 'New copy has a modified title';

    $copy = $group->clone;
    cmp_deeply $copy, $group, 'Group and its clone are identical';
    is @{$copy->entries}, 3, 'Group copy has as many entries as the original';
    is @{$copy->entries->[0]->history}, 1, 'Entry in group copy has history';

    $copy = $group->clone(history => 0);
    is @{$copy->entries}, 3, 'Group copy without history has as many entries as the original';
    is @{$copy->entries->[0]->history}, 0, 'Entry in group copy has no history';

    $copy = $group->clone(entries => 0);
    is @{$copy->entries}, 0, 'Group copy without entries has no entries';
    is $copy->name, 'Passwords', 'Group copy label is the same as the original';

    $copy = $group->clone(relabel => 1);
    is $copy->name, 'Passwords - Copy', 'Group copy relabeled from the original title';
    is $kdbx->entries->size, 3, 'No new entries were added to the database';

    $copy = $group->clone(relabel => 1, parent => 1);
    is $kdbx->entries->size, 6, 'Copy a group within parent doubles the number of entries in the database';
    isnt $group->entries->[0]->uuid, $copy->entries->[0]->uuid,
        'First entry in group and its copy are different';
};

subtest 'Transactions' => sub {
    my $kdbx = File::KDBX->new;

    my $root    = $kdbx->root;
    my $entry   = $kdbx->add_entry(
        label => 'One',
        last_modification_time => Time::Piece->strptime('2022-04-20', '%Y-%m-%d'),
        username => 'Fred',
    );

    my $txn = $root->begin_work;
    $root->label('Toor');
    $root->notes('');
    $txn->commit;
    is $root->label, 'Toor', 'Retain change to root label after commit';

    $root->begin_work;
    $root->label('Root');
    $entry->label('Zap');
    $root->rollback;
    is $root->label, 'Toor', 'Undo change to root label after rollback';
    is $entry->label, 'Zap', 'Retain change to entry after rollback';

    $txn = $root->begin_work(entries => 1);
    $root->label('Root');
    $entry->label('Zippy');
    undef $txn; # implicit rollback
    is $root->label, 'Toor', 'Undo change to root label after implicit rollback';
    is $entry->label, 'Zap', 'Undo change to entry after rollback with deep transaction';

    $txn = $entry->begin_work;
    my $mtime = $entry->last_modification_time;
    my $username = $entry->string('UserName');
    $username->{meh} = 'hi';
    $entry->username('jinx');
    $txn->rollback;
    is $entry->string('UserName'), $username, 'Rollback keeps original references';
    is $entry->last_modification_time, $mtime, 'No last modification time change after rollback';

    $txn = $entry->begin_work;
    $entry->username('jinx');
    $txn->commit;
    isnt $entry->last_modification_time, $mtime, 'Last modification time changes after commit';

    {
        my $txn1 = $root->begin_work;
        $root->label('alien');
        {
            my $txn2 = $root->begin_work;
            $root->label('truth');
            $txn2->commit;
        }
    }
    is $root->label, 'Toor', 'Changes thrown away after rolling back outer transaction';

    {
        my $txn1 = $root->begin_work;
        $root->label('alien');
        {
            my $txn2 = $root->begin_work;
            $root->label('truth');
        }
        $txn1->commit;
    }
    is $root->label, 'alien', 'Keep committed change after rolling back inner transaction';

    {
        my $txn1 = $root->begin_work;
        $root->label('alien');
        {
            my $txn2 = $root->begin_work;
            $root->label('truth');
            $txn2->commit;
        }
        $txn1->commit;
    }
    is $root->label, 'truth', 'Keep committed change from inner transaction';

    $txn = $root->begin_work;
    $root->label('Lalala');
    my $dump = $kdbx->dump_string('a');
    $txn->commit;
    is $root->label, 'Lalala', 'Keep committed label change after dump';
    my $load = File::KDBX->load_string($dump, 'a');
    is $load->root->label, 'truth', 'Object dumped before committing matches the pre-transaction state';
};

done_testing;
