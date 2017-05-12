use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::DZil;
use Test::Fatal;
use Test::Deep;
use Path::Tiny;

use lib 't/lib';
use GitSetup;

foreach my $order_by (qw(name commits))
{
    my $tempdir = no_git_tempdir();
    my $tzil = Builder->from_config(
        { dist_root => 'does-not-exist' },
        {
            add_files => {
                path(qw(source dist.ini)) => simple_ini(
                    [ GatherDir => ],
                    [ 'Git::Contributors' => { order_by => $order_by } ],
                ),
                path(qw(source lib Foo.pm)) => "package Foo;\n1;\n",
            },
            tempdir_root => $tempdir->stringify,
        },
    );

    my $root = path($tzil->tempdir)->child('source');
    my $git = git_wrapper($root);

    my $changes = $root->child('Changes');
    $changes->spew("Release history for my dist\n\n");
    $git->add('Changes');
    $git->commit({ message => 'first commit', author => 'Anon Y. Moose <anon@null.com>' });

    $changes->append("- a changelog entry\n");
    $git->add('Changes');
    $git->commit({ message => 'second commit', author => 'Z. Tinman <ztinman@example.com>' });

    $changes->append("- another changelog entry\n");
    $git->add('Changes');
    $git->commit({ message => 'third commit', author => 'Z. Tinman <ztinman@example.com>' });

    $tzil->chrome->logger->set_debug(1);

    is(
        exception { $tzil->build },
        undef,
        'build proceeds normally',
    );

    my @contributors = (
        'Anon Y. Moose <anon@null.com>',
        'Z. Tinman <ztinman@example.com>',
    );

    cmp_deeply(
        $tzil->distmeta,
        superhashof({
            x_contributors =>
                $order_by eq 'name' ? \@contributors
              : $order_by eq 'commits' ? [ reverse @contributors ]
              : die 'bad option',
            x_Dist_Zilla => superhashof({
                plugins => supersetof(
                    {
                        class => 'Dist::Zilla::Plugin::Git::Contributors',
                        config => {
                            'Dist::Zilla::Plugin::Git::Contributors' => superhashof({
                                order_by => $order_by,
                            }),
                        },
                        name => 'Git::Contributors',
                        version => Dist::Zilla::Plugin::Git::Contributors->VERSION,
                    },
                ),
            }),
        }),
        'contributor names are sorted by ' . $order_by,
    ) or diag 'got distmeta: ', explain $tzil->distmeta;

    diag 'got log messages: ', explain $tzil->log_messages
        if not Test::Builder->new->is_passing;
}

done_testing;
