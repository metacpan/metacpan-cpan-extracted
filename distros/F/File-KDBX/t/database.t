#!/usr/bin/env perl

use utf8;
use warnings;
use strict;

use FindBin qw($Bin);
use lib "$Bin/lib";
use TestCommon;

use File::KDBX;
use File::Temp qw(tempfile);
use Test::Deep;
use Test::More 1.001004_001;
use Time::Piece;

subtest 'Create a new database' => sub {
    my $kdbx = File::KDBX->new;

    $kdbx->add_group(name => 'Meh');
    ok $kdbx->_has_implicit_root, 'Database starts off with implicit root';

    my $entry = $kdbx->add_entry({
        username    => 'hello',
        password    => {value => 'This is a secret!!!!!', protect => 1},
    });

    ok !$kdbx->_has_implicit_root, 'Adding an entry to the root group makes it explicit';

    $entry->remove;
    ok $kdbx->_has_implicit_root, 'Removing group makes the root group implicit again';
};

subtest 'Clone' => sub {
    my $kdbx = File::KDBX->new;
    $kdbx->add_group(name => 'Passwords')->add_entry(title => 'My Entry');

    my $copy = $kdbx->clone;
    cmp_deeply $copy, $kdbx, 'Clone keeps the same structure and data' or dumper $copy;

    isnt $kdbx, $copy, 'Clone is a different object';
    isnt $kdbx->root, $copy->root,
        'Clone root group is a different object';
    isnt $kdbx->root->groups->[0], $copy->root->groups->[0],
        'Clone group is a different object';
    isnt $kdbx->root->groups->[0]->entries->[0], $copy->root->groups->[0]->entries->[0],
        'Clone entry is a different object';

    my @objects = $copy->objects->each;
    subtest 'Cloned objects refer to the cloned database' => sub {
        plan tests => scalar @_;
        for my $object (@_) {
            my $object_kdbx = eval { $object->kdbx };
            is $object_kdbx, $copy, 'Object: ' . $object->label;
        }
    }, @objects;
};

subtest 'Iteration algorithm' => sub {
    # Database
    # - Root
    #   - Group1
    #     - EntryA
    #     - Group2
    #       - EntryB
    #   - Group3
    #     - EntryC
    my $kdbx = File::KDBX->new;
    my $group1 = $kdbx->add_group(label => 'Group1');
    my $group2 = $group1->add_group(label => 'Group2');
    my $group3 = $kdbx->add_group(label => 'Group3');
    my $entry1 = $group1->add_entry(label => 'EntryA');
    my $entry2 = $group2->add_entry(label => 'EntryB');
    my $entry3 = $group3->add_entry(label => 'EntryC');

    cmp_deeply $kdbx->groups->map(sub { $_->label })->to_array,
        [qw(Root Group1 Group2 Group3)], 'Default group order';
    cmp_deeply $kdbx->entries->map(sub { $_->label })->to_array,
        [qw(EntryA EntryB EntryC)], 'Default entry order';
    cmp_deeply $kdbx->objects->map(sub { $_->label })->to_array,
        [qw(Root Group1 EntryA Group2 EntryB Group3 EntryC)], 'Default object order';

    cmp_deeply $kdbx->groups(algorithm => 'ids')->map(sub { $_->label })->to_array,
        [qw(Root Group1 Group2 Group3)], 'IDS group order';
    cmp_deeply $kdbx->entries(algorithm => 'ids')->map(sub { $_->label })->to_array,
        [qw(EntryA EntryB EntryC)], 'IDS entry order';
    cmp_deeply $kdbx->objects(algorithm => 'ids')->map(sub { $_->label })->to_array,
        [qw(Root Group1 EntryA Group2 EntryB Group3 EntryC)], 'IDS object order';

    cmp_deeply $kdbx->groups(algorithm => 'dfs')->map(sub { $_->label })->to_array,
        [qw(Group2 Group1 Group3 Root)], 'DFS group order';
    cmp_deeply $kdbx->entries(algorithm => 'dfs')->map(sub { $_->label })->to_array,
        [qw(EntryB EntryA EntryC)], 'DFS entry order';
    cmp_deeply $kdbx->objects(algorithm => 'dfs')->map(sub { $_->label })->to_array,
        [qw(Group2 EntryB Group1 EntryA Group3 EntryC Root)], 'DFS object order';

    cmp_deeply $kdbx->groups(algorithm => 'bfs')->map(sub { $_->label })->to_array,
        [qw(Root Group1 Group3 Group2)], 'BFS group order';
    cmp_deeply $kdbx->entries(algorithm => 'bfs')->map(sub { $_->label })->to_array,
        [qw(EntryA EntryC EntryB)], 'BFS entry order';
    cmp_deeply $kdbx->objects(algorithm => 'bfs')->map(sub { $_->label })->to_array,
        [qw(Root Group1 EntryA Group3 EntryC Group2 EntryB)], 'BFS object order';
};

