package Lingua::YaTeA::Sentence;
use strict;
use warnings;

our $counter = 0;
our $in_doc_counter = 0;
our $start_char = 0;

our $VERSION=$Lingua::YaTeA::VERSION;

sub new
{
    my ($class,$documents) = @_;
    my $this = {};
    bless ($this,$class);
     $this->{ID} = $counter;
    $this->{IN_DOC_ID} = $in_doc_counter;
    $this->{DOCUMENT} = $documents->getCurrent;
    return $this;
}

sub resetInDocCounter
{
    my ($class) = @_;
    $in_doc_counter = 0;
}

sub resetStartChar
{
    my ($class) = @_;
    $start_char = 0;
}

sub updateStartChar
{
    my ($class,$word) = @_;
    $start_char += $word->getLexItem->getLength +1;
}

sub getDocument
{
    my ($this) = @_;
    return $this->{DOCUMENT};
}

sub getID
{
    my ($this) = @_;
    return $this->{ID};
}

sub getInDocID
{
    my ($this) = @_;
    return $this->{IN_DOC_ID};
}


1;

__END__

=head1 NAME

Lingua::YaTeA::Sentence - Perl extension for sentence

=head1 SYNOPSIS

  use Lingua::YaTeA::Sentence;
  Lingua::YaTeA::Sentence->new($document);

=head1 DESCRIPTION

the module implements sentences of the document. An identifier (field
C<ID>) is associated to each sentence. The field C<IN_DOC_ID> records
the rank of the sentence in the document. The field C<DOCUMENT> is
the reference to the document object.

=head1 METHODS


=head2 new()

    new($document);

the method creates a new sentence and defined the reference given the
document C<$document>.


=head2 resetInDocCounter()

    resetInDocCounter();

The method resets the counter managing the sentence rank in a
document.

=head2 resetStartChar()

    resetStartChar()

The method resets the C<$start_char> offset.

=head2 updateStartChar()

    updateStartChar($word);

The method updates the C<$start_char> offset given the length of the
inflected form of the word C<$word>.


=head2 getDocument()

    getDocument();

The method returns the reference of the document which contains the
sentence.

=head2 getID()

    getID();

The method returns the sentence identifier.

=head2 getInDocID()

    getInDocID();

The method returns the rank of the sentence in the document.

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
