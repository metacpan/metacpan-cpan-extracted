use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::Deep;
use Test::DZil;
use Path::Tiny;

plan skip_all => 'proper keyword merging depends on CPAN::Meta::Merge and Dist::Zilla support: ' . $@
    unless eval 'require CPAN::Meta::Merge; CPAN::Meta::Merge->VERSION("2.142060"); 1'
        and eval 'require Dist::Zilla; Dist::Zilla->VERSION("5.021"); 1';

my $tzil = Builder->from_config(
    { dist_root => 'does-not-exist' },
    {
        add_files => {
            path(qw(source dist.ini)) => simple_ini(
                [ GatherDir => ],
                [ MetaConfig => ],
                [ Keywords => 'from plugin' => { keywords => [qw(foo bar)] } ],
                [ Keywords => 'direct' => { keywords => [qw(bar baz)] } ],
            ),
            path(qw(source lib Foo.pm)) => "package Foo;\n1\n",
        },
    },
);

$tzil->chrome->logger->set_debug(1);
$tzil->build;

cmp_deeply(
    $tzil->distmeta,
    superhashof({
        dynamic_config => 0,
        keywords => [qw(foo bar baz)],
        x_Dist_Zilla => superhashof({
            plugins => supersetof(
                {
                    class => 'Dist::Zilla::Plugin::Keywords',
                    config => {
                        'Dist::Zilla::Plugin::Keywords' => {
                            keywords => [qw(foo bar)],
                        },
                    },
                    name => 'from plugin',
                    version => Dist::Zilla::Plugin::Keywords->VERSION,
                },
                {
                    class => 'Dist::Zilla::Plugin::Keywords',
                    config => {
                        'Dist::Zilla::Plugin::Keywords' => {
                            keywords => [qw(bar baz)],
                        },
                    },
                    name => 'direct',
                    version => Dist::Zilla::Plugin::Keywords->VERSION,
                },
            ),
        }),
    }),
    'metadata contains merged keywords',
) or diag 'got distmeta: ', explain $tzil->distmeta;

diag 'saw log messages: ', explain($tzil->log_messages)
    if not Test::Builder->new->is_passing;

done_testing;
