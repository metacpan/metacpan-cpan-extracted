#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More 0.90;
use Test::DZil;
use IPC::Cmd 'can_run';
use Path::Tiny;

plan skip_all => 'msgfmt not found' unless can_run 'msgfmt';

sub tzil {
    Builder->from_config(
        { dist_root => 't/dist' },
        {
            add_files => {
                'source/dist.ini' => simple_ini(
                    'GatherDir',
                    'ExecDir',
                    ['LocaleTextDomain', @_],
                ),
            },
        },
    );
}

ok my $tzil = tzil(), 'Create tzil';

ok $tzil->build, 'Build it';
my @messages = grep { /^\Q[LocaleTextDomain]/ } @{ $tzil->log_messages };
is $messages[0], '[LocaleTextDomain] Compiling language files in po',
    'Compiling message should have been emitted';

my $i = 0;
my $slurp = $tzil->can('slurp_file_raw') || $tzil->can('slurp_file');
for my $lang (qw(de fr)) {
    like $messages[++$i], qr/(?:po.$lang[.]po: )?19/m,
        "$lang.po message should have been logged";
    ok my $contents = $tzil->$slurp(
        "build/share/LocaleData/$lang/LC_MESSAGES/DZT-Sample.mo",
    ), "Read in $lang .mo file";
    like $contents, qr/^Language: $lang$/m,
        "Compiled $lang .mo should have language content";
}

my $files = $tzil->plugin_named('LocaleTextDomain')->found_files();
is scalar grep({ $_->name() =~ m{sample$} } @{ $files }), 1,
    'bin/sample file is found';
is scalar grep({ $_->name() =~ m{Sample[.]pm$} } @{ $files }), 1,
    'lib/Sample.pm file is found';

# Specify the attributes.
ok $tzil = tzil({
    textdomain       => 'org.imperia.simplecal',
    lang_dir         => 'po',
    share_dir        => 'lib',
    msgfmt           => 'msgfmt',
    lang_file_suffix => 'po',
    bin_file_suffix  => 'bo',
    language         => ['fr'],
    finder           => [':InstallModules'],
}), 'Create another tzil';

ok $tzil->build, 'Build again';
@messages = grep { /^\Q[LocaleTextDomain]/ } @{ $tzil->log_messages };
is $messages[0], '[LocaleTextDomain] Compiling language files in po',
    'Compiling message should have been emitted again';

ok -e path($tzil->tempdir)->child("build/lib/LocaleData/fr/LC_MESSAGES/org.imperia.simplecal.bo"),
    'Should have fr .bo file';
ok !-e path($tzil->tempdir)->child("build/lib/LocaleData/de/LC_MESSAGES/org.imperia.simplecal.bo"),
    'Should not have de .bo file';

$i = 0;
for my $lang (qw(fr)) {
    like $messages[++$i], qr/(?:po.$lang[.]po: )?19/m,
        "$lang.po message should have been logged again";
    ok my $contents = $tzil->$slurp(
        "build/lib/LocaleData/$lang/LC_MESSAGES/org.imperia.simplecal.bo",
    ), "Read in $lang .bo file";
    like $contents, qr/^Language: $lang$/m,
        "Complied $lang .bo file should have language content";
}

$files = $tzil->plugin_named('LocaleTextDomain')->found_files();
is scalar grep({ $_->name() =~ m{sample$} } @{ $files }), 0,
    'bin/sample file is not found since :ExecFiles finder is not in use';
is scalar grep({ $_->name() =~ m{Sample[.]pm$} } @{ $files }), 1,
    'lib/Sample.pm file is found';

done_testing;
