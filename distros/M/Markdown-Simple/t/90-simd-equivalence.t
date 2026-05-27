#!/usr/bin/env perl
# Phase 10 / Task 10.6 — SIMD ↔ scalar equivalence harness.
#
# For every JSON case file under t/data and every .md sample under
# bench/corpus, render once with the SIMD backend forced ON and once
# with it forced OFF, and assert byte-identical HTML output. This is
# the single most important guardrail for phase 10: any time the
# bitmap/dispatch fast paths drift away from the scalar reference,
# this test fires.

use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/../blib/lib";
use lib "$FindBin::Bin/../blib/arch";

use Markdown::Simple qw(markdown_to_html);

# Capability gate.
unless (Markdown::Simple->can('_simd_force_scalar')) {
    plan skip_all => 'SIMD knobs unavailable in this build';
}

my $backend = Markdown::Simple::_simd_backend();
diag("SIMD backend: $backend");

# ---- sample corpus ----
my @samples;

# Tiny inline fixtures that exercise every dispatch class.
push @samples, map { { name => "inline-$_->[0]", md => $_->[1] } } (
    [ plain    => "hello world\n" ],
    [ emph     => "*a* _b_ **c** __d__ ***e*** ~f~ ~~g~~\n" ],
    [ links    => "[t](u 'x')  [r][1]  ![a](i)\n\n[1]: y\n" ],
    [ entities => "a & b < c > d \" e &amp; &#x41;\n" ],
    [ code     => "`x` ``y``  \\*not emph\\*\n" ],
    [ escape   => "\\\\ \\` \\* \\_ \\{ \\}\n" ],
    [ html     => "<span>hi</span>  <em>x</em>\n" ],
    [ table    => "| a | b |\n|---|---|\n| 1 | 2 |\n" ],
    [ fence    => "```\ncode\n```\n" ],
    [ heading  => "# h1\n\n## h2\n\nsetext\n=====\n" ],
    [ list     => "- a\n- b\n  - c\n\n1. x\n2. y\n" ],
    [ mixed    => "Para with `code`, *emph*, [link](u), ![img](i), and a\n"
                . "soft break.\nNew line.\n" ],
);

# Big files if present.
for my $f (glob("$FindBin::Bin/../bench/corpus/*.md")) {
    open my $fh, '<:raw', $f or next;
    local $/;
    push @samples, { name => "corpus:" . (split m{/}, $f)[-1], md => scalar <$fh> };
}

# Spec test inputs (CommonMark + GFM) — these are the gold standard for
# coverage of weird edge cases.
for my $j ("$FindBin::Bin/data/commonmark-spec.json",
           "$FindBin::Bin/data/gfm-spec.json") {
    next unless -f $j;
    require JSON::PP;
    open my $fh, '<:raw', $j or next;
    local $/;
    my $cases = JSON::PP::decode_json(scalar <$fh>);
    close $fh;
    for my $c (@$cases) {
        next unless defined $c->{markdown};
        push @samples, {
            name => "spec:" . (defined $c->{section} ? $c->{section} : '?') . "#" . (defined $c->{example} ? $c->{example} : '?'),
            md   => $c->{markdown},
            gfm  => ($j =~ /gfm/ ? 1 : 0),
        };
    }
}

plan tests => scalar(@samples);

for my $s (@samples) {
    Markdown::Simple::_simd_force_scalar(1);
    my $scalar = markdown_to_html($s->{md}, { gfm => (defined $s->{gfm} ? $s->{gfm} : 0) });

    Markdown::Simple::_simd_force_scalar(0);
    my $simd   = markdown_to_html($s->{md}, { gfm => (defined $s->{gfm} ? $s->{gfm} : 0) });

    is($simd, $scalar, "$s->{name} simd==scalar")
        or do {
            my $hex = sub { join(' ', map { sprintf "%02x", ord } split //, substr(shift, 0, 64)) };
            diag("scalar (first 64 bytes hex): " . $hex->($scalar));
            diag("simd   (first 64 bytes hex): " . $hex->($simd));
        };
}
