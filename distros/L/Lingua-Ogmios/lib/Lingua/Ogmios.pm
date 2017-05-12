package Lingua::Ogmios;


our $VERSION='0.011';


use strict;
use warnings;


use File::Path;

use Lingua::Ogmios::Config;
use Lingua::Ogmios::FileManager;
use Lingua::Ogmios::DocumentCollection;
use Lingua::Ogmios::Timer;


my $debug_devel_level = 0;

sub new {
    my $class = shift;
    my %args = @_;

    binmode(STDERR, ":utf8");
    binmode(STDOUT, ":utf8");
    binmode(STDIN, ":utf8");

    warn "\n----\nNew Platform\n" unless $debug_devel_level < 1;

    my $rcfile = "/etc/ogmios/nlpplatform.rc";
    my $config;

    if (exists $args{"rcfile"}) {
	$rcfile = $args{"rcfile"};
    }

    my $NLPPlatform = {
	'Config' => undef,
	'DocumentCollection' => [],
	"timer" => Lingua::Ogmios::Timer->new(),
    };

    bless $NLPPlatform, $class;
    $NLPPlatform->{"timer"}->start;
    
    $NLPPlatform->load_config($rcfile);

    return $NLPPlatform;

}

sub load_config 
{
    my ($self,$rcfile) = @_;

    warn "self = $self\nrcfile=$rcfile\n"  unless $debug_devel_level < 2;

    if ( ! -f $rcfile ) {
	warn "$rcfile does not exist; Configuration is not loaded\n";
	return (-1);
    }
 
# Read the configuration file

    warn "Setting the configuration file ...\n" unless $debug_devel_level < 1;
    if ((!defined $rcfile) || ($rcfile eq "")) {
 	$rcfile = "/etc/ogmios/nlpplatform.rc";
    }

    $self->{'Config'} = Lingua::Ogmios::Config->new($rcfile);
    
#     mkpath($config{'ALVISTMP'});
#     return(%config);
}

sub getConfig {
    my ($self) = @_;

    return($self->{Config});
}

sub printConfig {

    my $self = shift @_;

    return($self->getConfig->print(@_));
}

sub printConfigDOT {

    my $self = shift @_;

    return($self->getConfig->printDOT(@_));
}

sub getDocumentCollection {
    my ($self) = @_;

    return($self->{'DocumentCollection'});
}

sub addDocumentCollection {
    my ($self, $documentCollection) = @_;

    push @{$self->getDocumentCollection}, $documentCollection;
}

sub loadData {
    my ($self, $data) = @_;

    my $documentCollection = Lingua::Ogmios::DocumentCollection->new($data, "data");
    
    $self->addDocumentCollection($documentCollection);
}



sub loadDocuments {

    my ($self, $files) = @_;

    my $file;
    my $type;
    my $Filemanager;

# is a directory
#   foreach do below foreach file

# is a file

#   1. Alvis : a. 1 document (keep in memory)
#              b. N documents
#                  I. Keep all in memory
#                  II. Store temporary in a spool

#                  i. Processing by document
#                  ii. Processing of M documents

#   2. non Alvis, XML : -> Convert to Alvis XML format (1 document - or less often N documents )

#   3. non Alvis, non XML : -> Convertion to Alvis (1 document)

    $Filemanager = Lingua::Ogmios::FileManager->new($self->getConfig->getSupplementaryMagicFile);

    foreach $file (@$files) {
	if ( ! -e $file ) {
	    warn "$file does not exist; File not loaded\n";
	} else {
	    # Type/format of the document
	    if (($self->getConfig->isInputInALVISFormat) || ($Filemanager->getType($file) eq "text/xml ns=http://alvis.info/enriched/")) {
		warn "Document $file is in Alvis XML format\n";
		# Alvis XML format
		my $documentCollection = Lingua::Ogmios::DocumentCollection->new($file, "file", $self->getConfig);
		
		$self->addDocumentCollection($documentCollection);
	    }

	    # Convert into ALVIS XML 
	}
	
    }    
}

sub tokenisation {
    my ($self) = @_;

    my $documentCollection;

    foreach $documentCollection (@{$self->getDocumentCollection}) {
	$documentCollection->tokenisation;
    }
    return(0);
}

