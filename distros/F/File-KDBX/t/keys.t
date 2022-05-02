#!/usr/bin/env perl

use warnings;
use strict;

use lib 't/lib';
use TestCommon;

use Crypt::Misc 0.029 qw(decode_b64 encode_b64);
use File::KDBX::Constants qw(:key_file);
use File::KDBX::Key;
use File::Temp qw(tempfile);
use Test::More;

subtest 'Primitives' => sub {
    my $pkey = File::KDBX::Key->new('password');
    isa_ok $pkey, 'File::KDBX::Key::Password';
    is $pkey->raw_key, decode_b64('XohImNooBHFR0OVvjcYpJ3NgPQ1qq73WKhHvch0VQtg='),
        'Can calculate raw key from password' or diag encode_b64($pkey->raw_key);

    my $fkey = File::KDBX::Key->new(\'password');
    isa_ok $fkey, 'File::KDBX::Key::File';
    is $fkey->raw_key, decode_b64('XohImNooBHFR0OVvjcYpJ3NgPQ1qq73WKhHvch0VQtg='),
        'Can calculate raw key from file' or diag encode_b64($fkey->raw_key);

    my $ckey = File::KDBX::Key->new([
        $pkey,
        $fkey,
        'another password',
        File::KDBX::Key::File->new(testfile(qw{keys hashed.key})),
    ]);
    isa_ok $ckey, 'File::KDBX::Key::Composite';
    is $ckey->raw_key, decode_b64('FLV8/zOT9mEL8QKkzizq7mJflnb25ITblIPq608MGrk='),
        'Can calculate raw key from composite' or diag encode_b64($ckey->raw_key);
};

for my $test (
    [KEY_FILE_TYPE_XML,     'xmlv1.key',   'OF9tj+tfww1kHNWQaJlZWIlBdoTVXOazP8g/vZK7NcI=', '1.0'],
    [KEY_FILE_TYPE_XML,     'xmlv2.key',   'OF9tj+tfww1kHNWQaJlZWIlBdoTVXOazP8g/vZK7NcI=', '2.0'],
    [KEY_FILE_TYPE_BINARY,  'binary.key',  'QlkDxuYbDPDpDXdK1470EwVBL+AJBH2gvPA9lxNkFEk='],
    [KEY_FILE_TYPE_HEX,     'hex.key',     'QlkDxuYbDPDpDXdK1470EwVBL+AJBH2gvPA9lxNkFEk='],
    [KEY_FILE_TYPE_HASHED,  'hashed.key',  '8vAO4mrMeq6iCa1FHeWm/Mj5al8HIv2ajqsqsSeUC6U='],
) {
    my ($type) = @$test;
    subtest "Load $type key file" => sub {
        my ($type, $filename, $expected_key, $version) = @_;

        my $key = File::KDBX::Key::File->new(testfile('keys', $filename));
        is $key->raw_key, decode_b64($expected_key),
            "Can calculate raw key from $type file" or diag encode_b64($key->raw_key);
        is $key->type, $type, "File type is detected as $type";
        is $key->version, $version, "File version is detected as $version" if defined $version;
    }, @$test;

    subtest "Save $type key file" => sub {
        my ($type, $filename, $expected_key, $version) = @_;

        my ($fh, $filepath) = tempfile('keyfile-XXXXXX', TMPDIR => 1, UNLINK => 1);
        close($fh);
        note $filepath;
        my $key = File::KDBX::Key::File->new(
            filepath    => $filepath,
            type        => $type,
            version     => $version,
            raw_key     => decode_b64($expected_key),
        );

        my $e = exception { $key->save };

        if ($type == KEY_FILE_TYPE_HASHED) {
            like $e, qr/invalid type/i, "Cannot save $type file";
            return;
        }
        is $e, undef, "Save $type file";

        my $key2 = File::KDBX::Key::File->new($filepath);
        is $key2->type, $key->type, 'Loaded key file has the same type';
        is $key2->raw_key, $key->raw_key, 'Loaded key file has the same raw key';
    }, @$test;
}

subtest 'IO handle key files' => sub {
    my $buf = 'password';
    open(my $fh, '<', \$buf) or die "open failed: $!\n";

    my $key = File::KDBX::Key::File->new($fh);
    is $key->raw_key, decode_b64('XohImNooBHFR0OVvjcYpJ3NgPQ1qq73WKhHvch0VQtg='),
        'Can calculate raw key from file handle' or diag encode_b64($key->raw_key);
    is $key->type, 'hashed', 'file type is detected as hashed';

    my ($fh_save, $filepath) = tempfile('keyfile-XXXXXX', TMPDIR => 1, UNLINK => 1);
    is exception { $key->save(fh => $fh_save, type => KEY_FILE_TYPE_XML) }, undef,
        'Save key file using IO handle';
    close($fh_save);

    my $key2 = File::KDBX::Key::File->new($filepath);
    is $key2->type, KEY_FILE_TYPE_XML, 'Loaded key file has the same type';
    is $key2->filepath, $filepath, 'Loaded key remembers the filepath';
    is $key2->raw_key, $key->raw_key, 'Loaded key file has the same raw key';
    $key2->reload;
    is $key2->raw_key, $key->raw_key, 'Raw key is the same when reloaded same file';

    my $easy_raw_key = "\1" x 32;
    $key->init(\$easy_raw_key);
    $key->save(filepath => $filepath);

    $key2->reload;
    is $key2->raw_key, "\1" x 32, 'Raw key is changed after reload';
};

subtest 'Key file error handling' => sub {
    is exception { File::KDBX::Key::File->new }, undef, 'Cannot instantiate uninitialized';

    like exception { File::KDBX::Key::File->init },
        qr/^Missing key primitive/, 'Throw if no primitive is provided';

    like exception { File::KDBX::Key::File->new(testfile(qw{keys nonexistent})) },
        qr/^Failed to open key file/, 'Throw if file is missing';

    like exception { File::KDBX::Key::File->new({}) },
        qr/^Unexpected primitive type/, 'Throw if primitive is the wrong type';
};

done_testing;
