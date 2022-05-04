#!/usr/bin/env perl

use utf8;
use warnings;
use strict;

use lib 't/lib';
use TestCommon;

use File::KDBX;
use File::KDBX::Constants qw(:version);
use Test::Deep;
use Test::More;

subtest 'Verify Format300' => sub {
    my $kdbx = File::KDBX->load(testfile('Format300.kdbx'), 'a');

    ok_magic $kdbx, KDBX_VERSION_3_0, 'Get the correct KDBX3 file magic';

    cmp_deeply $kdbx->headers, {
        cipher_id => "1\301\362\346\277qCP\276X\5!j\374Z\377",
        compression_flags => 1,
        encryption_iv => "\214\306\310\0322\a9P\230\306\253\326\17\214\344\255",
        inner_random_stream_id => 2,
        inner_random_stream_key => "\346\n8\2\322\264i\5\5\274\22\377+\16tB\353\210\1\2m\2U%\326\347\355\313\313\340A\305",
        kdf_parameters => {
            "\$UUID" => "\311\331\363\232b\212D`\277t\r\b\301\212O\352",
            R => num(6000),
            S => "\340\377\235\255\222o\1(\226m\373\tC{K\352\f\332M\302|~P\e\346J\@\275A\227\236\366",
        },
        master_seed => "Z\230\355\353\2303\361\237-p\345\27nM\22<E\252\314k\20\257\302\343p\"y\5sfw ",
        stream_start_bytes => "\276\277jI1_\325\a\375\22\3\366\2V\"\316\370\316E\250B\317\232\232\207K\345.P\256b/",
    }, 'Extract headers' or diag explain $kdbx->headers;

    is $kdbx->meta->{database_name}, 'Test Database Format 0x00030000', 'Extract database name from meta';
    is $kdbx->root->name, 'Format300', 'Extract name of root group';
};

subtest 'Verify NonAscii' => sub {
    my $kdbx = File::KDBX->load(testfile('NonAscii.kdbx'), 'Δöض');

    ok_magic $kdbx, KDBX_VERSION_3_1, 'Get the correct KDBX3 file magic';

    cmp_deeply $kdbx->headers, {
        cipher_id => "1\301\362\346\277qCP\276X\5!j\374Z\377",
        compression_flags => 0,
        encryption_iv => "\264\256\210m\311\312s\274U\206\t^\202\323\365]",
        inner_random_stream_id => 2,
        inner_random_stream_key => "Z\244]\373\13`\2108=>\r\224\351\373\316\276\253\6\317z\356\302\36\fW\1776Q\366\32\34,",
        kdf_parameters => {
            "\$UUID" => "\311\331\363\232b\212D`\277t\r\b\301\212O\352",
            R => num(6000),
            S => "l\254\250\255\240U\313\364\336\316#\254\306\231\f%U\207J\235\275\34\b\25036\26\241\a\300\26\332",
        },
        master_seed => "\13\350\370\214{\0276\17dv\31W[H\26\272\4\335\377\356\275N\"\2A1\364\213\226\237\303M",
        stream_start_bytes => "\220Ph\27\"h\233^\263mf\3339\262U\313\236zF\f\23\b9\323\346=\272\305})\240T",
    }, 'Extract headers' or diag explain $kdbx->headers;

    is $kdbx->meta->{database_name}, 'NonAsciiTest', 'Extract database name from meta';
};

