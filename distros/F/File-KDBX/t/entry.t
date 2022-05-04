#!/usr/bin/env perl

use warnings;
use strict;

use lib 't/lib';
use TestCommon;

use File::KDBX::Entry;
use File::KDBX;
use Test::Deep;
use Test::More;

subtest 'Construction' => sub {
    my $entry = File::KDBX::Entry->new(my $data = {username => 'foo'});
    is $entry, $data, 'Provided data structure becomes the object';
    isa_ok $data, 'File::KDBX::Entry', 'Data structure is blessed';
    is $entry->{username}, 'foo', 'username is in the object still';
    is $entry->username, '', 'username is not the UserName string';

    like exception { $entry->kdbx }, qr/disconnected/, 'Dies if disconnected';
    $entry->kdbx(my $kdbx = File::KDBX->new);
    is $entry->kdbx, $kdbx, 'Set a database after instantiation';

    is_deeply $entry, {username => 'foo', strings => {UserName => {value => ''}}},
        'Entry data contains what was provided to the constructor plus vivified username';

    $entry = File::KDBX::Entry->new(username => 'bar');
    is $entry->{username}, undef, 'username is not set on the data';
    is $entry->username, 'bar', 'username is set correctly as the UserName string';

    cmp_deeply $entry, noclass({
        auto_type => {
            associations => [],
            data_transfer_obfuscation => 0,
            default_sequence => "{USERNAME}{TAB}{PASSWORD}{ENTER}",
            enabled => bool(1),
        },
        background_color => "",
        binaries => {},
        custom_data => {},
        custom_icon_uuid => undef,
        foreground_color => "",
        history => [],
        icon_id => "Password",
        override_url => "",
        previous_parent_group => undef,
        quality_check => bool(1),
        strings => {
            Notes => {
                value => "",
            },
            Password => {
                protect => bool(1),
                value => "",
            },
            Title => {
                value => "",
            },
            URL => {
                value => "",
            },
            UserName => {
                value => "bar",
            },
        },
        tags => "",
        times => {
            last_modification_time => isa('Time::Piece'),
            creation_time => isa('Time::Piece'),
            last_access_time => isa('Time::Piece'),
            expiry_time => isa('Time::Piece'),
            expires => bool(0),
            usage_count => 0,
            location_changed => isa('Time::Piece'),
        },
        uuid => re('^(?s:.){16}$'),
    }), 'Entry data contains UserName string and the rest default attributes';
};

subtest 'Accessors' => sub {
    my $entry = File::KDBX::Entry->new;

    $entry->creation_time('2022-02-02 12:34:56');
    cmp_ok $entry->creation_time->epoch, '==', 1643805296, 'Creation time coerced into a Time::Piece (epoch)';
    is $entry->creation_time->datetime, '2022-02-02T12:34:56', 'Creation time coerced into a Time::Piece';
};

subtest 'Custom icons' => sub {
    plan tests => 10;
    my $gif = pack('H*', '4749463839610100010000ff002c00000000010001000002003b');

    my $entry = File::KDBX::Entry->new(my $kdbx = File::KDBX->new, icon_id => 42);
    is $entry->custom_icon_uuid, undef, 'UUID is undef if no custom icon is set';
    is $entry->custom_icon, undef, 'Icon is undef if no custom icon is set';
    is $entry->icon_id, 'KCMMemory', 'Default icon is set to something';

    is $entry->custom_icon($gif), $gif, 'Setting a custom icon returns icon';
    is $entry->custom_icon, $gif, 'Henceforth the icon is set';
    is $entry->icon_id, 'Password', 'Default icon got changed to first icon';
    my $uuid = $entry->custom_icon_uuid;
    isnt $uuid, undef, 'UUID is now set';

    my $found = $entry->kdbx->custom_icon_data($uuid);
    is $entry->custom_icon, $found, 'Custom icon on entry matches the database';

    is $entry->custom_icon(undef), undef, 'Unsetting a custom icon returns undefined';
    $found = $entry->kdbx->custom_icon_data($uuid);
    is $found, $gif, 'Custom icon still exists in the database';
};

subtest 'History' => sub {
    my $kdbx = File::KDBX->new;
    my $entry = $kdbx->add_entry(label => 'Foo');
    is scalar @{$entry->history}, 0, 'New entry starts with no history';
    is $entry->current_entry, $entry, 'Current new entry is itself';
    ok $entry->is_current, 'New entry is current';

    my $txn = $entry->begin_work;
    $entry->notes('Hello!');
    $txn->commit;
    is scalar @{$entry->history}, 1, 'Committing creates a historical entry';
    ok $entry->is_current, 'New entry is still current';
    ok $entry->history->[0]->is_historical, 'Historical entry is not current';
    is $entry->notes, 'Hello!', 'New entry is modified after commit';
    is $entry->history->[0]->notes, '', 'Historical entry is saved without modification';
};

subtest 'Update UUID' => sub {
    my $kdbx = File::KDBX->new;

    my $entry1 = $kdbx->add_entry(label => 'Foo');
    my $entry2 = $kdbx->add_entry(label => 'Bar');

    $entry2->url(sprintf('{REF:T@I:%s} {REF:T@I:%s}', $entry1->id, lc($entry1->id)));
    is $entry2->expand_url, 'Foo Foo', 'Field reference expands'
        or diag explain $entry2->url;

    $entry1->uuid("\1" x 16);

    is $entry2->url, '{REF:T@I:01010101010101010101010101010101} {REF:T@I:01010101010101010101010101010101}',
        'Replace field references when an entry UUID is changed';
    is $entry2->expand_url, 'Foo Foo', 'Field reference expands after UUID is changed'
        or diag explain $entry2->url;
};

subtest 'Auto-type' => sub {
    my $kdbx = File::KDBX->new;

    my $entry = $kdbx->add_entry(title => 'Meh');
    $entry->add_auto_type_association({
        window              => 'Boring Store',
        keystroke_sequence  => 'yeesh',
    });
    $entry->add_auto_type_association({
        window              => 'Friendly Bank',
        keystroke_sequence  => 'blah',
    });

    my $window_title = 'Friendly';
    my $entries = $kdbx->entries(auto_type => 1)
    ->filter(sub {
        my ($ata) = grep { $_->{window} =~ /\Q$window_title\E/i } @{$_->auto_type_associations};
        return [$_, $ata->{keystroke_sequence} || $_->auto_type_default_sequence] if $ata;
    });
    cmp_ok $entries->count, '==', 1, 'Find auto-type window association';

    (undef, my $keys) = @{$entries->next};
    is $keys, 'blah', 'Select the correct association';
};

done_testing;
