use strict;
use warnings;

use utf8;
use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::DZil;
use Test::Fatal;
use Test::Deep;
use Path::Tiny;

use lib 't/lib';
use GitSetup;

## == Test Description ==
#
# Git resolves 'user.name' starting with ./.git/config
# And then proceeds to ~/.gitconfig
#
# If neither of these things exist, then calling:
#
#   git config user.name
#
# Causes Git to throw a fatal exception
#
# A scenario which may trigger this is as follows:
#
# 1. User has a brand new profile
# 2. User clones some distribution that uses Git::Contributors
# 3. User attempts to do 'dzil build'
#
# Because the user never configured user.name, git fatalises.

my $tempdir = no_git_tempdir();
my $tzil = Builder->from_config(
    { dist_root => 'does-not-exist' },
    {
        add_files => {
            path(qw(source dist.ini)) => simple_ini(
                [ GatherDir => ],
                [ 'Git::Contributors' => { include_releaser => 0 } ],
            ),
            path(qw(source lib Foo.pm)) => "package Foo;\n1;\n",
        },
        tempdir_root => $tempdir->stringify,
    },
);

my $root = path($tzil->tempdir)->child('source');
my $git = git_wrapper($root, { setup_user => undef });

my $changes = $root->child('Changes');
$changes->spew("Release history for my dist\n\n");

{
    # Note:
    # We must set these environment variables to coerce git into committing happily.
    # Without them, git will complain about authors and stuff'
    # due to no 'user.name' in either --global or ./
    local ( $ENV{'GIT_AUTHOR_NAME'}, $ENV{'GIT_COMMITTER_NAME'} )   = ('Anon Y. Mus') x 2;
    local ( $ENV{'GIT_AUTHOR_EMAIL'}, $ENV{'GIT_COMMITTER_EMAIL'} ) = ('anonymus@example.org') x 2;

    $git->add('Changes');
    $git->commit({ message => 'first commit', author => 'Ilmari <ilmari@example.org>' });
}

$tzil->chrome->logger->set_debug(1);

is(
  exception { $tzil->build },
  undef,
  'build proceeds normally',
);

cmp_deeply(
    $tzil->distmeta->{x_contributors},
    [ 'Ilmari <ilmari@example.org>', ],
    'contributor names are extracted, with authors not stripped',
) or diag 'got distmeta: ', explain $tzil->distmeta;

diag 'saw log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;

done_testing;
