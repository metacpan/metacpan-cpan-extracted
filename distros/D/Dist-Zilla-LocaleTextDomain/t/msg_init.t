#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More 0.90;
use Test::DZil;
use IPC::Cmd 'can_run';
use Path::Tiny;
use Test::File;
use Test::File::Contents;
use Dist::Zilla::App::Tester;
use App::Cmd::Tester::CaptureExternal;

BEGIN {
    # Make Tester to inherit CaptureExternal to prevent "Bad file descriptor".
    package Dist::Zilla::App::Tester;
    for (@Dist::Zilla::App::Tester::ISA) {
        $_ = 'App::Cmd::Tester::CaptureExternal' if $_ eq 'App::Cmd::Tester';
    }
}

$ENV{DZIL_GLOBAL_CONFIG_ROOT} = 't';

my $ext = $^O eq 'MSWin32' ? '.exe' : '';
plan skip_all => 'msginit not found' unless can_run 'msginit' . $ext;
plan skip_all => 'xgettext not found' unless can_run 'xgettext' . $ext;

require_ok 'Dist::Zilla::App::Command::msg_init';
is_deeply [Dist::Zilla::App::Command::msg_init->command_names],
    ['msg-init'], 'Should have correct message name';
is Dist::Zilla::App::Command::msg_init->abstract,
    'add language translation files to a distribution',
    'Should have correct abstract';
is Dist::Zilla::App::Command::msg_init->usage_desc,
    '%c %o <language_code> [<language_code> ...]',
    'Should have correct usage description';
is_deeply [Dist::Zilla::App::Command::msg_init->opt_spec], [
    [ 'xgettext|x=s'         => 'location of xgttext utility'      ],
    [ 'msginit|i=s'          => 'location of msginit utility'      ],
    [ 'encoding|e=s'         => 'character encoding to be used'    ],
    [ 'pot-file|pot|p=s'     => 'pot file location'                ],
    [ 'copyright-holder|c=s' => 'name of the copyright holder'     ],
    [ 'bugs-email|b=s'       => 'email address for reporting bugs' ],
], 'Option spec should be correct';

# Start with no lang specified.
ok my $result = test_dzil('t/dist', [qw(msg-init)]),
    'Call msg-init with no arg';
isnt $result->exit_code, 0, 'Should not have exited 0';
like $result->error, qr/Error: dzil msg-init takes one or more arguments/,
    'Should have reason for the failure in the error message';

# Create a new language.
ok $result = test_dzil('t/dist', [qw(msg-init ja.UTF-8)]),
    'Init ja.UTF-8';
is $result->exit_code, 0, 'Should have exited 0' or diag @{ $result->log_messages };
ok((grep {
    /extracting gettext strings/
} @{ $result->log_messages }),  'Should have logged the POT file creation');
ok((grep { /ja[.]po/} @{ $result->log_messages }),
   'File name should have been emitted from msginit');

my $po = path $result->tempdir, qw(source po ja.po);
file_exists_ok $po, 'po/ja.po should now exist';
file_contents_like $po, qr/Language: ja/,
    'Language name "ja" should be present';
file_contents_like $po, qr/\QLast-Translator: Automatically generated/,
    'Should not have set translator';
file_contents_like $po,
    qr/^\Qmsgid "Hi"\E$/m,
    'po/ja.pot should exist should have "Hi" msgid';
file_contents_like $po,
    qr/^\Qmsgid "Bye"\E$/m,
    'po/ja.pot should exist should have "Bye" msgid';

# Try creating an existing language.
ok $result = test_dzil('t/dist', [qw(msg-init fr)]), 'Init existing lang';
isnt $result->exit_code, 0, 'Should not have exited 0' or diag @{ $result->log_messages };
like $result->error, qr/po.fr[.]po already exists/,
    'Should get error trying to create existing language';

# Now specify a bunch of options.
my $pot = path qw(po org.imperia.simplecal.pot);
ok $result = test_dzil('t/dist', [
    'msg-init',
    '--encoding'         => 'Latin-1',
    '--pot-file'         => $pot,
    '--copyright-holder' => 'Homer Simpson',
    '--bugs-email'       => 'foo@bar.com',
    'pt_BR'
]), 'Init with options';

is $result->exit_code, 0, 'Should have exited 0' or diag @{ $result->log_messages };
ok(!(grep {
    /extracting gettext strings/
} @{ $result->log_messages }),  'Should not have logged the POT file creation');

ok((grep { /pt_BR[.]po/} @{ $result->log_messages }),
   'pt_BR name should have been emitted from msginit');

$po = path $result->tempdir, qw(source po pt_BR.po);
file_exists_ok $po, 'po/pt_BR.po should now exist';
file_contents_like $po, qr/Language: pt_BR/,
    'Language name "pt_BR" should be present';
file_contents_like $po, qr/\QLast-Translator: Automatically generated/,
    'Should not have set translator';
file_contents_like $po, qr/^\Qmsgid "January"\E$/m,
    'po/pt_BR.po should have "January" msgid';
file_contents_like $po, qr/^\Qmsgid "February"\E$/m,
    'po/pt_BR.po should have "February" msgid';

# Now point to an invalid POT file.
ok $result = test_dzil('t/dist', [qw(msg-init ja --pot-file nonesuch.pot)]),
    'Init with nonexistent pot file';
isnt $result->exit_code, 0, 'Should not have exited 0' or diag @{ $result->log_messages };
like $result->error,
    qr/\QTemplate file nonesuch.pot does not exist/,
    'Should get error trying to use nonexistent POT file';

# Fail with various other invalid values.
for my $spec (
    [
        'ja',
        'bad xgettext',
        'Cannot find "./nonexistent": Are the GNU gettext utilities installed?',
        '--xgettext' => './nonexistent'
    ],
    [
        'ja',
        'bad msginit',
        'Cannot find "./nonexistent": Are the GNU gettext utilities installed?',
        '--msginit' => './nonexistent'
    ],
    [
        'ja',
        'bad encoding',
        '"L0LZ" is not a valid encoding',
        '--encoding' => 'L0LZ',
    ],
    [
        'FOO',
        'bad lang',
        '"FOO" is not a valid language code',
    ],
    [
        'en-L0LZ',
        'bad-country',
        '"L0LZ" is not a valid country code',
    ],
    [
        'en_L0LZ',
        'bad_country',
        '"L0LZ" is not a valid country code',
    ],
    [
        'en-US.L0LZ',
        'bad lang encoding',
        '"L0LZ" is not a valid encoding',
    ],
) {
    my $lang = shift @{$spec};
    my $desc = shift @{$spec};
    my $msg  = shift @{$spec};
    ok my $result = test_dzil( 't/dist', [ 'msg-init', $lang, @{ $spec } ] ),
      "Execute with $desc";
    isnt $result->exit_code, 0, "Should not have exited 0 with $desc";
    like $result->error, qr/\Q$msg/, "Should get $desc error";
}

done_testing;
