use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::DZil;
use Test::Fatal;
use Path::Tiny;

use Test::File::ShareDir
    -share => { -module => { 'Dist::Zilla::Plugin::DynamicPrereqs' => 'share/DynamicPrereqs' } };

my $tzil = Builder->from_config(
    { dist_root => 'does-not-exist' },
    {
        add_files => {
            path(qw(source dist.ini)) => simple_ini(
                [ GatherDir => ],
                [ Prereqs => { 'strict' => '0', 'Test::More' => '0' } ],
                [ DynamicPrereqs => {
                        -raw => [
                            q|$WriteMakefileArgs{PREREQ_PM}{'Test::More'} = $FallbackPrereqs{'Test::More'} = '0.123'|,
                            q|if eval { require Test::More; 1 };|,
                        ],
                    },
                ],
            ),
            path(qw(source lib Foo.pm)) => "package Foo;\n1;\n",
        },
    },
);

$tzil->chrome->logger->set_debug(1);
like(
    exception { $tzil->build },
    # before Dist::Zilla 5.022, Makefile.PL is not created until [MakeMaker]
    # runs its setup_installer, so we will fail to find a file to munge.
    qr/No Makefile.PL found!/,
    'build aborts due to Makefile.PL not existing at the expected phase',
) or diag 'got log messages: ', explain $tzil->log_messages;

diag 'got log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;

done_testing;
