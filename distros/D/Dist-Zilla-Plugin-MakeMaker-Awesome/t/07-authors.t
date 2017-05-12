use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::Deep;
use Test::DZil;
use Path::Tiny;
use File::pushd 'pushd';

{
    my $tzil = Builder->from_config(
        { dist_root => 'does-not-exist' },
        {
            add_files => {
                path(qw(source dist.ini)) => simple_ini(
                    {   # merge into root section
                        author   => [
                            'Anon Y. Moose <anon@null.com>',
                            'Anne O\'Thor <anne@cpan.org',
                        ],
                    },
                    'GatherDir',
                    [ Prereqs => { perl => 5.016 } ],   # must be before MMA
                    'MakeMaker::Awesome',
                ),
            },
        },
    );

    $tzil->chrome->logger->set_debug(1);
    $tzil->build;

    like(
        $tzil->slurp_file('build/Makefile.PL'),
        qr/^\s*['"]AUTHOR['"]\s*=>\s*\[\s*[^]]+\],/m,
        'AUTHOR generated as a listref, when perl version already accomodates the ExtUtils::MakeMaker version',
    );

    cmp_deeply(
        $tzil->distmeta,
        superhashof({
            prereqs => {
                configure => {
                    requires => {
                        'ExtUtils::MakeMaker' => '6.5702',
                    },
                },
                runtime => {
                    requires => {
                        perl => '5.016',
                    },
                },
            },
        }),
        'minimum EUMM version is set accordingly',
    )
        or diag 'got distmeta: ', explain $tzil->distmeta;

    diag 'got log messages: ', explain $tzil->log_messages
        if not Test::Builder->new->is_passing;
}

{
    my $tzil = Builder->from_config(
        { dist_root => 'does-not-exist' },
        {
            add_files => {
                path(qw(source dist.ini)) => simple_ini(
                    {   # merge into root section
                        author   => [
                            'Anon Y. Moose <anon@null.com>',
                            'Anne O\'Thor <anne@cpan.org',
                        ],
                    },
                    'GatherDir',
                    [ 'MakeMaker::Awesome' => { eumm_version => '6.68' } ],
                ),
            },
        },
    );

    $tzil->chrome->logger->set_debug(1);
    $tzil->build;

    like(
        $tzil->slurp_file('build/Makefile.PL'),
        qr/^\s*['"]AUTHOR['"]\s*=>\s*\[\s*[^]]+\],/m,
        'AUTHOR generated as a listref, when eumm_version already accomodates the requirement',
    );

    cmp_deeply(
        $tzil->distmeta,
        superhashof({
            prereqs => {
                configure => {
                    requires => {
                        'ExtUtils::MakeMaker' => '6.68',
                    },
                },
            },
        }),
        'ExtUtils::MakeMaker prereq matches eumm_version',
    )
        or diag 'got distmeta: ', explain $tzil->distmeta;

    diag 'got log messages: ', explain $tzil->log_messages
        if not Test::Builder->new->is_passing;
}

{
    my $tzil = Builder->from_config(
        { dist_root => 'does-not-exist' },
        {
            add_files => {
                path(qw(source dist.ini)) => simple_ini(
                    {   # merge into root section
                        author   => [
                            'Anon Y. Moose <anon@null.com>',
                            'Anne O\'Thor <anne@cpan.org',
                        ],
                    },
                    'GatherDir',
                    'MakeMaker::Awesome',
                ),
            },
        },
    );

    $tzil->chrome->logger->set_debug(1);
    $tzil->build;

    like(
        $tzil->slurp_file('build/Makefile.PL'),
        qr/^\s*['"]AUTHOR['"]\s*=>\s*(['"]).+['"],/m,
        'AUTHOR generated as string, not listref',
    );

    cmp_deeply(
        $tzil->distmeta,
        superhashof({
            prereqs => {
                configure => {
                    requires => {
                        'ExtUtils::MakeMaker' => '0',
                    },
                },
            },
        }),
        'minimum EUMM version is still zero, when we cannot justify raising it just for the listref AUTHOR feature',
    )
        or diag 'got distmeta: ', explain $tzil->distmeta;

    diag 'got log messages: ', explain $tzil->log_messages
        if not Test::Builder->new->is_passing;
}

done_testing;
