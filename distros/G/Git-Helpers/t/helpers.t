use strict;
use warnings;

use Capture::Tiny qw( capture_stderr );
use File::Temp qw( tempdir );
use File::Touch qw( touch );
use Git::Helpers qw(
    checkout_root
    current_branch_name
    is_inside_work_tree
    remote_url
    travis_url
);
use Git::Version ();
use Git::Sub;
use Test::Fatal;
use Test::Git 1.313;
use Test::More;
use Test::Requires::Git 1.005;

test_requires_git();

my $r = test_repository();

{
    my $root = checkout_root( $r->work_tree );
    ok( $root, "got root $root" );
}

{
    chdir( $r->work_tree );
    my $root = checkout_root;
    ok( $root, "got root $root" );
    is( $root, $r->work_tree, 'root matches work_tree' );

    my $v = Git::Version->new(`git --version`);

SKIP: {
        skip "$v is lower than 2.7", 2, unless $v ge 2.7;
        my $remote_url  = 'git@github.com:oalders/git-helpers.git';
        my $remote_name = 'foobarbaz';
        git::remote( 'add', $remote_name, $remote_url );
        is(
            remote_url($remote_name), $remote_url,
            'remote_url is ' . $remote_url
        );
        is(
            travis_url($remote_name),
            'https://travis-ci.org/oalders/git-helpers',
            'travis_url'
        );
    }

    # Do some bootstrapping so that we have a branch with an arbitrary name.
    git::config( 'user.email', 'fdrebin@policesquad.org' );
    git::config( 'user.name',  'Frank Drebin' );

    my $file = 'README';
    touch($file);
    git::add($file);
    git::commit( '-m', $file );

    my $stderr = capture_stderr {
        git::checkout( '-b', $file );
    };
    diag $stderr;

    is( current_branch_name(), $file, 'current branch is ' . $file );

    ok( is_inside_work_tree(), 'is_inside_work_tree' );
    chdir('..');
    ok( !is_inside_work_tree(), 'not is_inside_work_tree' );
}

{
    my $dir = tempdir( CLEANUP => 1 );
    like(
        exception { checkout_root($dir) }, qr/Error in/,
        'dies on missing git repository'
    );
}

done_testing();
