use strict;
use warnings;
use Test::More 0.88;
use Test::DZil;
use Test::Deep;
use Path::Tiny;

for my $trial (0, 1) {
    local $ENV{TRIAL} = $trial;
    my $tzil = Builder->from_config(
        { dist_root => 'does-not-exist' },
        {
            add_files => {
                path(qw(source dist.ini)) => simple_ini(
                    [ GatherDir => ],
                    [ MetaConfig => ],

                    [ 'Run::BeforeBuild' => { run => [ '"%x" %o%pscript%prun.pl before_build %s %n %v%t %o.%d.%a. %x' ] } ],
                    [ 'Run::AfterBuild' => { run => [ '"%x" %o%pscript%prun.pl after_build %n %v%t %o %d %s %s %v%t .%a. %x' ] } ],
                    [ 'Run::BeforeArchive' => { run => [ '"%x" %o%pscript%prun.pl before_archive %o %d %v%t %n %a %x' ] } ],
                    [ 'Run::BeforeRelease' => { run => [ '"%x" %o%pscript%prun.pl before_release %n -d %o %d %s -v %v%t .%a. %x' ] } ],
                    [ 'Run::Release' => { run => [ '"%x" %o%pscript%prun.pl release %s %n %v%t %o %d/a %d/b %a %x' ] } ],
                    [ 'Run::AfterRelease' => { run => [ '"%x" %o%pscript%prun.pl after_release %o %d %v%t %s %s %n %a %x' ] } ],
                ),
                path(qw(source lib Foo.pm)) => "package Foo;\n1;\n",
                path(qw(source script run.pl)) => <<'SCRIPT',
use strict;
use warnings;

# I do nothing!
SCRIPT
            },
        },
    );

    my $source_dir = 'fakesource';
    my $build_dir = 'fakebuild';

    my %f = (
        a => 'DZT-Sample-0.001.tar.gz',
        n => 'DZT-Sample',
        o => $source_dir,
        d => $build_dir,
        v => '0.001',
        t => $tzil->is_trial ? '-TRIAL' : '',
    );

    my $formatter = $tzil->plugin_named('Run::AfterRelease')->build_formatter({
        archive   => $f{a},
        source_dir => $source_dir,
        dir       => $build_dir,
        pos       => [qw(run run reindeer)]
    });

    is $formatter->format('snowflakes/%v%t|%n\\%s,%s,%s,%s in %o %d(%a)'),
        "snowflakes/$f{v}$f{t}|$f{n}\\run,run,reindeer, in $f{o} $f{d}($f{a})",
        'correct formatting';

    is $formatter->format('%v%t%s%n'), "$f{v}$f{t}$f{n}", 'ran out of %s (but not the constants)';

    $tzil->chrome->logger->set_debug(1);
    $tzil->release;

    cmp_deeply(
        $tzil->distmeta,
        superhashof({
            x_Dist_Zilla => superhashof({
                plugins => supersetof(
                    {
                        class => 'Dist::Zilla::Plugin::Run::BeforeBuild',
                        config => {
                            'Dist::Zilla::Plugin::Run::Role::Runner' => {
                                run => [ '"%x" %o%pscript%prun.pl before_build %s %n %v%t %o.%d.%a. %x' ],
                                fatal_errors => 1,
                                quiet => 0,
                                version => Dist::Zilla::Plugin::Run::Role::Runner->VERSION,
                            },
                        },
                        name => 'Run::BeforeBuild',
                        version => Dist::Zilla::Plugin::Run::BeforeBuild->VERSION,
                    },
                    {
                        class => 'Dist::Zilla::Plugin::Run::AfterBuild',
                        config => {
                            'Dist::Zilla::Plugin::Run::Role::Runner' => {
                                run => [ '"%x" %o%pscript%prun.pl after_build %n %v%t %o %d %s %s %v%t .%a. %x' ],
                                fatal_errors => 1,
                                quiet => 0,
                                version => Dist::Zilla::Plugin::Run::Role::Runner->VERSION,
                            },
                        },
                        name => 'Run::AfterBuild',
                        version => Dist::Zilla::Plugin::Run::AfterBuild->VERSION,
                    },
                    {
                        class => 'Dist::Zilla::Plugin::Run::BeforeArchive',
                        config => {
                            'Dist::Zilla::Plugin::Run::Role::Runner' => {
                                run => [ '"%x" %o%pscript%prun.pl before_archive %o %d %v%t %n %a %x' ],
                                fatal_errors => 1,
                                quiet => 0,
                                version => Dist::Zilla::Plugin::Run::Role::Runner->VERSION,
                            },
                        },
                        name => 'Run::BeforeArchive',
                        version => Dist::Zilla::Plugin::Run::BeforeArchive->VERSION,
                    },
                    {
                        class => 'Dist::Zilla::Plugin::Run::BeforeRelease',
                        config => {
                            'Dist::Zilla::Plugin::Run::Role::Runner' => {
                                run => [ '"%x" %o%pscript%prun.pl before_release %n -d %o %d %s -v %v%t .%a. %x' ],
                                fatal_errors => 1,
                                quiet => 0,
                                version => Dist::Zilla::Plugin::Run::Role::Runner->VERSION,
                            },
                        },
                        name => 'Run::BeforeRelease',
                        version => Dist::Zilla::Plugin::Run::BeforeRelease->VERSION,
                    },
                    {
                        class => 'Dist::Zilla::Plugin::Run::Release',
                        config => {
                            'Dist::Zilla::Plugin::Run::Role::Runner' => {
                                run => [ '"%x" %o%pscript%prun.pl release %s %n %v%t %o %d/a %d/b %a %x' ],
                                fatal_errors => 1,
                                quiet => 0,
                                version => Dist::Zilla::Plugin::Run::Role::Runner->VERSION,
                            },
                        },
                        name => 'Run::Release',
                        version => Dist::Zilla::Plugin::Run::Release->VERSION,
                    },
                    {
                        class => 'Dist::Zilla::Plugin::Run::AfterRelease',
                        config => {
                            'Dist::Zilla::Plugin::Run::Role::Runner' => {
                                run => [ '"%x" %o%pscript%prun.pl after_release %o %d %v%t %s %s %n %a %x' ],
                                fatal_errors => 1,
                                quiet => 0,
                                version => Dist::Zilla::Plugin::Run::Role::Runner->VERSION,
                            },
                        },
                        name => 'Run::AfterRelease',
                        version => Dist::Zilla::Plugin::Run::AfterRelease->VERSION,
                    },
                ),
            }),
        }),
        'dumped configs are good',
    ) or diag 'got distmeta: ', explain $tzil->distmeta;

    diag 'got log messages: ', explain $tzil->log_messages
        if not Test::Builder->new->is_passing;
}

done_testing;
