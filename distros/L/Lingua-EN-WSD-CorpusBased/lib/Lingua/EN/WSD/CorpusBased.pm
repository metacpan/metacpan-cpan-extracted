package Lingua::EN::WSD::CorpusBased;

our $VERSION = "0.11";

use warnings;
use strict;
use String::Util qw(crunch);
use stem;
use Lingua::EN::WSD::CorpusBased::Corpus;

sub new {
    my $class = shift;

    my %args = ('debug' => 0,
		'strict' => 0,
		'stem' => 1,
		'hypernyms' => 1,
		'hyponyms' => 1,
		@_);
    return -1 if (ref($args{'wnref'}) ne 'WordNet::QueryData');
    return -1 if (ref($args{'cref'}) ne 'Lingua::EN::WSD::CorpusBased::Corpus');
    
    my $this = { 'wn' => $args{'wnref'},
		 'corpus' => $args{'cref'},
		 'debug' => $args{'debug'},
		 'strict' => $args{'strict'},
		 'flexibility' => $args{'flexibility'},
		 'stem' => $args{'stem'},
		 'stemmer' => stem->new($args{'wnref'}),
		 'hype' => $args{'hypernyms'},
		 'hypo' => $args{'hyponyms'}};
    return bless $this, $class;
}

sub init {
    my $self = shift;
    my %args = @_;
    my $term = $args{'term'};
    my @t = split / +/, lc($term);
    $self->{'term'} = \@t;
    $self->{'size'} = scalar @t;
    $self->{'inWN'} = $self->{'wn'}->queryWord($self->term,"syns");
    $self->{'wnTerm'} = crunch($self->{'stemmer'}->stemString(($self->{'inWN'}?$self->term:$self->head)));
    if ($self->{'debug'} > 0) {
	print STDERR 'CorpusBased object initialized (term="'.join(' ',@{ $self->{'term'} }).'", ';
	print STDERR 'size="'.$self->{'size'}.'", ';
	print STDERR 'inWN="'.$self->{'inWN'}.'", ';
	print STDERR 'wnTerm="'.$self->{'wnTerm'}.")\n";
    }
}
  
sub ready {
    my $self = shift;
    return 0 if (! exists($self->{'term'}));
    return 0 if ($self->{'term'} eq '');
    return 1;
}

sub term {
    my $self = shift;
    return -1 if (! $self->ready);
    return lc(join("_",@{$self->{'term'}}));
}

sub head {
    my $self = shift;
    return -1 if (! $self->ready);
    return lc($self->{'term'}->[$self->{'size'} - 1]);
}

sub term_replace {
    my $self = shift;
    my $replacement = shift;
    return -1 if (! $self->ready);
    my @t = @{$self->{'term'}};
    pop(@t);
    push(@t,split(/_/,$replacement));
    return \@t;
}


sub synsets {
    my $self = shift;
    my %returnlist = ();
    return [] if (! $self->ready);
    my $query = $self->{'wnTerm'};
    my @senses = $self->{'wn'}->queryWord($query,"syns");
    foreach my $word_pos (@senses) {
	foreach my $word_pos_num ($self->{'wn'}->querySense($word_pos,"syns")) {
	    $returnlist{$word_pos_num} = 1;
	};
    };
    my @t = keys %returnlist;
    
    return \@t;
}

