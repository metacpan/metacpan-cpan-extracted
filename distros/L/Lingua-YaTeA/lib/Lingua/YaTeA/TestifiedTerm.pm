package Lingua::YaTeA::TestifiedTerm;
use strict;
use warnings;
use UNIVERSAL;
use NEXT;
use Scalar::Util qw(blessed);

our $id = 0;
our $VERSION=$Lingua::YaTeA::VERSION;

sub new
{
    my ($class_or_object,$num_content_words,$words_a,$tag_set,$source,$match_type) = @_;
   
    my $this = shift;
    
    $this = bless {}, $this unless ref $this;
    $this->{ID} = $id;
    $this->{IF} = ();
    $this->{POS} = ();
    $this->{LF} = ();
    $this->{SOURCE} = [];
    $this->{WORDS} = [];
    $this->{REG_EXP} = ();
    $this->{FOUND} = 0;
    $this->{OCCURRENCES} = [];
    $this->{INDEX_SET} = Lingua::YaTeA::IndexSet->new;
    $this->buildLinguisticInfos($words_a,$tag_set);
    push @{$this->getSource}, split /,/,$source;
    $this->buildRegularExpression($match_type);
    $this->setIndexSet(scalar @{$this->getWords});
    $this->NEXT::new(@_);
    return $this;
}

sub isInLexicon
{
    my ($this,$filtering_lexicon_h,$match_type) = @_;
    my $lex_item;
    
    foreach $lex_item (@{$this->getWords})
    {
	if($match_type eq "loose") # look at IF or LF
	{
	    if(
	       (!exists $filtering_lexicon_h->{lc($lex_item->getIF)})
	       &&
	       (!exists $filtering_lexicon_h->{lc($lex_item->getLF)})
	       )
	    {
		# current word does not appear in the corpus : testified term won't be loaded
		return 0;
	    }
	}
	else
	{
	    if($match_type eq "strict") # look at IF and POS
	    {
		if (!exists $filtering_lexicon_h->{lc($lex_item->getIF)."~".$lex_item->getPOS})
		{
		    # current word does not appear in the corpus : testified term won't be loaded
		    return 0;
		}
		
	    }
	    else
	    {
		# default match: look at IF
		if(!exists $filtering_lexicon_h->{lc($lex_item->getIF)})
		{
			
		    # current word does not appear in the corpus : testified term won't be loaded
		    return 0;
		}		
		
	    }
	}
    }
    return 1;
}


sub buildLinguisticInfos
{
    my ($this,$lex_items_a,$tag_set) = @_;
    
    my $lex;
    my $IF;
    my $POS;
    my $LF;
    my %prep = ("of"=>"of", "to"=>"to");
    
    
    foreach $lex (@$lex_items_a)
    {
	if ((blessed($lex)) && ($lex->isa("Lingua::YaTeA::LexiconItem")))
	{
	    $IF .= $lex->getIF . " " ;
	    #if (exists $prep{$lex->getLF})
	    if ($tag_set->existTag('PREPOSITIONS',$lex->getIF))
	    {
		$POS .= $lex->getLF . " ";
	    }
	    else
	    {
		$POS .= $lex->getPOS . " ";
	    }
	    $LF .= $lex->getLF . " " ;
	    push @{$this->getWords}, $lex;
	}
	else
	{
	    die "problem: " . $lex . "\n";
	}
    }
    $IF =~ s/\s+$//;
    $POS =~ s/\s+$//;
    $LF =~ s/\s+$//;
    $this->setIF($IF);
    $this->setPOS($POS);
    $this->setLF($LF);
}

sub getWords
{
    my ($this) = @_;
    return $this->{WORDS};
}

sub setIF
{
    my ($this,$new) = @_;
    $this->{IF} = $new;
}

sub setPOS
{
    my ($this,$new) = @_;
    $this->{POS} = $new;
}

sub setLF
{
    my ($this,$new) = @_;
    $this->{LF} = $new;
}

sub getIF
{
    my ($this) = @_;
    return $this->{IF};
}

sub getPOS
{
    my ($this) = @_;
    return $this->{POS};
}

sub getLF
{
    my ($this) = @_;
    return $this->{LF};
}

sub getID
{
    my ($this) = @_;
    return $this->{ID};
}


sub buildKey
{
    my ($this) = @_;
    my $key = $this->{"IF"} . "~" . $this->{"POS"} . "~" . $this->{"LF"};
    return $key;
}

sub getSource
{
    my ($this) = @_;
    return $this->{SOURCE};
}

