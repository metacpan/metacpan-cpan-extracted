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
plan skip_all => 'msgmerge not found' unless can_run 'msgmerge' . $ext;
plan skip_all => 'xgettext not found' unless can_run 'xgettext' . $ext;

require_ok 'Dist::Zilla::App::Command::msg_merge';
is_deeply [Dist::Zilla::App::Command::msg_merge->command_names],
    ['msg-merge'], 'Should have correct message name';
is Dist::Zilla::App::Command::msg_merge->abstract,
    'merge localization strings into translation catalogs',
    'Should have correct abstract';
is Dist::Zilla::App::Command::msg_merge->usage_desc,
    '%c %o <language_code> [<language_code> ...]',
    'Should have correct usage description';
is_deeply [Dist::Zilla::App::Command::msg_merge->opt_spec], [
    [ 'xgettext|x=s'         => 'location of xgttext utility'      ],
    [ 'msgmerge|m=s'         => 'location of msgmerge utility'     ],
    [ 'encoding|e=s'         => 'character encoding to be used'    ],
    [ 'pot-file|pot|p=s'     => 'pot file location'                ],
    [ 'copyright-holder|c=s' => 'name of the copyright holder'     ],
    [ 'bugs-email|b=s'       => 'email address for reporting bugs' ],
    [ 'backup!'              => 'back up files before merging'     ],
], 'Option spec should be correct';

# Start with no file specified.
ok my $result = test_dzil('t/dist', [qw(msg-merge)]),
    'Call msg-merge with no arg';
is $result->exit_code, 0, 'Should have exited 0' or diag @{ $result->log_messages };
ok got_msg(qr/extracting gettext strings/),
    'Should have logged the POT file creation';

for my $lang (qw(de fr)) {
    my $po = path 'po', "$lang.po";
    ok got_msg(qr/Merging gettext strings into $po/),
        "Should have message for merging $lang.po";
    my $path = path $result->tempdir, qw(source po), "$lang.po";
    file_exists_ok $path, "$po should exist";
    file_not_exists_ok "$path~", "$po~ should not exist";
    file_contents_like $path,
        qr/^\Qmsgid "Hi"\E$/m, qq{$po should have "Hi" msgid};
    file_contents_like $path,
        qr/^\Q#~ msgid "May"\E$/m, qq{$po should have "May" msgid commented out};
}

# Try specifying a file.
my $de = path qw(po de.po);
my $fr = path qw(po fr.po);
ok $result = test_dzil('t/dist', [qw(msg-merge), $de, '--backup']),
    'Call msg-merge with de.po arg';
is $result->exit_code, 0, 'Should have exited 0' or diag @{ $result->log_messages };
ok got_msg(qr/extracting gettext strings/),
    'Should have logged the POT file creation';

# Make sure the German was merged.
my $path = path $result->tempdir, 'source', $de;
ok got_msg(qr/Merging gettext strings into $de/),
    "Should have message for merging $de";
file_exists_ok $path, "$de should exist";
file_exists_ok "$path~", "$de~ backup should not exist";
file_contents_like $path,
    qr/^\Qmsgid "Hi"\E$/m, qq{$de should have "Hi" msgid};
file_contents_like $path,
    qr/^\Q#~ msgid "May"\E$/m, qq{$de should have "May" msgid commented out};

# The French should not have been merged.
$path = path $result->tempdir, 'source', $fr;
ok !got_msg(qr/Merging gettext strings into $fr/),
    "Should not have message for merging $fr";
file_exists_ok $path, "$fr should exist";
file_not_exists_ok "$path~", "$fr~ should not exist";
file_contents_unlike $path,
    qr/^\Qmsgid "Hi"\E$/m, qq{$fr should not have "Hi" msgid};
file_contents_like $path,
    qr/^\Qmsgid "May"\E$/m, qq{$fr should have uncommented "May" msgid};

# Now specify a bunch of options.
my $pot = path qw(po org.imperia.simplecal.pot);
ok $result = test_dzil('t/dist', [
    'msg-merge',
    '--encoding'         => 'Latin-1',
    '--pot-file'         => path(qw(po org.imperia.simplecal.pot)),
    '--copyright-holder' => 'Homer Simpson',
    '--bugs-email'       => 'foo@bar.com',
    '--backup',
]), 'Init with options';

is $result->exit_code, 0, 'Should have exited 0' or diag @{ $result->log_messages };
ok !got_msg(qr/extracting gettext strings/),
    'Should not have logged the POT file creation';

for my $lang (qw(de fr)) {
    my $po = path 'po', "$lang.po";
    ok got_msg(qr/Merging gettext strings into $po/),
        "Should have message for merging $lang.po";
    my $path = path $result->tempdir, qw(source po), "$lang.po";
    file_exists_ok $path, "$po should exist";
    file_not_exists_ok "$path~", "$po~ should not exist (no changes)";
    file_contents_unlike $path,
        qr/^\Qmsgid "Hi"\E$/m, qq{$po should not have "Hi" msgid};
    file_contents_like $path,
        qr/^\Qmsgid "May"\E$/m, qq{$po should have "May" msgid};
}

my $nonpot = path(qw(po nonexistent.top));
# Now try a non-existent POT file.
ok $result = test_dzil('t/dist', [
    'msg-merge',
    '--pot-file' => $nonpot,
]), 'Execute with nonexistent POT file';
isnt $result->exit_code, 1, 'Should not have exited 0';
like $result->error, qr/^[[][^]]+[]]\s+Template file $nonpot does not exist\b/,
    'Should have got error about nonexistent POT';

sub got_msg {
    my $regex = shift;
    return 1 if grep { /$regex/ } @{ $result->log_messages };
    return 0;
}

#use Data::Dump; ddx $result->log_messages;

done_testing;
