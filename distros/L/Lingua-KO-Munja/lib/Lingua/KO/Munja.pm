package Lingua::KO::Munja;
use warnings;
use strict;
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw/roman2hangul hangul2roman/;
our %EXPORT_TAGS = (
    all => \@EXPORT_OK,
);
our $VERSION = '0.08';
use Convert::Moji 'make_regex';

my $verbose;

sub makearegex
{
    my @possibles = @_;
    @possibles = map {$_ =~ s/^-$//; $_} @possibles;
    make_regex (@possibles);
}

my @initial = qw(
    g   kk  n   d   tt  r   m   b   pp  s   ss  -   j   jj
    ch  k   t   p   h
);

my $initial_re = makearegex (@initial);

my %initial = a2h (@initial);

my @peak = qw(
    a   ae  ya  yae eo  e   yeo ye  o   wa  wae oe  yo  u
    wo  we  wi  yu  eu  ui  i
);

my $peak_re = makearegex (@peak);

my %peak = a2h (@peak);

my @final = qw(
    -   g   kk  ks  n   nj  nh  d   l   lg  lm  lb  ls  lt
    lp  lh  m   b   ps  s   ss  ng  j   c   k   t   p   h
);

my $final_re = makearegex (@final);

my %final = a2h (@final);

sub hangul
{
    my ($initial, $peak, $final) = @_;
    for ($initial, $peak, $final) {
        if (! $_) {
            $_ = '-';
        }
    }
    if ($verbose) {
	print "Initial = $initial, peak = $peak, final = $final\n";
	print "Initial = $initial{$initial}, peak = $peak{$peak}, final = $final{$final}\n";
    }
    my $x = (($initial{$initial} * 21) + $peak{$peak}) * 28 + $final{$final};
    my $hangul = chr (0xAC00 + $x);
    return $hangul;
}

sub roman2hangul
{
    my ($input) = @_;
    my $match = "$initial_re$peak_re$final_re";
    $match =~ s/\\-//g;
    while ($input =~ s/((?:$match)+)/ROMAN/) {
        my $i = $1;
        if ($verbose) {
            print "Looking at '$i' from '$input'.\n";
        }
        my @syllables;
        while ($i =~ s/($match)$//g) {
            if ($verbose) {
                print "pushing $1\n";
            }
            unshift @syllables, $1;
        }
        my @hangul;
        for my $s (@syllables) {
            my $h = $s;
            $h =~ s/^$match$/hangul ($1, $2, $3)/ge;
            push @hangul, $h;
        }
        my $output = join '', @hangul;
        $input =~ s/ROMAN/$output/;
    }
    return $input;
}

# Given an array, make a hash with the elements as keys and a unique
# number as values.

sub a2h
{
    my @array = @_;
    my %hash;
    my $count = 0;
    for my $k (@array) {
        $hash{$k} = $count;
        $count++;
    }
    return %hash;
}

sub romanize
{
    my ($char) = @_;
    my $han = ord ($char) - 0xAC00;
    my $init = int ($han / (21 * 28));
    my $peak = int ($han / 28) % 21;
    my $final = $han % 28;
    my $roman = join '', $initial[$init], $peak[$peak], $final[$final];
    return $roman;
}

sub hangul2roman
{
    my ($hangul) = @_;
    $hangul =~ s/(\p{Hangul})/romanize ($1)/ge;
    $hangul =~ s/-//g;
    return $hangul;
}

1;

