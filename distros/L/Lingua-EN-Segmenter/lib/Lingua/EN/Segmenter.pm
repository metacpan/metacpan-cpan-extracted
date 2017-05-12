package Lingua::EN::Segmenter;

=head1 NAME
    
Lingua::EN::Segmenter - Subdivide texts into passages that represent subtopics

=head1 SYNOPSIS
    
Don't directly use this module. Use L<Lingua::EN::Segmenter::TextTiling> instead.
        
=head1 DESCRIPTION
    
See synopsis.

=head1 EXTENDING

L<Lingua::EN::Segmenter::TextTiling> inherits from this module. If you want to
segment text using a method other than text tiling, create a different module
under Lingua::EN::Segmenter::* and inherit from this module.

=head1 AUTHORS
    
David James <splice@cpan.org>
    
=head1 SEE ALSO
    
L<Lingua::EN::Segmenter::TextTiling>,  L<Lingua::EN::Segmenter::Baseline>, 
L<Lingua::EN::Segmenter::Evaluator>, L<http://www.cs.toronto.edu/~james>

=head1 LICENSE

  Copyright (c) 2002 David James
  All rights reserved.
  This program is free software; you can redistribute it and/or
  modify it under the same terms as Perl itself.
  
=cut

$VERSION = 0.10;
@EXPORT_OK = qw(
    set_tokens_per_tile
    set_paragraph_regexp
    set_non_word_regexp
    set_locale
    set_stop_words
    segment
    segments
);

use strict;
use base 'Class::Exporter';
use Lingua::EN::Splitter;
use Carp qw(croak);


# Create a new instance of this object
sub new {
    my $class = shift;
    bless {
        MIN_SEGMENT_SIZE=>2,
        splitter=>Lingua::EN::Splitter->new,
        @_
    }, $class
}

sub segment {
    croak "Use Lingua::EN::Segmenter::TextTiling instead.";
}

sub segments {
    my ($self, $num_segments, $input) = @_;

    my $segment_breaks = $self->segment($num_segments,$input);
    my @segment_breaks = sort { $a <=> $b } keys %{$segment_breaks};
    my @paragraphs = @{$self->{splitter}->paragraphs($input)};
    my @segments;
    my $last_segment = -1;
    foreach (@segment_breaks,$#paragraphs) {
        next if $last_segment == $_;
        push @segments, join "\n\n", @paragraphs[$last_segment+1..$_];
        $last_segment = $_;
    }
    return @segments;
}


#########################################################
# Mutator methods
#########################################################


sub set_min_segment_size {
    my $self = shift;
    $self->{MIN_SEGMENT_SIZE} = shift;
}

sub set_tokens_per_tile {
    my $self = shift;
    $self->{splitter}->set_tokens_per_tile(@_);
}

sub set_paragraph_regexp {
    my $self = shift;
    $self->{splitter}->set_paragraph_regexp(@_);
}

sub set_non_word_regexp {
    my $self = shift;
    $self->{splitter}->set_non_word_regexp(@_);
}

sub set_locale {
    my $self = shift;
    $self->{splitter}->set_locale(@_);
}


1;
