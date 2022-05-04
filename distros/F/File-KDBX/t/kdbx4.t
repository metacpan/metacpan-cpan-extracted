#!/usr/bin/env perl

use utf8;
use warnings;
use strict;

use lib 't/lib';
use TestCommon;

use File::KDBX;
use File::KDBX::Constants qw(:version :kdf);
use Test::Deep;
use Test::More;
use boolean qw(:all);

subtest 'Verify Format400' => sub {
    my $kdbx = File::KDBX->load(testfile('Format400.kdbx'), 't');
    $kdbx->unlock;

    ok_magic $kdbx, KDBX_VERSION_4_0, 'Get the correct KDBX4 file magic';

    cmp_deeply $kdbx->headers, {
        cipher_id => "\326\3\212+\213oL\265\245\$3\2321\333\265\232",
        compression_flags => 1,
        encryption_iv => "3?\207P\233or\220\215h\2240",
        kdf_parameters => {
            "\$UUID" => "\357cm\337\214)DK\221\367\251\244\3\343\n\f",
            I => num(2),
            M => num(1048576),
            P => num(2),
            S => "V\254\6m-\206*\260\305\f\0\366\24:4\235\364A\362\346\221\13)}\250\217P\303\303\2\331\245",
            V => num(19),
        },
        master_seed => ";\372y\300yS%\3331\177\231\364u\265Y\361\225\3273h\332R,\22\240a\240\302\271\357\313\23",
    }, 'Extract headers' or diag explain $kdbx->headers;

    is $kdbx->meta->{database_name}, 'Format400', 'Extract database name from meta';
    is $kdbx->root->name, 'Format400', 'Extract name of root group';

    my ($entry, @other) = $kdbx->entries->grep(\'400', 'title')->each;
    is scalar @other, 0, 'Database has one entry';

    is $entry->title, 'Format400', 'Entry is titled';
    is $entry->username, 'Format400', 'Entry has a username set';
    is keys %{$entry->strings}, 6, 'Entry has six strings';
    is $entry->string_value('Format400'), 'Format400', 'Entry has a custom string';
    is keys %{$entry->binaries}, 1, 'Entry has one binary';
    is $entry->binary_value('Format400'), "Format400\n", 'Entry has a binary string';
};

subtest 'KDBX4 upgrade' => sub {
    my $kdbx = File::KDBX->new;

    $kdbx->kdf_parameters->{+KDF_PARAM_UUID} = KDF_UUID_AES_CHALLENGE_RESPONSE;
    is $kdbx->minimum_version, KDBX_VERSION_4_0, 'AES challenge-response KDF requires upgrade';
    $kdbx->kdf_parameters->{+KDF_PARAM_UUID} = KDF_UUID_ARGON2D;
    is $kdbx->minimum_version, KDBX_VERSION_4_0, 'Argon2D KDF requires upgrade';
    $kdbx->kdf_parameters->{+KDF_PARAM_UUID} = KDF_UUID_ARGON2ID;
    is $kdbx->minimum_version, KDBX_VERSION_4_0, 'Argon2ID KDF requires upgrade';
    $kdbx->kdf_parameters->{+KDF_PARAM_UUID} = KDF_UUID_AES;
    is $kdbx->minimum_version, KDBX_VERSION_3_1, 'Reset upgrade requirement';

    $kdbx->public_custom_data->{foo} = 42;
    is $kdbx->minimum_version, KDBX_VERSION_4_0, 'Public custom data requires upgrade';
    delete $kdbx->public_custom_data->{foo};
    is $kdbx->minimum_version, KDBX_VERSION_3_1, 'Reset upgrade requirement';

    my $entry = $kdbx->add_entry;
    $entry->custom_data(foo => 'bar');
    is $kdbx->minimum_version, KDBX_VERSION_4_0, 'Entry custom data requires upgrade';
    delete $entry->custom_data->{foo};
    is $kdbx->minimum_version, KDBX_VERSION_3_1, 'Reset upgrade requirement';

    my $group = $kdbx->add_group;
    $group->custom_data(foo => 'bar');
    is $kdbx->minimum_version, KDBX_VERSION_4_0, 'Group custom data requires upgrade';
    delete $group->custom_data->{foo};
    is $kdbx->minimum_version, KDBX_VERSION_3_1, 'Reset upgrade requirement';
};

