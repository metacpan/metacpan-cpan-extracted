package Lingua::YaTeA::TermCandidate;
use strict;
use warnings;
# use UNIVERSAL;
# use Scalar::Util qw(blessed);

our $id = 0;
our $VERSION=$Lingua::YaTeA::VERSION;

sub new
{
    my ($class) = @_;
    my $this;
    $this->{ID} = $id++;
    $this->{KEY} = "";
    $this->{HEAD} = ();
    $this->{WORDS} = [];
    $this->{OCCURRENCES} = [];
    $this->{RELIABILITY} = ();
    $this->{TERM_STATUS} = 1;
    $this->{ORIGINAL_PHRASE} = ();
#     $this->{WEIGHT} = 0;
    $this->{WEIGHTS} = {};
    $this->{ROOT} = ();
    $this->{MNP_STATUS} = 0;  # added by SA 13/02/2009
    bless ($this,$class);
    return $this;
}

sub setROOT {
    my ($this, $ROOT) = @_;
    push @{$this->{ROOT}}, $ROOT;
    return($this->{ROOT});
}

sub getROOT {
    my ($this) = @_;
    return($this->{ROOT});
}

sub setTermStatus {
    my ($this, $status) = @_;
    $this->{TERM_STATUS} = $status;
    return($this->{TERM_STATUS});
}

sub getTermStatus {
    my ($this) = @_;
    return($this->{TERM_STATUS});
}

sub isTerm {
    my ($this) = @_;

    return($this->getTermStatus != 0);
}

sub getLength
{
    my ($this) = @_;
    return scalar @{$this->getWords};
}

sub addWord
{
    my ($this,$leaf,$words_a) = @_;
    push @{$this->{WORDS}}, $words_a->[$leaf->getIndex];
}

sub addOccurrence
{
    my ($this,$occurrence) = @_;
    if($occurrence->isMaximal)
    {
	$this->{MNP_STATUS} = 1;  # added by SA 13/02/2009:: if at least one occurrence is a MNP, TC is a MNP
    }
    push @{$this->{OCCURRENCES}}, $occurrence;
}

sub addOccurrences
{
    my ($this,$occurrences_a) = @_;
    my $occurrence;
    foreach $occurrence (@$occurrences_a)
    {
	$this->addOccurrence($occurrence);
    }
}

sub getKey
{
    my ($this) = @_;
    return $this->{KEY};
}

sub getID
{
    my ($this) = @_;
    return $this->{ID};
}

sub getMNPStatus
{
    my ($this) = @_;
    return $this->{MNP_STATUS};
}

sub editKey
{
    my ($this,$string) = @_;
    $this->{KEY} .= $string;
}

sub setHead
{
    my ($this) = @_;
    $this->{HEAD} = $this->searchHead(0);
}

sub getHead
{
    my ($this) = @_;
    return $this->{HEAD};
}

sub setWeight
{
    my $this = shift;
    my $weight;
    my $weight_name;
    if (scalar(@_) == 2) {
	$weight_name = shift;
    } else {
	# default weight because it's the first 
	$weight_name = "DDW";	
    }
    $weight = shift;
    $this->getWeights->{$weight_name} = $weight;

#     $this->{WEIGHT} = $weight;
}

sub getWeight
{
    my $this = shift;

    my $weight_name;
    if (@_) {
	$weight_name = shift;
    } else {
	# default wieght because it's the first 
	$weight_name = "DDW";	
    }
    return($this->getWeights->{$weight_name});

#     return $this->{WEIGHT};
}

sub setWeights
{
    my ($this,$weight) = @_;
    $this->{WEIGHTS} = $weight;
}

sub getWeights
{
    my ($this) = @_;
    return($this->{WEIGHTS});
}

sub getWeightNames
{
    my ($this) = @_;
    return(keys %{$this->{WEIGHTS}});
}

sub getWords
{
    my ($this) = @_;
    return $this->{WORDS};
}

sub getWord
{
    my ($this,$index) = @_;
    return $this->getWords->[$index];
}

sub getOccurrences
{
    my ($this) = @_;
    return $this->{OCCURRENCES};
}

sub getOccurrencesNumber
{
    my ($this) = @_;
    return scalar @{$this->getOccurrences};
}

sub buildLinguisticInfos
{
    my ($this,$tagset) = @_;
    my $if;
    my $pos;
    my $lf;
    my $word;
    
    foreach $word (@{$this->getWords})
    {
	$if .= $word->getIF . " " ;
	if ($tagset->existTag('PREPOSITIONS',$word->getIF))
	{
	    $pos .= $word->getLF . " ";
	}
	else
	{
	    $pos .= $word->getPOS . " ";
	}
	$lf .= $word->getLF . " " ;
    }
    $if =~ s/\s+$//;
    $pos =~ s/\s+$//;
    $lf =~ s/\s+$//;
    return ($if,$pos,$lf);

}

sub getIF
{
    my ($this) = @_;
    my $word;
    my $if;
    foreach $word (@{$this->getWords})
    {
	$if .= $word->getIF . " " ;
    }
    $if =~ s/\s+$//;
    return $if;
}

sub getLF
{
    my ($this) = @_;
    my $word;
    my $lf;
    foreach $word (@{$this->getWords})
    {
	$lf .= $word->getLF . " " ;
    }
    $lf =~ s/\s+$//;
    return $lf;
}

