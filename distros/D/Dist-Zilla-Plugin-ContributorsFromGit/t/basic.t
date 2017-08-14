use strict;
use warnings;
use utf8;

use autodie 'system';
use autobox::Core;

use Test::More;
use Test::TempDir::Tiny;
use Test::DZil;
use File::chdir;
use File::Which 'which';
use IPC::System::Simple (); # explicit dep for autodie system
use Path::Class;

use Test::File::ShareDir -share => {
    -dist => {
        'Dist-Zilla-Plugin-ContributorsFromGit' => 'share',
    },
};


use lib 't/lib';
use EnsureStdinTty;

plan skip_all => 'git not found'
    unless which 'git';

$ENV{GIT_AUTHOR_EMAIL}    = 'Test Ing <test@test.ing>';
$ENV{GIT_COMMITTER_EMAIL} = 'Test Ing <test@test.ing>';

my $dist_root = tempdir;

my @AUTHORS = (
    'Some One <one@some.org>',
    'Another One <two@some.org>',
    'James "宮川達彦" Salmoń <woo@bip.com>',
    'E. Xavier Ample <example@EXAMPLE.ORG>'
);

{
    local $CWD = "$dist_root";
    system $_ for
        'git init',
        'touch foo && git add foo',
        "git commit --author '$AUTHORS[0]' -m 'one'",
        'touch bar && git add bar',
        "git commit --author '$AUTHORS[1]' -m 'two'",
        'touch baz && git add baz',
        "git commit --author '$AUTHORS[2]' -m 'three'",
        'touch biff && git add biff',
        "git commit --author '$AUTHORS[3]' -m 'four'",
        'touch aack && git add aack',
        q{git commit --author 'Your Name <you@example.com>' -m 'two'},
        ;
}

my $STASH_NAME = '%PodWeaver';
my @dist_ini   = qw(ContributorsFromGit FakeRelease);

my $tzil = Builder->from_config(
    { dist_root => "$dist_root" },
    {
        add_files => {
            'source/dist.ini' => simple_ini(@dist_ini),
        },
    },
);

isa_ok $tzil, 'Dist::Zilla::Dist::Builder';
ok $tzil->plugin_named('ContributorsFromGit'), 'tzil has our test plugin';

ok !$tzil->stash_named($STASH_NAME), 'tzil does not yet have the stash';
$tzil->release;

is_deeply
    [ sort @{$tzil->distmeta->{x_contributors}} ],
    [ sort @AUTHORS[0..2] ],
    "x_contributors metadata"
    ;

my $stash = $tzil->stash_named($STASH_NAME);
isa_ok $stash, 'Dist::Zilla::Stash::PodWeaver';

my $cleanup_ok = is_deeply
    [
        sort
        map  { $stash->_config->{$_}                }
        grep { /^Contributors\.contributors\[\d+\]/ }
        $stash->_config->keys->flatten
    ],
    [ sort @AUTHORS[0..2] ],
    'contributors and git authors match up',
    ;

done_testing;
