use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Path::Tiny;
use Test::Deep;
use Test::DZil;

my $tzil = Builder->from_config(
    { dist_root => 'does-not-exist' },
    {
        add_files => {
            path(qw(source dist.ini)) => simple_ini(
                'GatherDir',
                'MakeMaker::Awesome',
                'MetaConfig',
            ),
            path(qw(source lib Foo.pm)) => "package Foo;\n\n1",
        },
    },
);

$tzil->chrome->logger->set_debug(1);
$tzil->build;

cmp_deeply(
    $tzil->distmeta,
    superhashof({
        prereqs => {
            configure => { requires => { 'ExtUtils::MakeMaker' => '0' } },
        },
        dynamic_config => 0,
        x_Dist_Zilla => superhashof({
            plugins => supersetof(
                superhashof({
                    class => 'Dist::Zilla::Plugin::MakeMaker::Awesome',
                    # [MakeMaker] and Dist::Zilla::Role::TestRunner might also
                    # record some configs of their own, depending on version
                    config => {
                        'Dist::Zilla::Plugin::MakeMaker' => superhashof({
                            make_path => ignore,
                            version => Dist::Zilla::Plugin::MakeMaker->VERSION,
                        }),
                        'Dist::Zilla::Role::TestRunner' => superhashof({
                            Dist::Zilla::Role::TestRunner->can('default_jobs') ? ( default_jobs => ignore ) : (),
                            version => Dist::Zilla::Role::TestRunner->VERSION,
                        }),
                    },
                    name => 'MakeMaker::Awesome',
                    version => Dist::Zilla::Plugin::MakeMaker::Awesome->VERSION,
                }),
            ),
        }),
    }),
    'config is properly included in metadata',
)
    or diag 'got distmeta: ', explain $tzil->distmeta;

diag 'got log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;

done_testing;
