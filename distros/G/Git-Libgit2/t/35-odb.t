#!/usr/bin/env perl
use Test2::V0;
use Path::Tiny;
use Git::Libgit2 qw( init_lib shutdown_lib check_rc oid_from_hex );
use Git::Libgit2::FFI ();
use FFI::Platypus::Buffer qw( scalar_to_buffer );

local $ENV{GIT_CONFIG_GLOBAL} = '/dev/null';
local $ENV{GIT_CONFIG_SYSTEM} = '/dev/null';

init_lib();

my $tmp = Path::Tiny->tempdir;
my $repo;
check_rc Git::Libgit2::FFI::git_repository_init( \$repo, "$tmp", 0 );
check_rc Git::Libgit2::FFI::git_repository_set_head( $repo, 'refs/heads/main' );

# --- one blob so there is an object that is present ---
my $blob_buf = "\0" x 20;
my ($blob_ptr) = scalar_to_buffer($blob_buf);
my ($content_ptr) = scalar_to_buffer("odb content\n");
check_rc Git::Libgit2::FFI::git_blob_create_from_buffer( $blob_ptr, $repo, $content_ptr, 12 );

# --- the repository's own ODB knows the blob and not an absent oid ---
my $odb;
check_rc Git::Libgit2::FFI::git_repository_odb( \$odb, $repo );
ok( $odb, 'git_repository_odb returned an odb handle' );

ok( Git::Libgit2::FFI::git_odb_exists( $odb, $blob_ptr ), 'repository odb has the blob' );

my $absent_buf = oid_from_hex( 'deadbeef' x 5 );
my ($absent_ptr) = scalar_to_buffer($absent_buf);
ok( !Git::Libgit2::FFI::git_odb_exists( $odb, $absent_ptr ), 'repository odb lacks an absent oid' );

# --- git_odb_new takes no repository: a fresh odb has no backends ---
my $empty;
check_rc Git::Libgit2::FFI::git_odb_new( \$empty );
ok( $empty, 'git_odb_new returned an odb handle' );
ok( !Git::Libgit2::FFI::git_odb_exists( $empty, $blob_ptr ), 'fresh odb has no backends: even the blob is unknown' );

Git::Libgit2::FFI::git_odb_free($empty);
Git::Libgit2::FFI::git_odb_free($odb);
Git::Libgit2::FFI::git_repository_free($repo);
shutdown_lib();
done_testing;