sub buildRegularExpression
{
    my ($this,$match_type) = @_;
    my $frontier = "\(\\n\\<\\/\?FRONTIER ID=\[0\-9\]\+ TT=\[0\-9\]\+\\>\)\*";
    my $reg_exp = $frontier . "\?";
    my $lex;
   
    if($match_type eq "loose") # IF or LF
    {
	foreach $lex (@{$this->getWords})
	{
	    $reg_exp .= "\(\(\\n".quotemeta($lex->getIF) . "\\t\[\^\\t\]\+\\t\[\^\\t\]\+\)\|\(\\n\[\^\\t\]\+\\t\[\^\\t\]\+\\t". quotemeta($lex->getLF) . "\)\)" . $frontier;
	    
	}
    }
    else
    { 
	if($match_type eq "strict") # IF and POS
	{
	    foreach $lex (@{$this->getWords})
	    {
		$reg_exp .= "\\n".quotemeta($lex->getIF) . "\\t".quotemeta($lex->getPOS) ."\\t\[\^\\t\]\+" . $frontier;
	    }
	}
	else
	{
	    foreach $lex (@{$this->getWords}) # IF
	    {
		$reg_exp .= "\\n".quotemeta($lex->getIF) . "\\t\[\^\\t\]\+\\t\[\^\\t\]\+" . $frontier;
	    }
	}
    }
    $reg_exp .= "\\n";
    $this->{REG_EXP} = $reg_exp;
}


sub getRegExp
{
    my ($this) = @_;
    return $this->{REG_EXP};
}

sub getWord
{
    my ($this,$index) = @_;
    return $this->getWords->[$index];

}

sub addOccurrence
{
    my ($this,$phrase_occurrence,$phrase,$key,$fh) = @_;
    my $start_offset;
    my $end_offset;
    my $testified_occurrence;
    my @index = split(/-/,$key);
    ($start_offset,$end_offset) = $this->getPositionInPhrase($phrase,\@index,$fh);
    $testified_occurrence = Lingua::YaTeA::Occurrence->new;
    $testified_occurrence->setInfoForTestifiedTerm($phrase_occurrence->getSentence,$phrase_occurrence->getStartChar + $start_offset, $phrase_occurrence->getEndChar - $end_offset);
    push @{$this->{OCCURRENCES}}, $testified_occurrence; 
}

