#!/usr/bin/env perl
#
# Benchmarks for File::Raw::Gzip across the four plugin phases:
#
#   READ   - decompress whole-file slurp
#   WRITE  - compress whole-file spew
#   STREAM - line-by-line through each_line()
#   CHAIN  - .csv.gz -> AoA via plugin => ['gzip','csv']
#
# Compares against IO::Compress::Gzip / IO::Uncompress::Gunzip and
# (for chain) Text::CSV_XS with manual gunzip. Run with the local
# blib/ on @INC so an installed copy doesn't shadow the working tree:
#
#   make && perl -Mblib bench/gzip.pl
use strict;
use warnings;
use Benchmark qw(cmpthese);
use File::Temp qw(tempdir);
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use File::Raw qw(import);
use File::Raw::Gzip;

use IO::Compress::Gzip       qw(gzip);
use IO::Uncompress::Gunzip   qw(gunzip $GunzipError);

my $iters = $ENV{BENCH_ITERS} || -2;   # negative => run for that many CPU seconds
my $tmpdir = tempdir(CLEANUP => 1);

# Build payloads. Small / medium / large in plaintext bytes. Real-ish
# entropy via a repeating-but-jittery byte pattern so deflate has work
# to do but the ratio doesn't collapse to 0.
sub make_payload {
    my ($bytes) = @_;
    my $line   = join('', map { chr(0x30 + ($_ % 64)) } 0 .. 199) . "\n";
    my $chunks = int($bytes / length($line)) + 1;
    return substr(($line x $chunks), 0, $bytes);
}

my %sizes = (
    small  => 1_024,
    medium => 100 * 1024,
    large  => 5 * 1024 * 1024,
);

my %paths;          # plain.txt, plain.gz per size
for my $name (sort keys %sizes) {
    my $payload = make_payload($sizes{$name});
    my $plain = "$tmpdir/$name.txt";
    my $gz    = "$tmpdir/$name.gz";
    File::Raw::spew($plain, $payload);
    gzip(\$payload, $gz) or die "gzip failed: $!";
    $paths{$name} = { plain => $plain, gz => $gz, size => length $payload };
}

sub banner {
    my ($title) = @_;
    print "\n=== $title ===\n";
}

# ---------------------------------------------------------------
# READ - decompress an entire .gz to a scalar
# ---------------------------------------------------------------
banner("READ: decompress whole file -> scalar");
for my $name (qw(small medium large)) {
    my $gz   = $paths{$name}{gz};
    my $size = $paths{$name}{size};
    print "\n--- $name (plaintext $size B) ---\n";
    cmpthese($iters, {
        'File::Raw::Gzip slurp' => sub {
            my $bytes = file_slurp($gz, plugin => 'gzip');
        },
        'IO::Uncompress::Gunzip slurp' => sub {
            my $bytes;
            gunzip($gz => \$bytes) or die "gunzip: $GunzipError";
        },
        'IO::Uncompress::Gunzip read-loop' => sub {
            my $z = IO::Uncompress::Gunzip->new($gz)
                or die "open: $GunzipError";
            my $bytes = '';
            my $buf;
            while ($z->read($buf, 65536)) { $bytes .= $buf }
            $z->close;
        },
    });
}

# ---------------------------------------------------------------
# WRITE - compress a payload and write it to disk
# ---------------------------------------------------------------
banner("WRITE: scalar -> .gz on disk");
for my $name (qw(small medium large)) {
    my $payload = File::Raw::slurp($paths{$name}{plain});
    my $size    = length $payload;
    my $out_a   = "$tmpdir/$name.out_a.gz";
    my $out_b   = "$tmpdir/$name.out_b.gz";
    print "\n--- $name (plaintext $size B) ---\n";
    cmpthese($iters, {
        'File::Raw::Gzip spew' => sub {
            file_spew($out_a, $payload, plugin => 'gzip');
        },
        'IO::Compress::Gzip' => sub {
            gzip(\$payload => $out_b) or die "gzip: $!";
        },
    });
}

