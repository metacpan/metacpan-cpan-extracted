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

{
    my $tempdir = no_git_tempdir();
    my $tzil = Builder->from_config(
        { dist_root => 'does-not-exist' },
        {
            add_files => {
                path(qw(source dist.ini)) => simple_ini(
                    {   # merge into root section
                        author   => [
                            'Anne O\'Thor <author@example.com>',
                        ],
                    },
                    [ GatherDir => ],
                    [ MetaConfig => ],
                    [ 'Git::Contributors' ],
                ),
                path(qw(source lib Foo.pm)) => "package Foo;\n1;\n",
                path(qw(source .mailmap)) => "Anon Nonny Moose <anonnonny\@moose.org> Anon Y. Moose <anon\@null.com>\n",
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

    $tzil->chrome->logger->set_debug(1);

    is(
        exception { $tzil->build },
        undef,
        'build proceeds normally',
    );

    cmp_deeply(
        $tzil->distmeta,
        superhashof({
            x_contributors => [
                'Anon Nonny Moose <anonnonny@moose.org>',
            ],
            x_Dist_Zilla => superhashof({
                plugins => supersetof(
                    {
                        class => 'Dist::Zilla::Plugin::Git::Contributors',
                        config => {
                            'Dist::Zilla::Plugin::Git::Contributors' => {
                                include_authors => 0,
                                include_releaser => 1,
                                order_by => 'name',
                                paths => [],
                                git_version => ignore,
                            },
                        },
                        name => 'Git::Contributors',
                        version => Dist::Zilla::Plugin::Git::Contributors->VERSION,
                    },
                ),
            }),
        }),
        'contributor names are extracted, with .mailmap entries applied',
    ) or diag 'got distmeta: ', explain $tzil->distmeta;

    diag 'got log messages: ', explain $tzil->log_messages
        if not Test::Builder->new->is_passing;
}

done_testing;
