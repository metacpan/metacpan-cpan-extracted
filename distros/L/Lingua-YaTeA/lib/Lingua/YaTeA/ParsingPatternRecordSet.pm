package Lingua::YaTeA::ParsingPatternRecordSet;
use strict;
use warnings;

use Lingua::YaTeA::ParsingPatternRecord;
use Lingua::YaTeA::ParsingPattern;
use Lingua::YaTeA::ParsingPatternParser;

our $max_content_words = 0;

our $VERSION=$Lingua::YaTeA::VERSION;

sub new
{
    my ($class,$file_path,$tag_set,$message_set,$display_language) = @_;
    my $this = {};
    bless ($this,$class);
    $this->{PARSING_RECORDS} = {};
    $this->loadPatterns($file_path,$tag_set,$message_set,$display_language);
    return $this;
}

sub loadPatterns
{
    my ($this,$file_path,$tag_set,$message_set,$display_language) = @_;
  
    my $fh = FileHandle->new("<$file_path");


    my $parser = Lingua::YaTeA::ParsingPatternParser->new();

    $parser->YYData->{PPRS} = $this;
    $parser->YYData->{FH} = $fh;
    $parser->YYData->{CANDIDATES} = $tag_set->getTagList("CANDIDATES");
    $parser->YYData->{PREPOSITIONS} = $tag_set->getTagList("PREPOSITIONS");
    $parser->YYData->{DETERMINERS} = $tag_set->getTagList("DETERMINERS");

    $parser->YYParse(yylex => \&Lingua::YaTeA::ParsingPatternParser::_Lexer, yyerror => \&Lingua::YaTeA::ParsingPatternParser::_Error);

#     print STDERR "nberr: " . $parser->YYNberr() ."\n";
}


sub checkContentWords
{
    my ($this,$num_content_words,$num_line) = @_;
    if($num_content_words == 0)
    {
	die "No content word in pattern line " . $num_line . "\n";
    }
}

sub addPattern
{
    my ($this,$pattern) = @_;
    my $record;
    if (! $this->existRecord($pattern->getPOSSequence))
    {
	$record = $this->addRecord($pattern->getPOSSequence);
    }
    else
    {
	$record = $this->getRecord($pattern->getPOSSequence);
    }
    $record->addPattern($pattern);
}

sub getRecord
{
    my ($this,$name) = @_;
    return $this->{PARSING_RECORDS}->{$name};
}

sub addRecord
{
    my ($this,$name) = @_;
    $this->{PARSING_RECORDS}->{$name} = Lingua::YaTeA::ParsingPatternRecord->new($name);    

}

sub existRecord
{
    my ($this,$name) = @_;
    if (exists $this->{PARSING_RECORDS}{$name})
    {
	return $this->{PARSING_RECORDS}{$name};
    }
    return 0;
}

sub getRecordSet
{
    my ($this) = @_;
    return $this->{PARSING_RECORDS};
	
}


sub print
{
    my ($this) = @_;
    my $record;
    foreach $record (values %{$this->getRecordSet})
    {
	$record->print;
    }
}



1;


__END__

=head1 NAME

Lingua::YaTeA::ParsingPatternRecordSet - Perl extension for managing the set of the parsing patterns

=head1 SYNOPSIS

  use Lingua::YaTeA::ParsingPatternRecordSet;
  Lingua::YaTeA::ParsingPatternRecordSet->new($file_path,$tag_set,$message_set,$display_language);

=head1 DESCRIPTION

The module aims at managing the set of parsing pattern records used in
the term extraction process. Each parsing pattern is associated to a
record designated by a name defined as the concatenation of the
Part-of-Speech tags of the parsing pattern. The module provides
methods for managing the sets of parsing patterns read from a config
file. The parsing patterns are stored in the field C<PARSING_RECORDS>.

=head1 METHODS


=head2 new()

 new($file_path,$tag_set,$message_set,$display_language);


The method creates a new parsing pattern set. The parsing patterns are
read from the config file C<$file_path>. The parameter C<$tag_set>
provides sets of tags for the candidats, prepositions and determiners
(this information has been previously loaded thanks to a another
module). The parameters C<$message_set> and C<display_language> are
used for printing related information in the right language.

=head2 loadPatterns()

    loadPatterns($file_path,$tag_set,$message_set,$display_language);

The method calls the parser of the file (C<$file_path>) containing the parsing patterns.

creates a new parsing pattern set. The parameter C<$tag_set> provides
sets of tags for the candidats, prepositions and determiners (this
information has been previously loaded thanks to a another
module). The parameters C<$message_set> and C<display_language> are
used for printing related information in the right language.

=head2 checkContentWords()

    checkContentWords($num_content_words,$num_line);

The method checks if there is at least a content word or a
part-of-speech tag referring a content word in the pattern, otherwise
it dies.

=head2 addPattern()

    addPattern($pattern);

The method adds the pattern C<$pattern> in the current record of the
parsing pattern set.

=head2 getRecord()

    getRecord($name);

The method returns the record of parsing pattern designated by the
name C<$name> (the concatenation of the Part-of-Speech tags).

=head2 addRecord()

    addRecord($name);

The method creates a new record designated by the
name C<$name> (the concatenation of the Part-of-Speech tags).

=head2 existRecord()

    existRecord($name);

The method checks if it exists a record designated by the
name C<$name> (the concatenation of the Part-of-Speech tags).

=head2 getRecordSet()

    getRecordSet();

The method returns the set of parsing pattern records.

=head2 print()

The method prints the set of parsing pattern records.

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
