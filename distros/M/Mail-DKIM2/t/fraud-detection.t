#!/usr/bin/perl -w
# Chain of Custody forgery detection.
#
# A conformant DKIM2 verifier MUST reconstruct each lower Message-Instance from
# the higher instance's Recipe and re-check its hashes (spec-06 §5, §10-11).
# These vectors each have a TOP instance (m=2) whose hashes are correct AND
# whose signature is valid, but a Recipe that does NOT reconstruct the signed
# m=1 state.  A verifier that only trusts the top instance accepts them; a
# correct one rejects them at m=1 reconstruction.
#
# Regenerate the vectors with:  perl build-fraud-test.pl
#
# Interop note (2026-07-08): the hosted socketlabs (/api/v1/dkim2/verify) and
# dkim2.eu (/validate) verifiers accept ALL THREE forgeries below — they do not
# verify lower instances against their Recipes.  Both of our implementations
# (bin/validate.pl and ../python/dkim2verify.py) reject them.
use 5.020;
use strict;
use warnings;
use Test::More;

my $dir = 'tests/expected';
plan skip_all => "fraud vectors not found (run: perl build-fraud-test.pl)"
    unless -e "$dir/chain-fraud-control.eml";

sub validate {
    my $file = shift;
    my $out = `perl -Ilib bin/validate.pl --ignore-timestamps $dir/$file 2>&1`;
    return ($? >> 8, $out);
}

# The honest control must validate end-to-end (m=2 -> m=1).
{
    my ($rc, $out) = validate('chain-fraud-control.eml');
    is($rc, 0, 'control (honest recipe) validates the whole chain') or diag $out;
}

# Each forgery must be rejected, and for the right reason (a reconstruction
# hash mismatch, not a signature or parse failure).
for my $case (
    ['chain-fraud-header.eml',        qr/header hash mismatch/,
        'header lie: recipe omits an added Reply-To'],
    ['chain-fraud-body.eml',          qr/body hash mismatch/,
        'body lie: body changed, recipe declares no body change'],
    ['chain-fraud-body-truncate.eml', qr/body hash mismatch/,
        'body lie: innocent-looking truncating copy-range hides an edited line'],
) {
    my ($file, $re, $desc) = @$case;
    my ($rc, $out) = validate($file);
    isnt($rc, 0, "$desc: rejected");
    like($out, $re, "$desc: rejected for m=1 reconstruction mismatch") or diag $out;
}

done_testing;
