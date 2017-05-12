package Lingua::YaTeA::MonolexicalTermCandidate;
use strict;
use warnings;
use Lingua::YaTeA::TermCandidate;

our @ISA = qw(Lingua::YaTeA::TermCandidate);

our $VERSION=$Lingua::YaTeA::VERSION;

sub new
{
    my ($class) = @_;
    my $this = $class->SUPER::new;
    bless ($this,$class);
    return $this;
}

sub searchHead
{
    my ($this) = @_;
    return $this;
}

sub setOccurrences
{
    my ($this,$phrase_occurrences_a,$offset,$word_length,$maximal) = @_;
    my $phrase_occurrence;
    
    foreach $phrase_occurrence (@$phrase_occurrences_a)
    {
	my $occurrence = Lingua::YaTeA::Occurrence->new;
	$occurrence->{SENTENCE} =  $phrase_occurrence->getSentence;
	$occurrence->{START_CHAR} = $phrase_occurrence->getStartChar + $offset;
	$occurrence->{END_CHAR} = $phrase_occurrence->getStartChar + $offset + $word_length;
	$occurrence->{MAXIMAL} = $maximal;
	$this->addOccurrence($occurrence);
    }

}

sub getPOS
{
    my ($this) = @_;
    return $this->getWords->[0]->getPOS;
}

sub getIF
{
    my ($this) = @_;
    return $this->getWords->[0]->getIF;
}

sub addMonolexicalOccurrences
{
    my ($this,$phrase_set,$monolexical_transfer_h) = @_;
    my $key = $this->getIF . "~" . $this->getPOS . "~" . $this->getLF;
    my $occurrences_a;
    if(exists $phrase_set->{$key})
    {
	$occurrences_a = $phrase_set->{$key}->getOccurrences;
	$this->addOccurrences($occurrences_a);
	$phrase_set->{$key}->setTC(1);
	$monolexical_transfer_h->{$phrase_set->{$key}->getID}++;
    }
}

sub getHeadAndLinks
{
    my ($this,$LGPmapping_h) = @_;
    my $head = $this->getWord(0);
    my @links;
    return ($head,0,\@links);
}


1;


__END__

=head1 NAME

Lingua::YaTeA::MonolexicalTermCandidate - Perl extension for the monolexical term candidate

=head1 SYNOPSIS

  use Lingua::YaTeA::MonolexicalTermCandidate;
  Lingua::YaTeA::MonolexicalTermCandidate->new();

=head1 DESCRIPTION

The module implements the monolexical (r single word) term
candadiate. It inheris of the module C<Lingua::YaTeA::TermCandidate>.

=head1 METHODS

=head2 new()

    new();

the methods creates a new monolexical term candidate.

=head2 searchHead()

    searchHead();

The method returns the head component of the term candidate. As it is
single word term candidate, the head component is the current node.

=head2 setOccurrences()

    setOccurrences($phrase_occurrences_a,$offset,$word_length,$maximal);

The method associates a list of new occurrence, referred by
C<$phrase_occurrences_a> to the current term candidate. C<$offset> is
the offset of all the occurrences of the list in the document.
C<$word_length> is the length of the word string. C<$maximal>
indicates if the occurrence is a maximal noun phrase.

=head2 getPOS()

    getPOS();

The method returns the Part-Of-Speech tag of the word associated to
the term candidate.

=head2 getIF()

    getIF();

The method returns the inflected form of the word associated to the
term candidate.


=head2 addMonolexicalOccurrences()

    addMonolexicalOccurrences($phrase_set,$monolexical_transfer_h);

The method adds a list new occurrences C<$phrase_set> to the list of
occurrences of the current term candidate.

C<$monolexical_transfer_h> is a reference to a hashtable containing
the phrases that can not be parsed (monolexical phrase are considered
as unparsable).


=head2 getHeadAndLinks()

    getHeadAndLinks($LGPmapping_h);

The method returns the head of the current term candidate (the term
candidate itself) and a reference to an empty array containing the
syntactic relations.

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
