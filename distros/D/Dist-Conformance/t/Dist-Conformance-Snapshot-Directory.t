#!/usr/bin/env perl
use 5.040;
use warnings FATAL => 'all';
use re '/aasx';
use Test2::V0;
use Test2::Plugin::NoWarnings;
use FindBin::libs;
use File::Temp();
use Mojo::File();

use Dist::Conformance::Snapshot::Directory();
use Dist::Conformance::Source::Git();

# The configuration of the person who runs the tests, such as a core.hooksPath, stays out.
local $ENV{GIT_CONFIG_GLOBAL}   = '/dev/null';
local $ENV{GIT_CONFIG_NOSYSTEM} = 1;

sub checkout () {
    my $root = Mojo::File->new( File::Temp::tempdir( CLEANUP => 1 ) );
    $root->child('CLAUDE.md')->spew("hello\n");
    $root->child( 'git-hooks', 'pre-commit' )->dirname->make_path;
    $root->child( 'git-hooks', 'pre-commit' )->spew(q{});
    $root->child( '.git',      'hooks' )->make_path;
    $root->child( '.git',      'config' )->spew("[core]\n");
    my $sub = $root->child('sub')->make_path;
    $sub->child('.git')->spew("gitdir: /bogus\n");
    symlink 'CLAUDE.md', $root->child('link') or die "symlink: $!";
    return $root;
}

subtest new => sub {
    like( dies { Dist::Conformance::Snapshot::Directory->new },                          qr/root\ is\ required/, 'root is required' );
    like( dies { Dist::Conformance::Snapshot::Directory->new( root => '/bogus/none' ) }, qr/not\ a\ directory/,  'root must be a directory' );
};

subtest paths => sub {
    my $snapshot = Dist::Conformance::Snapshot::Directory->new( root => checkout() );
    is(
        $snapshot->paths,
        {
            'CLAUDE.md'            => 'ce013625030ba8dba906f756967f9e9ca394464a',
            'git-hooks/pre-commit' => 'e69de29bb2d1d6434b8b29ae775ad8c2e48c5391',
            'link'                 => Dist::Conformance::Snapshot::blob_sha('CLAUDE.md'),
        },
        'every file with its blob SHA, a link hashed by its target, and nothing from a .git at any depth',
    );
};

subtest 'contains, sha and content' => sub {
    my $snapshot = Dist::Conformance::Snapshot::Directory->new( root => checkout() );
    ok( $snapshot->contains('CLAUDE.md'),  'a file is there' );
    ok( $snapshot->contains('link'),       'a link is there' );
    ok( !$snapshot->contains('git-hooks'), 'a directory is not a path' );
    ok( !$snapshot->contains('nope'),      'a missing file is not there' );
    is( $snapshot->sha('CLAUDE.md'),     'ce013625030ba8dba906f756967f9e9ca394464a', 'the SHA of one file' );
    is( $snapshot->sha('nope'),          undef,                                      'no SHA for a missing file' );
    is( $snapshot->content('CLAUDE.md'), "hello\n",                                  'the bytes of a file' );
    is( $snapshot->content('git-hooks'), undef,                                      'a directory has no content' );
    is( $snapshot->content('nope'),      undef,                                      'a missing file has no content' );
};

subtest file => sub {
    my $snapshot = Dist::Conformance::Snapshot::Directory->new( root => checkout() );
    for my $bad ( qw{/bogus/abs ../outside a/../../outside a/..}, q{} ) {
        like( dies { $snapshot->file($bad) }, qr/not\ a\ relative\ path/, "'$bad' is refused" );
    }
    is( $snapshot->file('a/..b')->basename, '..b', 'a name that only starts with two dots is a name' );
};

