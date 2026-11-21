#!/usr/bin/env perl
use Test2::V0;
use FFI::Platypus::Buffer qw( scalar_to_buffer );

use Git::Libgit2 qw( :all );

# Pin libgit2 away from the user's gitconfig — exact bug Git::Raw shipped.
local $ENV{GIT_CONFIG_GLOBAL} = '/dev/null';
local $ENV{GIT_CONFIG_SYSTEM} = '/dev/null';

init_lib;

# git_fetch_options.prune sits directly behind the embedded git_remote_callbacks
# struct, and that struct gained fields between releases (120 bytes in 1.5, 128
# in 1.9). A hardcoded offset does not fail loudly: it writes the prune value
# into whichever callback pointer moved into its place — in 1.9 that is
# `update_refs`, which libgit2 then prefers over `update_tips` and calls. The
# offset therefore has to come from the library we are actually linked against.
my $off = fetch_options_prune_offset;

ok $off >= 128, 'prune sits behind version + the smallest known callbacks struct';
is $off % 4, 0, 'on a 4-byte boundary';
is( ( $off - 8 ) % 8, 0, 'and the callbacks struct it follows is pointer-aligned' );

# Cross-check the probe against the struct libgit2 initializes for itself:
# GIT_FETCH_OPTIONS_INIT leaves prune at GIT_FETCH_PRUNE_UNSPECIFIED (0) and
# sets update_fetchhead, the field directly behind it, to
# GIT_REMOTE_UPDATE_FETCHHEAD (1 << 0). This does not re-derive the offset --
# it asserts that the offset we report lands on that documented pair, which a
# stale hardcoded value does not.
my $buf = "\0" x 512;
my ($ptr) = scalar_to_buffer($buf);
check_rc Git::Libgit2::FFI::git_fetch_options_init( $ptr, 1 );

is unpack( 'l', substr( $buf, $off, 4 ) ), 0,
  'the probed slot holds GIT_FETCH_PRUNE_UNSPECIFIED after init';
is unpack( 'l', substr( $buf, $off + 4, 4 ) ), 1,
  'and update_fetchhead follows directly behind it';

done_testing;
