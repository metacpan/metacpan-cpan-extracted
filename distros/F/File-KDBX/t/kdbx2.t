#!/usr/bin/env perl

use warnings;
use strict;

use lib 't/lib';
use TestCommon;

use File::KDBX;
use File::KDBX::Constants qw(:version :kdf);
use Test::Deep;
use Test::More;

my $kdbx = File::KDBX->load(testfile('Format200.kdbx'), 'a');

verify_kdbx2($kdbx, KDBX_VERSION_2_0);
is $kdbx->kdf->uuid, KDF_UUID_AES, 'KDBX2 file has a usable KDF configured';

my $dump;
like warning { $dump = $kdbx->dump_string('a', randomize_seeds => 0) }, qr/upgrading database/i,
    'There is a warning about a change in file version when writing';

my $kdbx_from_dump = File::KDBX->load_string($dump, 'a');
verify_kdbx2($kdbx_from_dump, KDBX_VERSION_3_1);
is $kdbx->kdf->uuid, KDF_UUID_AES, 'New KDBX3 file has the same KDF';

sub verify_kdbx2 {
    my $kdbx = shift;
    my $vers = shift;

    ok_magic $kdbx, $vers, 'Get the correct KDBX2 file magic';

    cmp_deeply $kdbx->headers, superhashof({
        cipher_id => "1\301\362\346\277qCP\276X\5!j\374Z\377",
        compression_flags => 1,
        encryption_iv => "D+VZ\277\274>\226K\225\3237\255\231\35\4",
        inner_random_stream_id => 2,
        inner_random_stream_key => "\214\aW\253\362\177<\346n`\263l\245\353T\25\261BnFp\177\357\335\36(b\372z\231b\355",
        kdf_parameters => {
            "\$UUID" => "\311\331\363\232b\212D`\277t\r\b\301\212O\352",
            R => 6000,
            S => "S\202\207A\3475\265\177\220\331\263[\334\326\365\324B\\\2222zb-f\263m\220\333S\361L\332",
        },
        master_seed => "\253!\2\241\r*|{\227\0276Lx\215\32\\\17\372d\254\255*\21r\376\251\313+gMI\343",
        stream_start_bytes => "\24W\24\3262oU\t>\242B\2666:\231\377\36\3\353 \217M\330U\35\367|'\230\367\221^",
    }), 'Get expected headers from KDBX2 file' or diag explain $kdbx->headers;

    cmp_deeply $kdbx->meta, superhashof({
        custom_data => {},
        database_description => "",
        database_description_changed => obj_isa('Time::Piece'),
        database_name => "",
        database_name_changed => obj_isa('Time::Piece'),
        default_username => "",
        default_username_changed => obj_isa('Time::Piece'),
        entry_templates_group => "\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0",
        entry_templates_group_changed => obj_isa('Time::Piece'),
        generator => ignore(),
        last_selected_group => "\226Y\251\22\356zB\@\214\222ns\273a\263\221",
        last_top_visible_group => "\226Y\251\22\356zB\@\214\222ns\273a\263\221",
        maintenance_history_days => 365,
        memory_protection => superhashof({
            protect_notes => bool(0),
            protect_password => bool(0),
            protect_title => bool(0),
            protect_url => bool(1),
            protect_username => bool(1),
        }),
        recycle_bin_changed => obj_isa('Time::Piece'),
        recycle_bin_enabled => bool(1),
        recycle_bin_uuid => "\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0",
    }), 'Get expected metadata from KDBX2 file' or diag explain $kdbx->meta;

    $kdbx->unlock;

    is scalar @{$kdbx->root->entries}, 1, 'Get one entry in root';

    my $entry = $kdbx->root->entries->[0];
    is $entry->title, 'Sample Entry', 'Get the correct title';
    is $entry->username, 'User Name', 'Get the correct username';

    cmp_deeply $entry->binaries, {
        "myattach.txt" => {
            value => "abcdefghijk",
        },
        "test.txt" => {
            value => "this is a test",
        },
    }, 'Get two attachments from the entry' or diag explain $entry->binaries;

    my @history = @{$entry->history};
    is scalar @history, 2, 'Get two historical entries';
    is scalar keys %{$history[0]->binaries}, 0, 'First historical entry has no attachments';
    is scalar keys %{$history[1]->binaries}, 1, 'Second historical entry has one attachment';
    cmp_deeply $history[1]->binary('myattach.txt'), {
        value => 'abcdefghijk',
    }, 'The attachment has the correct content';
}

done_testing;
