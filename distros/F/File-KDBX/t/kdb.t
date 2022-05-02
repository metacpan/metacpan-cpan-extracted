#!/usr/bin/env perl

use warnings;
use strict;

use lib 't/lib';
use TestCommon;

use Encode qw(decode);
use File::KDBX;
use Test::Deep;
use Test::More;

eval { require File::KeePass; require File::KeePass::KDBX }
    or plan skip_all => 'File::KeePass and File::KeePass::KDBX required to test KDB files';

my $kdbx = File::KDBX->load(testfile('basic.kdb'), 'masterpw');

sub test_basic {
    my $kdbx = shift;

    cmp_deeply $kdbx->headers, superhashof({
        cipher_id => "1\301\362\346\277qCP\276X\5!j\374Z\377",
        encryption_iv => "\250\354q\362\13\247\353\247\222!\232\364Lj\315w",
        master_seed => "\212z\356\256\340+\n\243ms2\364'!7\216",
        transform_rounds => 713,
        transform_seed => "\227\264\n^\230\2\301:!f\364\336\251\277\241[\3`\314RG\343\16U\333\305eT3:\240\257",
    }), 'Get expected headers from KDB file' or diag explain $kdbx->headers;

    is keys %{$kdbx->deleted_objects}, 0, 'There are no deleted objects' or dumper $kdbx->deleted_objects;
    is scalar @{$kdbx->root->groups}, 2, 'Root group has two children';

    my $group1 = $kdbx->root->groups->[0];
    isnt $group1->uuid, undef, 'Group 1 has a UUID';
    is $group1->name, 'Internet', 'Group 1 has a name';
    is scalar @{$group1->groups}, 2, 'Group 1 has subgroups';
    is scalar @{$group1->entries}, 2, 'Group 1 has entries';
    is $group1->icon_id, 1, 'Group 1 has an icon';

    my ($entry11, $entry12, @other) = @{$group1->entries};

    isnt $entry11->uuid, undef, 'Entry has a UUID';
    is $entry11->title, 'Test entry', 'Entry has a title';
    is $entry11->icon_id, 1, 'Entry has an icon';
    is $entry11->username, 'I', 'Entry has a username';
    is $entry11->url, 'http://example.com/', 'Entry has a URL';
    is $entry11->password, 'secretpassword', 'Entry has a password';
    is $entry11->notes, "Lorem ipsum\ndolor sit amet", 'Entry has notes';
    ok $entry11->expires, 'Entry is expired';
    is $entry11->expiry_time, 'Wed May  9 10:32:00 2012', 'Entry has an expiration time';
    is scalar keys %{$entry11->binaries}, 1, 'Entry has a binary';
    is $entry11->binary_value('attachment.txt'), "hello world\n", 'Entry has a binary';

    is $entry12->title, '', 'Entry 2 has an empty title';
    is $entry12->icon_id, 0, 'Entry 2 has an icon';
    is $entry12->username, '', 'Entry 2 has an empty username';
    is $entry12->url, '', 'Entry 2 has an empty URL';
    is $entry12->password, '', 'Entry 2 has an empty password';
    is $entry12->notes, '', 'Entry 2 has empty notes';
    ok !$entry12->expires, 'Entry 2 is not expired';
    is scalar keys %{$entry12->binaries}, 0, 'Entry has no binaries';

    my $group11 = $group1->groups->[0];
    is $group11->label, 'Subgroup 1', 'Group has subgroup';
    is scalar @{$group11->groups}, 1, 'Subgroup has subgroup';

    my $group111 = $group11->groups->[0];
    is $group111->label, 'Unexpanded', 'Has unexpanded group';
    is scalar @{$group111->groups}, 1, 'Subgroup has subgroup';

    my $group1111 = $group111->groups->[0];
    is $group1111->label, 'abc', 'Group has subsubsubroup';
    is scalar @{$group1111->groups}, 0, 'No more subgroups';

    my $group12 = $group1->groups->[1];
    is $group12->label, 'Subgroup 2', 'Group has another subgroup';
    is scalar @{$group12->groups}, 0, 'No more subgroups';

    my $group2 = $kdbx->root->groups->[1];
    is $group2->label, 'eMail', 'Root has another subgroup';
    is scalar @{$group2->entries}, 1, 'eMail group has an entry';
    is $group2->icon_id, 19, 'Group has a standard icon';
}
for my $test (
    ['Basic' => $kdbx],
    ['Basic after dump & load roundtrip'
        => File::KDBX->load_string($kdbx->dump_string('a', randomize_seeds => 0), 'a')],
) {
    my ($name, $kdbx) = @$test;
    subtest $name, \&test_basic, $kdbx;
}

