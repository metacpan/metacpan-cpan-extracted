#!/usr/bin/env perl
use Test2::V0;

use Git::Libgit2 qw( init_lib cert_hostkey_offsets );
use Git::Libgit2::FFI ();

# Pin libgit2 away from the user's gitconfig — exact bug Git::Raw shipped.
local $ENV{GIT_CONFIG_GLOBAL} = '/dev/null';
local $ENV{GIT_CONFIG_SYSTEM} = '/dev/null';

init_lib;

# git_cert_hostkey is { git_cert parent; git_cert_ssh_t type; unsigned char
# hash_md5[16]; hash_sha1[20]; hash_sha256[32]; ... }. The two leading
# fields are enums (int-sized on every ABI libgit2 supports) and the hash
# fields are char arrays with no alignment demands, so the layout up to the
# end of hash_sha256 is padding-free and follows from sizeof(int) alone.
# The compile-time cross-check against the real offsetof() lives in
# Git::Native's t/75-cert-hostkey-layout.t, which reads these same values.
my %off = cert_hostkey_offsets();

my $int = Git::Libgit2::FFI::ffi()->sizeof('int');

is $off{type}, $int, 'type sits directly behind the embedded git_cert';
is $off{sha1} - $off{type}, $int + 16,
  'sha1 follows type (int) and hash_md5[16] with no padding';
is $off{sha256} - $off{sha1}, 20,
  'sha256 follows directly behind hash_sha1[20]';

# The values every supported ABI actually produces (int == 4). If a platform
# with a different int size ever shows up, the derivation above still holds
# and Git::Native's offsetof() test is the authority.
if ($int == 4) {
  is \%off, { type => 4, sha1 => 24, sha256 => 44 },
    'the 1.5.x/1.9.x layout values on an int-is-4-bytes ABI';
}

# Stability: repeated calls agree (the result is derived, not probed, but
# the contract is a constant per process).
is { cert_hostkey_offsets() }, \%off, 'offsets are stable across calls';

done_testing;
