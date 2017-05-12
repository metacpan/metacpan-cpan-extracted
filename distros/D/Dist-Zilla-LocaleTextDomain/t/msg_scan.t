#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More 0.90;
use Test::DZil;
use IPC::Cmd 'can_run';
use Path::Class;
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

plan skip_all => 'xgettext not found' unless can_run 'xgettext';

require_ok 'Dist::Zilla::App::Command::msg_scan';

my $result = test_dzil('t/dist', [qw(msg-scan)]);
is $result->exit_code, 0, "dzil would have exited 0" or diag @{ $result->log_messages };

ok((grep {
    /extracting gettext strings into po.DZT-Sample[.]pot/
} @{ $result->log_messages }),  'Should have logged the POT file creation');

my $pot = file $result->tempdir, qw(source po DZT-Sample.pot);
file_exists_ok $pot, 'po/DZT-Sample.pot should exist';
file_contents_like $pot, qr/\QCopyright (C) YEAR David E. Wheeler/m,
    'po/DZT-Sample.pot should have copyright holder';
file_contents_like $pot, qr/^\Q"Project-Id-Version: DZT-Sample 1.2\n"\E$/m,
    'po/DZT-Sample.pot should exist should have project ID and version';
file_contents_like $pot,
    qr/^\Q"Report-Msgid-Bugs-To: david\E[@]\Qjustatheory.com\n"\E$/m,
    'po/DZT-Sample.pot should exist should have bugs email';
file_contents_like $pot,
    qr/^\Qmsgid "Hi"\E$/m,
    'po/DZT-Sample.pot should exist should have "Hi" msgid';
file_contents_like $pot,
    qr/^\Qmsgid "Bye"\E$/m,
    'po/DZT-Sample.pot should exist should have "Bye" msgid';
file_contents_like $pot,
    qr/^\Qmsgid "Foo"\E$/m,
    'po/DZT-Sample.pot should exist should have "Foo" msgid';

# Try setting some stuff.
$result = test_dzil('t/dist', [qw(
    msg-scan
    --pot-file my.pot
    --bugs-email homer@example.com
    --copyright-holder
), 'Homer Simpson']);
is $result->exit_code, 0, "dzil would have exited 0 again" or diag @{ $result->log_messages };

ok((grep {
    /extracting gettext strings into my[.]pot/
} @{ $result->log_messages }),  'Should have logged the mo.pot creation');

$pot = file $result->tempdir, qw(source my.pot);
file_exists_ok $pot, 'my.pot should exist';
file_contents_like $pot, qr/\QCopyright (C) YEAR Homer Simpson/m,
    'my.pot should have copyright holder';
file_contents_like $pot, qr/^\Q"Project-Id-Version: DZT-Sample 1.2\n"\E$/m,
    'my.pot should exist should have project ID and version';
file_contents_like $pot,
    qr/^\Q"Report-Msgid-Bugs-To: homer\E[@]\Qexample.com\n"\E$/m,
    'my.pot should exist should have custom bugs email';
file_contents_like $pot,
    qr/^\Qmsgid "Hi"\E$/m,
    'my.pot should exist should have "Hi" msgid';
file_contents_like $pot,
    qr/^\Qmsgid "Bye"\E$/m,
    'my.pot should exist should have "Bye" msgid';

# Use finder attribute
$result = test_dzil('t/dist2', [qw(msg-scan)]);
is $result->exit_code, 0, "dzil would have exited 0" or diag @{ $result->log_messages };

ok((grep {
    /extracting gettext strings into po.DZT-Sample2[.]pot/
} @{ $result->log_messages }),  'Should have logged the POT file creation');

$pot = file $result->tempdir, qw(source po DZT-Sample2.pot);
file_exists_ok $pot, 'po/DZT-Sample2.pot should exist';
file_contents_like $pot,
    qr/bar[.]pl:6$/m,
    'po/DZT-Sample2.pot should have entry for "bar.pl" file';
file_contents_like $pot,
    qr/^\Qmsgid "Bar"\E$/m,
    'po/DZT-Sample2.pot should exist should have "Bar" msgid';
file_contents_like $pot,
    qr/Config[.]pm:6$/m,
    'po/DZT-Sample2.pot should have entry for "Config.pm" file';
file_contents_like $pot,
    qr/^\Qmsgid "Foo"\E$/m,
    'po/DZT-Sample2.pot should exist should have "Foo" msgid';

done_testing;
