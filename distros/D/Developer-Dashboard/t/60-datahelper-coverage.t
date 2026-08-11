#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Test::More;
use File::Temp qw(tempdir);

use lib 'lib';

use Developer::Dashboard::PathRegistry;
use Developer::Dashboard::DataHelper qw(j je);

# Hermetic, isolated runtime: keep every layer discovery rooted in a throwaway
# home and cwd so nothing on the developer box leaks into this coverage check.
my $home = tempdir( CLEANUP => 1 );
local $ENV{HOME} = $home;
chdir $home or die "cannot chdir to hermetic home $home: $!";

my $paths = Developer::Dashboard::PathRegistry->new( home => $home );
ok( defined $paths, 'hermetic PathRegistry built so cwd layer resolution is sandboxed' );

# --- j(): encode side ------------------------------------------------------
my $encoded = j( { a => 1 } );
like( $encoded, qr/"a"/, 'j() encodes a hashref to JSON text' );
like( $encoded, qr/1/,   'j() preserves the encoded value' );

# --- je(): left operand of ($_[0] // "") is DEFINED ------------------------
# The common path: a real JSON string is passed, so the defined-or keeps the
# left operand and hands valid text straight to the decoder.
my $decoded = je('{"a":1}');
is( ref($decoded),  'HASH', 'je() decodes JSON text into a hash reference' );
is( $decoded->{a},  1,      'je() round-trips the decoded value' );

# --- je(): right operand of ($_[0] // "") is TAKEN -------------------------
# This is the previously-uncovered condition side: with an undefined argument
# the defined-or falls through to the empty-string fallback, which is then
# handed to json_decode(). Empty string is not valid JSON, so the decoder
# throws -- but the // fallback has already been exercised by the time it does,
# which is exactly the branch this test drives. We capture the die so the test
# stays clean.
{
    my $rv = eval { je(undef); 1 };
    ok( !$rv, 'je(undef) reaches the empty-string fallback and json_decode rejects it' );
    like( $@, qr/malformed JSON/, 'the fallback empty string is what got decoded' );
}

# Same undefined-left path, but via a bare no-argument call ($_[0] absent).
{
    my $rv = eval { je(); 1 };
    ok( !$rv, 'je() with no argument also takes the // fallback side' );
    like( $@, qr/malformed JSON/, 'bare je() decodes the empty-string fallback' );
}

done_testing;

__END__

=pod

=head1 NAME

t/60-datahelper-coverage.t - branch/condition coverage for the j()/je() JSON compatibility helpers

=head1 PURPOSE

This test closes the Devel::Cover branch and condition gap in the older JSON
helper module that exposes C<j()> and C<je()>. Its specific job is to drive both
sides of the defined-or expression inside C<je()> -- the ordinary path where a
defined JSON string is decoded, and the fallback path where an undefined
argument collapses to the empty-string default before decoding.

=head1 WHY IT EXISTS

Full-suite coverage exercised C<je()> only with defined JSON arguments, so the
undefined-argument side of C<$_[0] // ''> was never taken and the module sat
below the repository's all-metrics 100% bar. This file exists so the fallback
branch stays exercised: an undefined or absent argument must still resolve to the
empty-string default and reach the decoder, and that behavior cannot silently
regress out of coverage.

=head1 WHEN TO USE

Use this file when changing the compatibility JSON helpers, when altering how an
undefined value is defaulted before decoding, or when the shared JSON backend's
decode error behavior changes.

=head1 HOW TO USE

Run C<prove -lv t/60-datahelper-coverage.t> while iterating on the helper module.
Keep it green under C<prove -lr t> and under the coverage gate before release.

=head1 WHAT USES IT

Developers during TDD, the repository regression suite, and the Devel::Cover
coverage gate all use this file to keep the compatibility helper's branch and
condition coverage complete.

=head1 EXAMPLES

Example 1:

  perl -Ilib t/60-datahelper-coverage.t

Run this coverage check standalone from a source checkout.

Example 2:

  prove -lv t/60-datahelper-coverage.t

Run the dedicated helper coverage test by itself with verbose output.

Example 3:

  prove -lr t

Run it inside the full repository suite before release.

=cut