sub getPositionInPhrase
{
    my ($this,$phrase,$index_a,$fh) = @_;
    my @before;
    my @after;
    my $index;
    my $start_offset = 0;
    my $end_offset = 0;
    #print $fh $index_a->[0] . "\n";
    #print $fh $index_a->[$#$index_a] . "\n";
    for ($index = 0; $index < $index_a->[0]; $index++)
    {
	push @before, $index;
    }
    for ($index = $index_a->[$#$index_a] +1; $index < $phrase->getIndexSet->getSize; $index++)
    {
	push @after, $index;
    }

    foreach $index (@before)
    {
	$start_offset += $phrase->getWord($index)->getLength +1;
    }
    
    foreach $index (@after)
    {
	$end_offset += $phrase->getWord($index)->getLength +1;
    }
   
    return ($start_offset,$end_offset);   
}

sub setIndexSet
{
    my ($this,$size) = @_;
    my $i = 0;
    while ($i < $size)
    {
	$this->getIndexSet->addIndex($i);
	$i++;
    }
    
}

sub getIndexSet
{
    my ($this) = @_;
    return $this->{INDEX_SET};
}

sub getOccurrences
{
    my ($this) = @_;
    return $this->{OCCURRENCES};
}


1;


__END__

=head1 NAME

Lingua::YaTeA::TestifiedTerm - Perl extension for Testified Term

=head1 SYNOPSIS

  use Lingua::YaTeA::TestifiedTerm;
  Lingua::YaTeA::TestifiedTerm->new(num_content_words,$words_a,$tag_set,$source,$match_type);

=head1 DESCRIPTION

The module implements a representation of the testified terms,
i.e. terms from a terminological resource. Those testified terms are
used to find corresponding terms in the corpus. Each testified term is
described by its identifier (C<ID>), its inflected form C<IF>, its
list of part-of-speech tags C<POS>, its lemma C<LF>, the
terminological source C<SOURCE>, the list of word components C<WORDS>,
the regular expression used to identify it in the corpus (C<REG_EXP>),
the indication whether the testified term is found or not (C<FOUND>),
its list of occurrences C<OCCURRENCES> and the list of the word index
entries (C<INDEX_SET>).

The three information C<IF>, C<POS> and C<LF> are computed from the
information issued from their word components.

=head1 METHODS

=head2 new()

    new($num_content_words,$words_a,$tag_set,$source,$match_type);

This method creates a new object representing a testified term. It
sets the fields C<IF>, C<POS>, C<LF>, C<REG_EXP>, C<INDEX_SET> and
C<SOURCE>. C<$words_a> and C<$tag_set> are used to initialise the
lignuistic information (C<IF>, C<POS>, C<LF>). C<$source> initialises
the C<SOUCE> field. C<$mach_type> defines the type of matching for
finding the terms in the corpus.

=head2 isInLexicon()

    isInLexicon($filtering_lexicon_h, $match_type);

This method checks if all the words of a testified term appear in the
lexicon of the text (C<$filtering_lexicon_h>) according to the
matching type C<$match_type>: C<loose> (each word matches either a
inflected form or a lemmatised form) C<strict> (each word matches a
inflected form with the correct Part-of-Speech tag) C<default> (each
word mathces a inflected form). The method returns 1 if all the words
of the testified term are found in the lexicon, otherwise it returns 0.

C<$filtering_lexicon_h> is a hash table containing the inflected
forms, the lemmatised form and the concatenation of the inflected form
and the Partof-speech tag (separated by a C<~> character) of each word
in the text.

=head2 buildLinguisticInfos()

    buildLinguisticInfos($words, $tagset);

The method returns the inflected form, the postag list and the lemma
of the term candidate as an array (each informationn is the
concatenation of the word information found in the array C<$words> and
the Part-of-Speech tags C<$tagset>).


=head2 getWords()

    getWords();

The mathod returns the list of the words that are components of the
term candidate.

=head2 setIF()

    setIF();

The method sets the inflected form of the term candidate.

=head2 setPOS()

    setPOS();

The method sets the list of the part-of-speech tags of the term
candidate.

=head2 setLF()

    setLF();

The method sets the canonical form (lemma) of the term candidate.

=head2 getIF()

    getIF();

The method returns the inflected form of the term candidate.

=head2 getPOS()

    getPOS();

The method returns the list of the part-of-speech tags of the term
candidate.

=head2 getLF()

    getLF();

The method returns the canonical form (lemma) of the term candidate.

=head2 getID()

    getID();

This method returns the identifier of the term candidate.

=head2 buildKey()


    buoldKey();

This method builds the key of the testified term, i.e. the
concatenation of the inflected form, the postag list and the lemma
(separated by the character '~').

=head2 getSource()

    getSource(),

The method returns the terminological resource where the testified
term is issued.

=head2 buildRegularExpression()

    buildRegularExpression($match_type);

The method computes the regular expression corresponding to the term
according to the type of matching defined by C<$mach_type>. This
regular expression will be used to find the term in the corpus.

=head2 getRegExp()

    getReqExp();

The method returns the regular expression corresponding to the
testified term (field C<REG_EXP>).

=head2 getWord()

    getWord($index);

The method returns the word at the position C<
index> in the list of the components of the term candidate.

=head2 addOccurrence()

    addOccurrence($phrase_occurrence,$phrase,$key,$fh);

This method looks for the current testified term with the occurrence
C<hrase_occurrence> of the phrase C<$phrase> (according to the key
C<$key>). And then the occurrence is recorded in the list of
occurrences C<OCCURRENCES>.  C<$fh> is the  file
hanlder of a debugging file.

=head2 getPositionInPhrase()

    getPositionInPhrase($phrase,$index_a,$fh);

The method returns the position (start and end offsets) of the phrase
C<$phrase> according to the index array C<index_a>. C<$fh> is the
file hanlder of a debugging file.

=head2 setIndexSet()

    setIndexSet($size);

This method initialises the index set with the number betwwen 0 and
C<$size> (usually the number of words).

=head2 getIndexSet()

    getIndexSet();

This method returns the index set (field C<INDEX_SET>) of the word components.

=head2 getOccurrences()

    getOccurrences();

This method returns the list of the occurrences of the term candidate,
as an array reference.

=head1 SEE ALSO

Sophie Aubin and Thierry Hamon. Improving Term Extraction with
Terminological Resources. In Advances in Natural Language Processing
(5th International Conference on NLP, FinTAL 2006). pages
380-387. Tapio Salakoski, Filip Ginter, Sampo Pyysalo, Tapio Pahikkala
(Eds). August 2006. LNAI 4139.


=head1 AUTHOR

Thierry Hamon <thierry.hamon@univ-paris13.fr> and Sophie Aubin <sophie.aubin@lipn.univ-paris13.fr>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Thierry Hamon and Sophie Aubin

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
