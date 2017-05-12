package Lingua::YaTeA::DocumentSet;
use strict;
use warnings;
use Lingua::YaTeA::Document;
use Lingua::YaTeA::WordFromCorpus;

our $VERSION=$Lingua::YaTeA::VERSION;

sub new
{
    my ($class) = @_;
    my $this = {};
    bless ($this,$class);
    $this->{DOCUMENTS} = [];
    $this->addDefaultDocument;
    return $this;
}


sub getDocuments
{
    my ($this) = @_;
    return $this->{DOCUMENTS};
}

sub addDefaultDocument
{
    my ($this,$word) = @_;
    push @{$this->{DOCUMENTS}}, Lingua::YaTeA::Document->newDefault;
}

sub addDocument
{
    my ($this,$word) = @_;
    if($Lingua::YaTeA::WordFromCorpus::counter==1)
    {
   	$this->getCurrent->update($word);
    }
    else{
	$Lingua::YaTeA::Document::counter++;
	push @{$this->{DOCUMENTS}}, Lingua::YaTeA::Document->new($word);
    }

}


sub getCurrent
{
    my ($this)= @_;
    return $this->{DOCUMENTS}[-1];
}

sub getDocumentNumber
{
    my ($this) = @_;
    return scalar @{$this->{DOCUMENTS}};
}

1;

__END__

=head1 NAME

Lingua::YaTeA::DocumentSet - Perl extension for document set

=head1 SYNOPSIS

  use Lingua::YaTeA::DocumentSet;
  Lingua::YaTeA::DocumentSet->new();

=head1 DESCRIPTION

The module implements the document set. Documents are stored in an
array (the attribut C<DOCUMENT> is a reference to this array).

=head1 METHODS

=head2 new()

The method creates a set of documents and returns it.

=head2 getDocuments()

    getDocuments();

The method returns the set of document as a reference to an array.


=head2 addDefaultDocument()

    addDefaultDocument();

The method initiates a new document with an empty word.

=head2 addDocument()

    addDocument($word);

The method adds a word to the current document.

=head2 getCurrent()

    getCurrent();

The method returns the current document (i.e. the last document).


=head2 getDocumentNumber()

    getDocumentNumber();

The method returns the size of the document set (i.e. the number of
documents in the set).


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
