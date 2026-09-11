#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Test::More;
use File::Spec;
use FindBin;
use File::Temp qw(tempdir);
use File::Path qw(make_path);

my $ROOT = File::Spec->rel2abs( File::Spec->catdir( $FindBin::Bin, File::Spec->updir ) );
my $T    = File::Spec->catdir( $ROOT, 't' );

# WHY THIS FILE EXISTS (DD-816)
#   Ten pairs of t/ files shared a numeric prefix on 2026-09-07 - the exact
#   class d1a6053b renumbered away once already. Nothing enforced uniqueness,
#   so parallel work reintroduced it. This is a suite-level population check
#   over the t/ DIRECTORY, not over documentation citations (that is
#   DD-786's separate, complementary guard) - a fresh collision on a prefix
#   nothing has cited yet is invisible to that guard and caught only here.
#
# Purpose: find every t/*.t file and group by its leading numeric prefix.
# Input:   a directory to scan
# Output:  a hashref of prefix => arrayref of basenames, for every prefix
#          claimed by more than one file
sub colliding_prefixes {
    my ($dir) = @_;
    opendir my $dh, $dir or die "cannot read $dir: $!";
    my @files = sort grep { /\A\d+-.*\.t\z/ } readdir $dh;
    closedir $dh;

    my %by_prefix;
    for my $file (@files) {
        my ($prefix) = $file =~ /\A(\d+)-/;
        push @{ $by_prefix{$prefix} }, $file;
    }
    return { map { $_ => $by_prefix{$_} } grep { @{ $by_prefix{$_} } > 1 } keys %by_prefix };
}

# A test aimed at an empty set can only return the answer it hoped for -
# confirm the population is non-empty before trusting a clean result.
{
    opendir my $dh, $T or die $!;
    my @real = grep { /\A\d+-.*\.t\z/ } readdir $dh;
    closedir $dh;
    ok( scalar(@real) > 100, 'the real t/ population is non-empty and large (found ' . scalar(@real) . ')' );
}

# THE PROPERTY THIS FILE EXISTS TO DEFEND, against the REAL tree.
{
    my $collisions = colliding_prefixes($T);
    is_deeply( $collisions, {}, 'no two t/ files share a numeric prefix' )
      or diag( "colliding prefixes: " . join( ', ', map { "$_: @{$collisions->{$_}}" } sort keys %$collisions ) );
}

# CONTROL: the checker actually discriminates, exercised against a real
# constructed directory rather than asserted from reading the code - a
# fixture-only test could pass by construction without ever proving the
# function distinguishes anything.
{
    my $clean = tempdir( CLEANUP => 1 );
    for my $n (qw(1-a.t 2-b.t 3-c.t)) {
        open my $fh, '>', File::Spec->catfile( $clean, $n ) or die $!;
        close $fh;
    }
    is_deeply( colliding_prefixes($clean), {}, 'CONTROL: a genuinely unique-prefix directory reports no collisions' );

    my $dirty = tempdir( CLEANUP => 1 );
    for my $n (qw(1-a.t 1-b.t 2-c.t)) {
        open my $fh, '>', File::Spec->catfile( $dirty, $n ) or die $!;
        close $fh;
    }
    my $found = colliding_prefixes($dirty);
    is_deeply( $found, { 1 => [ '1-a.t', '1-b.t' ] },
        'CONTROL: a directory with a real duplicate is caught, naming both files' );
}

done_testing;

__END__

=head1 NAME

t/178-t-numeric-prefix-uniqueness.t - guards against two t/ files sharing a
numeric prefix

=head1 PURPOSE

Asserts that no two files under C<t/> share a leading numeric prefix, and
carries genuine controls proving the check discriminates a real collision
from a clean directory.

=head1 WHY IT EXISTS

Ten pairs of t/ files shared a numeric prefix on 2026-09-07 (DD-816) - the
exact class C<d1a6053b> renumbered away once already. The project's own
operating rules and several docs pages cite tests by bare prefix (C<t/15>,
C<t/158>), trusting it to
resolve to exactly one file; a fresh collision makes that silently
ambiguous, and C<prove -lr t> runs every file regardless of its name, so
nothing else notices. This guard's population is the C<t/> directory
itself, distinct from and complementary to DD-786's citation-resolution
guard (C<t/15-release-metadata.t>), whose population is documentation
text.

=head1 WHEN TO USE

It runs in the ordinary suite. Consult it before assigning a new numeric
prefix to a fresh test file, or when investigating why a bare-prefix doc
reference resolves to more than one file.

=head1 HOW TO USE

    prove -lv t/178-t-numeric-prefix-uniqueness.t

=head1 WHAT USES IT

Nothing programmatic; it is a standing guard, run by C<prove -lr t> and by
the coverage gate.

=head1 EXAMPLES

Copying any existing t/ file to a name sharing another file's prefix makes
the real-population assertion fail, naming both files by exact filename.

=cut
