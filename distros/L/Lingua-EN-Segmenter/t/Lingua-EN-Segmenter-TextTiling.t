#!/usr/bin/perl -w

use strict;
use Config;

use Test::More tests=>12;
use_ok ('Lingua::EN::Segmenter::TextTiling');
use_ok ('Lingua::EN::Segmenter::Evaluator',qw(evaluate_segmenter));
use_ok ('Lingua::EN::Splitter',qw(paragraph_breaks));
use lib '.';

my $segment1 = 
q(Lingua::EN::Segmenter is a useful module that allows text to be split up 
into words, paragraphs, segments, and tiles.

Paragraphs are by default indicated by blank lines. Known segment breaks are
indicated by a line with only the word "segment_break" in it.

The module detects paragraphs that are unrelated to each other by comparing 
the number of words per-paragraph that are related. The algorithm is designed
to work only on long segments.);

my $segment2 =
q(SOUTH OF BAGHDAD, Iraq (CNN) -- Seven U.S. troops freed Sunday after being 
held by Iraqi forces arrived by helicopter at a base south of Baghdad and were 
transferred to a C-130 transport plane headed for Kuwait, CNN's Bob Franken 
reported from the scene.);

my $text = "$segment1\n\nsegment_break\n\n$segment2";
  
my $num_segment_breaks = 1;
my $tiler = new Lingua::EN::Segmenter::TextTiling();
my @segments = $tiler->segments($num_segment_breaks,$text);
is($segments[0],$segment1);
is($segments[1],$segment2);

my %label = map { $_->{para}=>$_ } evaluate_segmenter($tiler,$text);
my $num_paragraphs = @{paragraph_breaks($text)};
my $output = "";
foreach my $i (0..$num_paragraphs-1) {
    my @label = map { $label{$i}{$_} || 0 }
        qw(para true label strict relaxed very_relaxed);
 
    $output .= sprintf "%4d  %4d  %5s  %3d  %3.1f  %4d\n", @label;
}
is($output,
"   0     0      0    0  0.0     0
   1     0      0    0  0.0     0
   2     1      L    1  1.0     1
");

my $OS = $Config::Config{'osname'};

my $dir;

if (-e "eg/segmenter.pl") {
    $dir = ".";
} elsif (-e "../eg/segmenter.pl") {
    $dir = "..";
} else {
    die "Could not find eg/segmenter.pl!";
}

my $segment_evaluator = "$dir/eg/segmenter.pl";
my $segments = join " ", map { "$dir/eg/Segment/$_" } 
    qw(S01 S02 S03 S04 S05 S06 S07 S08 S09 S10);

my $evaluation = `$Config{perlpath} -Mlib=lib -Mlib=../lib -Mlib=t/lib $segment_evaluator -v $segments`;
$evaluation =~ s/Average recall = +([\d\.]+)%, average precision = +([\d\.]+)%//;
my $recall = $1;
my $precision = $2;
ok($recall>62, "Strict recall on large database is greater than 62% (actual: $recall)");
ok($precision>62, "Strict precision on large database is greater than 62% (actual: $precision)");
$evaluation =~ s/Average recall = +([\d\.]+)%, average precision = +([\d\.]+)%//;
$recall = $1;
$precision = $2;
ok($recall>74, "Relaxed recall on large database is greater than 74% (actual: $recall)");
ok($precision>74, "Relaxed precision on large database is greater than 74% (actual: $precision)");
$evaluation =~ s/Average recall = +([\d\.]+)%, average precision = +([\d\.]+)%//;
$recall = $1;
$precision = $2;
ok($recall>89, "Very Relaxed recall on large database is greater than 89% (actual: $recall)");
ok($precision>89, "Very Relaxed precision on large database is greater than 89% (actual: $precision)");
