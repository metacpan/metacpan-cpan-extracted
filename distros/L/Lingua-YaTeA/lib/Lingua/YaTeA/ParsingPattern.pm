package Lingua::YaTeA::ParsingPattern;
use strict;
use warnings;

use Lingua::YaTeA::NodeSet;
use Lingua::YaTeA::InternalNode;
use Lingua::YaTeA::RootNode;
use Lingua::YaTeA::PatternLeaf;
# use Data::Dumper;
 
our $VERSION=$Lingua::YaTeA::VERSION;

sub new
{
    my ($class,$parse,$pos_sequence,$node_set,$priority,$direction,$num_content_words,$num_line) = @_;
    my $this = {};
    bless ($this,$class);
    $this->{PARSE} = $parse;
    $this->{PRIORITY} = $priority;
    $this->{PARSING_DIRECTION} = $direction;
    $this->{DECLARATION_LINE} = $num_line;
    $this->{POS_SEQUENCE} = $pos_sequence;
    $this->{NODE_SET} = $node_set;
    $this->{CONTENT_WORDS} = $num_content_words;
    return $this;
}

sub setNodeSet
{
    my ($this,$node_set) = @_;
    $this->{NODE_SET} = $node_set;
}



sub getParse
{
    my ($this) = @_;
    return $this->{PARSE};
}


sub getLength
{
    my ($this) = @_;
    my @array = split (/ /, $this->getPOSSequence);
    return scalar @array;
}


sub getPriority
{
    my ($this) = @_;
    return $this->{PRIORITY};
}

sub getDirection
{
    my ($this) = @_;
    return $this->{PARSING_DIRECTION};
}

sub getNodeSet
{
    my ($this) = @_;
    return $this->{NODE_SET};
}

sub getNumContentWords
{
    my ($this) = @_;
    return $this->{CONTENT_WORDS};
}

sub getPOSSequence
{
    my ($this) = @_;
    return $this->{POS_SEQUENCE};
}

sub print
{
    my ($this) = @_;
   
    print "\t[\n";
    print "\tPARSE: " . $this->getParse . "\n";
    print "\tPOS: " . $this->getPOSSequence . "\n";
    print "\tPRIORITY: " . $this->getPriority . "\n";
    print "\tPARSING_DIRECTION: " . $this->getDirection . "\n";
    print "\tNODE_SET: \n";
    $this->getNodeSet->print;
    print "]\n";
}


1;


__END__

=head1 NAME

Lingua::YaTeA::ParsingPattern - Perl extension for parsing pattern

=head1 SYNOPSIS

  use Lingua::YaTeA::ParsingPattern;
  Lingua::YaTeA::ParsingPattern->new($parse,$pos_sequence,$node_set,$priority,$direction,$num_content_words,$num_line);

=head1 DESCRIPTION

The module implements a parsing pattern, i.e. the structure used to
parse noun phrases or identify reliability islands. Several field
decribe it. C<PARSE> is the string defining the parsing pattern, and
C<NODE_SET> is the tree representing the parsing pattern. The priority
of the parsing pattern is recorded in the field C<PRIORITY>. The field
C<PARSING_DIRECTION> contains the parsing direction of the
pattern. The field C<DELARACTION_LINE> is the line number of the
parsing pattern in the file. the Part-Of-Speech sequence is stored in
the field C<POS_SEQUENCE> and the number of content words is recorded
in the field C<CONTENT_WORDS>.

=head1 METHODS

=head2 new()

    new($parse,$pos_sequence,$node_set,$priority,$direction,$num_content_words,$num_line);

The method creates a new parsing pattern. The field C<PARSE> is set
with C<$parse>. C<$pos_sequence> sets the field C<POS_SEQUENCE>. the
fiekd C<NODE_SET> is set with C<$node_set>. C<$priority> is the value
of the field C<PRIORITY>. The direction of parsing
(C<PARSING_DIRECTION>) is set with C<$direction>. The variable
C<$num_line> sets the field C<DECLARATION_LINE>, and the field
C<CONTENT_WORDS> is set with C<$num_content_words>.


=head2 setNodeSet()

    setNodeSet($node_set);

This method sets the node set (field C<NODE_SET>).

=head2 getParse()

    getParse();

The method returns the string designing the parsing pattern (field
C<PARSE>).

=head2 getLength()

    getLength();

The method returns the number of elements of the parsing patterns.

=head2 getPriority()

    getPriority();

The method returns the priority of the parsing pattern (field
C<PRIORITY>).

=head2 getDirection()

    getDirection();

The method returns the parsing direction of the parsing pattern (field
C<PARSING_DIRECTIONa>).

=head2 getNodeSet()

    getNodeSet();

The method returns the set of nodes corresponding to the parsing
pattern (field C<NODE_SET>).

=head2 getNumContentWords()

    getNumContentWords();

The method returns the number of content words of the parsing pattern
(field C<CONTENT_WORD>).

=head2 getPOSSequence()

    getPOSSequence();

The method returns the Part-Of-Speech sequence of the parsing pattern
(field C<POS_SEQUENCE>).

=head2 print()

    print();

The method prints the information related to the parsing pattern.


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
