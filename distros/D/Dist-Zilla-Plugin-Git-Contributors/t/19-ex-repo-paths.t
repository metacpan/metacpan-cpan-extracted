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

# in this test, the repository root and distribution root are different, and  we take files from outside the
# distribution root, so we need to make an extra directory level inside the tempdir we pass to dzil.

# tempdir
# -> repo_root (tempdir_root passed to tzil)
#    -> tempdir
#       -> myconfig.txt
#       -> source (dist root)
#          -> Changes
#          -> lib
#             -> Foo.pm

my $repo_root = no_git_tempdir()->child('repo_root');
$repo_root->mkpath;
my $tzil = Builder->from_config(
    { dist_root => 'does-not-exist' },
    {
        tempdir_root => $repo_root->stringify,
        add_files => {
            path(qw(source dist.ini)) => simple_ini(
                {   # merge into root section
                    author   => [
                        'Anon Y. Moose <anon@null.com>',
                        'Anne O\'Thor <author@example.com>',
                    ],
                },
                [ GatherDir => ],
                [ MetaConfig => ],
                [ 'Git::Contributors' => { paths => [ '../myconfig.txt' ] } ],
            ),
            path(qw(source lib Foo.pm)) => "package Foo;\n1;\n",
        },
    },
);

my $dist_root = path($tzil->tempdir)->child('source');
my $git = git_wrapper($repo_root);

my $changes = $dist_root->child('Changes');
$changes->spew("Release history for my dist\n\n");
$git->add($changes->stringify);
$git->commit({ message => 'first commit', author => 'Hey Jude <jude@example.org>' });

my $module = $dist_root->child('lib', 'Foo.pm');
$module->parent->mkpath;
$module->append("'ohhai'\n");
$git->add($module->stringify);
$git->commit({ message => 'second commit', author => 'Anon Y. Moose <anon@null.com>' });

my $configfile = $dist_root->child('..', 'myconfig.txt');
$configfile->spew("This is my config file. There are many like it but this is mine.\n");
$git->add($configfile->stringify);
$git->commit({ message => 'third commit', author => 'Foo Bar <foo@bar.com>' });

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
            'Foo Bar <foo@bar.com>',
        ],
        x_Dist_Zilla => superhashof({
            plugins => supersetof(
                {
                    class => 'Dist::Zilla::Plugin::Git::Contributors',
                    config => {
                        'Dist::Zilla::Plugin::Git::Contributors' => superhashof({
                            paths => [ '../myconfig.txt' ],
                        }),
                    },
                    name => 'Git::Contributors',
                    version => Dist::Zilla::Plugin::Git::Contributors->VERSION,
                },
            ),
        }),
    }),
    'contributor names are extracted, from only the specified path',
) or diag 'got distmeta: ', explain $tzil->distmeta;

diag 'got log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;

done_testing;