# ---------------------------------------------------------------
# STREAM - line-by-line iteration over a .gz
# ---------------------------------------------------------------
banner("STREAM: line-by-line over .gz");
for my $name (qw(small medium large)) {
    my $gz   = $paths{$name}{gz};
    my $size = $paths{$name}{size};
    print "\n--- $name (plaintext $size B) ---\n";
    cmpthese($iters, {
        'each_line plugin=gzip' => sub {
            my $n = 0;
            File::Raw::each_line($gz, sub { $n++ }, plugin => 'gzip');
        },
        'IO::Uncompress::Gunzip getline' => sub {
            my $z = IO::Uncompress::Gunzip->new($gz)
                or die "open: $GunzipError";
            my $n = 0;
            while (defined(my $line = $z->getline)) { $n++ }
            $z->close;
        },
        'gunzip slurp + split /\n/' => sub {
            my $bytes;
            gunzip($gz => \$bytes) or die "gunzip: $GunzipError";
            my @lines = split /\n/, $bytes, -1;
            my $n = scalar @lines;
        },
    });
}

# ---------------------------------------------------------------
# CHAIN - .csv.gz -> AoA in one call
#
# Off by default. Loading File::Raw::Separated against a -Mblib copy
# of File::Raw::Gzip can crash the process if the installed File::Raw
# doesn't match the version Separated was built against - bus error,
# not catchable. Opt in with BENCH_CHAIN=1 once you've verified all
# three dists are built against the same File::Raw (e.g. inside the
# docker harness, or a fresh local install of all three).
# ---------------------------------------------------------------
banner("CHAIN: .csv.gz -> AoA");
my $have_separated = eval { require File::Raw::Separated; 1 };
my $have_csv_xs    = eval { require Text::CSV_XS;          1 };

if (!$ENV{BENCH_CHAIN}) {
    print "\n[skip] CHAIN bench is opt-in. Re-run with BENCH_CHAIN=1 once\n";
    print "       File::Raw + File::Raw::Separated + File::Raw::Gzip are\n";
    print "       all built against the same File::Raw.\n";
} elsif (!$have_separated) {
    print "\n[skip] File::Raw::Separated not installed; chain bench skipped.\n";
} else {
    for my $name (qw(small medium large)) {
        # Synthesise a CSV.gz of similar plaintext size.
        my $rows_n = $name eq 'small'  ?    50
                   : $name eq 'medium' ?  5_000
                   :                     50_000;
        my @rows = map { [ "id$_", "name$_", "value-$_-payload-XYZ", $_ * 7 ] }
                   1 .. $rows_n;
        my $csv = join('', map { join(',', @$_) . "\n" } @rows);
        my $gz  = "$tmpdir/$name.csv.gz";
        gzip(\$csv, $gz) or die "gzip: $!";
        my $csz = -s $gz;

        print "\n--- $name (csv $rows_n rows, gz $csz B) ---\n";

        my %tests = (
            'plugin=[gzip,csv]' => sub {
                my $rs = file_slurp($gz, plugin => ['gzip', 'csv']);
            },
            'gunzip + plugin=csv' => sub {
                my $bytes;
                gunzip($gz => \$bytes) or die "gunzip: $GunzipError";
                my $tmp = "$tmpdir/$name.unwrapped.csv";
                File::Raw::spew($tmp, $bytes);
                my $rs = file_slurp($tmp, plugin => 'csv');
            },
        );
        if ($have_csv_xs) {
            $tests{'gunzip + Text::CSV_XS'} = sub {
                my $z = IO::Uncompress::Gunzip->new($gz)
                    or die "open: $GunzipError";
                my $csv_x = Text::CSV_XS->new({ binary => 1, auto_diag => 1 });
                my @out;
                while (my $row = $csv_x->getline($z)) { push @out, $row }
                $z->close;
            };
        }
        cmpthese($iters, \%tests);
    }
}

print "\nDone. tempdir was $tmpdir (cleaned up).\n";
