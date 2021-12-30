#!perl -T
use strict;
use warnings;
use Test2::V0;

use Git::MoreHooks::GitRepoAdmin;

BEGIN {
    can_ok( 'Git::MoreHooks::GitRepoAdmin', '_setup_config' );
    can_ok( 'Git::MoreHooks::GitRepoAdmin', '_current_version' );
    can_ok( 'Git::MoreHooks::GitRepoAdmin', '_new_version' );
    can_ok( 'Git::MoreHooks::GitRepoAdmin', '_ref_matches' );
    can_ok( 'Git::MoreHooks::GitRepoAdmin', '_update_server_side' );
    can_ok( 'Git::MoreHooks::GitRepoAdmin', 'check_affected_refs_client_side' );
    can_ok( 'Git::MoreHooks::GitRepoAdmin', 'check_affected_refs_server_side' );
}

done_testing();
