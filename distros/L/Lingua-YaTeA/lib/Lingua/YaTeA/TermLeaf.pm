package Lingua::YaTeA::TermLeaf;
use Lingua::YaTeA::Edge;
use strict;
use warnings;

our @ISA = qw(Lingua::YaTeA::Edge);
our $VERSION=$Lingua::YaTeA::VERSION;

sub new
{
    my ($class,$index) = @_;
    my $this = $class->SUPER::new;
    $this->{INDEX} = $index;
    bless ($this,$class);
    return $this;
}


sub getIF
{
    my ($this,$words_a) = @_;
    return $words_a->[$this->getIndex]->getIF;
}



sub getPOS
{
    my ($this,$words_a) = @_;
    return $words_a->[$this->getIndex]->getPOS;
}

sub getLF
{
    my ($this,$words_a) = @_;
    return $words_a->[$this->getIndex]->getLF;
}

sub getID
{
    my ($this,$words_a) = @_;
    return $words_a->[$this->getIndex]->getID;
}


sub getIndex
{
    my ($this) = @_;
    return $this->{INDEX};
}

sub getLength
{
    my ($this,$words_a) = @_;
    return $words_a->[$this->getIndex]->getLength;
}

sub getWord
{
    my ($this,$words_a) = @_;
    return $words_a->[$this->getIndex];
}

sub searchHead
{
    my ($this) = @_;
    return $this;
}


sub print
{
    my ($this,$words_a,$fh) = @_;
    if(!defined $fh)
    {
	$fh = \*STDERR
    }
    if(defined $words_a)
    {
	 $this->printWords($words_a,$fh) ;	
	 print  $fh " (" . $this->getIndex. ")";
    }
    else
    {
	print $fh $this->getIndex;
    }
}

sub printWords
{
    my ($this,$words_a,$fh) = @_;
#     if(!defined $fh)
#     {
# 	$fh = \*STDERR
#     }
    print $fh $this->getIF($words_a);
}

sub searchRightMostLeaf
{
    my ($this,$depth_r) = @_;
    return $this;
}

sub searchLeftMostLeaf
{
    my ($this) = @_;
    return $this;
}

1;

__END__

=head1 NAME

Lingua::YaTeA::TermLeaf - Perl extension for leaf node of term tree

=head1 SYNOPSIS

  use Lingua::YaTeA::TermLeaf;
  Lingua::YaTeA::TermLeaf->new($index);

=head1 DESCRIPTION

This module implements the leaf node of a testified term represented
as tree. Objects inherit of the module C<Lingua::YaTeA::Edge>. 
A field C<INDEX> records the position of the associated word(s).


=head1 METHODS

=head2  new()

    new($index);

The method creates a new term leaf. C<$index> records the position of
the associated word(s).

=head2 getIF()

    getIF($words_a);

The method returns the inflected form of the term leaf. C<$words_a> is
the array containing the associated word.

=head2 getPOS()

    getPOS($words_a);

The method returns the Part-of-speech of the term leaf. C<$words_a> is
the array containing the associated word.


=head2 getLF()

    getLF($words_a);

The method returns the lemmatized form of the term leaf. C<$words_a>
is the array containing the associated word.

=head2 getID()

    getID($words_a);

The method returns the identifier of the term leaf. C<$words_a>
is the array containing the associated word.


=head2 getIndex()

    getIndex();

The method returns the position of the word associated to the term leaf.


=head2 getLength()

    getLength($words_a);

The method returns the length of the word associated to the term leaf.
C<$words_a> is the array containing the associated word.

=head2 getWord()

    getWord($words_a);

The method returns the word associated to the term leaf. C<$words_a>
is the array containing the associated word.

=head2 searchHead()

    searchHead();

The method returns the head of the current term leaf, i.e. the term
leaf itself.

=head2 print()

    print($words_a, $fh);

The method prints the term leaf in the file
descriptor C<$fh>.


=head2 printWords()

    printWords($words_a, $fh);

The method prints the inflected form of the words associated to the
term leaf (C<$words_a>) in the file descriptor C<$fh>.

=head2 searchRightMostLeaf()

    searchRightMostLeaf($depth_r);

The method returns the current term leaf as the right most term leaf.

=head2 searchLeftMostLeaf()

    searchLeftMostLeaf();

The method returns the current term leaf as the left most term leaf.



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
