use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::Deep;
use Test::DZil;
use Path::Tiny;

my $preamble = <<'PREAMBLE';
name = DZT-Sample
abstract = Sample DZ Dist
version  = 0.001
author   = E. Xavier Ample <example@example.org>
license  = Perl_5
copyright_holder = E. Xavier Ample

[MetaConfig]
PREAMBLE

foreach my $dist_ini (
    simple_ini(
        [ MetaConfig => ],
        [ Keywords => { keywords => [ qw(foo bar baz) ] } ],
    ),
    $preamble . <<'INI',
[Keywords]
keyword = foo
keyword = bar
keyword = baz
INI
    $preamble . <<'INI',
[Keywords]
keywords = foo bar baz
INI
    $preamble . <<'INI',
[Keywords]
keywords = foo bar
keyword = baz
INI
)
{
    my $tzil = Builder->from_config(
        { dist_root => 'does-not-exist' },
        {
            add_files => {
                path(qw(source dist.ini)) => $dist_ini,
            },
        },
    );

    $tzil->chrome->logger->set_debug(1);
    $tzil->build;

    cmp_deeply(
        $tzil->distmeta,
        superhashof({
            dynamic_config => 0,
            keywords => [ qw(foo bar baz) ],
            x_Dist_Zilla => superhashof({
                plugins => supersetof(
                    {
                        class => 'Dist::Zilla::Plugin::Keywords',
                        config => {
                            'Dist::Zilla::Plugin::Keywords' => {
                                keywords => [qw(foo bar baz)],
                            },
                        },
                        name => 'Keywords',
                        version => Dist::Zilla::Plugin::Keywords->VERSION,
                    },
                ),
            }),
        }),
        'metadata is correct',
    ) or diag 'got distmeta: ', explain $tzil->distmeta;

    diag 'saw log messages: ', explain($tzil->log_messages)
        if not Test::Builder->new->is_passing;
}

done_testing;
