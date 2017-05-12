use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::DZil;
use Test::Deep '!none';
use Test::Fatal;
use Path::Tiny;

use Test::Needs { 'Dist::Zilla::Plugin::ModuleBuildTiny' => '0.011' };

my $tzil = Builder->from_config(
    { dist_root => 'does-not-exist' },
    {
        add_files => {
            path(qw(source dist.ini)) => simple_ini(
                [ GatherDir => ],
                [ MetaConfig => ],
                [ ModuleBuildTiny => { ':version' => '0.011', static => 'auto' } ],
                [ MetaJSON => ],
                [ 'StaticInstall' => { mode => 'auto' } ],
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
        x_static_install => 1,
        x_Dist_Zilla => superhashof({
            plugins => supersetof(
                {
                    class => 'Dist::Zilla::Plugin::StaticInstall',
                    config => {
                        'Dist::Zilla::Plugin::StaticInstall' => {
                            mode => 'auto',
                            dry_run => 0,
                        },
                    },
                    name => 'StaticInstall',
                    version => Dist::Zilla::Plugin::StaticInstall->VERSION,
                },
            ),
        }),
    }),
    'plugin metadata indicates a static install',
) or diag 'got distmeta: ', explain $tzil->distmeta;

# TODO: replace with Test::Deep::notmember($string)
use List::Util 1.33 'none';
sub notmember {
    my $not_expects = shift;
    code(sub {
        my $got = shift;
        return (0, 'item is not an ARRAY') if ref $got ne 'ARRAY';
        none { eq_deeply($_, $not_expects) } @$got
            ? 1 : (0, 'item exists: ', explain $got);
    })
}

cmp_deeply(
    $tzil->log_messages,
    notmember('[StaticInstall] setting x_static_install to 1'),
    'did not log setting the flag value - [ModuleBuildTiny] beat us to it',
);

diag 'got log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;

done_testing;
