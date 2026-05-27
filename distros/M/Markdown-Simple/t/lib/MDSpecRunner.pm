package MDSpecRunner;
# Shared spec-test driver for t/98-gfm-spec.t and t/99-commonmark-spec.t.
#
# Loads a CommonMark-style spec.json (array of {example, markdown, html, section, ...}),
# runs each example through Markdown::Simple, compares with MDNormalise::normalise,
# and reports pass/fail in a Test::More-friendly way that's gated by a
# known-failures file.
#
# Strict semantics:
#   - any failing example NOT in known_failures => test fails (regression)
#   - any example listed in known_failures that NOW PASSES => test fails
#     (forces removal from file as features land, preventing rot)

use strict;
use warnings;
use Exporter 'import';
use FindBin;
use lib "$FindBin::Bin/lib";
use JSON::PP   ();
use Test::More ();
use Markdown::Simple ();
use MDNormalise qw(normalise);

our @EXPORT_OK = qw(run_spec load_known_failures);

sub load_known_failures {
    my $file = shift;
    return {} unless -f $file;
    open my $fh, '<', $file or die "open $file: $!";
    my %k;
    while (<$fh>) {
        chomp;
        s/#.*//;
        s/^\s+|\s+$//g;
        next unless length;
        $k{$_} = 1;
    }
    close $fh;
    return \%k;
}

sub run_spec {
    my %args   = @_;
    my $label  = $args{label} || 'spec';
    my $json   = $args{json};
    my $known  = load_known_failures(defined $args{known_failures} ? $args{known_failures} : '');
    my $render = $args{render} || \&Markdown::Simple::markdown_to_html;

    open my $fh, '<:raw', $json or die "open $json: $!";
    my $raw = do { local $/; <$fh> };
    close $fh;
    my $cases = JSON::PP::decode_json($raw);

    my (@pass_ids, @fail_ids, %fail_by_section, %got_for, %want_for);
    for my $c (@$cases) {
        my $id   = $c->{example};
        # Spec convention: an expected body of "<IGNORE>" means the test
        # exists only to ensure the renderer doesn't crash on the input;
        # any non-die output is acceptable.
        my $ignore = (defined $c->{html} && $c->{html} =~ /\A<IGNORE>\s*\z/);
        my $got  = eval { $render->($c->{markdown}) };
        if ($ignore) {
            if (defined $got) { push @pass_ids, $id; }
            else              { push @fail_ids, $id;
                                $fail_by_section{ $c->{section} || '(none)' }++;
                                $got_for{$id}  = '<die>';
                                $want_for{$id} = $c->{html}; }
            next;
        }
        my $g    = normalise($got);
        my $w    = normalise($c->{html});
        if (defined $got && $g eq $w) {
            push @pass_ids, $id;
        } else {
            push @fail_ids, $id;
            $fail_by_section{ $c->{section} || '(none)' }++;
            $got_for{$id}  = defined $got ? $got : '<die>';
            $want_for{$id} = $c->{html};
        }
    }

    my $total = @pass_ids + @fail_ids;
    my $pct   = $total ? 100 * @pass_ids / $total : 0;
    Test::More::diag(sprintf "%s: %d/%d (%.1f%%) pass",
        $label, scalar(@pass_ids), $total, $pct);

    # Regression set: failures not in known_failures
    my @regressions = grep { !$known->{$_} } @fail_ids;
    # Newly passing set: ids listed in known_failures that now pass
    my %fail_set = map { $_ => 1 } @fail_ids;
    my @newly_pass = grep { !$fail_set{$_} } keys %$known;

    if (@regressions) {
        Test::More::diag("regressions (not in known_failures):");
        for my $id (sort { $a <=> $b } @regressions) {
            Test::More::diag(sprintf "  example %d", $id);
            if ($ENV{SPEC_VERBOSE}) {
                Test::More::diag("    want: " . _escape($want_for{$id}));
                Test::More::diag("    got:  " . _escape($got_for{$id}));
            }
        }
    }
    if (@newly_pass) {
        Test::More::diag("examples in known_failures that now PASS (remove them from $args{known_failures}):");
        Test::More::diag("  " . join(',', sort { $a <=> $b } @newly_pass));
    }

    Test::More::ok( !@regressions, "$label: no new regressions" );
    Test::More::ok( !@newly_pass,
        "$label: known_failures has no stale entries" );

    return {
        pass        => \@pass_ids,
        fail        => \@fail_ids,
        regressions => \@regressions,
        newly_pass  => \@newly_pass,
        pct         => $pct,
        total       => $total,
    };
}

sub _escape {
    my $s = shift; $s = '' unless defined $s;
    $s =~ s/\\/\\\\/g;
    $s =~ s/\n/\\n/g;
    $s =~ s/\t/\\t/g;
    return length($s) > 200 ? substr($s,0,200) . "..." : $s;
}

1;
