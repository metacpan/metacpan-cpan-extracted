package Lingua::YaTeA::WordFromCorpus;
use strict;
use warnings;
use Lingua::YaTeA::WordOccurrence;
# use UNIVERSAL;
# use Scalar::Util qw(blessed);

our @ISA = qw(Lingua::YaTeA::WordOccurrence);
our $counter = 0;

our $VERSION=$Lingua::YaTeA::VERSION;

sub new
{
    my ($class,$form,$lexicon,$sentences) = @_;
    my $this = $class->SUPER::new($form);
    bless ($this,$class);
    $this->{ID} = $counter;
    $this->{LEX_ITEM} = $this->setLexItem($form,$lexicon);    
    $this->{SENTENCE} = $sentences->getCurrent;
    $this->{START_CHAR} = $Lingua::YaTeA::Sentence::start_char;
    return $this;
}


sub setLexItem
{
    my ($this,$form,$lexicon) = @_;
    return $lexicon->addOccurrence($form);
}


sub getID
{
    my ($this) = @_;
    return $this->{ID};
}


sub getSentence
{
    my ($this) = @_;
    return $this->{SENTENCE};
}

sub getDocument
{
    my ($this) = @_;
    return $this->getSentence->getDocument;
}

sub getSentenceID
{
    my ($this) = @_;
    return $this->getSentence->getID;
}

sub getDocumentID
{
    my ($this) = @_;
    return $this->getSentence->getDocument->getID;
}

sub getStartChar
{
    my ($this) = @_;
    return $this->{START_CHAR};
}

sub getLexItem
{
    my ($this) = @_;
    return $this->{LEX_ITEM};
}

sub isSentenceBoundary
{
    my ($this,$sentence_boundary) = @_;
   
    if ($this->getLexItem->getPOS eq $sentence_boundary)
    {
	return 1;
    }
    return 0;
}

sub isDocumentBoundary
{
    my ($this,$document_boundary) = @_;
   
    if ($this->getLexItem->getPOS eq $document_boundary)
    {
	return 1;
    }
    return 0;
}



sub updateSentence
{
    my ($this,$sentences) = @_;
    $this->{SENTENCE} = $sentences->getCurrent;
}

sub updateStartChar
{
    my ($this) = @_;
    $this->{START_CHAR} = $Lingua::YaTeA::Sentence::start_char;
}

sub isChunkingFrontier
{
    my ($this,$chunking_data) = @_;
    my @types = ("POS",  "LF", "IF");
    my $type;
    foreach $type (@types)
    {
	# word is a chunking frontier
	if ($chunking_data->existData("ChunkingFrontiers",$type,$this->getLexItem->{$type}) == 1)
	{
	    # word is not a chunking exception : end
	    if (! $this->isChunkingException($chunking_data) )
	    {
		
		return 1;
	    }
	    return 0;
	}
    }
    return 0;
}

sub isChunkingException
{
    my ($this,$chunking_data) = @_;
    my @types = ("POS",  "LF", "IF");
    my $type;
    foreach $type (@types)
    {
	if ($chunking_data->existData("ChunkingExceptions",$type,$this->getLexItem->{$type}) == 1)
	{
	    return 1;
	}
    }
    return 0;
}

sub isCleaningFrontier
{
    my ($this,$chunking_data) = @_;
    my @types = ("POS",  "LF", "IF");
    my $type;
    foreach $type (@types)
    {
	if ($chunking_data->existData("CleaningFrontiers",$type,$this->getLexItem->{$type}) == 1)
	{
	    if (! $this->isCleaningException($chunking_data))
	    {
		return 1;
	    }
	}
    }
    return 0;
}

sub isCleaningException
{
    my ($this,$chunking_data) = @_;
    my @types = ("POS",  "LF", "IF");
    my $type;
    foreach $type (@types)
    {
	if ($chunking_data->existData("CleaningExceptions",$type,$this->getLexItem->{$type}) == 1)
	{
	    return 1;
	}
    }
    return 0;
}

sub isCompulsory
{
    my ($this,$compulsory) = @_;
#    my $compuslory = $options->getCompulsory;
    
    if # (
# 	((blessed($this)) && ($this->isa("Lingua::YaTeA::TestifiedTermMark")))
# 	||
	($this->getLexItem->getPOS =~ /$compulsory/) 
#	)
    {
	return 1;
    }
    return 0;
}

sub getPOS
{
    my ($this) = @_;
    return $this->getLexItem->getPOS;
}

