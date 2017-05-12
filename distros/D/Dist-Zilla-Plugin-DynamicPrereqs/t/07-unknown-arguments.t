use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::DZil;
use Test::Fatal;
use Path::Tiny;
use Test::Deep;

use Test::File::ShareDir
    -share => { -module => { 'Dist::Zilla::Plugin::DynamicPrereqs' => 'share/DynamicPrereqs' } };

my $tzil = Builder->from_config(
    { dist_root => 'does-not-exist' },
    {
        add_files => {
            path(qw(source dist.ini)) => simple_ini(
                [ GatherDir => ],
                [ Prereqs => { 'strict' => '0', 'Test::More' => '0' } ],
                [ MakeMaker => ],
                [ DynamicPrereqs => {
                        -raw => [
                            q|$WriteMakefileArgs{PREREQ_PM}{'Test::More'} = $FallbackPrereqs{'Test::More'} = '0.123'|,
                            q|if eval { require Test::More; 1 };|,
                        ],
                        unknown_arg => 'foo',
                    },
                ],
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
) or diag 'got log messages: ', explain $tzil->log_messages;

cmp_deeply(
    $tzil->log_messages,
    superbagof(
        re(qr/\QWarning: unrecognized argument (unknown_arg) passed. Perhaps you need to upgrade?\E/),
    ),
    'warning issued about unrecognized arguments',
) or diag 'got log messages: ', explain $tzil->log_messages;

diag 'got log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;

done_testing;
