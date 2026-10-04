#!/usr/bin/perl -w
# Conformance runner for the Turscar dkim2tests vectors (Steve Atkins),
# checked out as the git submodule at <repo>/dkim2tests.  Each vector's signed
# message is run through Mail::DKIM2::Verifier and the accept/reject decision
# is compared to the vector's ExpectedState ('pass' == accept, else reject).
#
# The vectors target draft-02, but the tag rules (case-insensitive identifiers,
# any order, single occurrence, FWS) and the >=1024-bit key requirement (§3.2)
# are unchanged in draft-06, so they apply to us directly.
#
# Exact status-code differences (we may say 'fail' where a vector says
# 'permerror') are reported as diagnostics but do not fail the gate; the
# security-critical property is the accept/reject decision.
use 5.020;
use strict;
use warnings;
use Test::More;
use Path::Tiny;
use lib 'lib', 't/lib';
use Mail::DKIM2::Common qw(parse_dkim_pubkey);
use Mail::DKIM2::Verifier;

my $tests_dir = path('../dkim2tests/tests');
plan skip_all => "dkim2tests submodule not checked out (git submodule update --init)"
    unless $tests_dir->is_dir;

eval { require TOML::Parser; 1 }
    or plan skip_all => "TOML::Parser not available";

# Upstream vectors we knowingly diverge from, with the reason (not gated).
my %KNOWN_DIVERGENCE = (
    # Steve's signer emitted an EMPTY s= signature value here (the .signed file
    # ends "...s = rsa2048:rsa-sha256:" with no bytes) — its own signature
    # insertion tripped over the very header whitespace this test exercises.
    # With no signature present, ExpectedState 'pass' is unachievable.
    tags_whitespace => 'upstream vector has an empty s= signature value',
);

my $parser = TOML::Parser->new;

sub verdict {
    my ($toml) = @_;
    my $d = $parser->parse_file("$toml");
    my $signed = path($tests_dir, $d->{SignedFile})->slurp_raw;
    my %dns = %{ $d->{DNS} // {} };
    my $cb = sub {
        my ($sig, $idx) = @_;
        my $sel = $sig->selector($idx) // return undef;
        my $dom = $sig->domain          // return undef;
        my $txt = $dns{"$sel._domainkey.$dom"} // return undef;
        return parse_dkim_pubkey($txt);
    };
    my $v = Mail::DKIM2::Verifier->new;
    $v->skip_timestamp_check(1);
    $v->set_pubkey_callback($cb);
    $v->PRINT($signed);
    $v->CLOSE;
    return ($d->{Name} // $toml->basename, $d->{ExpectedState} // '?',
            $v->result, $v->result_detail);
}

my ($gated, $skipped) = (0, 0);
my @tomls = sort $tests_dir->children(qr/\.toml$/);
for my $toml (@tomls) {
    my ($name, $exp, $got, $detail) = verdict($toml);
    if (my $why = $KNOWN_DIVERGENCE{$name}) {
    SKIP: { skip "$name: $why (got $got)", 1 }
        $skipped++;
        next;
    }
    $gated++;
    my $exp_accept = ($exp eq 'pass') ? 1 : 0;
    my $got_accept = ($got eq 'pass') ? 1 : 0;
    is($got_accept, $exp_accept, "$name: expect=$exp got=$got")
        or diag($detail);
    diag("  note: $name rejects as '$got', vector labels it '$exp'")
        if !$exp_accept && !$got_accept && $exp ne $got;
}

diag("$gated gated vectors agree on accept/reject; $skipped skipped");

done_testing;
