use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::DZil;
use Test::Fatal;
use Test::Deep;
use Path::Tiny;

use Test::Needs qw(Dist::Zilla::Plugin::PodWeaver Pod::Weaver::Section::Contributors);

use lib 't/lib';
use GitSetup;

$Pod::Weaver::Section::Contributors::VERSION = '0.007';

# Pod::Weaver::Section::Contributors is old
# two tests with identical conditions, except:
# - when there are contributor names, a warning is given
# - when there are no contributor names, no warning is given
foreach my $have_contributors (1, 0)
{
    my $tempdir = no_git_tempdir();
    my $tzil = Builder->from_config(
        { dist_root => 'does-not-exist' },
        {
            add_files => {
                path(qw(source dist.ini)) => simple_ini(
                    [ GatherDir => ],
                    [ PodWeaver => ],
                    [ 'Git::Contributors' ],
                ),
                path(qw(source lib Foo.pm)) => "package Foo;\n1;\n",
                path(qw(source weaver.ini)) => "[Contributors]\n",
            },
            tempdir_root => $tempdir->stringify,
        },
    );

    my $root = path($tzil->tempdir)->child('source');
    my $git = git_wrapper($root);

    my $changes = $root->child('Changes');
    $changes->spew("Release history for my dist\n\n");
    $git->add('Changes');
    $git->commit({
        message => 'first commit',
        author => ( $have_contributors ? 'Anon Y. Moose <anon@null.com>' : $tzil->authors->[0] ),
    });

    $tzil->chrome->logger->set_debug(1);

    is(
        exception { $tzil->build },
        undef,
        'build proceeds normally',
    );

    cmp_deeply(
        $tzil->log_messages,
        superbagof(
            re(qr/^\[Git::Contributors\] WARNING! You appear to ...+ version 0.008!$/),
        ),
        'got a warning about [Contributors] being too old',
    ) if $have_contributors;

    is(
        (grep { /^\[Git::Contributors\] WARNING! You appear to ...+ version 0.008!$/ } @{$tzil->log_messages}),
        0,
        'got no warning about [Contributors] being too old',
    ) if not $have_contributors;

    diag 'got log messages: ', explain $tzil->log_messages
        if not Test::Builder->new->is_passing;
}

done_testing;