subtest write => sub {
    my $root     = checkout();
    my $snapshot = Dist::Conformance::Snapshot::Directory->new( root => $root );
    $snapshot->write( 'deep/new/file', 'bytes' );
    is( $root->child(qw{deep new file})->slurp,                'bytes', 'writes the bytes, and makes the directories' );
    is( $root->child(qw{deep new file})->stat->mode & oct 777, oct 644, 'with mode 0644 by default' );
    $snapshot->write( 'CLAUDE.md', 'new', oct 755 );
    is( $snapshot->content('CLAUDE.md'),                 'new',   'replaces a file' );
    is( $root->child('CLAUDE.md')->stat->mode & oct 777, oct 755, 'with the mode it was given' );
    like( dies { $snapshot->write( '../escape', 'x' ) }, qr/not\ a\ relative\ path/, 'refuses to write outside the root' );
    ok( $snapshot->writable, 'a directory is writable' );
};

# A repository that git made, with one commit, so that a worktree can start from it.
sub repository () {
    my $root = Mojo::File->new( File::Temp::tempdir( CLEANUP => 1 ) );
    Dist::Conformance::Source::Git::git( qw{init --quiet}, "$root" );
    Dist::Conformance::Source::Git::git( q{-C}, "$root", qw{-c user.name=t -c user.email=t@test.test commit --quiet --allow-empty -m one} );
    return $root;
}

subtest hooks_dir => sub {
    my $hooks_of = sub ($root) { return Dist::Conformance::Snapshot::Directory->new( root => $root )->hooks_dir };
    my $root     = repository();
    is( $hooks_of->($root)->to_string, $root->child(qw{.git hooks})->to_string, 'a checkout keeps them in .git/hooks' );

    my $plain = Mojo::File->new( File::Temp::tempdir( CLEANUP => 1 ) );
    is( $hooks_of->($plain), undef, 'a directory that is not a checkout has none' );

    my $worktree = Mojo::File->new( File::Temp::tempdir( CLEANUP => 1 ) )->child('wt');
    Dist::Conformance::Source::Git::git( q{-C}, "$root", qw{worktree add --quiet --detach}, "$worktree" );
    is( $hooks_of->($worktree)->realpath->to_string, $root->child(qw{.git hooks})->realpath->to_string, 'a worktree uses the hooks of its main checkout' );

    my $elsewhere = Mojo::File->new( File::Temp::tempdir( CLEANUP => 1 ) );
    Dist::Conformance::Source::Git::git( q{-C}, "$root", qw{config core.hooksPath}, "$elsewhere" );
    is( $hooks_of->($worktree)->to_string, "$elsewhere", 'or the directory that core.hooksPath names' );

    Dist::Conformance::Source::Git::git( q{-C}, "$root", qw{config core.hooksPath git-hooks} );
    is( $hooks_of->($worktree)->to_string, $worktree->child('git-hooks')->to_string, 'which, when it is relative, each worktree finds in its own root' );
    is( $hooks_of->($root)->to_string,     $root->child('git-hooks')->to_string,     'and so does the main checkout' );

    my $odd = Mojo::File->new( File::Temp::tempdir( CLEANUP => 1 ) );
    $odd->child('.git')->spew("nonsense\n");
    like( dies { $hooks_of->($odd) }, qr/rev-parse\ --git-path\ hooks\ failed:/, 'a .git that git cannot read is an error of git' );
};

subtest 'install_hook and installed_hook' => sub {
    my $root     = repository();
    my $snapshot = Dist::Conformance::Snapshot::Directory->new( root => $root );
    is( $snapshot->installed_hook('pre-commit'), undef, 'no hook before it is installed' );
    $snapshot->install_hook( 'pre-commit', "#!/bin/sh\n" );
    is( $snapshot->installed_hook('pre-commit'),                       "#!/bin/sh\n", 'the hook is installed' );
    is( $root->child(qw{.git hooks pre-commit})->stat->mode & oct 777, oct 755,       'and executable' );
    like( dies { $snapshot->install_hook( '../x', q{} ) }, qr/not\ a\ hook\ name/, 'a hook name cannot leave the hooks directory' );

    my $plain = Dist::Conformance::Snapshot::Directory->new( root => File::Temp::tempdir( CLEANUP => 1 ) );
    like( dies { $plain->install_hook( 'pre-commit', q{} ) }, qr/not\ a\ git\ checkout/, 'no hook outside a checkout' );
    is( $plain->installed_hook('pre-commit'), undef, 'and none installed' );
};

done_testing;
