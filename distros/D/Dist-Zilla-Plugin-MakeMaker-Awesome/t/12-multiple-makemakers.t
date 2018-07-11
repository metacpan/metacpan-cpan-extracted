use strict;
use warnings;

use Test::More 0.96;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::DZil;
use Path::Tiny;
use Test::Fatal;

{
    my $tzil = Builder->from_config(
        { dist_root => 'does-not-exist' },
        {
            add_files => {
                path(qw(source dist.ini)) => simple_ini(
                    'GatherDir',
                    'MakeMaker',
                    'MakeMaker::Awesome',
                ),
                path(qw(source lib DZT Sample.pm)) => 'package DZT::Sample; 1',
            },
        },
    );

    $tzil->chrome->logger->set_debug(1);

    like(
        exception { $tzil->build },
        qr/\QYou can't use [MakeMaker] and [MakeMaker::Awesome] at the same time!\E/,
        'multiple MakeMakers results in a build error',
    );

    diag 'got log messages: ', explain $tzil->log_messages
        if not Test::Builder->new->is_passing;
}

{
    package my::MakeMaker;
    our @ISA = 'Dist::Zilla::Plugin::MakeMaker';
}

{
    package my::MakeMaker::Awesome;
    our @ISA = 'Dist::Zilla::Plugin::MakeMaker::Awesome';
}

{
    my $tzil = Builder->from_config(
        { dist_root => 'does-not-exist' },
        {
            add_files => {
                path(qw(source dist.ini)) => simple_ini(
                    'GatherDir',
                    '=my::MakeMaker',
                    '=my::MakeMaker::Awesome',
                    'MakeMaker',
                ),
                path(qw(source lib DZT Sample.pm)) => 'package DZT::Sample; 1',
            },
        },
    );

    $tzil->chrome->logger->set_debug(1);

    like(
        exception { $tzil->build },
        qr/\QYou can't use my::MakeMaker, my::MakeMaker::Awesome and [MakeMaker] at the same time!\E/,
        'error message is sane with >2 plugins and a different prefix',
    );

    diag 'got log messages: ', explain $tzil->log_messages
        if not Test::Builder->new->is_passing;
}

done_testing;