sub synonyms {
    my ($self,$synset) = @_;
    return () if ((! defined $synset) or $synset eq '');
    return (map 
	    { /([^\#]*)\#[nva]\#\d+/; $1 }
	    $self->{'wn'}->querySense($synset,"syns"));
}

sub hypernyms {
    my ($self,$synset) = @_;
    return () if ((! defined $synset) or $synset eq '');
    return $self->{'wn'}->querySense($synset,"hype");
}

sub hyponyms {
    my ($self,$synset) = @_;
    return () if ((! defined $synset) or $synset eq '');
    return $self->{'wn'}->querySense($synset,"hypo");
}

sub count {
    my $self = shift;
    return -1 if ((! defined $self->{'corpus'}) or
		  (! exists $self->{'corpus'}));
    return $self->{'corpus'}->count(@_);
}

sub v {
    my ($self,$synset) = @_;
    return -1 if (! defined $synset or
		  $synset eq '');
    my $sum = 0;
    foreach my $synonym ($self->synonyms($synset)) {
	if ($self->{'inWN'}) {
	    $sum += $self->count(split(/_/,$synonym));
	} else {
	    $sum += $self->count(@{$self->term_replace($synonym)});
	}
    };

    # hypernyms
    if ($self->{'hype'}) {
	foreach my $hypernym ($self->hypernyms($synset)) {
	    foreach my $synonym ($self->synonyms($hypernym)) {
		if ($self->{'inWN'}) {
		    $sum += $self->count(split(/_/,$synonym));
		} else {
		    $sum += $self->count(@{$self->term_replace($synonym)});
		}
	    };
	};
    };

    # hyponyms
    if ($self->{'hypo'}) {
	foreach my $hyponym ($self->hyponyms($synset)) {
	    foreach my $synonym ($self->synonyms($hyponym)) {
		if ($self->{'inWN'}) {
		    $sum += $self->count(split(/_/,$synonym));
		} else {
		    $sum += $self->count(@{$self->term_replace($synonym)});
		}
	    };
	};
    };
    return $sum;
}

sub sense {
    my $self = shift;
    my $max = 0;
    return [] if ($self->{'wnTerm'} eq '');
    my @maxsynsets = ();
    foreach my $synset (@{$self->synsets}) {
	print STDERR '  '.$synset."\n" if ($self->{'debug'} > 0);
	my $value = $self->v($synset)."\n";
	if ($value > $max) {
	    @maxsynsets = ($synset);
	    $max = $value;
	} elsif ($value == $max) {
	    push(@maxsynsets, $synset);
	};
    }
    if (scalar @maxsynsets == scalar @{ $self->synsets } and
	$self->{'strict'}) {
	return [];
    }
    return \@maxsynsets;
}

sub wsd {
    my ($self,$term) = @_;
    return -1 if ($term eq '');
    print STDERR "Doing WSD for term '$term'\n" if ($self->{'debug'} > 0);
    $self->init('term' => $term);
    return $self->sense;
}

sub debug {
    my $self = shift;
    return $self->{'debug'};
}

1;

__END__

=head1 NAME

Lingua::EN::WSD::CorpusBased - Word Sense Disambiguation using a domain corpus

=head1 SYNOPSIS

   my $wn = WordNet::QueryData->new;
   my $corpus = Lingua::EN::WSD::CorpusBased::Corpus->new('corpus' => '_democorpus_',
                                                          'wnref' => $wn);
                            
   my $wsd = Lingua::EN::WSD::CorpusBased->new('wnref' => $wn,
                                               'cref' => $corpus);

   print join(', ',@{$wsd->wsd('e-mail application')}); # prints 'application#n#3'

=head1 DESCRIPTION

This Module allows a disambiguation of word senses based on a domain corpus. The system works based on the assumption, that in one corpus, only one sense of a word is used. Basically, we count for each sense the number of occurrences of one of its synonyms. The one with the highest number is then the right one. 

=head2 Corpus

The corpus is managed by an additional module L<Lingua::EN::WSD::CorpusBased::Corpus>. It stores the corpus and allows a fast access to its sentences. You should look into the documentation of the corpus module, since it expects the corpus to be in a preprocessed state.

=head1 METHODS

=over 4

=item new

Creates a new object. Takes a couple of arguments:

B<wnref>  A reference to a WordNet::QueryData object. Obligatory. 

B<cref>  A reference to a Corpus object. Obligatory.

B<debug>  A switch for the debug mode of the object. Optional, default: 0.

B<stem>  If you set this switch to 1, the term in question will be lemmatized using the stem module. If set to 0, only the original term will be sent to WordNet. In this case, it is possible that no WordNet entry is found for the term, leading to an empty list returned by the wsd-method. Optional, default: 1.

B<strict>  Controls whether the algorithm returns all senses or no sense in cases where they all are weighted equally. This happens especially, if the terms are not mentioned at all in the corpus (in which case I would recommend a larger corpus). Optional, default: 0.

B<hyponyms>  Controls whether we use not only synonyms, but also hyponyms. Optional, default 1

B<hypernyms>  Controls whether we use not only synonyms, but also hypernyms. Optional, default 1. 
Returns a blessed reference to the object or -1 if you did not supply references to objects of WordNet::QueryData and Lingua::EN::WSD::CorpusBased::Corpus.

=item wsd

    $obj->wsd($term);

The method for doing the word sense disambiguation. Returns a reference to a list of senses which seem the most probable for the given term. This can be the empty list (depends on your settings for 'strict'). The method returns -1 if you do not provide the term to disambiguate.

B<term>  The term you want to disambiguate. Required. 

=item debug

Returns the debug level in which the object is currently running. 

=back

=head2 Internal Methods

=over 4

=item init

Internal method. Prepares the object for a disambiguation run. Is automatically called by the method wsd. Has to be called before any call of sense, because it does some preprocessing. Takes one parameter.

B<term>  The term in question. Required. 

=item sense

    $obj->sense;

Internal method. Iterates over all senses of the given (via init) term and returns a reference to a list of the best senses. Takes no arguments.

=item v

    $obj->v($synset);

Internal method. Calculates the weight for a synset as sense of the given term. Returns the weight or -1 if $synset is undefined or an empty string.

=item count

    $obj->count(@words);

Internal method. Just a wrapper for the appropriate method of the corpus-object. Returns the number of occurrences or -1 if the corpus object is not available.

=item hyponyms

    $obj->hyponyms($synset);

Internal method. Returns a list of hyponyms (synsets) for a given (as argument) word. If the synset argument is not provided, undefined or an empty string, the method returns an empty list. 

=item hypernyms

    $obj->hypernyms($synset);

Internal method. Returns a list of hypernyms (synsets) for a given (as argument) word. If the synset argument is not provided, undefined or an empty string, the method returns an empty list. 

=item synonyms

    $obj->synonyms($synset);

Internal method. Returns a list of synonyms for a synset, which is given as a an argument. The returned list contains words, not synsets. If the synset argument is not provided, undefined or an empty string, the method returns an empty list. 

=item synsets

    $obj->synsets($word);

Internal method. Returns a reference to a list of synsets for the given term. This list includes all possible part of speeches (as long as they are defined in WordNet). Returns a reference to an empty list if something goes wrong (i.e. no term has been given to the object).

=item term_replace

Internal method. Returns the term in question after replacing the last word with the second argument. The returned string has underscores instead of spaces. Returns -1 if no term is known to the object.

=item head

Internal method. Returns the grammatical head of the term. In case of multi-word expressions, this is the last word of the expression, otherwise it's the word itself. Returns -1 if no term is given.

=item term

Internal method. Returns the term in question with underscores instead of spaces. Returns -1 if no term is given.

=item ready

Internal method. Returns a true value if the object is ready for disambiguation. This method especially checks if the term is set via init and if the preprocessing went ok. 

=back

=head1 BUGS

None so far. If you find some, please report them to me, reiter@cpan.org.

=head1 TODO

=over 4

=item *

A lot more useful debug output

=item *

Making more methods externally useful, allowing a more flexible use of the module. 

=back

=head1 SEE ALSO

It might be interesting to look at the modules L<WordNet::SenseRelate::AllWords> and L<WordNet::SenseRelate::TargetWord>, since they work in the same area. 

=head1 COPYRIGHT

Copyright (c) 2006 by Nils Reiter.

This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.


