#!perl -T
use strict;
use warnings;
use Test2::V0;

use Git::MoreHooks::CheckCommitAuthorFromMailmap;

BEGIN {
    can_ok( 'Git::MoreHooks::CheckCommitAuthorFromMailmap', '_setup_config' );
    can_ok( 'Git::MoreHooks::CheckCommitAuthorFromMailmap', 'check_commit_at_client' );
    can_ok( 'Git::MoreHooks::CheckCommitAuthorFromMailmap', 'check_commit_at_server' );
    can_ok( 'Git::MoreHooks::CheckCommitAuthorFromMailmap', '_check_author' );
    can_ok( 'Git::MoreHooks::CheckCommitAuthorFromMailmap', '_check_mailmap' );
    can_ok( 'Git::MoreHooks::CheckCommitAuthorFromMailmap', 'check_ref' );
    can_ok( 'Git::MoreHooks::CheckCommitAuthorFromMailmap', 'check_affected_refs' );
    can_ok( 'Git::MoreHooks::CheckCommitAuthorFromMailmap', 'check_patchset' );
}

done_testing();
