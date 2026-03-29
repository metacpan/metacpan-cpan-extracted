#!/usr/bin/env perl
#
# Benchmark: Litavis (XS/C) vs Crayon (pure Perl)
#
# Usage:
#   perl -Iblib/lib -Iblib/arch bench/vs_crayon.pl
#
# Requires: Benchmark (core), Litavis (this module), Crayon (optional)
#

use strict;
use warnings;
use Benchmark qw(cmpthese timethese);

# ── Load modules ──────────────────────────────────────────────

eval { require Litavis; Litavis->import(); 1 }
    or die "Cannot load Litavis: $@\nRun: perl Makefile.PL && make\n";

my $have_crayon = eval { require Crayon; Crayon->import(); 1 };

# ── Generate test CSS ─────────────────────────────────────────

sub generate_css {
    my ($num_rules) = @_;
    my @parts;
    for my $i (1..$num_rules) {
        my $color_idx = $i % 16;
        my $hex = sprintf('#%02x%02x%02x', ($i * 17) % 256, ($i * 31) % 256, ($i * 47) % 256);
        push @parts, ".rule-$i { color: $hex; font-size: ${i}px; padding: ${i}px; margin: ${i}px; }";
    }
    return join("\n", @parts);
}

sub generate_nested_css {
    my ($num_rules) = @_;
    my @parts;
    for my $i (1..$num_rules) {
        my $hex = sprintf('#%02x%02x%02x', ($i * 17) % 256, ($i * 31) % 256, ($i * 47) % 256);
        push @parts, ".parent-$i { color: $hex; .child { font-size: ${i}px; } }";
    }
    return join("\n", @parts);
}

sub generate_dedup_css {
    my ($num_groups, $rules_per_group) = @_;
    my @parts;
    for my $g (1..$num_groups) {
        my $hex = sprintf('#%02x%02x%02x', ($g * 17) % 256, ($g * 31) % 256, ($g * 47) % 256);
        for my $r (1..$rules_per_group) {
            push @parts, ".group${g}-rule${r} { color: $hex; padding: 8px; }";
        }
    }
    return join("\n", @parts);
}

sub generate_var_css {
    my ($num_rules) = @_;
    my @parts;
    push @parts, '$primary: #3498db;';
    push @parts, '$secondary: #2ecc71;';
    push @parts, '$dark: #2c3e50;';
    for my $i (1..$num_rules) {
        my $var = $i % 3 == 0 ? '$primary' : $i % 3 == 1 ? '$secondary' : '$dark';
        push @parts, ".rule-$i { color: $var; font-size: ${i}px; }";
    }
    return join("\n", @parts);
}

# ── Prepare test inputs ──────────────────────────────────────

my %inputs = (
    'small_50'      => generate_css(50),
    'medium_500'    => generate_css(500),
    'large_5000'    => generate_css(5000),
    'nested_100'    => generate_nested_css(100),
    'dedup_heavy'   => generate_dedup_css(50, 5),    # 50 groups × 5 = 250 rules, many identical
    'var_200'       => generate_var_css(200),
);

# ── Print header ──────────────────────────────────────────────

print "=" x 70, "\n";
print "Litavis vs Crayon Benchmark\n";
print "=" x 70, "\n\n";

if ($have_crayon) {
    print "Crayon: available (version $Crayon::VERSION)\n";
} else {
    print "Crayon: NOT INSTALLED (Litavis-only benchmarks)\n";
}
print "Litavis:   version $Litavis::VERSION\n\n";

# ── Run benchmarks ────────────────────────────────────────────

for my $name (sort keys %inputs) {
    my $css = $inputs{$name};
    my $size = length($css);
    my $rule_count = () = $css =~ /\{/g;

    print "-" x 70, "\n";
    printf "%-20s  %d rules, %d bytes\n", $name, $rule_count, $size;
    print "-" x 70, "\n";

    my %bench;

    # Litavis parse + compile
    $bench{litavis} = sub {
        my $d = Litavis->new;
        $d->parse($css);
        my $out = $d->compile();
    };

    # Crayon parse + compile (if available)
    if ($have_crayon) {
        $bench{crayon} = sub {
            my $c = Crayon->new;
            my ($struct) = $c->parse($css);
            my $out = $c->compile($struct);
        };
    }

    cmpthese(-2, \%bench);
    print "\n";
}

# ── Litavis-only: parse vs compile breakdown ─────────────────────

print "=" x 70, "\n";
print "Litavis Breakdown: parse vs compile (medium_500)\n";
print "=" x 70, "\n\n";

{
    my $css = $inputs{medium_500};

    # Pre-parsed for compile-only benchmark
    my $pre = Litavis->new;
    $pre->parse($css);

    cmpthese(-2, {
        'parse_only' => sub {
            my $d = Litavis->new;
            $d->parse($css);
        },
        'compile_only' => sub {
            # compile is non-destructive, so we can reuse
            $pre->compile();
        },
        'parse+compile' => sub {
            my $d = Litavis->new;
            $d->parse($css);
            $d->compile();
        },
    });
}

print "\nDone.\n";
