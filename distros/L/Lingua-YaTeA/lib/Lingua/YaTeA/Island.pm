package Lingua::YaTeA::Island;
use strict;
use warnings;

our $id = 0;

our $VERSION=$Lingua::YaTeA::VERSION;

sub new
{
    my ($class,$index,$type,$source) = @_;
    my $this = {};
    bless ($this,$class);
    $this->{ID} = $id++;
    $this->{INDEX_SET} = $index;
    $this->{TYPE} = $type;
    $this->{SOURCE} = $source;
    $this->{INTEGRATED} = 0;
    return $this;
}

sub getIndexSet
{
    my ($this) = @_;
    return $this->{INDEX_SET};
}

sub isIntegrated
{
    my ($this) = @_;
    return $this->{INTEGRATED};
}


sub getType
{
    my ($this) = @_;
    return $this->{TYPE};

}

sub getParsingMethod
{
    my ($this) = @_;
    return $this->getSource->getParsingMethod;
}

sub getIF
{
    my ($this) = @_;
    return $this->getSource->getIF;
}

sub getSource
{
    my ($this) = @_;
    return $this->{SOURCE};
}



sub getID
{
    my ($this) = @_;
    return $this->{ID};

}

sub importNodeSets
{
    my ($this) = @_;
    my $node_sets_a;
    my $tree;
    my $node_set;
    $node_sets_a = $this->getSource->exportNodeSets;
    
    foreach $node_set (@$node_sets_a)
    {
	$node_set->updateLeaves($this->getIndexSet);
    }
    return $node_sets_a;
}

sub gapSize
{
    my ($this) = @_;
    my $i;
    my $gap =0;
    my $index = $this->getIndexSet->getIndexes->[0];
    for ($i=1; $i < scalar @{$this->getIndexSet->getIndexes}; $i++)
    {
	if($this->getIndexSet->getIndexes->[$i] != $index + 1)
	{
#	    return 0;
	    $gap += $this->getIndexSet->getIndexes->[$i] - $index;
	}
	$index = $this->getIndexSet->getIndexes->[$i];
    }
    return $gap;
}


sub print
{
    my ($this,$fh) = @_;

    if(defined $fh)
    {
	print $fh "form: " . $this->getIF;
	print $fh " - indexes: "; 
	$this->getIndexSet->print($fh);
	print $fh "- parsing method : " . $this->getParsingMethod;
	print $fh " - type: " . $this->getType . "\n";
	

    }
    else
    {
	print "form: " . $this->getIF;
	print " - indexes: "; 
	$this->getIndexSet->print;
	print " - type: " . $this->getType . "\n";
    }
}


1;


__END__

=head1 NAME

Lingua::YaTeA::Island - Perl extension for island of reliability

=head1 SYNOPSIS

  use Lingua::YaTeA::Island;
  Lingua::YaTeA::Island->new($index,$type,$source);

=head1 DESCRIPTION


This module reprensents the I<island of reliability> and provided
related methods for manipulating if. An island of reliability is a
subsequence (contiguous or not) of a Maximal Noun Phrase (MNP) that
corresponds to a shorter term candidate that was parsed during the
first step of the parsing process.

An island is defined with a list of parsed  phrase (i.e. the sequence of
Part-of-Speech tags) corresponding to the current island (field
C<SOURCE>), the index set for the parsed phrase corresponding to the current
island (field C<INDEX_SET>), the origin of the island (field C<TYPE> ;
value C<endogenous> if issued from the parsing of the current text,
C<exogenous> if issued fom an input resource or previous text
parsing).

An identifier (recorded in the field C<ID> is associated to the
isalnd. the information that the island is used in the parsing of a
wider parsed phrase or island, is recorded in the field C<INTEGRATED> (the
default value is 0).

=head1 METHODS


=head2 new()

    new($index,$type,$source);

The method defined a new island. C<$source> is the list of parsed phrase 
(i.e. the concatenation of Part-of-Speech tags or the key of the
pharses) corresponding to the island. C<$index> is the index set for
the parsed phrase corresponding to the current island. C<$type> is the
origin of the island (value C<endogenous> if issued from the parsing
of the current text, C<exogenous> if issued fom an input resource or
previous text parsing).

=head2 getIndexSet()

    getIndexSet();

The method returns the index set for the parsed phrase corresponding to the
current island.

=head2 getType()

    getType();

The method returns the origin of the island (C<endogenous> or
C<exogenous>).

=head2 getParsingMethod()

     getParsingMethod();

The method return the parsing methods associated to the parsed phrase
corresponding to the island of reliability.

=head2 getIF()

    getIF();

The method returns the inflected form of the parsed phrase
corresponding to the island of reliability.


=head2 getSource()

    getSource();

The method return the parsed phrase (i.e. the sequence of
Part-of-Speech tags) corresponding to the island of reliability.


=head2 getID()

    getID();

The method returns the identifier of the island.


=head2 importNodeSets()

    importNodeSets();

This method returns a copu of the node sets corresponding to the
island. The methods also updates the index set of the island.

=head2 gapSize()

    gapSize();

The method returns the number of words into the word sequence
delimited by the island island but not appearing in the island.

=head2 print()

    print($fh);

The pethod prints the island into the stream C<$fh>.

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
