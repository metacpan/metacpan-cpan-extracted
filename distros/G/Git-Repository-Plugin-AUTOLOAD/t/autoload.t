use strict;
use warnings;
use Test::More;
use Test::Git;
use Test::Requires::Git;
use File::Temp qw( tempdir );
use File::Spec::Functions qw( catfile catdir );
use Git::Repository qw( AUTOLOAD );

test_requires_git '1.5.0';

# setup the environment
my %env = (

    # ensure local configs won't interfere
    GIT_CONFIG_NOSYSTEM => 1,
    XDG_CONFIG_HOME     => undef,
    HOME                => undef,

    # no locale
    LC_ALL => 'C',

    # author / committer
    GIT_AUTHOR_NAME     => 'Test Author',
    GIT_AUTHOR_EMAIL    => 'test.author@example.com',
    GIT_COMMITTER_NAME  => 'Test Committer',
    GIT_COMMITTER_EMAIL => 'test.committer@example.com',
);

# pick a test repository
my $r = test_repository( git => { env => \%env } );

# no branch
is_deeply( [ $r->branch ], [], 'branch (none)' );

# add a file
my $file = 'hello.txt';
{
    open my $fh, '>', catfile( $r->work_tree, $file )
        or die "Can't open $file for writing: $!";
    print $fh "Hello, world!\n";
}
$r->add($file);
my $mesg = $r->commit( '-m' => 'hello' );

# one branch: master
is_deeply( [ $r->branch ], ['* master'], 'branch (master)' );

# git show $sha1 vs. git show
my ($sha1) = $mesg =~ /([0-9a-f]{5,})/g;
is_deeply( [ $r->show($sha1) ], [ $r->show ], 'show' );

# get the full SHA-1 (and test passing options)
my ($SHA1) = split / /,
    scalar( $r->cat_file( '--batch-check', { input => $sha1 } ) );

# get it some other way
is( $r->rev_parse('master'), $SHA1, 'rev-parse' );

# simple log
is( $r->log('--pretty=oneline'), "$SHA1 hello", 'log' );

# as class methods
my $dir = tempdir( CLEANUP => 1 );
Git::Repository->clone( $r->git_dir, { cwd => $dir } );

# different repositories
my $s = Git::Repository->new( work_tree => glob( catdir( $dir, '*' ) ) );
ok( $s->work_tree ne $r->work_tree, 'different repositories' );

# but same content
is( $s->rev_parse('master'), $SHA1, 'rev-parse' );

# check remotes
is_deeply( [ $r->remote ], [],         'remote' );
is_deeply( [ $s->remote ], ['origin'], 'remote' );

done_testing;
