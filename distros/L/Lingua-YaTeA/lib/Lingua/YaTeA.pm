package Lingua::YaTeA;

use strict;
use warnings;
use utf8;

=encoding utf8

=head1 NAME

Lingua::YaTeA - Perl extension for extracting terms from a corpus and providing a syntactic analysis in a head-modifier format.

=head1 SYNOPSIS

use Lingua::YaTeA;

my %config = Lingua::YaTeA::load_config($rcfile);

$yatea = Lingua::YaTeA->new($config{"OPTIONS"}, \%config);

$corpus = Lingua::YaTeA::Corpus->new($corpus_path,$yatea->getOptionSet,$yatea->getMessageSet);

$yatea->termExtraction($corpus);


=head1 DESCRIPTION

This module is the main module of the software named YaTeA. It aims at
extracting noun phrases that look like terms from a corpus.  It
provides their syntactic analysis in a head-modifier representation.
As an input, the term extractor requires a corpus which has been
segmented into words and sentences, lemmatized and tagged with
part-of-speech (POS) information. The input file is encoded in
UTF-8. The implementation of this term extractor allows to process
large corpora.  Data provided with YaTeA allow to extract terms from
English and French texts.  But new linguistic features can be
integrated to extract terms from another language. Moreover,
linguistic features can be modified or created for a sub-language or
tagset.

For the use of YaTeA, see the documentation with the script C<yatea>.

The main strategy of analysis of the term candidates is based on the
exploitation of simple parsing patterns and endogenous
disambiguation. Exogenous disambiguation is also made possible for the
identification and the analysis of term candidates by the use of
external resources, I<i.e.> lists of testified terms.

=head2 ANALYSIS: ENDOGENOUS AND EXOGENOUS DISAMBIGUATION

Endogenous disambiguation consists in the exploitation of intermediate
chunking and parsing results for the parsing of a given Maximal Noun
Phrase (MNP). This feature allows the parse of complex noun phrases
using a limited number of simple parsing patterns (80 patterns
containing a maximum of 3 content words in the experiments described
below). All the MNPs corresponding to parsing patterns are parsed
first. In a second step, remaining unparsed MNPs are processed using
the results of the first step as I<islands of reliability>.  An
I<island of reliability> is a subsequence (contiguous or not) of a MNP
that corresponds to a shorter term candidate that was parsed during
the first step of the parsing process. This subsequence along with its
internal analysis is used as an anchor in the parsing of the
MNP. Islands are used to simplify the POS sequence of the MNP for
which no parsing pattern was found. The subsequence covered by the
island is reduced to its syntactic head. In addition, islands increase
the degree of reliability of the parse. When no resource is provided
and as there is no parsing pattern defined for the complete POS
sequence "NN NN NN of NN" corresponding to the term candidate
"Northern blot analysis of cwlH", the progressive method is
applied. In such a case, the TC is bracketed from the right to the
left, which results in a poor quality analysis. When considering the
island of reliability "northern blot analysis", the correct bracketing
is found.


=head1 METHODS

=head2 load_config()

    load_config($rcfile);

The method loads the configuration of the NLP Platform by reading the
configuration file given in argument. It returns the hashtable
containing the configuration.

=head2 new()

    new($command_line_options_h,$system_config_h);

The methods creates a new term extractor and sets oprtions from the
command line (C<$commend_line_options_h>) and options defined in the
hashtable (C<$system_config_h>) given by address. The methods returns
the created object.

=head2 termExtraction()

    termExtraction($corpus);

This method applies a extraction process on the corpus C<$corpus>
given as parameter, and stores results in the directories specified in
the configuration files.


=head2 setOptions()

    setOptions($command_line_options_h);

This method creates an option set. It sets the options defined in the
hashtable C<$command_line_options_h> (given by reference) and checks
if the C<language> parameter is defined in the configuration.


=head2 setConfigFiles()

    setConfigFiles($this,$system_config_h);


