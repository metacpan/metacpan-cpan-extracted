package Lingua::YaTeA::LexiconItem;
use strict;
use warnings;

our $counter =0;

our $VERSION=$Lingua::YaTeA::VERSION;

sub new
{
    my ($class,$form) = @_;
    my $this = {};
    bless ($this,$class);
    $this->{ID} = $counter;
    my @lex_infos = split /\t/, $form;
    $this->{IF} = $lex_infos[0];
    $this->{POS} = $lex_infos[1];
    $this->{LF} = $this->setLF($lex_infos[2],$this->{IF});
    $this->{LENGTH} = $this->setLength;
    $this->{FREQUENCY} = 0;
    return $this;
}


sub setLF
{
    my ($this,$LF,$IF) = @_;
    if (defined $LF) { 
	if ($LF =~ /(\<unknown\>)|(\@card@)/){ # si le lemme est inconnu du tagger (TTG) : lemme = forme flechie
	    return $IF;               
	} 
    } else {
	$LF = "";
    }
    return $LF;
} 

sub setLength
{
    my ($this) = @_;
    return length($this->{IF});
}

sub incrementFrequency
{
    my ($this) = @_;
    $this->{FREQUENCY}++;
}

sub getID
{
    my ($this) = @_;
    return $this->{ID};
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

sub getLength
{
    my ($this) = @_;
    return $this->{LENGTH};
}

sub getFrequency
{
    my ($this) = @_;
    return $this->{FREQUENCY};
}

sub getAny
{
    my ($this,$field) = @_;
    return $this->{$field};
}

sub isCleaningFrontier
{
    my ($this,$chunking_data) = @_;
    my @types = ("POS",  "LF", "IF");
    my $type;
    foreach $type (@types)
    {
	if ($chunking_data->existData("CleaningFrontiers",$type,$this->getAny($type)) == 1)
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
	if ($chunking_data->existData("CleaningExceptions",$type,$this->getAny($type)) == 1)
	{
	    return 1;
	}
    }
    return 0;
}

1;

__END__

=head1 NAME

Lingua::YaTeA::LexiconItem - Perl extension for representing word

=head1 SYNOPSIS

  use Lingua::YaTeA::LexiconItem;
  Lingua::YaTeA::LexiconItem->($form);

=head1 DESCRIPTION

The module implements the representation of the word occuring in the
lexicon of corpus. The word is described with its inflected form
(field C<$IF>), its Part-of-Speech tag (field C<POS>), it lemmatised
form (field C<LF>), the size in characters (field C<LENGTH>), its
frequency in the corpus (field C<FREQUENCY>).

=head1 METHODS

=head2 new()

    new($form);

The method creates a new lexicon item from the form C<$form>(the
concatenation of the inflected form, the Part-of-Speech tag, and the
lemmatised form).

=head2 setLF()

    setLF($LF,$IF);

The method set the field C<LF> (lemmatised form). If the C<$LF> is
equal to C<unknown> or C<@card@> (some default lemma from TreeTagger),
the inflected form is considered as the lemmatised form.

=head2 setLength()

    setLength();

The method computes the size in characters of the inflected form.

=head2 incrementFrequency()

    incrementFrequency();

The method increments the frequency of the lexicon item.

=head2 getID()

    getID();

The method returns the identifier of the lexicon item.

=head2 getIF()

    getIF();

The method returns the inflected form of the lexicon item.

=head2 getPOS()

    getPOS();

The method returns the Part-of-Speech of the lexicon item.

=head2 getLF()

    getLF();

The method returns the lemmatised form of the lexicon item.

=head2 getLength()

    getLength();

The method returns the size, in characters, of the inflected form of
the lexicon item.

=head2 getFrequency()

    getFrequency()

The method returns the frequency of the lexicon item.

=head2 getAny()

    getAny($field);

The method returns the value of the field C<$field>.

=head2 isCleaningFrontier()

    isCleaningFrontier($chunking_data);

The method indicates if the lexicon item apprears in one of the
cleaning frontier C<$chunking_data>.

=head2 isCleaningException()

    isCleaningException($chunking_data);

The method indicates if the lexicon item apprears in one of the
cleaning exception C<$chunking_data>.


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
