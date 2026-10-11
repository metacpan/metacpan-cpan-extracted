#!perl
use strict;
use warnings;
use Test2::V0;

use Test2::Require::Module 'Git::MoreHooks::CheckTrailers';
use Git::MoreHooks::CheckTrailers;

BEGIN {
    can_ok( 'Git::MoreHooks::CheckTrailers', '_setup_config' );
    can_ok( 'Git::MoreHooks::CheckTrailers', '_parse_field' );
    can_ok( 'Git::MoreHooks::CheckTrailers', '_parse_spec' );
    can_ok( 'Git::MoreHooks::CheckTrailers', '_specs' );
    can_ok( 'Git::MoreHooks::CheckTrailers', '_paragraphs' );
    can_ok( 'Git::MoreHooks::CheckTrailers', '_trailers' );
    can_ok( 'Git::MoreHooks::CheckTrailers', '_suspect_lines' );
    can_ok( 'Git::MoreHooks::CheckTrailers', '_accounted_for' );
    can_ok( 'Git::MoreHooks::CheckTrailers', '_commit_kinds' );
    can_ok( 'Git::MoreHooks::CheckTrailers', '_matches' );
    can_ok( 'Git::MoreHooks::CheckTrailers', 'deny_errors' );
    can_ok( 'Git::MoreHooks::CheckTrailers', 'require_errors' );
    can_ok( 'Git::MoreHooks::CheckTrailers', 'order_errors' );
    can_ok( 'Git::MoreHooks::CheckTrailers', 'message_errors' );
    can_ok( 'Git::MoreHooks::CheckTrailers', 'check_message_file' );
    can_ok( 'Git::MoreHooks::CheckTrailers', 'check_ref' );
    can_ok( 'Git::MoreHooks::CheckTrailers', 'check_patchset' );
}

done_testing();
