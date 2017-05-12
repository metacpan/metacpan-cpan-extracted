use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Path::Tiny;
use Test::Fatal;
use Test::Deep;
use Test::DZil;

# earlier versions of the upstream MakeMaker plugins did not ever have
# customized dump_configs, for us to test for
use Test::Needs { 'Dist::Zilla::Role::TestRunner' => '5.014' };

my $tzil = Builder->from_config(
    { dist_root => 'does-not-exist' },
    {
        add_files => {
            path(qw(source dist.ini)) => simple_ini(
                'GatherDir',
                [ 'ModuleBuildTiny' => { version => 0 } ],
                'MakeMaker::Fallback',
                'MetaConfig',
            ),
            path(qw(source lib Foo.pm)) => "package Foo;\n\n1",
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
        dynamic_config => 0,
        x_Dist_Zilla => superhashof({
            plugins => supersetof(
                {
                    class => 'Dist::Zilla::Plugin::MakeMaker::Fallback',
                    config => superhashof({
                        'Dist::Zilla::Role::TestRunner' => ignore,  # changes over time
                        # maybe Dist::Zilla::Plugin::MakeMaker::Awesome
                    }),
                    name => 'MakeMaker::Fallback',
                    version => Dist::Zilla::Plugin::MakeMaker::Fallback->VERSION,
                },
            ),
        })
    }),
    'config is properly included in metadata',
) or diag 'got distmeta: ', explain $tzil->distmeta;

diag 'got log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;

done_testing;
