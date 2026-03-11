#!/usr/bin/perl
use 5.016;
use strict;
use warnings;

use Getopt::Long;

binmode *STDOUT, ':utf8';
binmode *STDERR, ':utf8';

my $USAGE = <<"HERE";
Usage: $0 [-n num] [-p] <CN | KR | JP> [file] ...
HERE

my %lang_props = (
    'cn' => [ 'Han' ],
    'kr' => [ 'Hangul' ],
    'jp' => [ 'Hiragana', 'Katakana', 'CJK' ],
);

my %lang_vars = map { $_ => uc($_) . "_CHARS" } qw(cn kr jp);

sub unicode_histogram {

    my ($file, @props) = @_;

    if (!@props) {
        die '@props not provided';
    }

    my @classes;
    for my $p (@props) {
        if ($p !~ /^[\w\s]+$/) {
            die "Invalid property name '$p'";
        }
        push @classes, "\\p{$p}";
    }

    my $rx = do {
        my $s = '(' . join('|', @classes) . ')';
        qr/$s/;
    };

    my $fh = do {
        if ($file eq '-') {
            binmode *STDIN, ':encoding(UTF-8)';
            *STDIN;
        } else {
            open my $fh, '<', $file or die "Failed to open $file: $!";
            binmode $fh, ':encoding(UTF-8)';
            $fh;
        }
    };

    my %histogram;
    while (my $l = readline $fh) {
        for my $m ($l =~ /$rx/g) {
            $histogram{ $m }++;
        }
    }

    if ($fh ne *STDIN) {
        close $fh;
    }

    return \%histogram;

}

sub print_histogram {

    my ($hist, $num) = @_;

    my @pairs = sort { $b->[1] <=> $a->[1] }
                map { [ $_, $hist->{ $_ } ] }
                keys %$hist;

    if (@pairs > $num) {
        @pairs = @pairs[0 .. $num-1];
    }

    for my $p (@pairs) {
        say "$p->[0] : $p->[1]";
    }

}

sub print_perl {

    my ($hist, $name, $num) = @_;

    my @pairs = sort { $b->[1] <=> $a->[1] }
                map { [ $_, $hist->{ $_ } ] }
                keys %$hist;

    if (@pairs > $num) {
        @pairs = @pairs[0 .. $num-1];
    }

    if ($name !~ /^\w+$/) {
        die "'$name' is not a valid Perl name";
    }

    say "my \@$name = (";
    my $l = '';
    for my $p (@pairs) {
        my $c = qq{'$p->[0]',};
        if (length($c) + length($l) > 80) {
            say $l;
            $l = '';
        }
        $l .= $c;
    }
    if ($l ne '') {
        say $l;
    }

    say ");";

}

my $num = 512;
my $output_perl = 0;

GetOptions(
    'n=i' => \$num,
    'p'   => \$output_perl,
    'h'   => sub { print $USAGE; exit 0 },
) or die $USAGE;

my $lang = shift @ARGV;
if (not defined $lang) {
    die $USAGE;
}
$lang = lc $lang;
if (not exists $lang_props{ $lang }) {
    die "Invalid language\n";
}

my @files = @ARGV;
if (!@files) {
    @files = ('-');
}

my %hist;
for my $f (@files) {
    my $h = unicode_histogram($f, @{ $lang_props{ $lang } });
    for my $k (keys %$h) {
        $hist{ $k } += $h->{ $k };
    }
}

if ($output_perl) {
    print_perl(\%hist, $lang_vars{ $lang }, $num);
} else {
    print_histogram(\%hist, $num);
}