subtest 'Recycle bin' => sub {
    my $kdbx = File::KDBX->new;
    my $entry = $kdbx->add_entry(label => 'Meh');

    my $bin = $kdbx->groups->grep(name => 'Recycle Bin')->next;
    ok !$bin, 'New database has no recycle bin';

    is $kdbx->recycle_bin_enabled, 1, 'Recycle bin is enabled';
    $kdbx->recycle_bin_enabled(0);

    $entry->recycle_or_remove;
    cmp_ok $entry->is_recycled, '==', 0, 'Entry is not recycle if recycle bin is disabled';

    $bin = $kdbx->groups->grep(name => 'Recycle Bin')->next;
    ok !$bin, 'Recycle bin not autovivified if recycle bin is disabled';
    is $kdbx->entries->size, 0, 'Database is empty after removing entry';

    $kdbx->recycle_bin_enabled(1);

    $entry = $kdbx->add_entry(label => 'Another one');
    $entry->recycle_or_remove;
    cmp_ok $entry->is_recycled, '==', 1, 'Entry is recycled';

    $bin = $kdbx->groups->grep(name => 'Recycle Bin')->next;
    ok $bin, 'Recycle bin group autovivifies';
    cmp_ok $bin->icon_id, '==', 43, 'Recycle bin has the trash icon';
    cmp_ok $bin->enable_auto_type, '==', 0, 'Recycle bin has auto type disabled';
    cmp_ok $bin->enable_searching, '==', 0, 'Recycle bin has searching disabled';

    is $kdbx->entries->size, 1, 'Database is not empty';
    is $kdbx->entries(searching => 1)->size, 0, 'Database has no entries if searching';
    cmp_ok $bin->all_entries->size, '==', 1, 'Recycle bin has an entry';

    $entry->recycle_or_remove;
    is $kdbx->entries->size, 0, 'Remove entry if it is already in the recycle bin';
};

subtest 'Maintenance' => sub {
    my $kdbx = File::KDBX->new;
    $kdbx->add_group;
    $kdbx->add_group->add_group;
    my $entry = $kdbx->add_group->add_entry;

    cmp_ok $kdbx->remove_empty_groups, '==', 3, 'Remove two empty groups';
    cmp_ok $kdbx->groups->count, '==', 2, 'Two groups remain';

    $entry->begin_work;
    $entry->commit;
    cmp_ok $kdbx->prune_history(max_age => 5), '==', 0, 'Do not remove new historical entries';

    $entry->begin_work;
    $entry->commit;
    $entry->history->[0]->last_modification_time(scalar gmtime - 86400 * 10);
    cmp_ok $kdbx->prune_history(max_age => 5), '==', 1, 'Remove a historical entry';
    cmp_ok scalar @{$entry->history}, '==', 1, 'One historical entry remains';

    cmp_ok $kdbx->remove_unused_icons, '==', 0, 'No icons to remove';
    $kdbx->add_custom_icon('fake image 1');
    $kdbx->add_custom_icon('fake image 2');
    $entry->custom_icon('fake image 3');
    cmp_ok $kdbx->remove_unused_icons, '==', 2, 'Remove unused icons';
    cmp_ok scalar @{$kdbx->custom_icons}, '==', 1, 'Only one icon remains';

    my $icon_uuid = $kdbx->add_custom_icon('fake image');
    $entry->custom_icon('fake image');
    cmp_ok $kdbx->remove_duplicate_icons, '==', 1, 'Remove duplicate icons';
    is $entry->custom_icon_uuid, $icon_uuid, 'Uses of removed icon change';
};

subtest 'Dumping to filesystem' => sub {
    my $kdbx = File::KDBX->new;
    $kdbx->add_entry(title => 'Foo', password => 'whatever');

    my ($fh, $filepath) = tempfile('kdbx-XXXXXX', TMPDIR => 1, UNLINK => 1);
    close($fh);

    $kdbx->dump($filepath, 'a');

    my $kdbx2 = File::KDBX->load($filepath, 'a');
    my $entry = $kdbx2->entries->map(sub { $_->title.'/'.$_->expand_password })->next;
    is $entry, 'Foo/whatever', 'Dump and load an entry';

    $kdbx->dump($filepath, key => 'a', atomic => 0);

    $kdbx2 = File::KDBX->load($filepath, 'a');
    $entry = $kdbx2->entries->map(sub { $_->title.'/'.$_->expand_password })->next;
    is $entry, 'Foo/whatever', 'Dump and load an entry (non-atomic)';
};

done_testing;
