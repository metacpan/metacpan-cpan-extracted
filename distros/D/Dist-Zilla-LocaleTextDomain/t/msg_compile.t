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

my $ext = $^O eq 'MSWin32' ? '.exe' : '';
plan skip_all => 'msgfmt not found' unless can_run 'msgfmt' . $ext;

require_ok 'Dist::Zilla::App::Command::msg_compile';
is_deeply [Dist::Zilla::App::Command::msg_compile->command_names],
    ['msg-compile'], 'Should have correct message name';

is Dist::Zilla::App::Command::msg_compile->abstract,
    'compile language translation files',
    'Should have correct abstract';

is Dist::Zilla::App::Command::msg_compile->usage_desc,
    '%c %o [<language_code> ...]',
    'Should have correct usage description';

is_deeply [Dist::Zilla::App::Command::msg_compile->opt_spec], [
    [ 'dest-dir|d=s' => 'location in which to save complied files'    ],
    [ 'msgfmt|m=s'   => 'location of msgfmt utility'                  ],
], 'Option spec should be correct';

# Start with no options or args.
my $result = test_dzil('t/dist', [qw(msg-compile)]);
is $result->exit_code, 0, "dzil would have exited 0";
my $i = 0;
for my $lang (qw(de fr)) {
    like $result->log_messages->[$i++], qr/(?:po.$lang[.]po: )?19/m,
        "$lang.po message should have been logged";
    my $mo = file $result->tempdir,
        qw(source LocaleData), $lang, qw(LC_MESSAGES DZT-Sample.mo);
    my $t = $result->tempdir;
    file_exists_ok $mo, "$lang .mo file should now exist";
    file_contents_like $mo, qr/^Language: $lang$/m,
        "Compiled $lang .mo should have language content";
}

# Try creating just one language.
my $de = file qw(po de.po);
my $fr = file qw(po fr.po);
$result = test_dzil('t/dist', [qw(msg-compile), $fr]);
is $result->exit_code, 0, '"msg-compile fr" should have exited 0';
is @{ $result->log_messages }, 1, 'Should have only one log message';
like $result->log_messages->[0], qr/(?:po.fr[.]po: )?19/m,
    '... And it should be for the french file';
my $mo = file $result->tempdir,
    qw(source LocaleData fr LC_MESSAGES DZT-Sample.mo);
file_exists_ok $mo, "fr .mo file should exist";
file_contents_like $mo, qr/^Language: fr$/m,
    "f r.mo should have language content";
$mo = file $result->tempdir,
    qw(source LocaleData de LC_MESSAGES DZT-Sample.mo);
file_not_exists_ok $mo, 'de .mo file should not exist';

# Make sure it works when we specify the optoins.
$result = test_dzil('t/dist', [qw(msg-compile --dest-dir foo --msgfmt), 'msgfmt' . $ext]);
is $result->exit_code, 0, '"msg-compile" with options sould have exited 0';

$i = 0;
for my $lang (qw(de fr)) {
    like $result->log_messages->[$i++], qr/(?:po.$lang[.]po: )?19/m,
        "$lang.po message should have been logged";
    my $mo = file $result->tempdir,
        qw(source foo LocaleData), $lang, qw(LC_MESSAGES DZT-Sample.mo);
    my $t = $result->tempdir;
    file_exists_ok $mo, "$lang .mo file should now exist";
    file_contents_like $mo, qr/^Language: $lang$/m,
        "Compiled $lang .mo should have language content";
}


done_testing;
