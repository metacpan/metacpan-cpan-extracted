#!/usr/bin/env perl

# First of all, initialize the TextTiling module:
use Lingua::EN::Splitter qw(paragraph_breaks);
use Lingua::EN::Segmenter::TextTiling;
use Lingua::EN::Segmenter::Evaluator  qw(evaluate_segmenter calc_stats);
use File::Slurp qw(read_file);
my $tiler = Lingua::EN::Segmenter::TextTiling->new();

# Q1. num. of tokens per sequence
$tiler->set_tokens_per_tile(20);

# Q2. num. of token_sequence per block.
$tiler->set_tiles_per_block(7);

# Q3. average smoothing
$tiler->set_number_of_smoothing_rounds(2);

# Q4.  In Hearst paper, there must be at least 3
#      intervening blocks between boundaries. 
#      Do you have the same setting? Can I change that?
# 
$tiler->set_min_segment_size(2);

# Q5. can I set the number of boundaries?
my $num_segments = 2;

# Sample text file with two segment breaks. Only one of the segment breaks
# is marked with 'segment_break', but TextTiling identifies both breaks
# anyway.
my $text = <<EOT;
SOUTH OF BAGHDAD, Iraq (CNN) -- Seven U.S. troops freed Sunday after being 
held by Iraqi forces arrived by helicopter at a base south of Baghdad and were 
transferred to a C-130 transport plane headed for Kuwait, CNN's Bob Franken 

SOUTH OF BAGHDAD, Iraq (CNN) -- Seven U.S. troops freed Sunday after being 
held by Iraqi forces arrived by helicopter at a base south of Baghdad and were 
transferred to a C-130 transport plane headed for Kuwait, CNN's Bob Franken 

SOUTH OF BAGHDAD, Iraq (CNN) -- Seven U.S. troops freed Sunday after being 
held by Iraqi forces arrived by helicopter at a base south of Baghdad and were 
transferred to a C-130 transport plane headed for Kuwait, CNN's Bob Franken 

Lingua::EN::Splitter is a useful module that allows text to be split up 
into words, paragraphs, segments, and tiles.

Paragraphs are by default indicated by blank lines. Known segment breaks are

Paragraphs are by default indicated by blank lines. Known segment breaks are
Paragraphs are by default indicated by blank lines. Known segment breaks are
Paragraphs are by default indicated by blank lines. Known segment breaks are
Paragraphs are by default indicated by blank lines. Known segment breaks are

Paragraphs are by default indicated by blank lines. Known segment breaks are
Paragraphs are by default indicated by blank lines. Known segment breaks are
Paragraphs are by default indicated by blank lines. Known segment breaks are
Paragraphs are by default indicated by blank lines. Known segment breaks are
Paragraphs are by default indicated by blank lines. Known segment breaks are

This module does not make any attempt to guess segment boundaries. For that,
see L<Lingua::EN::Segmenter::TextTiling>. This module does not make any attempt to guess segment boundaries. For that, see L<Lingua::EN::Segmenter::TextTiling>.
This module does not make any attempt to guess segment boundaries. For that, see L<Lingua::EN::Segmenter::TextTiling>.

segment_break

SOUTH OF BAGHDAD, Iraq (CNN) -- Seven U.S. troops freed Sunday after being 
held by Iraqi forces arrived by helicopter at a base south of Baghdad and were 
transferred to a C-130 transport plane headed for Kuwait, CNN's Bob Franken 
reported from the scene. 
SOUTH OF BAGHDAD, Iraq (CNN) -- Seven U.S. troops freed Sunday after being 
held by Iraqi forces arrived by helicopter at a base south of Baghdad and were 
transferred to a C-130 transport plane headed for Kuwait, CNN's Bob Franken 
reported from the scene. 

SOUTH OF BAGHDAD, Iraq (CNN) -- Seven U.S. troops freed Sunday after being 
held by Iraqi forces arrived by helicopter at a base south of Baghdad and were 
transferred to a C-130 transport plane headed for Kuwait, CNN's Bob Franken 
reported from the scene. 
EOT

# Show our scoring breakdown
my %label = map { $_->{para}=>$_ } evaluate_segmenter($tiler,$text,$num_segments);
my $num_paragraphs = @{paragraph_breaks($text)};
print "Para  True  Label  Str  Rel  VRel\n";
foreach my $i (0..$num_paragraphs-1) {
   my @label = map { $label{$i}{$_} || 0 }
      qw(para true label strict relaxed very_relaxed);
   
   printf "%4d  %4d  %5s  %3d  %3.1f  %4d\n",
      @label;
   
}
print "\n";

# Output scores
printf "Results from TextTiling algorithm:
      Strict scoring:       %2d%% recall, %2d%% precision
      Relaxed scoring:      %2d%% recall, %2d%% precision
      V. relaxed scoring:   %2d%% recall, %2d%% precision

", calc_stats(evaluate_segmenter($tiler,$text,$num_segments));
