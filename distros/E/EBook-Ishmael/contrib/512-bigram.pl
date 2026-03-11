#!/usr/bin/perl
use 5.016;
use strict;
use warnings;
use utf8;

use Encode qw(encode);
use Getopt::Long;
use List::Util qw(sum);
use POSIX qw(round);

binmode *STDOUT, ':utf8';
binmode *STDERR, ':utf8';

my %recognized_encodings = map { $_ => 1 } qw(
    iso8859-5 cp1252    latin1    cp1250
    cp1251    cp1253    cp1254    cp1255
    cp1256
);

my %encoding_bigram_names = map { $_ => uc(s/\W//gr) . '_FREQS' }
                            keys %recognized_encodings;

my %ignore_ascii = (
    'iso8859-5' => 1, # Cyrillic
    'cp1252'    => 0, # Western European Latin
    'cp1250'    => 0, # Centra/Eastern European Latin
    'cp1251'    => 1, # Cyrillic
    'cp1253'    => 1, # Greek
    'cp1254'    => 0, # Turkish
    'cp1255'    => 1, # Hebrew
    'cp1256'    => 1, # Arabic
);

my $USAGE = <<"HERE";
Usage: $0 [-R] [-p] [-n num] <encoding> [file] ...
HERE

sub build_bigram {

    my ($file, $encoding) = @_;
    $encoding = lc $encoding;
    if (not exists $recognized_encodings{ $encoding }) {
        die "invalid encoding '$encoding'";
    }

    my $ignore_ascii = $ignore_ascii{ $encoding };

    my $fh = do {
        if ($file eq '-') {
            binmode *STDIN, ":encoding($encoding)";
            *STDIN;
        } else {
            open my $fh, '<', $file or die "Failed to open $file: $!";
            binmode $fh, ":encoding($encoding)";
            $fh;
        }
    };

    my %bigram;
    my $prev;
    while (my $l = readline $fh) {
        chomp $l;
        if ($ignore_ascii) {
            $l =~ s/[a-z][A-Z]//g;
        }
        for my $i (0 .. length($l)-1) {
            my $c = substr $l, $i, 1;
            if ($c =~ /^\s$/) {
                undef $prev;
            } else {
                if (defined $prev) {
                    $bigram{ $prev . $c }++;
                }
                $prev = $c;
            }
        }
        undef $prev;
    }

    if ($fh ne *STDIN) {
        close $fh;
    }

    return \%bigram;

}

sub bigram_percentage {

    my ($bigram, $top) = @_;

    if (!%$bigram) {
        return 1.0;
    }

    my $total = sum values %$bigram;
    my @pairs = sort { $b->[1] <=> $a->[1] }
                map { [ $_, $bigram->{ $_ } ] }
                keys %$bigram;

    if ($top > @pairs) {
        return 1.0;
    }

    my $top_sum = 0;
    for my $p (@pairs[0 .. $top-1]) {
        $top_sum += $p->[1];
    }

    return $top_sum / $total;

}

sub print_histogram {

    my ($bigram, $num) = @_;

    my @pairs = sort { $b->[1] <=> $a->[1] }
                map { [ $_, $bigram->{ $_ } ] }
                keys %$bigram;

    if (@pairs > $num) {
        @pairs = @pairs[0 .. $num-1];
    }

    for my $p (@pairs) {
        say "$p->[0] : $p->[1]";
    }

}

sub print_perl {

    my ($bigram, $name, $encoding, $num) = @_;
    if ($name !~ /^\w+$/) {
        die "'$name' is not a valid name";
    }
    if (not exists $recognized_encodings{ $encoding }) {
        die "'$encoding' is not a valid encoding";
    }

    my @pairs = sort { $b->[1] <=> $a->[1] }
                map { [ $_, $bigram->{ $_ } ] }
                keys %$bigram;

    if (@pairs > $num) {
        @pairs = @pairs[0 .. $num-1];
    }

    say "my %$name = map { \$_ => 1 } (";
    my $l = '';
    for my $p (@pairs) {
        my $decoded = encode($encoding, $p->[0], Encode::FB_CROAK);
        my $b1 = ord(substr $decoded, 0, 1);
        my $b2 = ord(substr $decoded, 1, 1);
        my $s = sprintf q{"\x%02x\x%02x",}, $b1, $b2;
        if (length($l) + length($s) > 80) {
            say $l;
            $l = '';
        }
        $l .= $s;
    }
    if ($l ne '') {
        say $l;
    }
    say ");";

}

my $num = 512;
my $output_perl = 0;
my $get_percentage = 0;

GetOptions(
    'R'   => \$get_percentage,
    'p'   => \$output_perl,
    'n=i' => \$num,
    'h'   => sub { print $USAGE; exit 0 },
) or die $USAGE;

my $encoding = shift @ARGV;
if (not defined $encoding) {
    die $USAGE;
}
$encoding = lc $encoding;
if (not exists $recognized_encodings{ $encoding }) {
    die "Invalid encoding\n";
}

my @files = @ARGV;
if (!@files) {
    @files = ('-');
}

my %bigram;
for my $f (@files) {
    my $h = build_bigram($f, $encoding);
    for my $k (keys %$h) {
        $bigram{ $k } += $h->{ $k };
    }
}

if ($get_percentage) {
    my $p = bigram_percentage(\%bigram, $num);
    $p = round($p * 100);
    say $p;
} elsif ($output_perl) {
    print_perl(\%bigram, $encoding_bigram_names{ $encoding },
               $encoding, $num);
} else {
    print_histogram(\%bigram, $num);
}
