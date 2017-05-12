package Lingua::EN::Splitter;

=head1 NAME

Lingua::EN::Splitter - Split text into words, paragraphs, segments, and tiles

=head1 SYNOPSIS

  use Lingua::EN::Splitter qw(words paragraphs paragraph_breaks 
                              segment_breaks tiles set_tokens_per_tile);
  
  my $text = <<EOT;
  Lingua::EN::Splitter is a useful module that allows text to be split up 
  into words, paragraphs, segments, and tiles.
  
  Paragraphs are by default indicated by blank lines. Known segment breaks are
  indicated by a line with only the word "segment_break" in it.
  
  segment_break
  
  This module does not make any attempt to guess segment boundaries. For that,
  see L<Lingua::EN::Segmenter::TextTiling>.
  
  EOT

  # Set the number of tokens per tile to 20 (the default)
  set_tokens_per_tile(20);

  my @words = words $text;
  my @paragraphs = paragraphs $text;
  my @paragraph_breaks = paragraph_breaks $text;
  my @segment_breaks = segment_breaks $text;
  my @tiles = tile words $text;
  
  print "@words[0..3,5]";     # Prints "lingua en segmenter is useful"
  print "@words[43..46,53]";  # Prints "this module does not guess"
  print $paragraphs[2];       # Prints the third paragraph of the above text
  print $paragraph_breaks[2]; # Prints which tile the 3rd paragraph starts on
  print $segment_breaks[1];   # Prints which tile the 2nd segment starts on
  print $tiles[1];            # Prints @words[20..39] filtered for stopwords 
                              # and stemmed

  # This module can also be used in an object-oriented fashion
  my $splitter = new Lingua::EN::Splitter;
  @words = $splitter->words $text;


=head1 DESCRIPTION

See synopsis.

This module can be used in an object-oriented fashion or the routines can be 
exported.

=head1 AUTHORS

David James <splice@cpan.org>

=head1 SEE ALSO

L<Lingua::EN::Segmenter::TextTiling>, L<Class::Exporter>, 
L<http://www.cs.toronto.edu/~james>

=cut

$VERSION = 0.10;
@EXPORT_OK = qw(
    words 
    paragraphs 
    breaks 
    paragraph_breaks
    segment_breaks
    
    set_tokens_per_tile
    set_paragraph_regexp
    set_non_word_regexp
    set_locale
    set_stop_words
);

use Math::HashSum qw(hashsum);
use base 'Class::Exporter';
use Lingua::Stem;
use Lingua::EN::StopWords qw(%StopWords);
use strict;
use Carp qw(croak);
no warnings;

# Create a new instance of this object
sub new {
    my $class = shift;
    my $stemmer = Lingua::Stem->new;
    $stemmer->stem_caching({ -level=>2 });
    bless {
        PARAGRAPH_BREAK=>qr/\n\s*(segment_break)?\s*\n/,
        NON_WORD_CHARACTER=>qr/\W/,
        TOKENS_PER_TILE=>20,
        STEMMER=>$stemmer,
        STOP_WORDS=>\%StopWords,
        @_
    }, $class;
}

# Split text into words
sub words {
    my $self = shift;     
    my $input = lc shift;
    $input =~ s/$self->{PARAGRAPH_BREAK}/ /g;
    return [ split /$self->{NON_WORD_CHARACTER}+/, $input ];
}

# Split text into paragraphs
sub paragraphs {
    my ($self, $input) = @_;
    return [ 
        grep { /\S/ and !/^segment_break$/i } 
        split /$self->{PARAGRAPH_BREAK}/i, $input 
    ];
}

# Return a list of paragraph and segment breaks
sub breaks {
    my $self = shift;
    my $input = lc shift;
    
    # Eliminate empty paragraphs at the very end
    $input =~ s/$self->{PARAGRAPH_BREAK}\s*\Z//;

    # Convert paragraph breaks to tokens
    $input =~ s/$self->{PARAGRAPH_BREAK}/ PNO$1 /g;

    my @words = split /(?:$self->{NON_WORD_CHARACTER})+/, $input;
    my (@breaks,%segment_breaks,$num_words);
   
    foreach (@words) {
        if (/^PNO(segment_break)?$/) {
            my $segment_break = $1;
            $segment_break and $segment_breaks{scalar @breaks}++; 
            push @breaks, $num_words / $self->{TOKENS_PER_TILE};
        } else {
            $num_words++;
        }
    }
    return (\@breaks,\%segment_breaks);
}

# Return a list of paragraph breaks
sub paragraph_breaks {
    my $self = shift;
    return ($self->breaks(@_))[0];
}

# Return a list of real segment breaks
sub segment_breaks {
    my $self = shift;
    return ($self->breaks(@_))[1];
}

# Convert a list of words into tiles
sub tile {
    my $self = shift;
    my $words = ref $_[0] ? shift : \@_;
    my @tiles;

    while (@$words) {
        push @tiles, { 
            hashsum map { @{$self->{STEMMER}->stem($_)}, 1 } 
            grep { !exists $self->{STOP_WORDS}->{$_} }
            splice @$words, 0, $self->{TOKENS_PER_TILE}
        };
    }
    return \@tiles;
}

#########################################################
# Mutator methods
#########################################################

sub set_tokens_per_tile {
    my $self = shift;
    $self->{TOKENS_PER_TILE} = shift;
}

sub set_paragraph_regexp {
    my $self = shift;
    $self->{PARAGRAPH_BREAK} = shift;
}

sub set_non_word_regexp {
    my $self = shift;
    $self->{NON_WORD_CHARACTER} = shift;
}

sub set_locale {
    my $self = shift;
    $self->{STEMMER}->set_locale(shift);
}

sub set_stop_words {
    my $self = shift;
    $self->{STOP_WORDS} = shift;
}


1;