subtest 'Verify Compressed' => sub {
    my $kdbx = File::KDBX->load(testfile('Compressed.kdbx'), '');

    ok_magic $kdbx, KDBX_VERSION_3_1, 'Get the correct KDBX3 file magic';

    cmp_deeply $kdbx->headers, {
        cipher_id => "1\301\362\346\277qCP\276X\5!j\374Z\377",
        compression_flags => 1,
        encryption_iv => "Z(\313\342\212x\f\326\322\342\313\320\352\354:S",
        inner_random_stream_id => 2,
        inner_random_stream_key => "+\232\222\302\20\333\254\342YD\371\34\373,\302:\303\247\t\26\$\a\370g\314\32J\240\371;U\234",
        kdf_parameters => {
            "\$UUID" => "\311\331\363\232b\212D`\277t\r\b\301\212O\352",
            R => num(6000),
            S => "\3!\230hx\363\220nV\23\340\316\262\210\26Z\al?\343\240\260\325\262\31i\223y\b\306\344V",
        },
        master_seed => "\0206\244\265\203m14\257T\372o\16\271\306\347\215\365\376\304\20\356\344\3713\3\303\363\a\5\205\325",
        stream_start_bytes => "i%Ln\30\r\261\212Q\266\b\201\et\342\203\203\374\374E\303\332\277\320\13\304a\223\215#~\266",
    }, 'Extract headers' or diag explain $kdbx->headers;

    is $kdbx->meta->{database_name}, 'Compressed', 'Extract database name from meta';
};

subtest 'Verify ProtectedStrings' => sub {
    my $kdbx = File::KDBX->load(testfile('ProtectedStrings.kdbx'), 'masterpw');

    ok_magic $kdbx, KDBX_VERSION_3_1, 'Get the correct KDBX3 file magic';

    cmp_deeply $kdbx->headers, {
        cipher_id => "1\301\362\346\277qCP\276X\5!j\374Z\377",
        compression_flags => 1,
        encryption_iv => "\0177y\356&\217\215\244\341\312\317Z\246m\363\251",
        inner_random_stream_id => 2,
        inner_random_stream_key => "%M\333Z\345\22T\363\257\27\364\206\352\334\r\3\361\250\360\314\213\253\237\23B\252h\306\243(7\13",
        kdf_parameters => ignore(),
        kdf_parameters => {
            "\$UUID" => "\311\331\363\232b\212D`\277t\r\b\301\212O\352",
            R => num(6000),
            S => "y\251\327\312mW8B\351\273\364#T#m:\370k1\240v\360E\245\304\325\265\313\337\245\211E",
        },
        master_seed => "\355\32<1\311\320\315\24\204\325\250\35+\2525\321\224x?\361\355\310V\322\20\331\324\"\372\334\210\233",
        stream_start_bytes => "D#\337\260,\340.\276\312\302N\336y\233\275\360\250|\272\346*.\360\256\232\220\263>\303\aQ\371",
    }, 'Extract headers' or diag explain $kdbx->headers;

    is $kdbx->meta->{database_name}, 'Protected Strings Test', 'Extract database name from meta';

    my $entry = $kdbx->entries->next;
    is $entry->title, 'Sample Entry', 'Get entry title';

    is $entry->string_peek('Password'), 'ProtectedPassword', 'Peek at password from entry';
    is $entry->string_peek('TestProtected'), 'ABC', 'Peek at protected string from entry';
    $kdbx->unlock;
    is $entry->username, 'Protected User Name', 'Get protected username from entry';
    is $entry->password, 'ProtectedPassword', 'Get protected password from entry';
    is $entry->string_value('TestProtected'), 'ABC', 'Get ABC string from entry';
    is $entry->string_value('TestUnprotected'), 'DEF', 'Get DEF string from entry';

    ok $kdbx->meta->{memory_protection}{protect_password}, 'Memory protection is ON for passwords';
    ok $entry->string('TestProtected')->{protect}, 'Protection is ON for TestProtected';
    ok !$entry->string('TestUnprotected')->{protect}, 'Protection is OFF for TestUnprotected';
};

subtest 'Verify BrokenHeaderHash' => sub {
    like exception { File::KDBX->load(testfile('BrokenHeaderHash.kdbx'), '') },
        qr/header hash does not match/i, 'Fail to load a database with a corrupted header hash';
};

subtest 'Dump and load' => sub {
    my $kdbx = File::KDBX->new;
    my $dump = $kdbx->dump_string('foo');
    ok $dump;
};

done_testing;
