package Lingua::EN::Segmenter::TextTiling;

=head1 NAME

Lingua::EN::Segmenter::TextTiling - Segment text using the TextTiling method

=head1 SYNOPSIS

  use Lingua::EN::Segmenter::TextTiling qw(segments);
  use lib '.';
  
  my $text = <<EOT;
  Lingua::EN::Segmenter is a useful module that allows text to be split up 
  into words, paragraphs, segments, and tiles.
  
  Paragraphs are by default indicated by blank lines. Known segment breaks are
  indicated by a line with only the word "segment_break" in it.
  
  The module detects paragraphs that are unrelated to each other by comparing 
  the number of words per-paragraph that are related. The algorithm is designed
  to work only on long segments. 
  
  SOUTH OF BAGHDAD, Iraq (CNN) -- Seven U.S. troops freed Sunday after being 
  held by Iraqi forces arrived by helicopter at a base south of Baghdad and were 
  transferred to a C-130 transport plane headed for Kuwait, CNN's Bob Franken 
  reported from the scene. 
  
  EOT
    
  my $num_segment_breaks = 1;
  my @segments = segments($num_segment_breaks,$text);
  print $segments[0]; # Prints the first three paragraphs of the above text
  print "\n----------SEGMENT_BREAK----------\n";
  print $segments[1]; # Prints the last paragraph of the above text
  
  # This module can also be used in an object-oriented fashion
  my $splitter = new Lingua::EN::Splitter;
  @words = $splitter->words($text);

=head1 DESCRIPTION

See synopsis.

=head1 EXTENDING

This module is designed to be easily extendable. Feel free to extend from this
module when designing alternate methods for text segmentation.

=head1 AUTHORS

David James <splice@cpan.org>

=head1 SEE ALSO

L<Lingua::EN::Segmenter::Baseline>, L<Lingua::EN::Segmenter::Evaluator>,
L<http://www.cs.toronto.edu/~james>

=head1 LICENSE

  Copyright (c) 2002 David James
  All rights reserved.
  This program is free software; you can redistribute it and/or
  modify it under the same terms as Perl itself.

=cut

$VERSION = 0.10;
@EXPORT_OK = qw(
    segment
    segments
    set_tiles_per_block
    set_number_of_smoothing_rounds
    set_tokens_per_tile
    set_paragraph_regexp
    set_non_word_regexp
    set_locale
    set_stop_words
);

use Math::Vector::SortIndexes qw(sort_indexes_descending);
use Math::VecStat qw(average min sum);
use Math::HashSum qw(hashsum);

use base 'Lingua::EN::Segmenter';
use strict;


# Create a new instance of the object
sub new {
    my $class = shift;
    $class->SUPER::new(
        TILES_PER_BLOCK=>7,
        NUMBER_OF_SMOOTHING_ROUNDS=>2,
        @_
    );
}

# Segment a piece of text 
sub segment {
    my ($self, $num_segments, $input) = @_;

    # Get smoothed depth scores
    my $scores = $self->smoothed_depth_scores($input);

    # Get paragraph breaks
    my $breaks = $self->{splitter}->paragraph_breaks($input);
    
    # Get predicted segment breaks 
    return $self->tile2segment($num_segments, $breaks, $scores);
}

sub set_tiles_per_block {
    my $self = shift;
    $self->{TILES_PER_BLOCK} = shift;
}

sub set_number_of_smoothing_rounds {
    my $self = shift;
    $self->{NUMBER_OF_SMOOTHING_ROUNDS} = shift;    
}


######################################################################
# PRIVATE METHODS
######################################################################

# Accept as input the scores of the tiles. Output segment scores.
sub tile2segment {
    my ($self, $num_segments, $breaks, $scores) = @_;    

    my @indexes = sort_indexes_descending @$scores;

    my @too_close = (
        -$self->{MIN_SEGMENT_SIZE}..-1, 1..$self->{MIN_SEGMENT_SIZE}
    );
    my @direction = qw(L R);
    my (%segments, %verbose, $cut_off_depth);
        
    # Calculate the most likely segment breaks
    GAP: foreach my $i (@indexes) {
        my $tile_no = $i + $self->{TILES_PER_BLOCK};
        my $closest_break = (min( map { abs($_ - $tile_no) } @$breaks ))[1];
        $segments{$closest_break+$_} and next GAP for (@too_close);
        $segments{$closest_break} .= 
            $direction[$breaks->[$closest_break] > $tile_no];
        $verbose{$tile_no} = [ $tile_no, $scores->[$i], $closest_break ];
        $cut_off_depth = $scores->[$i];
        last if keys %segments == $num_segments;
    }
    
    # Verbose output
    if ($self->{VERBOSE}) {
        printf "Cut-off depth = %6.4f\n\n", $cut_off_depth;
        print " Gap  Depth  Para\n"; 
        foreach (sort { $a <=> $b } keys %verbose) {
            printf "%4d %6.3f  %4d\n", @{$verbose{$_}}
        }
        print "\n";
    }    
    return \%segments;
}

# Calculate depth scores based on a list of gap scores
sub depth {
    no warnings;
    
    my $self = shift;
    my @score = @{$_[0]};
    my @depth;
    for my $i (1..$#score) {
        $depth[$i] = $score[$i-1] + $score[$i+1] - 2*$score[$i];
    }
    $depth[0] = $score[1] - $score[0];
    $depth[$#score] = $score[-2] - $score[-1];
    return \@depth;
}

# Given some depth scores, smooth them.
sub smooth {
    my $self = shift;
    my @depth = @{$_[0]};
    unshift @depth, $depth[0];
    push @depth, $depth[-1];
    for (1..$self->{NUMBER_OF_SMOOTHING_ROUNDS}) {
        foreach my $j (1..$#depth-1) {
            $depth[$j] = average $depth[$j-1], $depth[$j], $depth[$j+1];
        }
    }
    return [ @depth[1..$#depth-1] ];
}

# Take text as input and output a list of smoothed depth scores
sub smoothed_depth_scores {
    my ($self, $input) = @_;
    my $words = $self->{splitter}->words($input);
    my $tiles = $self->{splitter}->tile($words);
    my $depth_scores = $self->depth($self->gap_scores($tiles));
    return $self->smooth($depth_scores);
}

# Scores for the gap between two tiles
sub gap_scores {
    my $self = shift;
    my @tiles = @{$_[0]};
    my $TILES_PER_BLOCK = $self->{TILES_PER_BLOCK};
    my (@score, $i);
    for $i ($TILES_PER_BLOCK .. @tiles-$TILES_PER_BLOCK) {
        my $L = $i-$TILES_PER_BLOCK;
        my $R = $i+$TILES_PER_BLOCK-1;
        my %l = hashsum map { %$_ } @tiles[$L..$i-1];
        my %r = hashsum map { %$_ } @tiles[$i..$R];
        my %all = map { %$_ } @tiles[$L..$R];
        my $numerator = sum map { $l{$_}*$r{$_} } keys %all;
        my $denom1 = sum map { $l{$_}*$l{$_} } keys %all;
        my $denom2 = sum map { $r{$_}*$r{$_} } keys %all;
        push @score, $numerator/sqrt($denom1*$denom2);
    }
    return \@score;
}


1;





