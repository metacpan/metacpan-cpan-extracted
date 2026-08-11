#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Test::More;
use File::Temp qw(tempdir);
use File::Spec;
use Encode qw(encode_utf8);
use Digest::MD5 qw(md5_hex);

use lib 'lib';

use Developer::Dashboard::PathRegistry;
use Developer::Dashboard::SeedSync;

# Hermetic, isolated runtime. SeedSync is a pure content-digest helper module,
# but keep the standard tempdir + HOME + chdir isolation so the temporary seed
# files this test writes never touch the developer's real tree, and so the
# deepest .developer-dashboard layer resolves from an empty temporary root.
my $home = tempdir( CLEANUP => 1 );
local $ENV{HOME} = $home;
chdir $home or die "Unable to chdir to $home: $!";
my $paths = Developer::Dashboard::PathRegistry->new( home => $home );
isa_ok( $paths, 'Developer::Dashboard::PathRegistry', 'hermetic path registry rooted at the temp home' );

# --- content_md5 undef-content guard (drives the !defined $content branch) ---
is(
    Developer::Dashboard::SeedSync::content_md5(undef),
    Developer::Dashboard::SeedSync::content_md5(''),
    'content_md5 normalizes undef content to the empty-string digest',
);
is(
    Developer::Dashboard::SeedSync::content_md5(),
    Developer::Dashboard::SeedSync::content_md5(''),
    'content_md5 with no argument at all also falls back to the empty-string digest',
);
is(
    Developer::Dashboard::SeedSync::content_md5('managed-seed-body'),
    md5_hex('managed-seed-body'),
    'content_md5 hashes defined byte content directly',
);

# --- same_content_md5 both truth values ---
ok(
    Developer::Dashboard::SeedSync::same_content_md5( 'payload', 'payload' ),
    'same_content_md5 is true for identical payloads',
);
ok(
    !Developer::Dashboard::SeedSync::same_content_md5( 'payload', 'other-payload' ),
    'same_content_md5 is false for differing payloads',
);

# --- _content_bytes utf8 normalization (regression guard, not a coverage gap) ---
{
    my $unicode = "seed-smile-\x{1F600}";
    ok( utf8::is_utf8($unicode), 'wide unicode payload carries the internal utf8 flag' );
    is(
        Developer::Dashboard::SeedSync::content_md5($unicode),
        md5_hex( encode_utf8($unicode) ),
        'content_md5 encodes utf8-flagged content to bytes before hashing',
    );
}

# --- file_matches_content_md5 path-guard OR conditions (line 36) ---
is(
    Developer::Dashboard::SeedSync::file_matches_content_md5( undef, 'x' ),
    0,
    'file_matches_content_md5 returns 0 for an undefined path (first OR operand true)',
);
is(
    Developer::Dashboard::SeedSync::file_matches_content_md5( '', 'x' ),
    0,
    'file_matches_content_md5 returns 0 for an empty path (second OR operand true)',
);
my $missing = File::Spec->catfile( $home, 'does-not-exist-seed.txt' );
is(
    Developer::Dashboard::SeedSync::file_matches_content_md5( $missing, 'x' ),
    0,
    'file_matches_content_md5 returns 0 when a non-empty path is not a regular file (third OR operand true)',
);

# --- file_matches_content_md5 against a real on-disk file (false side of line 36) ---
my $real = File::Spec->catfile( $home, 'seed-match.txt' );
{
    open my $fh, '>:raw', $real or die "Unable to write $real: $!";
    print {$fh} 'managed-seed-body';
    close $fh or die "Unable to close $real: $!";
}
ok(
    Developer::Dashboard::SeedSync::file_matches_content_md5( $real, 'managed-seed-body' ),
    'file_matches_content_md5 is true when the on-disk file matches the wanted content',
);
ok(
    !Developer::Dashboard::SeedSync::file_matches_content_md5( $real, 'different-body' ),
    'file_matches_content_md5 is false when the on-disk file differs from the wanted content',
);

# --- file_matches_content_md5 open failure (drives the "or die" on line 37) ---
SKIP: {
    skip 'file permissions cannot block reads when running as root', 1 if $> == 0;
    my $unreadable = File::Spec->catfile( $home, 'unreadable-seed.txt' );
    {
        open my $fh, '>:raw', $unreadable or die "Unable to write $unreadable: $!";
        print {$fh} 'secret-seed-body';
        close $fh or die "Unable to close $unreadable: $!";
    }
    chmod 0000, $unreadable or die "Unable to chmod $unreadable: $!";
    my $error =
      eval { Developer::Dashboard::SeedSync::file_matches_content_md5( $unreadable, 'secret-seed-body' ); 1 }
      ? ''
      : $@;
    like(
        $error,
        qr/\QUnable to read $unreadable\E/,
        'file_matches_content_md5 dies when a present regular file cannot be opened for reading',
    );
    chmod 0600, $unreadable;    # let CLEANUP reclaim the file cleanly
}

done_testing;

__END__

=pod

=head1 NAME

t/63-seedsync-coverage.t - branch and condition coverage for the seed-sync content-digest helpers

=head1 PURPOSE

This test is the executable coverage contract for Developer::Dashboard::SeedSync,
the module that decides whether staged private helpers and seeded starter pages
need to be rewritten. It drives every decision edge of the digest helpers: the
undef-content normalization guard, each operand of the file-path guard, the
matching and non-matching on-disk comparison outcomes, and the unreadable-file
error path.

=head1 WHY IT EXISTS

It exists because SeedSync's guard clauses are defensive and are almost never
exercised by the higher-level init and bootstrap flows, which always pass a
defined path to a present, readable file. Without a dedicated test the undef and
empty path operands, the not-a-regular-file operand, and the unopenable-file
C<die> stay uncovered, so the library coverage gate cannot stay at 100 percent on
branch and condition metrics.

=head1 WHEN TO USE

Use this file when changing how managed seed files are compared by digest, when
adding a new dashboard-managed asset type that reuses these helpers, or when the
coverage gate reports an uncovered branch or condition inside the seed-sync
module.

=head1 HOW TO USE

Run C<perl -Ilib t/63-seedsync-coverage.t> or C<prove -lv t/63-seedsync-coverage.t>
while iterating on the digest helpers, and keep it green under C<prove -lr t> and
the Devel::Cover run before release. The permission-blocked read assertion is
skipped automatically when the suite runs as the root user, since root can open a
mode-0000 file.

=head1 WHAT USES IT

Developers during TDD, the full C<prove -lr t> repository suite, and the
Devel::Cover coverage gate all rely on this file to keep the seed-sync content
comparison branches and conditions exercised end to end.

=head1 EXAMPLES

Example 1:

  perl -Ilib t/63-seedsync-coverage.t

Run the standalone seed-sync coverage test directly while iterating.

Example 2:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lv t/63-seedsync-coverage.t

Exercise the same test while collecting coverage for the library code it reaches.

Example 3:

  prove -lr t

Put the change back through the whole repository suite before calling it done.

=cut
