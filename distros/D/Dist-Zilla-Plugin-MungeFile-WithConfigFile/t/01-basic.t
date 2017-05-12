use strict;
use warnings;

use utf8;
use Test::More;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::DZil;
use Config::Tiny;   # to read .ini files
use Path::Tiny;
use Test::Deep;

binmode $_, ':encoding(UTF-8)' foreach *STDOUT, *STDERR, map { Test::Builder->new->$_ } qw(output failure_output);

my $tzil = Builder->from_config(
    { dist_root => 'does-not-exist' },
    {
        add_files => {
            path(qw(source dist.ini)) => simple_ini(
                [ GatherDir => ],
                [ MetaConfig => ],
                [ 'MungeFile::WithConfigFile' => {
                        finder => ':MainModule',
                        configfile => 'config.ini',
                        house => 'château',
                    } ],
            ),
            'source/config.ini' => <<'CONFIG',
; Note: sadly, Config::Any does not assume UTF-8 file encoding
dog = chien
cat = chat
bird = oiseau
CONFIG
            'source/lib/Module.pm' => <<'MODULE'
package Module;

my $string = {{
'"our config data is:' . "\n"
. join("\n", map { $_ . ' => ' . $config_data->{$_} } sort keys %$config_data)
. "\n" . 'And that\'s just great!\n"'
}};
my ${{ $house }} = 'my castle';
1;
MODULE
        },
    },
);

$tzil->chrome->logger->set_debug(1);
$tzil->build;

my $content = $tzil->slurp_file('build/lib/Module.pm');

is(
    $content,
    <<'NEW_MODULE',
package Module;

my $string = "our config data is:
bird => oiseau
cat => chat
dog => chien
And that's just great!\n";
my $château = 'my castle';
1;
NEW_MODULE
    'module content is transformed',
);

cmp_deeply(
    $tzil->distmeta,
    superhashof({
        x_Dist_Zilla => superhashof({
            plugins => supersetof(
                {
                    class => 'Dist::Zilla::Plugin::MungeFile::WithConfigFile',
                    config => {
                        'Dist::Zilla::Plugin::MungeFile' => {
                            finder => [ ':MainModule' ],
                            files => [ ],
                            house => "ch\x{e2}teau",
                            version => Dist::Zilla::Plugin::MungeFile->VERSION,
                        },
                        'Dist::Zilla::Plugin::MungeFile::WithConfigFile' => {
                            configfile => 'config.ini',
                        },
                    },
                    name => 'MungeFile::WithConfigFile',
                    version => Dist::Zilla::Plugin::MungeFile::WithConfigFile->VERSION,
                },
            ),
        }),
    }),
    'distmeta is correct',
) or diag 'got distmeta: ', explain $tzil->distmeta;

diag 'got log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;

done_testing;