sub linguisticProcessing {
    my ($self) = @_;

    my $documentCollection;
    my $processing;
    my $wrapper;


# 	warn "Processing with the wrapper: " . $self->getConfig->getNLPToolFromIndex($self->getConfig->processingTool($processing))->wrapper . "\n";
	
#     }

    warn "\n";

    my @docset = values(%{$self->getDocumentCollection->[0]->getDocuments});

    my $tool_config;

    my $NLPTool;
    my $position;

    # TODO Externalize the setting of the NLP wrappers;

#     foreach $wrapper ($self->getConfig->getOrderedWrappers) {

    warn "number of process: " . $self->getConfig->getProcessingSetSize . "\n";

    if ($self->getConfig->getProcessingSetSize > 0) {

	$position = 0;
	foreach $processing ($self->getConfig->getOrderedProcessing) {
	    $position++;
	    $tool_config = $self->getConfig->getNLPToolFromIndex($self->getConfig->processingTool($processing));
	    $wrapper = $tool_config->wrapper;
	    
	    warn "[LOG] Processing with the wrapper: " . $wrapper . " ($processing) " . $self->getConfig->processingTool($processing) . "\n";
	    
	    eval "require $wrapper";
	    if ($@) {
		warn $@ . "\n";
		die "Problem while loading wrapper $wrapper - Abort\n\n";
	    } else {
		if ($position == $self->getConfig->getProcessingSetSize) {
		    $position = 'last';
		}
		warn "[LOG] position: $position (" . $self->getConfig->getProcessingSetSize . ")\n";
		$NLPTool = $wrapper->new($tool_config, $self->getConfig->getOgmiosTMPFILE, $self->getConfig->getOgmiosLOGFILE, $position, $self->getConfig->xmloutput_noStdXmlOutput, $self->getConfig->OgmiosOutStream);
		$NLPTool->run(\@docset);
	    }
	}
    }

#     foreach $documentCollection (@{$self->getDocumentCollection}) {
# 	$documentCollection->printDocumentList;
#     }

    # docColl
    # subdocColl
    # docRec
    return(0);
}

sub XMLout {
    my ($self) = @_;

    my $documentCollection;
    my $str;

    $str = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n";

    foreach $documentCollection (@{$self->getDocumentCollection}) {
	$str .= $documentCollection->XMLout;
    }
    return($str);
    
}


sub getTimer {
    my ($self) = @_;

    return($self->{'timer'});
}


1;

__END__

=encoding utf8


=head1 NAME

Lingua::Ogmios - Perl extension for configurable Natural Language Processing (NLP) platform

=head1 SYNOPSIS

use Lingua::Ogmios;

my $ogmios = Lingua::Ogmios::new();


=head1 DESCRIPTION


This module implements the alpha version of the configurable Natural
Language Processing (NLP) platform named Ogmios.  It provides overall
methods for the linguistic annotation of textual documents.
Linguistic annotations depend on the configuration variables and
dependencies between linguistic steps. This is a new version of the
module C<Alvis::NLPPlatform>

The Omgios NLP platform annotates textual documents with existing NLP
toos such Part-of-speech taggers (TreeTagger, GeniaTagge, Flemm), term
recognizer and term extractor (C<Lingua::YaTeA>).  Textual documents
are loaded in XML format and internally manipulated through data
structures representing the annotation levels: textual elements
(tokens, words, sentences), the properties associated with these
elements (Part-of-Speech categories, semantics categories) and
relations between elements (syntactic, semantic and anaphoric relations).

Each NLP tool is integrated in the platform through a wrapper.
Wrappers are specific module which prepares the input for the NLP tool
(based on the information in the internal data structures) and parse
the output to add computed information to the data structures.

=head1 METHODS

=head2 XMLout()

    $self->XMLout();

=head2 addDocumentCollection

    $self->addDocumentCollection($documentCollection);

=head2 getConfig

    $self->getConfig;

=head2 getDocumentCollection

    $self->getDocumentCollection;

=head2 getTimer

    $self->getTimer;

=head2 linguisticProcessing

    $self->linguisticProcessing;

=head2 loadData

    $self->loadData($data);

=head2 loadDocuments

    $self->loadDocuments($files);

=head2 load_config

    $self->load_config($rcfile);

=head2 new

    Lingua::Ogmios::new("rcfile" => $rcfile);

=head2 printConfig

    $self->printConfig;

=head2 printConfigDOT

    $self->printConfigDOT;

=head2 tokenisation

    $self->tokenisation;

=head1 SEE ALSO

Thierry Hamon et Adeline Nazarenko. "Le développement d'une
plate-forme pour l'annotation spécialisée de documents web: retour
d'expérience", Traitement Automatique des Langues
(TAL). 2008. 49(2). pages 127-154. (the most detailed presentation of
the platform but in French)

Thierry Hamon et Adeline Nazarenko et Thierry Poibeau et Sophie Aubin
et Julien Derivière "A Robust Linguistic Platform for Efficient and
Domain specific Web Content Analysis". Proceedings of RIAO 2007 -
Session Poster. 30 may - 1 june 2007. Pittsburgh, USA.

=head1 AUTHORS

Thierry Hamon <thierry.hamon@limsi.fr>

=head1 LICENSE

Copyright (C) 2013 by Thierry Hamon

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.


=cut

