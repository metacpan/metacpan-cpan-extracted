package Lingua::YaTeA::TagSet;
use strict;
use warnings;

our $VERSION=$Lingua::YaTeA::VERSION;


sub new
{
    my ($class,$file_path) = @_;
    my $this = {};
    bless ($this,$class);
    $this->{CANDIDATES} = {};
    $this->{PREPOSITIONS} = {};
    $this->{DETERMINERS} = {};
    $this->{COORDINATIONS} = {};
    $this->{ANY} = {};
    $this->loadTags($file_path);
    return $this;
}

sub loadTags
{
    my ($this,$file_path) = @_;
    
    my $fh = FileHandle->new("<$file_path");
    my $line;
    while ($line= $fh->getline)
    {
	if(($line !~ /^\s*$/)&&($line !~ /^\s*#/)) # line is not empty nor commented
	{
	    $this->parseSubset($line);
	}
    }
}


sub addTag
{
    my ($this,$subset,$tag) = @_;
    $this->getSubset($subset)->{$tag}++;
    $this->getSubset("ANY")->{$tag}++;
}

sub getSubset
{
    my ($this,$subset) = @_;
    return $this->{$subset};
}

sub getTagList
{
    my ($this,$subset) = @_;
    return $this->getSubset($subset)->{"ALL"};
}



sub existTag
{
    my ($this,$subset,$tag) = @_;
    if (exists $this->getSubset($subset)->{$tag})
    {
	return 1;	
    }
    return 0;
}

sub parseSubset
{
    my ($this,$line) = @_;
    my $subset_name;
    my @tags;
    my $tag;
    if($line =~ s/\!\!([\S^=]+)\s*=\s*\(\(([^\!]+)\)\)\!\!\s*$/$2/)
    {
	$subset_name = $1;
	@tags = split /\)\|\(/, $line;
	foreach $tag (@tags)
	{
	    $this->addTag($subset_name,$tag);
	}
	$this->makeALL($subset_name,\@tags);
    }
    else
    {
	die "declaration d'etiquettes: erreur\n";
    }
}

sub makeALL
{
    my ($this,$subset,$tags_a) = @_;
    ${$this->{$subset}}{"ALL"} = $this->sort($tags_a);
}



sub sort
{
    my ($this,$tags_a) = @_;
    my @tmp = reverse (sort @$tags_a);
    my $joint = "\)|\(";
    my $sorted_tag_list = join ($joint,@tmp);
    $sorted_tag_list = "\(\(" .  $sorted_tag_list . "\)\)";
    return $sorted_tag_list;
}

1;

__END__

=head1 NAME

Lingua::YaTeA::TagSet - Perl extension for managing the set of Part-of-Speech
tags and inflected that can be accepted in the terms.

=head1 SYNOPSIS

  use Lingua::YaTeA::TagSet;
  Lingua::YaTeA::TagSet->new();

=head1 DESCRIPTION

This module provides methods for managing a set of Part-of-Speech tags
of inflected forms that can be accepted in the terms to extract. Such
lists of tags or inflected form are used by the Parsing Patterns while
the syntactic analusys of the maximal noun phrases. This information
is generally stored in the c<TagSet> configuration file. The
definition of the different classes is provided: C<CANDIDATES}>(the content words),
C<DETERMINERS> (the determiner words), C<PREPOSITIONS> (the preposition words) and C<COORDINATIONS> (the coordination words).

=head1 METHODS

=head2 new()

    $file = "/home/thierry/YaTeAconfig/EN/TagSet";
    new($file);

This method creates an object with 5 fields C<CANDIDATES>,
C<PREPOSITIONS>, C<DETERMINERS>, C<COORDINATIONS>, C<ANY> and loads
the tags contained in the file C<$file>. The field C<ANY> contains all
the tags. A field designates a class of tags and is a hash table.


=head2 loadTags()

    loadTags($file);

This method opens the file C<$file> and loads all the tagsets.

=head2 addTag()

    addTag($subset,$tag);

This method stores the tag C<$tag> in the right class C<$subset>.

=head2 getSubset()

    getSubset($subset);

This method returns the field of the current object that contains tags
of the class C<$subset>.


=head2 getTagList()

    getTagList($subset);

This method returns all the tags of the class C<$subset>.

=head2 existTag()

    existTag($subset,$tag);

This methods indicates whether the tag C<$tag> exists in the subset of
tags C<$subset> (it returns the value 1) or not (its returns the value
0). The field of the objet corresponding to the structure is set.

=head2 parseSubset()

    parseSubset($line);

This method parses a line containing the definition of a subset of
tags. it sets the corresponding field in the object calling the
method. In case of an error of format, the method dies. 

=head2 makeALL()

    makeALL($subset, \@tags);

The method sets the field C<ALL> of the subset C<$subset> with the
 tags contained in the array C<\@tags> given by reference. This field
 is a string containg a regex. Each tag is an alternative.

=head2 sort()

    sort(\@tags);

The method returns a regex where each element of the array given by
reference is a alternative and is sorted.


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