sub test_custom_icons {
    my $kdbx = shift;
    $kdbx = $kdbx->() if ref $kdbx eq 'CODE';

    my ($icon, @other) = @{$kdbx->custom_icons};
    ok $icon, 'Database has a custom icon';
    is scalar @other, 0, 'Database has no other icons';

    like $icon->{data}, qr/^\x89PNG\r\n/, 'Custom icon is a PNG';
}
for my $test (
    ['Custom icons' => $kdbx],
    ['Custom icons after dump & load roundtrip' => sub {
        File::KDBX->load_string($kdbx->dump_string('a', allow_upgrade => 0, randomize_seeds => 0), 'a');
    }],
) {
    my ($name, $kdbx) = @$test;
    subtest $name, \&test_custom_icons, $kdbx;
}

subtest 'Group expansion' => sub {
    is $kdbx->root->groups->[0]->is_expanded, 1, 'Group is expanded';
    is $kdbx->root->groups->[0]->groups->[0]->is_expanded, 1, 'Subgroup is expanded';
    is $kdbx->root->groups->[0]->groups->[0]->groups->[0]->is_expanded, 0, 'Subsubgroup is not expanded';
};

subtest 'Autotype' => sub {
    my $group = $kdbx->root->groups->[0]->groups->[0];
    is scalar @{$group->entries}, 2, 'Group has two entries';

    my ($entry1, $entry2) = @{$group->entries};

    is $entry1->notes, "\nlast line", 'First entry has a note';
    TODO: {
        local $TODO = 'File::KeePass fails to parse out the default key sequence';
        is $entry1->auto_type->{default_sequence}, '{USERNAME}{ENTER}', 'First entry has a default sequence';
    };
    cmp_deeply $entry1->auto_type->{associations}, set(
        {
            keystroke_sequence => "{USERNAME}{ENTER}",
            window => "a window",
        },
        {
            keystroke_sequence => "{USERNAME}{ENTER}",
            window => "a second window",
        },
        {
            keystroke_sequence => "{PASSWORD}{ENTER}",
            window => "Window Nr 1a",
        },
        {
            keystroke_sequence => "{PASSWORD}{ENTER}",
            window => "Window Nr 1b",
        },
        {
            keystroke_sequence => "{USERNAME}{ENTER}",
            window => "Window 2",
        },
    ), 'First entry has auto-type window associations';

    is $entry2->notes, "start line\nend line", 'Second entry has notes';
    TODO: {
        local $TODO = 'File::KeePass fails to parse out the default key sequence';
        is $entry2->auto_type->{default_sequence}, '', 'Second entry has no default sequence';
        cmp_deeply $entry2->auto_type->{associations}, set(
            {
                keystroke_sequence => "",
                window => "Main Window",
            },
            {
                keystroke_sequence => "",
                window => "Test Window",
            },
        ), 'Second entry has auto-type window associations' or diag explain $entry2->auto_type->{associations};
    };
};

subtest 'KDB file keys' => sub {
    while (@_) {
        my ($name, $key) = splice @_, 0, 2;
        my $kdb_filepath = testfile("$name.kdb");
        my $kdbx = File::KDBX->load($kdb_filepath, $key);

        is $kdbx->root->name, $name, "Loaded KDB database with root group is named $name";
    }
}, (
    FileKeyBinary   => {file => testfile('FileKeyBinary.key')},
    FileKeyHex      => {file => testfile('FileKeyHex.key')},
    FileKeyHashed   => {file => testfile('FileKeyHashed.key')},
    CompositeKey    => ['mypassword', {file => testfile('FileKeyHex.key')}],
);

subtest 'Twofish' => sub {
    plan skip_all => 'File::KeePass does not implement the Twofish cipher';
    my $name = 'Twofish';
    my $kdbx = File::KDBX->load(testfile("$name.kdb"), 'masterpw');
    is $kdbx->root->name, $name, "Loaded KDB database with root group is named $name";
};

subtest 'CP-1252 password' => sub {
    my $name = 'CP-1252';
    my $kdbx = File::KDBX->load(testfile("$name.kdb"),
        decode('UTF-8', "\xe2\x80\x9e\x70\x61\x73\x73\x77\x6f\x72\x64\xe2\x80\x9d"));
    is $kdbx->root->name, $name, "Loaded KDB database with root group is named $name";
};

done_testing;