sub getPOS
{
    my ($this) = @_;
    my $word;
    my $pos;
    foreach $word (@{$this->getWords})
    {
	$pos .= $word->getPOS . " " ;
    }
    $pos =~ s/\s+$//;
    return $pos;
}

sub getFrequency
{
    my ($this) = @_;
    return scalar @{$this->getOccurrences};
}

sub setReliability
{
    my ($this,$reliability) = @_;
    $this->{RELIABILITY} = $reliability;
}

sub getReliability
{
    my ($this) = @_;
    return $this->{RELIABILITY};
}

sub getOriginalPhrase
{
    my ($this) = @_;
    return $this->{ORIGINAL_PHRASE};
}



1;

__END__

=head1 NAME

Lingua::YaTeA::TermCandidate - Perl extension for Term Candidate

=head1 SYNOPSIS

  use Lingua::YaTeA::TermCandidate;
  Lingua::YaTeA::TermCandidate->new();

=head1 DESCRIPTION


This module implements a representation of a term candidate.  Each
term candidate is described by its identifier (C<ID>), an internal key
C<KEY>, the minimal head of the term candidate C<HEAD>, the list of
word components C<WORDS>, its list of occurrences C<OCCURRENCES>, the
reliability C<RELIABILITY>, is status as term C<TERM_STATUS>
(according to the configuration, phrase recognised as term candidate
can be a term or not - the default value is 0), the reference to the
original phrase in the corpus C<ORIGINAL_PHRASE>, the associated
weights that can be considered as relevancy measures C<WEIGHTS>, its
root node C<ROOT>, the information whether the term if a maximal noun
phrase C<MNP_STATUS> (the default value is 0. a term candidate is
considered as maximal noun phrase if at least one occurrence is a
maximal noun phrase).

The key of the term candidate is the concatenation of the inflected
form, the postag list and the lemma (separated by the character '~').


=head1 METHODS

=head2 new()

    new();

The methord creates a new object of term candidate.

=head2 setRoot()

    setRoot();

The method sets the C<ROOT> field and returns it. 

=head2 getRoot()

    getRoot();

The method returns the C<ROOT> field. 

=head2 setTermStatus()

    setTermStatus();

The method sets the C<TERM_STATUS> field and returns it. 


=head2 getTermStatus()

    getTermStatus();

The method returns the C<TERM_STATUS> field. 

=head2 isTerm()

    isTerm();

This methods indicates if the term candidate has the term status or
not.

=head2 getLength()

    getLength();

This method returns the number of words composing the phrase.


=head2 addWord()

    addWord($node, $wordlist);

This method adds a word from the word list C<$wordlist> and referred
by the node C<$node>.


=head2 addOccurrence()

    addOccurrence($term_occurrence);

This method adds the term occurrence (C<$term_occurrence>) to the
current term candidate and indicates if it's a maximal noun phrase
(field C<MNP_STATUS>).


=head2 addOccurrences()

    addOccurrences($term_occurrence_list);

This method adds the term occurrences from the list
C<$term_occurrence_list> (which is a reference to an array).


=head2 getKey()

    getKey();

This method returns the key of the term candidate.

=head2 getID()

    getID();

This method returns the identifier of the term candidate.


=head2 getMNPStatus()

    getMNPStatus();

This method indicates if the term candidate is maximal noun phrase or
not.

=head2 editKey()

    ediKey($string);

This method allows to modify the key of the current term candidate by
adding the string C<$string>.


=head2 setHead()

    setHead();

This method sets the minimal head of the term candidate by searching
it in the parsing tree of the phrase.


=head2 getHead()

    getHead();

This method returns the minimal head of the term candidate. 


=head2 setWeight()

    setWeight($weight_name, $weight);

This method sets the weight C<$<weight_name> with the weight value
C<$weight>.


=head2 getWeight()

    getWeight($weight_name);

This method returns the weight value of the weight C<$<weight_name>.

=head2 setWeights()

    setWeights($weight_list);

This method sets a list of weights referred by the hash table
C<weight_list> where the key is the weight name and the value is the
weight value.

=head2 getWeights()

    getWeights();

This method returns the list of weights i.e. a hash table where the
key is the weight name and the value is the weight value.

=head2 getWeightNames()

    getWeightNames();

The method returns the list of the weight names that are instanciated,
as an array.


=head2 getWords()

    getWords();

The mathod returns the list of the words that are components of the
term candidate.

=head2 getword()

    getWord($index);

The method returns the word at the position C<
index> in the list of the components of the term candidate.

=head2 getOccurrences()

    getOccurrences();

This method returns the list of the occurrences of the term candidate, as an array reference.

=head2 buildLinguisticInfos()

    buildLinguisticInfos($tagset);

The method returns the inflected form, the postag list and and the
lemma of the term candidate as an array (each informationn is the
concatenation of the word information).

=head2 getIF()

    getIF();

The method returns the inflected form of the term candidate.

=head2 getLF()

    getLF();

The method returns the canonical form (lemma) of the term candidate.


=head2 getPOS()

    getPOS();

The method returns the list of the part-of-speech tags of the term
candidate.


=head2 getFrequency()

    getFrequency();

The method returns the frequency of the term candidate, i.e. the
number of occurrences of the term candidate.

=head2 setReliability()

    setReliability($reliability);

The method sets the reliability of the term candidate.

=head2 getReliability()

    getReliability();

The method returns the reliability of the term candidate.

=head2 getOriginalPhrase()

    getOriginalPhrase();

The method returns the original phrase issued from the corpus.

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
