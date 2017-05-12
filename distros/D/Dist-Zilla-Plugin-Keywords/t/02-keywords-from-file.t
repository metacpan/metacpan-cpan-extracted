use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::Deep;
use Test::DZil;
use Path::Tiny;

my $tzil = Builder->from_config(
    { dist_root => 'does-not-exist' },
    {
        add_files => {
            path(qw(source dist.ini)) => simple_ini(
                [ GatherDir => ],
                [ MetaConfig => ],
                [ Keywords => ],
            ),
            path(qw(source lib Foo.pm)) => <<MODULE,
package Foo;
# ABSTRACT: here there be Foo
# here is an irrelevant comment
# KEYWORDS: foo bar baz
# KEYWORDS: and more here, to be ignored
1;
=pod

=head1 SYNOPSIS

    # KEYWORDS: do not find these

=cut
MODULE
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

cmp_deeply(
    $tzil->log_messages,
    superbagof('[Keywords] found keyword string in main module: foo bar baz'),
    'we logged the strings we used',
);

diag 'saw log messages: ', explain($tzil->log_messages)
    if not Test::Builder->new->is_passing;

done_testing;
