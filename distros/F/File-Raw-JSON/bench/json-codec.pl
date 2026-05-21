#!/usr/bin/env perl
# bench/json-codec.pl -- compare File::Raw::JSON to Cpanel::JSON::XS,
# JSON::XS, JSON, and JSON::PP on decode + encode workloads.
#
# Run from dist root after `perl Makefile.PL && make`:
#
#   perl -Mblib bench/json-codec.pl
#
# Optional env knob:
#   BENCH_ITERS=N         override the default per-fixture iteration counts

use 5.010;
use strict;
use warnings;
use Time::HiRes qw(time);
use File::Raw::JSON qw(file_json_decode file_json_encode);

# ---- discover available codecs --------------------------------------

my @codecs;

if (eval { require File::Raw::JSON; 1 }) {
    push @codecs, {
        label  => 'File::Raw::JSON',
        decode => sub { file_json_decode($_[0]) },
        encode => sub { file_json_encode($_[0]) },
        pretty => sub { file_json_encode($_[0], pretty => 1, sort_keys => 1) },
    };
}

if (eval { require Cpanel::JSON::XS; 1 }) {
    my $compact = Cpanel::JSON::XS->new->utf8;
    my $pretty  = Cpanel::JSON::XS->new->utf8->pretty->canonical;
    push @codecs, {
        label  => 'Cpanel::JSON::XS',
        decode => sub { $compact->decode($_[0]) },
        encode => sub { $compact->encode($_[0]) },
        pretty => sub { $pretty->encode($_[0])  },
    };
}

if (eval { require JSON::XS; 1 }) {
    my $compact = JSON::XS->new->utf8;
    my $pretty  = JSON::XS->new->utf8->pretty->canonical;
    push @codecs, {
        label  => 'JSON::XS',
        decode => sub { $compact->decode($_[0]) },
        encode => sub { $compact->encode($_[0]) },
        pretty => sub { $pretty->encode($_[0])  },
    };
}

if (eval { require JSON; 1 }) {
    # JSON is the meta-distribution; it'll dispatch to whichever
    # backend is available.  Use both the procedural API (decode_json /
    # encode_json) and an OO instance for pretty.
    JSON->import(qw(decode_json encode_json));
    my $pretty = JSON->new->utf8->pretty->canonical;
    push @codecs, {
        label  => 'JSON',
        decode => sub { JSON::decode_json($_[0]) },
        encode => sub { JSON::encode_json($_[0]) },
        pretty => sub { $pretty->encode($_[0])   },
    };
}

if (eval { require JSON::PP; 1 }) {
    my $compact = JSON::PP->new->utf8;
    my $pretty  = JSON::PP->new->utf8->pretty->canonical;
    push @codecs, {
        label  => 'JSON::PP (pure Perl)',
        decode => sub { $compact->decode($_[0]) },
        encode => sub { $compact->encode($_[0]) },
        pretty => sub { $pretty->encode($_[0])  },
    };
}

@codecs or die "no JSON codecs available\n";

# ---- fixtures --------------------------------------------------------

# Small: typical config-file shape.
my $small = {
    name    => "config",
    version => "1.0.4",
    enabled => JSON::PP::true(),
    nested  => { count => 42, ratio => 3.14 },
    tags    => ["alpha", "beta", "gamma"],
};

# Medium: 100 rows of moderately-nested records.  Models a typical
# API response or CSV-as-JSON dataset.
my $medium = {
    rows  => [ map +{
                    id    => $_,
                    name  => "row_$_",
                    tags  => [ "tag1", "tag2", "tag3" ],
                    meta  => { created => "2026-05-08", count => $_ * 2 },
                    flags => [ JSON::PP::true(), JSON::PP::false() ],
                }, 1 .. 100 ],
    total => 100,
};

# Large: 10k records, each ~250 bytes.  Models a real-world JSON file.
my $large = {
    items => [ map +{
                    id     => $_,
                    sku    => sprintf("SKU-%08d", $_),
                    price  => 0.01 * $_,
                    qty    => $_ % 100,
                    name   => "Product number $_",
                    avail  => ($_ % 7 != 0) ? JSON::PP::true()
                                            : JSON::PP::false(),
                    tags   => [ map "tag_$_", 1..5 ],
                }, 1 .. 10_000 ],
};

# Pre-encode each fixture once (using Cpanel::JSON::XS as the canonical
# bytes producer if available, otherwise JSON::PP) so all decoders see
# the same input.
my $canon = (grep { $_->{label} eq 'Cpanel::JSON::XS' } @codecs)[0]
         || (grep { $_->{label} eq 'JSON::XS'         } @codecs)[0]
         || $codecs[0];

my %fixtures = (
    small  => { value => $small,  iters => $ENV{BENCH_ITERS} || 50_000 },
    medium => { value => $medium, iters => $ENV{BENCH_ITERS} ||  2_000 },
    large  => { value => $large,  iters => $ENV{BENCH_ITERS} ||     50 },
);
for my $name (keys %fixtures) {
    my $f = $fixtures{$name};
    $f->{bytes} = $canon->{encode}->($f->{value});
}

# ---- bench runner ----------------------------------------------------

sub bench_phase {
    my ($phase_name, $cb_key, $input_key, %opts) = @_;
    my @sizes = @{ $opts{sizes} || [qw(small medium large)] };

    print "\n=== $phase_name ===\n";

    for my $size (@sizes) {
        my $f     = $fixtures{$size};
        my $iters = $opts{iters} || $f->{iters};
        my $input = $f->{$input_key};

        printf "\n--- %s (%s, %d iters, %d bytes per op) ---\n",
            $phase_name, $size, $iters, length($f->{bytes});

        my %results;
        for my $codec (@codecs) {
            # Warm up.
            $codec->{$cb_key}->($input);
            my $t0 = time;
            $codec->{$cb_key}->($input) for 1..$iters;
            my $dt = time - $t0;
            $results{ $codec->{label} } = $dt;
            printf "  %-22s  %7.3f s   %10.0f ops/s\n",
                $codec->{label}, $dt, $iters / $dt;
        }

        # Show ratios against the fastest.
        my @sorted = sort { $results{$a} <=> $results{$b} } keys %results;
        my $best   = $sorted[0];
        printf "  -> fastest: %s (%.3f s)\n", $best, $results{$best};
        for my $label (@sorted[1..$#sorted]) {
            printf "     %-22s  %.2fx slower than %s\n",
                $label, $results{$label} / $results{$best}, $best;
        }
    }
}

bench_phase('DECODE',         'decode', 'bytes');
bench_phase('ENCODE compact', 'encode', 'value');
bench_phase('ENCODE pretty',  'pretty', 'value');

print "\nDone.\n";