=head2 setLocaleFiles()

    setLocaleFiles($this,$system_config_h);

=head2 addOptionsFromFile()

    addOptionsFromFile($this);


=head2 setMessageSet()

    setMessageSet($this,$system_config_h);


=head2 setTagSet()

    setTagSet($this);

=head2 setParsingPatterns()

    setParsingPatterns($this);


=head2 setChunkingDataSet()

    setChunkingDataSet($this);

=head2 setForbiddenStructureSet()

    setForbiddenStructureSet($this);



=head2 loadTestifiedTerms()

    loadTestifiedTerms($this,$process_counter_r,$corpus,$sentence_boundary,$document_boundary,$match_type,$message_set,$display_language);



=head2 setTestifiedTermSet()

    setTestifiedTermSet($this,$filtering_lexicon_h,$sentence_boundary,$match_type);



=head2 getTestifiedTermSet()

    getTestifiedTermSet($this);



=head2 getFSSet()

    getFSSet($this);



=head2 getConfigFileSet

    getConfigFileSet($this);



=head2 getLocaleFileSet()

    getLocaleFileSet($this);



=head2 getResultFileSet()

    getResultFileSet($this);



=head2 getOptionSet()

    getOptionSet($this);

This method returns the field C<OPTION_SET>.

=head2 getTagSet()

    getTagSet($this);



=head2 getChunkingDataSet()

    getChunkingDataSet($this);



=head2 getParsingPatternSet()

    getParsingPatternSet($this);


=head2 getMessageSet()

    getMessageSet($this);



=head2 getTestifiedSet()

    getTestifiedSet($this);



=head2 addMessageSetFile()

    addMessageSetFile($this);



=head2 displayExtractionResults()

    displayExtractionResults($this,$phrase_set,$corpus,$message_set,$display_language,$default_output);




=head1 CONFIGURATION

The configuration file of YaTeA is divided into two sections:

=over 

=item * Section C<DefaultConfig>

=over

=item * 

C<CONFIG_DIR> : directory containing the configuration files according to the language

=item * 

C<LOCALE_DIR> : directory containing the environment files according to the language

=item * 

C<RESULT_DIR> : directory where are stored the results (probably not useful)

=back

=item * Section C<OPTIONS>

=over

=item * 

