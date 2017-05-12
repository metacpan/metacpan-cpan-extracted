use strict;
use warnings;

use Test::More 0.88;
use Test::Warnings qw(:all :no_end_test);
use Test::DZil;
use Test::Fatal;
use Path::Tiny;
use Test::Deep;
use File::pushd 'pushd';

my $tzil = Builder->from_config(
    { dist_root => 'does-not-exist' },
    {
        add_files => {
            path(qw(source dist.ini)) => simple_ini(
                [ GatherDir => ],
                [ Manifest => ],
                [ MetaConfig => ],
                [ 'ModuleBuildTiny::Fallback' ],
                [ Prereqs => ConfigureRequires => { 'Acme::EtherSaysThisWillNeverExist' => '0' } ],
            ),
            path(qw(source lib Foo.pm)) => "package Foo;\n1;\n",
        },
    },
);

$tzil->chrome->logger->set_debug(1);
is(
    exception { $tzil->build },
    undef,
    'build proceeds normally',
);

cmp_deeply(
    $tzil->distmeta,
    superhashof({
        prereqs => superhashof({
            configure => {
                requires => {
                    'Module::Build::Tiny' => ignore,
                    'Acme::EtherSaysThisWillNeverExist' => '0',
                },
            },
        }),
        x_Dist_Zilla => superhashof({
            plugins => supersetof(
                {
                    class => 'Dist::Zilla::Plugin::ModuleBuildTiny::Fallback',
                    config => superhashof({
                        'Dist::Zilla::Plugin::ModuleBuildTiny::Fallback' => {
                            mb_version => '0.28',
                            plugins => [
                                superhashof({
                                    class => 'Dist::Zilla::Plugin::ModuleBuild',
                                    name => 'ModuleBuild, via ModuleBuildTiny::Fallback',
                                    version => Dist::Zilla::Plugin::ModuleBuild->VERSION,
                                }),
                                superhashof({
                                    class => 'Dist::Zilla::Plugin::ModuleBuildTiny',
                                    name => 'ModuleBuildTiny, via ModuleBuildTiny::Fallback',
                                    version => Dist::Zilla::Plugin::ModuleBuildTiny->VERSION,
                                }),
                            ],
                        },
                        # if new enough, we'll also see:
                        # 'Dist::Zilla::Role::TestRunner' => superhashof({})
                    }),
                    name => 'ModuleBuildTiny::Fallback',
                    version => ignore,
                },
            ),
        }),
    }),
    'all prereqs are in place; configs are properly included in metadata',
)
or diag 'got metadata: ', explain $tzil->distmeta;

my $build_dir = path($tzil->tempdir)->child('build');

my $build_pl = $build_dir->child('Build.PL')->slurp_utf8;
unlike($build_pl, qr/[^\S\n]\n/, 'no trailing whitespace in generated Build.PL');

subtest 'run the generated test' => sub
{
    my $wd = pushd $build_dir;

    my @warnings = warnings { do './Build.PL' };
    note 'ran tests successfully' if not $@;
    fail($@) if $@;

    cmp_deeply(
        \@warnings,
        [ re(qr/^Errors from configure prereqs:\n\s*\{\n\s+'Acme::EtherSaysThisWillNeverExist' => 'Can\\'t locate .+\n',\n\s+'Module::Build::Tiny' => ''\n\s*\}\n/ms) ],
        'correctly captured errors from configure-requires and dumped them',
    )
    or diag 'got warnings: ', explain \@warnings;
};

had_no_warnings() if $ENV{AUTHOR_TESTING};
done_testing;