subtest 'KDBX4.1 upgrade' => sub {
    my $kdbx = File::KDBX->new;

    my $group1 = $kdbx->add_group(label => 'One');
    my $group2 = $kdbx->add_group(label => 'Two');
    my $entry1 = $kdbx->add_entry(label => 'Meh');

    $group1->tags('hi');
    is $kdbx->minimum_version, KDBX_VERSION_4_1, 'Groups with tags requires upgrade';
    $group1->tags('');
    is $kdbx->minimum_version, KDBX_VERSION_3_1, 'Reset upgrade requirement';

    $entry1->quality_check(0);
    is $kdbx->minimum_version, KDBX_VERSION_4_1, 'Disable entry quality check requires upgrade';
    $entry1->quality_check(1);
    is $kdbx->minimum_version, KDBX_VERSION_3_1, 'Reset upgrade requirement';

    $group1->previous_parent_group($group2->uuid);
    is $kdbx->minimum_version, KDBX_VERSION_4_1, 'Previous parent group on group requires upgrade';
    $group1->previous_parent_group(undef);
    is $kdbx->minimum_version, KDBX_VERSION_3_1, 'Reset upgrade requirement';

    $entry1->previous_parent_group($group2->uuid);
    is $kdbx->minimum_version, KDBX_VERSION_4_1, 'Previous parent group on entry requires upgrade';
    $entry1->previous_parent_group(undef);
    is $kdbx->minimum_version, KDBX_VERSION_3_1, 'Reset upgrade requirement';

    $kdbx->add_custom_icon('data');
    is $kdbx->minimum_version, KDBX_VERSION_3_1, 'Icon with no metadata requires no upgrade';
    my $icon_uuid = $kdbx->add_custom_icon('data2', name => 'icon name');
    is $kdbx->minimum_version, KDBX_VERSION_4_1, 'Icon with name requires upgrade';
    $kdbx->remove_custom_icon($icon_uuid);
    is $kdbx->minimum_version, KDBX_VERSION_3_1, 'Reset upgrade requirement';
    $icon_uuid = $kdbx->add_custom_icon('data2', last_modification_time => gmtime);
    is $kdbx->minimum_version, KDBX_VERSION_4_1, 'Icon with modtime requires upgrade';
    $kdbx->remove_custom_icon($icon_uuid);
    is $kdbx->minimum_version, KDBX_VERSION_3_1, 'Reset upgrade requirement';

    $entry1->custom_data(foo => 'bar', last_modification_time => scalar gmtime);
    is $kdbx->minimum_version, KDBX_VERSION_4_1, 'Entry custom data modtime requires upgrade';
    delete $entry1->custom_data->{foo};
    is $kdbx->minimum_version, KDBX_VERSION_3_1, 'Reset upgrade requirement';

    $group1->custom_data(foo => 'bar', last_modification_time => scalar gmtime);
    is $kdbx->minimum_version, KDBX_VERSION_4_1, 'Group custom data modtime requires upgrade';
    delete $group1->custom_data->{foo};
    is $kdbx->minimum_version, KDBX_VERSION_3_1, 'Reset upgrade requirement';
};

