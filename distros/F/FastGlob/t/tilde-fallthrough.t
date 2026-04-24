#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use FastGlob ();

# Test that tilde patterns are preserved when expansion fails,
# matching CORE::glob behavior. Previously, ~nonexistent was
# silently dropped, returning an empty list.

# --- Unknown user: pattern should be preserved unchanged ---

{
    my @got = FastGlob::glob('~nonexistent_user_xyz_12345');
    is( scalar @got, 1,
        '~nonexistent_user returns one entry (not silently dropped)' );
    is( $got[0], '~nonexistent_user_xyz_12345',
        'unknown ~user pattern is preserved unchanged' );
}

# --- Known user (current user) still expands ---

SKIP: {
    my $homedir;

    if ( $^O eq 'MSWin32' ) {
        $homedir = defined($ENV{HOME}) ? $ENV{HOME} : $ENV{USERPROFILE};
    } else {
        my $has_getpwent = eval { getpwent(); 1 };
        endpwent() if $has_getpwent;
        skip 'getpwuid not available on this platform', 1 unless $has_getpwent;

        my @home = getpwuid($<);
        $homedir = $home[7];
    }

    skip 'cannot determine home directory', 1 unless $homedir && -d $homedir;

    my @got = FastGlob::glob('~');
    is( $got[0], $homedir, '~ still expands to home directory' );
}

done_testing;