C<language> I<language> : Definition of the language of the
corpus. Values are either C<FR> (French - TreeTagger output - TagSet
<http://www.ims.uni-stuttgart.de/~schmid/french-tagset.html>),
C<FR-Flemm> (French - output of Flemm analyser or C<EN> (English -
TreeTagger or GeniaTagger output - PennTreeBank Tagset)


=item * 

C<suffix> I<suffix> : Specification of a name for the current version
of the analysis. Results are gathered in a specific directory of this
name and result files also carry this suffix

=item *

C<output-path> : set the path to the directory that will contain the
 results for the current corpus (default: working directory)

=item * 

C<termino> I<File> : Name of a file containing a list of
testified terms. 

=item * 

C<monolexical-all> : all occurrences of monolexical phrases
are considered as term candidates. The value is 0 or 1.

=item * 

C<monolexical-included> : occurrences of monolexical term
candidates that appear in complex term candidates are also displayed. The value is 0 or 1.

=item * 

C<match-type> [loose or strict] :

=over

=item * 

C<loose> : testified terms match either inflected or lemmatized forms of each word

=item * 

C<strict> : testified terms match the combination of inflected form and POS tag of each word

=item * 

unspecified option: testified terms match match inflected forms of words

=back

=item * 

C<xmlout> : display of the parsed term candidates in XML format. The
value is 0 or 1.

=item * 

C<termList> : display of a list of terms and sub-terms along with
their frequency. To display only term candidates containing more than
one word (multi-word term candidates), specify the value C<multi>.
All term candidates will be displayed , monolexical and multi-word
term candidates with the value C<all>, or if any value is specified.

=item * 

C<printChunking> : displays of the corpus marked with phrases in a
HTML file along with the indication that they are term candidates or
not. The value is 0 or 1.

=item * 

C<TC-for-BioLG> : annotation of the corpus with term candidates in a
XML format compatible with the BioLG software. The value is 0 or 1.

=item * 

C<TT-for-BioLG> : annotation of the corpus with testified terms in a
XML format compatible with the BioLG software. The value is 0 or 1.
(http://www.it.utu.fi/biolg/, biological tuned version of the Link
Grammar Parser)

=item * 

C<XML-corpus-for-BioLG> : creation of a BioLG compatible XML version
of the corpus with PoS tags marked form each word. The value is 0 or 1.

=item * 

C<debug> : displays informations on parsed phrases (i.e. term
candidates) in a text format. The value is 0 or 1.


=item * 

C<annotate-only> : only annotate testified terms (no acquisition). The
value is 0 or 1.

=item * 

C<TTG-style-term-candidates> : term candidates are displayed in
TreeTagger output format. Term separator is the sentence boundary tag
C<SENT>. To extract only term candidates containing more than one
word (multi-word term candidates), specify the option C<multi>. 
All term candidates will be displayed , monolexical and multi-word
term candidates with the value C<all>, or if any value is specified.

=back

=back

=head1 CONTRIBUTORS

=over

=item *

Charlotte Roze has defined the configuration files to process a corpus
tagged with Flemm

=item * 

Wiktoria Golik, Robert Bossy and Claire Nédellec (MIG/INRA) have
corrected bugs and improve the mapping of testified terms.


=back

=head1 SEE ALSO

Sophie Aubin and Thierry Hamon. Improving Term Extraction with
Terminological Resources. In Advances in Natural Language Processing
(5th International Conference on NLP, FinTAL 2006). pages
380-387. Tapio Salakoski, Filip Ginter, Sampo Pyysalo, Tapio Pahikkala
(Eds). August 2006. LNAI 4139.

=head1 AUTHORS

Thierry Hamon <thierry.hamon@univ-paris13.fr> and Sophie Aubin <sophie.aubin@lipn.univ-paris13.fr>

=head1 LICENSE

Copyright (C) 2005 by Thierry Hamon and Sophie Aubin

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.


=cut

use Data::Dumper;
use Lingua::YaTeA::ParsingPatternRecordSet;
use Lingua::YaTeA::OptionSet;
use Lingua::YaTeA::Option;
use Lingua::YaTeA::FileSet;
use Lingua::YaTeA::MessageSet;
use Lingua::YaTeA::TagSet;
use Lingua::YaTeA::ChunkingDataSet;
use Lingua::YaTeA::ForbiddenStructureSet;
use Lingua::YaTeA::PhraseSet;
use Lingua::YaTeA::TestifiedTermSet;

use Config::General;

our $VERSION='0.622';

our $process_counter = 1;

sub load_config 
{

    my ($rcfile) = @_;
    
# Read de configuration file

    if ((! defined $rcfile) || ($rcfile eq "")) {
	$rcfile = "/usr/etc/yatea/yatea.rc";    
    }
    
    my $conf = new Config::General('-ConfigFile' => $rcfile,
				   '-InterPolateVars' => 1,
				   '-InterPolateEnv' => 1
				   );
    
    my %config = $conf->getall;
#    `mkdir -p $config{'ALVISTMP'}`; # to put in a specific method
    return(%config);
}


sub new
{
    my ($class,$command_line_options_h,$system_config_h) = @_;
    my $this = {};
    bless ($this,$class);
    $this->{OPTION_SET} = ();
    $this->{CONFIG_FILE_SET} = ();
    $this->{LOCALE_FILE_SET} = ();
    $this->{MESSAGE_SET} = ();
    $this->{TAG_SET} = ();
    $this->{PARSING_PATTERN_SET} = ();
    $this->{CHUNKING_DATA_SET} = ();
    $this->{FS_SET} = ();
    $this->{TESTIFIED_SET} = ();
    $this->setOptions($command_line_options_h);;
    $this->setConfigFiles($system_config_h);
    $this->addOptionsFromFile;
    $this->setLocaleFiles($system_config_h);
    $this->setMessageSet;
    $this->getOptionSet->handleOptionDependencies($this->getMessageSet);
    $this->getOptionSet->setDefaultOutputPath;
    $this->setTagSet;
    $this->setParsingPatterns;
    $this->setChunkingDataSet;
    $this->setForbiddenStructureSet;
    return $this;
}




sub termExtraction
{
    my ($this,$corpus) = @_;
    my $sentence_boundary = $this->getOptionSet->getSentenceBoundary;
    my $document_boundary = $this->getOptionSet->getDocumentBoundary;
    my $debug_fh = FileHandle->new(">".$corpus->getOutputFileSet->getFile('debug')->getPath);;
    binmode($debug_fh, ":utf8");
    $this->loadTestifiedTerms(\$process_counter,$corpus,$sentence_boundary,$document_boundary,$this->getOptionSet->MatchTypeValue,$this->getMessageSet,$this->getOptionSet->getDisplayLanguage);
    

    print STDERR $process_counter++ . ") " . ($this->getMessageSet->getMessage('LOAD_CORPUS')->getContent($this->getOptionSet->getDisplayLanguage)) . "\n";

    
#    warn "Language: " . $this->getOptionSet->getLanguage . "\n";

    $corpus->read($sentence_boundary,$document_boundary,$this->getFSSet,$this->getTestifiedTermSet,$this->getOptionSet->MatchTypeValue,$this->getMessageSet,$this->getOptionSet->getDisplayLanguage, $this->getOptionSet->getLanguage,$debug_fh);
    
    my $phrase_set = Lingua::YaTeA::PhraseSet->new;
    
    print STDERR $process_counter++ . ") " . ($this->getMessageSet->getMessage('CHUNKING')->getContent($this->getOptionSet->getDisplayLanguage)) . "\n";
    $corpus->chunk($phrase_set,$sentence_boundary,$document_boundary,$this->getChunkingDataSet,$this->getFSSet,$this->getTagSet,$this->getParsingPatternSet,$this->getTestifiedTermSet,$this->getOptionSet,$debug_fh);

    my $fh = FileHandle->new(">".$corpus->getOutputFileSet->getFile('unparsed')->getPath);
    binmode($fh, ":utf8");
    $phrase_set->printPhrases($fh);

#     print STDERR Dumper($phrase_set);

    $phrase_set->printChunkingStatistics($this->getMessageSet,$this->getOptionSet->getDisplayLanguage);
    if ((! defined $this->getOptionSet->getOption('annotate-only')) || ($this->getOptionSet->getOption('annotate-only')->getValue() == 0))
    {
	$phrase_set->sortUnparsed;
	
	print STDERR $process_counter++ . ") " . ($this->getMessageSet->getMessage('PARSING')->getContent($this->getOptionSet->getDisplayLanguage)) . "\n";
	
	$phrase_set->parseProgressively($this->getTagSet,$this->getOptionSet->getParsingDirection,$this->getParsingPatternSet,$this->getChunkingDataSet,$corpus->getLexicon,$corpus->getSentenceSet,$this->getMessageSet,$this->getOptionSet->getDisplayLanguage,$debug_fh);
	
	$phrase_set->printParsingStatistics($this->getMessageSet,$this->getOptionSet->getDisplayLanguage);
	
	if(
	    ((defined $this->getOptionSet->getOption('xmlout')) && ($this->getOptionSet->getOption('xmlout') == 1))
	    ||
	    ((defined $this->getOptionSet->getOption('termList')) && ($this->getOptionSet->getOption('termList') ne ""))
	    ||
	    ((defined $this->getOptionSet->getOption('printChunking')) && ($this->getOptionSet->getOption('printChunking')) == 1) 
	    ||
	    ((defined $this->getOptionSet->getOption('TC-for-BioLG')) && ($this->getOptionSet->getOption('TC-for-BioLG')) == 1)
	    ||
	    ((defined $this->getOptionSet->getOption('TTG-style-term-candidates')) && ($this->getOptionSet->getOption('TTG-style-term-candidates') ne ""))
	    ||
	    ($this->getOptionSet->getDefaultOutput == 1)
	    )
	{
	    $phrase_set->addTermCandidates($this->getOptionSet);
	    $corpus->makeDDW($phrase_set->getTermCandidates,$debug_fh);
	}
    }
    
    print STDERR $process_counter++ . ") " . ($this->getMessageSet->getMessage('RESULTS')->getContent($this->getOptionSet->getDisplayLanguage)) . "\n";
    
    $this->displayExtractionResults($phrase_set,$corpus,$this->getMessageSet,$this->getOptionSet->getDisplayLanguage,$this->getOptionSet->getDefaultOutput,$debug_fh);
    return(0);
}



sub setOptions
{
    my ($this,$command_line_options_h) = @_;
    my $options;

    $this->{OPTION_SET} = Lingua::YaTeA::OptionSet->new;
    
    $this->getOptionSet->addOptionSet($command_line_options_h,$this->getMessageSet,"EN");
    $this->getOptionSet->checkCompulsory("language");

}

sub setConfigFiles
{
    my ($this,$system_config_h) = @_;
    my $config_files;
    my $language = $this->getOptionSet->getLanguage;
#    print STDERR Dumper(%$system_config_h);
    my $repository = $system_config_h->{'DefaultConfig'}->{CONFIG_DIR} . "/" . $language;
   
    my @file_names = ("Options","ForbiddenStructures","ChunkingFrontiers","ChunkingExceptions","CleaningFrontiers","CleaningExceptions","ParsingPatterns","TagSet","LGPmapping");

    $this->{CONFIG_FILE_SET} = Lingua::YaTeA::FileSet->new($repository);

    $this->getConfigFileSet->checkRepositoryExists;
    
    $this->getConfigFileSet->addFiles($this->getConfigFileSet->getRepository,\@file_names);
}


sub setLocaleFiles
{
    my ($this,$system_config_h) = @_;
    my $config_files;
    my $repository = $system_config_h->{'DefaultConfig'}->{LOCALE_DIR} . "/";
    my @file_names = ("Messages");
    
    $this->{LOCALE_FILE_SET} = Lingua::YaTeA::FileSet->new($repository);
    $this->getLocaleFileSet->checkRepositoryExists;
    $this->addMessageSetFile;
}


sub addOptionsFromFile
{
    my ($this) = @_;
    
    $this->getOptionSet->readFromFile($this->getConfigFileSet->getFile("Options"));
}

sub setMessageSet
{
    my ($this,$system_config_h) = @_;
   
 
   $this->{MESSAGE_SET} = Lingua::YaTeA::MessageSet->new($this->getLocaleFileSet->getFile("Messages"),$this->getOptionSet->getDisplayLanguage);
}


sub setTagSet
{
    my ($this) = @_;
    $this->{TAG_SET} = Lingua::YaTeA::TagSet->new($this->getConfigFileSet->getFile("TagSet")->getPath);
#    print STDERR "Tagset loaded\n"
}

sub setParsingPatterns
{
    my ($this) = @_;
    $this->{PARSING_PATTERN_SET} = Lingua::YaTeA::ParsingPatternRecordSet->new($this->getConfigFileSet->getFile("ParsingPatterns")->getPath,$this->getTagSet,$this->getMessageSet,$this->getOptionSet->getDisplayLanguage);
#    print STDERR "Parsing Patterns loaded\n";
}

sub setChunkingDataSet
{
    my ($this) = @_;
    $this->{CHUNKING_DATA_SET} = Lingua::YaTeA::ChunkingDataSet->new($this->getConfigFileSet);
#    print STDERR "Chunking Data loaded\n";
}


sub setForbiddenStructureSet
{
    my ($this) = @_;
    $this->{FS_SET} = Lingua::YaTeA::ForbiddenStructureSet->new($this->getConfigFileSet->getFile("ForbiddenStructures")->getPath); 
#    print STDERR "Forbidden Structures loaded\n"
}


sub loadTestifiedTerms
{
    my ($this,$process_counter_r,$corpus,$sentence_boundary,$document_boundary,$match_type,$message_set,$display_language) = @_;
   
    my $filtering_lexicon_h;
    if	($this->getOptionSet->optionExists('termino'))
    {
	print STDERR "\n" . $$process_counter_r++ . ") " . $message_set->getMessage('LOADING_TESTIFIED')->getContent($display_language) . "\n";
	$filtering_lexicon_h = $corpus->preLoadLexicon($sentence_boundary,$document_boundary,$match_type);
	$this->setTestifiedTermSet($filtering_lexicon_h,$sentence_boundary,$match_type);
	print STDERR "\t" . $Lingua::YaTeA::TestifiedTerm::id . ($message_set->getMessage('TESTIFIED_LOADED')->getContent($display_language)) . "\n";
	$this->getTestifiedTermSet->changeKeyToID;
    }
    else
    {
# (($this->getOptionSet->getOption('TT-for-BioLG')->getValue() == 1) &&
 	# creation of an empty set of Testified Terms
	# TTforLGp can be used to build a XML version of the corpus compatible with BioLG, even if no testified terms are provided
	# if ($this->getOptionSet->optionExists('TT-for-BioLG'))
	# {
	    $this->{TESTIFIED_SET} = Lingua::YaTeA::TestifiedTermSet->new; 
	# }
    }
}


sub setTestifiedTermSet
{
    my ($this,$filtering_lexicon_h,$sentence_boundary,$match_type) = @_;
    my $file_path;
    $this->{TESTIFIED_SET} = Lingua::YaTeA::TestifiedTermSet->new; 

    $file_path = $this->getOptionSet->getOption('termino')->getValue; # modified by Thierry Hamon 05/02/2007
#     foreach $file_path (@{$this->getOptionSet->getOption('termino')->getValue})
#     {
	$this->getTestifiedSet->addSubset($file_path,$filtering_lexicon_h,$sentence_boundary,$match_type,$this->getTagSet);  
#     }
}


sub getTestifiedTermSet
{
    my ($this) = @_;
    return $this->{TESTIFIED_SET};
}



sub getFSSet
{
    my ($this) = @_;
    return $this->{FS_SET};
}

sub getConfigFileSet
{
    my ($this) = @_;
    return $this->{CONFIG_FILE_SET};
}

sub getLocaleFileSet
{
    my ($this) = @_;
    return $this->{LOCALE_FILE_SET};
}

sub getResultFileSet
{
    my ($this) = @_;
    return $this->{RESULT_FILE_SET};
}


sub getOptionSet
{
    my ($this) = @_;
    return $this->{OPTION_SET};
}

sub getTagSet
{
    my ($this) = @_;
    return $this->{TAG_SET};
}

sub getChunkingDataSet
{
    my ($this) = @_;
    return $this->{CHUNKING_DATA_SET};
}

sub getParsingPatternSet
{
    my ($this) = @_;
    return $this->{PARSING_PATTERN_SET};
}

sub getMessageSet
{
    my ($this) = @_;
    return $this->{MESSAGE_SET};
}

sub getTestifiedSet
{
    my ($this) = @_;
    return $this->{TESTIFIED_SET};
}

sub addMessageSetFile
{
    my ($this) = @_;
    my $repository = $this->getLocaleFileSet->getRepository;
    
    my $display_language = $this->getOptionSet->getLanguage; # default
    
    # if the language of message display is different from that of the processed text, the Messages file is searched in a different sister repository
    if(
	($this->getOptionSet->optionExists('MESSAGE_DISPLAY'))
	&&
	($this->getOptionSet->getDisplayLanguage ne $this->getOptionSet->getLanguage)
	)
    {
	$display_language = $this->getOptionSet->getDisplayLanguage;
    }

    $repository .=  $display_language ;
    $this->getLocaleFileSet->addFile($repository, 'Messages');
}

sub displayExtractionResults
{
    my ($this,$phrase_set,$corpus,$message_set,$display_language,$default_output,$debug_fh) = @_;

    
    
    if ((defined $this->getOptionSet->getOption('debug')) && ($this->getOptionSet->getOption('debug')->getValue() == 1))
    {
	print STDERR "\t-" . ($this->getMessageSet->getMessage('DISPLAY_RAW')->getContent($this->getOptionSet->getDisplayLanguage)) . "\'". $corpus->getOutputFileSet->getFile('debug')->getPath . "'\n";
	$phrase_set->printPhrases($debug_fh);
	$phrase_set->printUnparsable($corpus->getOutputFileSet->getFile('unparsable'));
#	$phrase_set->printUnparsed($corpus->getOutputFileSet->getFile('unparsed'));
    }

    if 
	(
	 ((defined $this->getOptionSet->getOption('xmlout')) && ($this->getOptionSet->getOption('xmlout')->getValue() == 1))
	 ||
	 ($default_output == 1)
	)
    {
	print STDERR "\t-" . ($this->getMessageSet->getMessage('DISPLAY_TC_XML')->getContent($this->getOptionSet->getDisplayLanguage)) . "\'". $corpus->getOutputFileSet->getFile('candidates')->getPath . "'\n";
	$phrase_set->printTermCandidatesXML($corpus->getOutputFileSet->getFile("candidates"),$this->getTagSet);
    }

    if ((defined $this->getOptionSet->getOption('printChunking')) && ($this->getOptionSet->getOption('printChunking')->getValue() == 1))
    {
	print STDERR "\t-" . ($this->getMessageSet->getMessage('DISPLAY_CORPUS_PHRASES')->getContent($this->getOptionSet->getDisplayLanguage)) . "\'". $corpus->getOutputFileSet->getFile('candidatesAndUnparsedInCorpus')->getPath . "'\n";
	
	$corpus->printCandidatesAndUnparsedInCorpus($phrase_set->getTermCandidates,$phrase_set->getUnparsable,$corpus->getOutputFileSet->getFile('candidatesAndUnparsedInCorpus'),$this->getOptionSet->getSentenceBoundary,$this->getOptionSet->getDocumentBoundary,$this->getOptionSet->getOption('COLOR_BLIND'));
    }

    if ((defined $this->getOptionSet->getOption('TC-for-BioLG')) && ($this->getOptionSet->getOption('TC-for-BioLG')->getValue() == 1)) 
    {
	print STDERR "\t-" . ($this->getMessageSet->getMessage('TC_FOR_LGP')->getContent($this->getOptionSet->getDisplayLanguage)) . "\'". $corpus->getOutputFileSet->getFile('TCforBioLG')->getPath . "'\n";
	$corpus->printCorpusForLGPwithTCs($phrase_set->getTermCandidates,$corpus->getOutputFileSet->getFile('TCforBioLG'),$this->getOptionSet->getSentenceBoundary,$this->getOptionSet->getDocumentBoundary,$this->getConfigFileSet->getFile("LGPmapping"),$this->getOptionSet->getChainedLinks,$this->getTagSet);
    }

    if ((defined $this->getOptionSet->getOption('TT-for-BioLG')) && ($this->getOptionSet->getOption('TT-for-BioLG')->getValue() == 1))
    {
	print STDERR "\t-" . ($this->getMessageSet->getMessage('TT_FOR_LGP')->getContent($this->getOptionSet->getDisplayLanguage)) . "\'". $corpus->getOutputFileSet->getFile('TTforBioLG')->getPath . "'\n";
	$corpus->printCorpusForLGPwithTTs($this->getTestifiedTermSet->getTestifiedTerms,$corpus->getOutputFileSet->getFile('TTforBioLG'),$this->getOptionSet->getSentenceBoundary,$this->getOptionSet->getDocumentBoundary,$this->getConfigFileSet->getFile("LGPmapping"),$this->getOptionSet->getParsingDirection,$this->getOptionSet->getChainedLinks,$this->getTagSet);
    }

    if ((defined $this->getOptionSet->getOption('XML-corpus-for-BioLG')) && ($this->getOptionSet->getOption('XML-corpus-for-BioLG')->getValue() == 1))
    {
	print STDERR "\t-" . ($this->getMessageSet->getMessage('XML_FOR_BIOLG')->getContent($this->getOptionSet->getDisplayLanguage)) . "\'". $corpus->getOutputFileSet->getFile('corpusForBioLG')->getPath . "'\n";
	$corpus->printCorpusForBioLG($corpus->getOutputFileSet->getFile('corpusForBioLG'),$this->getOptionSet->getSentenceBoundary,$this->getOptionSet->getDocumentBoundary,$this->getOptionSet->getChainedLinks,$this->getTagSet);
    }
    
    if (defined $this->getOptionSet->getOption('termList'))
    {
	print STDERR "\t-" . ($this->getMessageSet->getMessage('DISPLAY_TERM_LIST')->getContent($this->getOptionSet->getDisplayLanguage)) . "\'". $corpus->getOutputFileSet->getFile('termList')->getPath . "'\n";
	$phrase_set->printTermList($corpus->getOutputFileSet->getFile('termList'),$this->getOptionSet->getTermListStyle);
    }

#    warn $this->getOptionSet->getOption('TTG-style-term-candidates')->getValue() . "\n";

    if (defined $this->getOptionSet->getOption('TTG-style-term-candidates'))
    {
	print STDERR "\t-" . ($this->getMessageSet->getMessage('TTG_TERM_CANDIDATES')->getContent($this->getOptionSet->getDisplayLanguage)) . "\'". $corpus->getOutputFileSet->getFile('termCandidates')->getPath . "'\n";
	$phrase_set->printTermCandidatesTTG($corpus->getOutputFileSet->getFile("termCandidates"),$this->getOptionSet->getTTGStyle);
    } 

     if (defined $this->getOptionSet->getOption('bootstrap'))
     {
	 print STDERR "\t-" . ($this->getMessageSet->getMessage('DISPLAY_BOOTSTRAP')->getContent($this->getOptionSet->getDisplayLanguage)) . "\'". $corpus->getOutputFileSet->getFile('parsedTerms')->getPath . "'\n";
	$phrase_set->printBootstrapList($corpus->getOutputFileSet->getFile('parsedTerms'),$corpus->getName);
     }
    if ((defined $this->getOptionSet->getOption('XML-corpus-raw')) && ($this->getOptionSet->getOption('XML-corpus-raw')->getValue() == 1))
    {
	print STDERR "\t-" . ($this->getMessageSet->getMessage('DISPLAY_CORPUS_RAW')->getContent($this->getOptionSet->getDisplayLanguage)) . "\'". $corpus->getOutputFileSet->getFile('corpusRaw')->getPath . "'\n";
	
	$corpus->printXMLRawCorpus($corpus->getOutputFileSet->getFile('corpusRaw'),$this->getOptionSet->getSentenceBoundary,$this->getOptionSet->getDocumentBoundary);
    }
    return(0);
}


# To specify several files, repeat the -termino switch
# for each

1;