sub test_upgrade_master_key_integrity {
    my ($modifier, $expected_version) = @_;
    plan tests => $expected_version >= KDBX_VERSION_4_0 ? 6 : 5;

    my $kdbx = File::KDBX->new;
    $kdbx->kdf_parameters(fast_kdf);

    is $kdbx->kdf->uuid, KDF_UUID_AES, 'Default KDF is AES';

    {
        local $_ = $kdbx;
        $modifier->($kdbx);
    }
    is $kdbx->minimum_version, $expected_version,
        sprintf('Got expected minimum version after modification: %x', $kdbx->minimum_version);

    my $master_key = ['fffqcvq4rc', \'this is a keyfile', sub { 'chalresp 523rf2' }];
    my $dump;
    warnings { $kdbx->dump_string(\$dump, $master_key) };
    ok $dump, 'Can dump the database' or diag explain $dump;

    like exception { File::KDBX->load_string($dump, 'wrong key') },
        qr/invalid credentials/i, 'Cannot load a KDBX with the wrong key';

    # print STDERR "DUMP: [$dump]\n";

    my $kdbx2 = File::KDBX->load_string($dump, $master_key);

    is $kdbx2->version, $expected_version, sprintf('Got expected version: %x', $kdbx2->version);
    isnt $kdbx2->kdf->uuid, KDF_UUID_AES, 'No unexpected KDF' if $kdbx2->version >= KDBX_VERSION_4_0;

    # diag explain(File::KDBX->load_string($dump, $master_key, inner_format => 'Raw')->raw);
}
for my $test (
    [KDBX_VERSION_3_1, 'nothing', sub {}],
    [KDBX_VERSION_3_1, 'AES KDF', sub { $_->kdf_parameters(fast_kdf(KDF_UUID_AES)) }],
    [KDBX_VERSION_4_0, 'Argon2D KDF', sub { $_->kdf_parameters(fast_kdf(KDF_UUID_ARGON2D)) }],
    [KDBX_VERSION_4_0, 'Argon2ID KDF', sub { $_->kdf_parameters(fast_kdf(KDF_UUID_ARGON2ID)) }],
    [KDBX_VERSION_4_0, 'public custom data', sub { $_->public_custom_data->{foo} = 'bar' }],
    [KDBX_VERSION_3_1, 'custom data', sub { $_->custom_data(foo => 'bar') }],
    [KDBX_VERSION_4_0, 'root group custom data', sub { $_->root->custom_data(baz => 'qux') }],
    [KDBX_VERSION_4_0, 'group custom data', sub { $_->add_group->custom_data(baz => 'qux') }],
    [KDBX_VERSION_4_0, 'entry custom data', sub { $_->add_entry->custom_data(baz => 'qux') }],
) {
    my ($expected_version, $name, $modifier) = @$test;
    subtest "Master key integrity: $name" => \&test_upgrade_master_key_integrity,
        $modifier, $expected_version;
}

subtest 'Custom data' => sub {
    my $kdbx = File::KDBX->new;
    $kdbx->kdf_parameters(fast_kdf(KDF_UUID_AES));
    $kdbx->version(KDBX_VERSION_4_0);

    $kdbx->public_custom_data->{str} = '你好';
    $kdbx->public_custom_data->{num} = 42;
    $kdbx->public_custom_data->{bool} = true;
    $kdbx->public_custom_data->{bytes} = "\1\2\3\4";

    my $group = $kdbx->add_group(label => 'Group');
    $group->custom_data(str => '你好');
    $group->custom_data(num => 42);
    $group->custom_data(bool => true);

    my $entry = $kdbx->add_entry(label => 'Entry');
    $entry->custom_data(str => '你好');
    $entry->custom_data(num => 42);
    $entry->custom_data(bool => false);

    my $dump = $kdbx->dump_string('a');
    my $kdbx2 = File::KDBX->load_string($dump, 'a');

    is $kdbx2->public_custom_data->{str}, '你好', 'Store a string in public custom data';
    cmp_ok $kdbx2->public_custom_data->{num}, '==', 42, 'Store a number in public custom data';
    is $kdbx2->public_custom_data->{bool}, true, 'Store a boolean in public custom data';
    ok isBoolean($kdbx2->public_custom_data->{bool}), 'Boolean is indeed a boolean';
    is $kdbx2->public_custom_data->{bytes}, "\1\2\3\4", 'Store some bytes in public custom data';

    my $group2 = $kdbx2->groups->grep(label => 'Group')->next;
    is_deeply $group2->custom_data_value('str'), '你好', 'Store a string in group custom data';
    is_deeply $group2->custom_data_value('num'), '42', 'Store a number in group custom data';
    is_deeply $group2->custom_data_value('bool'), '1', 'Store a boolean in group custom data';

    my $entry2 = $kdbx2->entries->grep(label => 'Entry')->next;
    is_deeply $entry2->custom_data_value('str'), '你好', 'Store a string in entry custom data';
    is_deeply $entry2->custom_data_value('num'), '42', 'Store a number in entry custom data';
    is_deeply $entry2->custom_data_value('bool'), '0', 'Store a boolean in entry custom data';
};

done_testing;