sub isEndTrigger
{
    my ($this,$end_trigger_set) = @_;
    return $end_trigger_set->findTrigger($this);
}

sub isStartTrigger
{
    my ($this,$start_trigger_set) = @_;
    return $start_trigger_set->findTrigger($this);
}


sub getIF
{
    my ($this) = @_;
    return $this->getLexItem->getIF;
}

sub getLF
{
    my ($this) = @_;
    return $this->getLexItem->getLF;
}

1;

__END__

=head1 NAME

Lingua::YaTeA::WordFromCorpus - Perl extension for managing word of the corpus and related information

=head1 SYNOPSIS

  use Lingua::YaTeA::WordFromCorpus;
  Lingua::YaTeA::WordFromCorpus->new($form,$lexicon,$sentences);

=head1 DESCRIPTION

The module manages the word occurrence C<$form> of the corpus
(C<$form> is the inflected form of the word). It associates an
identifier (field C<ID>), the word entry of the lexicon C<$lexicon>
(field C<LEX_ITEM>), the sentence (from the sentence set
C<$sentences>) where the word occurrs (field C<SENTENCE>) and the
offset of the word in the sentence (C<START_CHAR>).

=head1 METHODS

=head2 new()

    new($form,$lexicon,$sentences);    

The method creates the objet correspoding to the word
C<$form>. C<$lexicon> and C<$sentences> are used to set the fields
C<LEX_ITEM> and C<SENTENCE> respectively.

=head2 setLexItem()

    setLexItem($form, $lexicon);

The method sets the field C<LEX_ITEM> of the word C<$form> with the
corresponding item in the lexicon C<$lexicon>.

=head2 getID()

    getID();

The method returns the identifier of the current word.

=head2 getSentence()

    getSentence();

The method return the sentence where occurs the current word.


=head2 getDocument()

    getDocument();

The method return the document where occurs the current word.

=head2 getSentenceID()

    getSentenceID();

The method return the identifier of the sentence where occurs the current word.


=head2 getDocumentID()

    getDocumentID();

The method return the identifier of the document where occurs the current word.

=head2 getStartChar()

    getStartChar();

The method returns the offset (field C<START_CHAR>) of the word in the
sentence.


=head2 getLexItem()

    getLexItem();


The method returns the lexicon item (field C<LEX_ITEM>) correspondig
to the current word.

=head2 isSentenceBoundary()

    isSentenceBoundary($sentence_boundary);

The methods indicates if the word is a sentence boundary (sentence
boundary is a string).


=head2 isDocumentBoundary()

    isDocumentBoundary($sentence_boundary);

The methods indicates if the word is a document boundary (sentence
boundary is a string).

=head2 updateSentence()

    updateSentence($sentences);

The method updates the field C<SENTENCE> regarding to the sentence set
(C<sentences>).


=head2 updateStartChar()

    updateSentence();

The method updates the field C<START_CHAR> regarding to the value of
the current offset in the sentence.


=head2 isChunkingFrontier()

    isChunkingFrontier($chunking_data);

The method indicates if the current word is a chunking frontier
according to the defined chunking data (C<$chunking_data>).

=head2 isChunkingException()

    isChunkingException($chunking_data);

The method indicates if the current word is a chunking exception
according to the defined chunking data (C<$chunking_data>).

=head2 isCleaningFrontier()

    isCleaningFrontier($chunking_data);

The method indicates if the current word is a cleaning frontier
according to the defined chunking data (C<$chunking_data>).


=head2 isCleaningException()

    isCleaningException($chunking_data);

The method indicates if the current word is a cleaning exception
according to the defined chunking data (C<$chunking_data>).


=head2 isCompulsory()

    izCompulsory($compulsory);

The method indicates if the Part-Of-Speech (POS) tag of the current
word is one of the required POS tag that must appear in a term.

=head2 getPOS()

    getPOS();

The methods returns the Part-Of-Speech tag of the current word.

=head2 isEndTrigger()

    isEndTrigger($end_trigger_set);

the method indicates if the word is at the end of a trigger (see
C<Lingua::YaTeA::TriggerSet> and C<Lingua::YaTeA::Trigger>).


=head2 isStartTrigger()

    isStartTrigger($start_trigger_set);

the method indicates if the word is at the start of a trigger (see
C<Lingua::YaTeA::TriggerSet> and C<Lingua::YaTeA::Trigger>).


=head2 getIF()

    getIF();

The methods returns the inflected form of the current word.

=head2 getLF()

    getLF();

The methods returns the lemmatised form of the current word.


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
