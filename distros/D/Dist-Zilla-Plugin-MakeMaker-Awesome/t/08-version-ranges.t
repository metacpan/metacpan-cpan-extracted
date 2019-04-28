use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::Deep;
use Test::Fatal;
use Test::DZil;
use Path::Tiny;

{
    my $tzil = Builder->from_config(
        { dist_root => 'does-not-exist' },
        {
            add_files => {
                path(qw(source dist.ini)) => simple_ini(
                    'GatherDir',
                    'MakeMaker::Awesome',
                    [ Prereqs => { 'External::Module' => '<= 1.23' } ],
                ),
                'source/lib/Foo.pm' => "package Foo;\n1\n",
            },
        },
    );

    $tzil->chrome->logger->set_debug(1);

    like(
        exception { $tzil->build },
        qr/\Q[MakeMaker::Awesome] found version range in runtime prerequisites, which ExtUtils::MakeMaker cannot parse (must specify eumm_version of at least 7.1101): External::Module <= 1.23\E/,
        'build does not permit passing unparsable version range',
    );

    diag 'got log messages: ', explain $tzil->log_messages
        if not Test::Builder->new->is_passing;
}
{
    my $tzil = Builder->from_config(
        { dist_root => 'does-not-exist' },
        {
            add_files => {
                path(qw(source dist.ini)) => simple_ini(
                    'GatherDir',
                    [ 'MakeMaker::Awesome' => { eumm_version => '7.12' } ],
                    [ Prereqs => { 'External::Module' => '<= 1.23' } ],
                ),
                'source/lib/Foo.pm' => "package Foo;\n1\n",
            },
        },
    );

    $tzil->chrome->logger->set_debug(1);
    is(
        exception { $tzil->build },
        undef,
        'build proceeds normally',
    );

    ok(
        !(grep m'[MakeMaker::Awesome] found version range', @{ $tzil->log_messages }),
        'got no warning about probably-unparsable version range',
    );

    diag 'got log messages: ', explain $tzil->log_messages
        if not Test::Builder->new->is_passing;
}

done_testing;
