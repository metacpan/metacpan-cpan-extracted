use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::DZil;
use Test::Fatal;
use Path::Tiny;

plan skip_all => 'This test is only useful for Dist::Zilla versions before 5.022'
    if eval "require Dist::Zilla::Plugin::MakeMaker; Dist::Zilla::Plugin::MakeMaker->VERSION('5.022'); 1";

my $tzil = Builder->from_config(
    { dist_root => 'does-not-exist' },
    {
        add_files => {
            path(qw(source dist.ini)) => simple_ini(
                [ GatherDir => ],
                [ MakeMaker => ],
                [ SmokeTests => ],
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
    qr/there is a Makefile.PL in the build now but we didn\'t see it in time to munge it/,
    'build aborts due to the file not existing at the expected phase',
) or diag 'got log messages: ', explain $tzil->log_messages;

diag 'got log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;

done_testing;
