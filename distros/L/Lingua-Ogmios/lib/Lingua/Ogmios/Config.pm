package Lingua::Ogmios::Config;


use strict;
use warnings;

use Config::General;
use Sys::Hostname;

use Lingua::Ogmios::Config::NLPTools;

use Data::Dumper;

my $debug_devel_level = 0;

sub new {
    my $class = shift;
    my ($rcfile) = @_;

    warn "New Configuration\n" unless $debug_devel_level < 1;

    my $config = {
	'OldVersion' => 0,
	'ConfigFile' => $rcfile,
	'ConfigData' => undef,
	'NLPToolIndex' => undef,
    };

    bless $config, $class;

    if (defined $rcfile) {
	$config->setConfigData($rcfile);
	$config->_checkVersionFile;
	$config->setOgmiosTMPFILE;
	$config->setOgmiosLOGFILE;
    }
    $config->indexNLPtools;

    return $config;
}

sub setConfigData {
    my ($self, $rcfile) = @_;

    warn "Loading Configuration\n" unless $debug_devel_level < 1;

    my $conf = new Config::General('-ConfigFile' => $rcfile,
 				   '-InterPolateVars' => 1,
 				   '-InterPolateEnv' => 1,
	);
    
    my %config = $conf->getall;

    $self->{'ConfigData'} = \%config;
    $self->correctProcessingSet;
}

sub _checkVersionFile {
    my ($self) = @_;

    if (exists $self->getConfigData->{'ALVISTMP'}) {
	$self->_setOldVersion;
	warn "==> Old fashionned platform config file ;-) Trying to convert into modern one\n";
	$self->_ConvertConfigFile;
    }

}

sub getConfigData {
    my $self = shift;

    return($self->{'ConfigData'});
}

sub setConfigFile {
    my ($self, $rcfile) = @_;

    $self->{'ConfigFile'} = $rcfile;
}

sub getConfigFile {
    my $self = shift;

    return($self->{'ConfigFile'});
}

sub _unsetOldVersion {
    my ($self) = @_;

    $self->{OldVersion} = 0;
}

sub _setOldVersion {
    my ($self) = @_;

    $self->{OldVersion} = 1;
}

sub _getOldVersion {
    my ($self) = @_;
    
    return($self->{OldVersion});
}

sub _ConvertConfigFile {
    my ($self, $option) = @_;

    # ALVISTMP -> OGMIOSTMP
    $self->setOgmiosTMPDIR($self->getConfigData->{'ALVISTMP'});
    if ((defined $option) && ($option eq "remove")) {
	delete $self->getConfigData->{'ALVISTMP'};
    }

    # PLATFORM_ROOT -> OGMIOSROOT ?
}
sub setOgmiosTMPFILE {
    my ($self, $tmpdir) = @_;

    $self->getConfigData->{'OGMIOSTMPFILE'} = $self->getOgmiosTMPDIR . "/ogmios." . hostname . ".$$";
    
}

sub getOgmiosTMPFILE {
    my ($self) = @_;

    return($self->getConfigData->{'OGMIOSTMPFILE'});
}

sub setOgmiosLOGFILE {
    my ($self, $logdir) = @_;

    $self->getConfigData->{'OGMIOSLOGFILE'} = $self->getOgmiosTMPDIR . "/ogmios." . hostname . ".$$.log";
    
}

sub getOgmiosLOGFILE {
    my ($self) = @_;

    return($self->getConfigData->{'OGMIOSLOGFILE'});
}

sub setOgmiosTMPDIR {
    my ($self, $tmpdir) = @_;

    $self->getConfigData->{'OGMIOSTMP'} = $tmpdir;
    
}

sub OgmiosOutStream {
    my ($self, $out_stream) = @_;

    if (defined $out_stream) {
	$self->getConfigData->{'OUT_STREAM'} = $out_stream;
    } else {
	$self->getConfigData->{'OUT_STREAM'} = \*STDERR
    }
    return(eval($self->getConfigData->{'OUT_STREAM'}));
}


sub getOgmiosTMPDIR {
    my ($self) = @_;

    return($self->getConfigData->{'OGMIOSTMP'});
}


sub setOgmiosROOTDIR {
    my ($self, $rootdir) = @_;

    $self->getConfigData->{'PLATFORM_ROOT'} = $rootdir;
}

sub getOgmiosROOTDIR {
    my ($self) = @_;

    return($self->getConfigData->{'PLATFORM_ROOT'});
}


sub setOgmiosDefaultLanguage {
    my ($self, $defaultLanguage) = @_;

    $self->getConfigData->{'DEFAULT_LANGUAGE'} = uc($defaultLanguage);
}

sub getOgmiosDefaultLanguage {
    my ($self) = @_;

    if (!defined($self->getConfigData->{'DEFAULT_LANGUAGE'})) {
	$self->setOgmiosDefaultLanguage('EN');
    }

    return(uc($self->getConfigData->{'DEFAULT_LANGUAGE'}));
}



sub setOgmiosNLPTOOLSROOT {
    my ($self, $nlptoolsdir) = @_;

    $self->getConfigData->{'NLP_tools_root'} = $nlptoolsdir;
}

sub getOgmiosNLPTOOLSROOT {
    my ($self) = @_;

    return($self->getConfigData->{'NLP_tools_root'});
}

sub setNLPConnection {
    my ($self) = @_;

    my %tmp;

    $self->getConfigData->{'NLP_connection'} = \%tmp;
}

sub getNLPConnection {
    my ($self) = @_;

    return($self->getConfigData->{'NLP_connection'});
}

sub setServerHost {
    my ($self, $host) = @_;

    $self->getNLPConnection->{'SERVER'} = $host;
}


sub getServerHost {
    my ($self) = @_;

    return($self->getNLPConnection->{'SERVER'});
}


sub setServerPort {
    my ($self, $port) = @_;

    $self->getNLPConnection->{'PORT'} = $port;
    
}

sub getServerPort {
    my ($self) = @_;

    return($self->getNLPConnection->{'PORT'});
}

sub setRetryConnection {
    my ($self, $retry) = @_;

    $self->getNLPConnection->{'RETRY_CONNECTION'} = $retry;
}

sub getRetryConnection {
    my ($self) = @_;

    return($self->getNLPConnection->{'RETRY_CONNECTION'});
}

sub getXMLINPUT {
    my ($self) = @_;

    return($self->getConfigData->{'XML_INPUT'});
}

sub setXMLINPUT {
    my ($self) = @_;

    my %tmp;

    $self->getConfigData->{'XML_INPUT'} = \%tmp;
}

sub InputFileFormat {
    my $self = shift;

    $self->getXMLINPUT->{'FILEFORMAT'} = shift if @_;
    return($self->getXMLINPUT->{'FILEFORMAT'});
}

sub isInputInALVISFormat {
    my $self = shift;

    return(uc($self->InputFileFormat) eq "ALVIS");
}

sub preserveWhiteSpace {
    my $self = shift;
    
    $self->getXMLINPUT->{PRESERVEWHITESPACE} = shift if @_;
    return $self->getXMLINPUT->{PRESERVEWHITESPACE};
}

sub linguisticAnnotationLoading {
    my $self = shift;
    
    $self->getXMLINPUT->{LINGUISTIC_ANNOTATION_LOADING} = shift if @_;
    return $self->getXMLINPUT->{LINGUISTIC_ANNOTATION_LOADING};
}

sub _printXMLINPUTVariables {
    my ($self) = @_;

    my $var;

    if (defined $self->getXMLINPUT) {

	my %xmlinput_vars = ("PRESERVEWHITESPACE" => ["Preserve White Space", $self->preserveWhiteSpace],
			     "LINGUISTIC_ANNOTATION_LOADING" => ["Loading previous linguistic annotation?", $self->linguisticAnnotationLoading],
	    );
	
	$self->printVar("  Section XML input behaviour", \%xmlinput_vars);
	
    }

}

sub getXMLOUTPUT {
    my ($self) = @_;

    return($self->getConfigData->{'XML_OUTPUT'});
}

sub setXMLOUTPUT {
    my ($self) = @_;

    my %tmp;

    $self->getConfigData->{'XML_OUTPUT'} = \%tmp;
}


sub xmloutput_form {
    my $self = shift;
    
    $self->getXMLOUTPUT->{FORM} = shift if @_;
    return $self->getXMLOUTPUT->{FORM};
}

sub xmloutput_id {
    my $self = shift;
    
    $self->getXMLOUTPUT->{ID} = shift if @_;
    return $self->getXMLOUTPUT->{ID};
}

sub xmloutput_tokenLevel {
    my $self = shift;
    
    $self->getXMLOUTPUT->{TOKEN_LEVEL} = shift if @_;
    return $self->getXMLOUTPUT->{TOKEN_LEVEL};
}

sub xmloutput_semanticUnitNamedEntityLevel {
    my $self = shift;
    
    $self->getXMLOUTPUT->{SEMANTIC_UNIT_NAMED_ENTITY_LEVEL} = shift if @_;
    return $self->getXMLOUTPUT->{SEMANTIC_UNIT_NAMED_ENTITY_LEVEL};
}


sub xmloutput_wordLevel {
    my $self = shift;
    
    $self->getXMLOUTPUT->{WORD_LEVEL} = shift if @_;
    return $self->getXMLOUTPUT->{WORD_LEVEL};
}


sub xmloutput_sentenceLevel {
    my $self = shift;
    
    $self->getXMLOUTPUT->{SENTENCE_LEVEL} = shift if @_;
    return $self->getXMLOUTPUT->{SENTENCE_LEVEL};
}


sub xmloutput_morphosyntacticFeatureLevel {
    my $self = shift;
    
    $self->getXMLOUTPUT->{MORPHOSYNTACTIC_FEATURE_LEVEL} = shift if @_;
    return $self->getXMLOUTPUT->{MORPHOSYNTACTIC_FEATURE_LEVEL};
}


sub xmloutput_lemmaLevel {
    my $self = shift;
    
    $self->getXMLOUTPUT->{LEMMA_LEVEL} = shift if @_;
    return $self->getXMLOUTPUT->{LEMMA_LEVEL};
}


sub xmloutput_semanticUnitTermLevel {
    my $self = shift;
    
    $self->getXMLOUTPUT->{SEMANTIC_UNIT_TERM_LEVEL} = shift if @_;
    return $self->getXMLOUTPUT->{SEMANTIC_UNIT_TERM_LEVEL};
}

sub xmloutput_semanticUnitLevel {
    my $self = shift;
    
    $self->getXMLOUTPUT->{SEMANTIC_UNIT_LEVEL} = shift if @_;
    return $self->getXMLOUTPUT->{SEMANTIC_UNIT_LEVEL};
}

sub xmloutput_syntacticRelationLevel {
    my $self = shift;
    
    $self->getXMLOUTPUT->{SYNTACTIC_RELATION_LEVEL} = shift if @_;
    return $self->getXMLOUTPUT->{SYNTACTIC_RELATION_LEVEL};
}

sub xmloutput_sectionLevel {
    my $self = shift;
    
    $self->getXMLOUTPUT->{SECTION_LEVEL} = shift if @_;
    return $self->getXMLOUTPUT->{SECTION_LEVEL};
}

sub xmloutput_enumerationLevel {
    my $self = shift;
    
    $self->getXMLOUTPUT->{ENUMERATION_LEVEL} = shift if @_;
    return $self->getXMLOUTPUT->{ENUMERATION_LEVEL};
}

sub xmloutput_noStdXmlOutput {
    my $self = shift;
    
    $self->getXMLOUTPUT->{NO_STD_XML_OUTPUT} = shift if @_;
    return $self->getXMLOUTPUT->{NO_STD_XML_OUTPUT};
}

# sub xmloutput_delete_noStdXmlOutput {
#     my $self = shift;
    
#     if (defined $self->getXMLOUTPUT->{NO_STD_XML_OUTPUT}) {
# 	delete $self->getXMLOUTPUT->{NO_STD_XML_OUTPUT};
#     }
# }


sub _printXMLOUTPUTVariables {
    my ($self) = @_;

    my $var;

    if (defined $self->getXMLOUTPUT) {

	my %xmloutput_vars = ("FORM" => ["print FORM", $self->xmloutput_form],
			     "ID" => ["print ID?", $self->xmloutput_id],
			     "TOKEN_LEVEL" => ["print Token Level?", $self->xmloutput_tokenLevel],
			     "SEMANTIC_UNIT_NAMED_ENTITY_LEVEL" => ["print Named Entities (semantic unit level)?", $self->xmloutput_semanticUnitNamedEntityLevel],
			     "WORD_LEVEL" => ["print Word Level?", $self->xmloutput_wordLevel],
			     "SENTENCE_LEVEL" => ["print Sentence Level?", $self->xmloutput_sentenceLevel],
			     "MORPHOSYNTACTIC_FEATURE_LEVEL" => ["print Morphosyntactic Feature Level?", $self->xmloutput_morphosyntacticFeatureLevel],
			     "LEMMA_LEVEL" => ["print Lemma Level?", $self->xmloutput_lemmaLevel],
			     "SEMANTIC_UNIT_TERM_LEVEL" => ["print Semantic Unit Term Level?", $self->xmloutput_semanticUnitTermLevel],
			     "SEMANTIC_UNIT_LEVEL" => ["print Semantic Unit Level?", $self->xmloutput_semanticUnitLevel],
			     "SYNTACTIC_RELATION_LEVEL" => ["print Syntactic Relation Level?", $self->xmloutput_syntacticRelationLevel],
			     "NO_STD_XML_OUTPUT" => ["No Standard XML output?", $self->xmloutput_noStdXmlOutput],
	    );
	
	$self->printVar("  Section XML output behaviour", \%xmloutput_vars);
	
    }


}


sub getNLPMisc {
    my ($self) = @_;

    return($self->getConfigData->{'NLP_misc'});
}

sub setNLMisc {
    my ($self) = @_;

    my %tmp;

    $self->getConfigData->{'NLP_misc'} = \%tmp;
}


sub _printNLPMisc {
    my ($self) = @_;

    my $var;

    if (defined $self->getNLPMisc) {
	my %nlpmisc_vars = ();
	
	$self->printVar("  Section NLP miscellaneous variables", \%nlpmisc_vars);
    }

}

sub getNLPTools {
    my ($self) = @_;

    return($self->getConfigData->{'NLP_tools'}->{'TOOL'});
}

sub setNLTools {
    my ($self) = @_;

    my %tmp;

    $self->getConfigData->{'NLP_tools'} = \%tmp;
}

# sub NLPtool {
#     my $self = shift;

    
# #     $self->getNLPTools->{t} = shift if @_;
# #     return $self->getXMLOUTPUT->{NO_STD_XML_OUTPUT};

# }

sub getNLPToolFromIndex {
    my $self = shift;
    my $entry = shift;


    return($self->getNLPToolIndex->{$entry});

}

sub getNLPToolIndex {
    my $self = shift;

    return($self->{'NLPToolIndex'});
}

sub setNLPToolIndex {
    my $self = shift;
    
    my %tmp;
    $self->{'NLPToolIndex'} = \%tmp;
}


sub indexNLPtools {
    my ($self) = @_;

    my $tool;
    my $tools;

#     print STDERR Dumper $self->getNLPTools;
    if ($tools = $self->getNLPTools) {
	foreach $tool (@$tools) {
# 	    warn "Added " . $self->addNLPTool($tool) . " to the index\n";
	    $self->addNLPTool($tool);
	}
    }
}

sub addNLPtool2index {
    my ($self, $tool_config) = @_;

#      warn "tool : $tool_config\n";

#       warn "Add " .  $tool_config->name . " to the index\n";
    if (!defined $self->getNLPToolIndex) {
	$self->setNLPToolIndex;
    }
    $self->getNLPToolIndex->{$tool_config->name} = $tool_config;
}

sub addNLPTool {
    my ($self, $data_config) = @_;

#     warn "new tool: $data_config\n";
    my $tool_config = Lingua::Ogmios::Config::NLPTools->new($data_config);
    

    $self->addNLPtool2index($tool_config);
    return($tool_config->name);
}


sub _printNLPTools {
    my ($self, $lang) = @_;

    my $var;
    my $tool;

    if (defined $self->getNLPToolIndex) {
	my %nlptools_vars = ();
	
	warn "  Section NLP tools definition\n";

	foreach $tool (keys %{$self->getNLPToolIndex}) {
	    $self->getNLPToolIndex->{$tool}->print($lang);
	}
    }
}

sub _printNLPToolsDOT {
    my ($self, $lang) = @_;

    my $var;
    my $tool;

    if (defined $self->getNLPToolIndex) {
	my %nlptools_vars = ();
	
	warn "  Section NLP tools definition\n";

	foreach $tool (keys %{$self->getNLPToolIndex}) {
	    # warn "lang(0): $lang\n";
	    $self->getNLPToolIndex->{$tool}->printDOT($lang);
	}
    }
}



sub setConverters {
    my ($self) = @_;

    my %tmp;

    $self->getConfigData->{'CONVERTERS'} = \%tmp;
}

sub getConverters {
    my ($self) = @_;

    return($self->getConfigData->{'CONVERTERS'});
}

sub getSupplementaryMagicFile {
    my ($self) = @_;

    return($self->getConverters->{'SupplMagicFile'});

}

sub setSupplementaryMagicFile {
    my ($self, $filename) = @_;

    $self->getConverters->{'SupplMagicFile'} = $filename

}

sub _printConverters {
    my ($self) = @_;

    my $var;


    if (defined $self->getConverters) {
	
	my %converter_vars = ("SupplMagicFile" => ["File for Additional Definition of Magic Number", $self->getSupplementaryMagicFile],
	    );

	$self->printVar("  Section INPUT CONVERTERS", \%converter_vars);

    }

# 	foreach $var (keys %Converter_vars) {
# 	    if (defined $config->{"CONVERTERS"}->{$var}) { 
# 		print STDERR "\t" . $Converter_vars{$var} . " : " . $config->{"CONVERTERS"}->{$var} . "\n";
# 	    }
# 	}
# 	print STDERR "\tRecognized formats:\n";
# 	$Converter_vars{"STYLESHEET"} = 1;
# 	my $format;
# 	foreach $format (keys %{$config->{"CONVERTERS"}}) {
# 	    if (!exists($Converter_vars{$format})) {
# 		print STDERR "\t\t$format\n";
# 	    }
# 	}

}

sub _printNLPConnectionVariables {
    my ($self) = @_;

    my $var;

    if (defined $self->getNLPConnection) {
	
	my %nlp_connection_vars = ("SERVER" => ["NLP Server host", $self->getServerHost],
				   "PORT" => ["NLP Server port", $self->getServerPort],
				   "RETRY_CONNECTION" => ["Number of time for retrying the connection", $self->getRetryConnection],
	    );

	$self->printVar("  Section Definition of the NLP connection", \%nlp_connection_vars);

    }
}

sub _printGeneralVariables {
    my ($self) = @_;

    my $var;

    my %general_vars = ( "OGMIOSTMP" => ["Temporary directory", $self->getOgmiosTMPDIR],
                          "PLATFORM_ROOT" => ["Platform Root Directory", $self->getOgmiosROOTDIR],
 			 "NLP_tools_root" => ["Root directory of the NLP tools", $self->getOgmiosNLPTOOLSROOT],
		     );

    $self->printVar("  General variables", \%general_vars);
}

sub printVar {
    my ($self, $title, $general_vars) = @_;
    my $var;

    warn "\n$title\n";

    my @tmp;

    if (ref $general_vars eq 'HASH') {
	@tmp = keys %$general_vars;
    } else {
	@tmp = @$general_vars;
    }

    foreach $var (@tmp) {
	if (defined $general_vars->{$var}) { 
 	    warn "\t". $general_vars->{$var}[0] . " ($var) : " . $general_vars->{$var}[1] . "\n";
	}
    }

}

sub getLinguisticAnnotation {

    my ($self) = @_;

    return($self->getConfigData->{"linguistic_annotation"});
}


sub setLinguisticAnnotation {
    my ($self) = @_;

    my %tmp;

    $self->getConfigData->{"linguistic_annotation"} = \%tmp;
}

sub setProcessing {
    my $self = shift;

    my %tmp;

    unless ( @_) {
	%tmp = ('id' => undef, 
		   'order' => -1, 
		   'tool' => undef, 
		   'comments' => undef
	    );
    } else {
	tmp{'id'} = $_[0]->{'id'};
	tmp{'order'} = $_[0]->{'order'};
	tmp{'tool'} = $_[0]->{'tool'};
	tmp{'comments'} = $_[0]->{'comments'};
    }

    push @{$self->getProcessingSet}, \%tmp;    
}

sub correctProcessingSet {
    my $self = shift;

#     warn  $self->getLinguisticAnnotation->{'processing'} . "\n";

#     warn  ref($self->getLinguisticAnnotation->{'processing'}) . "\n";

    if (ref($self->getLinguisticAnnotation->{'processing'}) eq "HASH") {
	my $tmp = $self->getLinguisticAnnotation->{'processing'};
	$self->setProcessingSet;

	push  @{$self->getProcessingSet}, $tmp;
    } else {
	if (ref($self->getLinguisticAnnotation->{'processing'}) ne "ARRAY") {
	    $self->setProcessingSet;
	}
    }

}

sub getProcessingSet {
    my $self = shift;


    return($self->getLinguisticAnnotation->{'processing'});
}

sub getProcessingSetSize {
    my $self = shift;


    return(scalar(@{$self->getLinguisticAnnotation->{'processing'}}));
}

sub setProcessingSet {
    my $self = shift;

    my @tmp;
    $self->getLinguisticAnnotation->{'processing'} = \@tmp;
}

sub processingId {
    my $self = shift;
    my $i = shift;

    if (ref($i) eq "HASH") {
    	$i->{'id'} = shift if @_;
	return $i->{'id'};
	
    } else {
	
    	$self->getProcessingSet->[$i]->{'id'} = shift if @_;
	return $self->getProcessingSet->[$i]->{'id'};
    }
}

sub processingOrder {
    my $self = shift;
    my $i = shift;

    if (ref($i) eq "HASH") {
    	$i->{'order'} = shift if @_;
	return $i->{'order'};
    } else {
	$self->getProcessingSet->[$i]->{'order'} = shift if @_;
	return $self->getProcessingSet->[$i]->{'order'};
    }
}

sub processingComments {
    my $self = shift;
    my $i = shift;

    if (ref($i) eq "HASH") {
    	$i->{'comments'} = shift if @_;
	return $i->{'comments'};
    } else {
	$self->getProcessingSet->[$i]->{'comments'} = shift if @_;
	return $self->getProcessingSet->[$i]->{'comments'};
    }

}

sub processingTool {
    my $self = shift;
    my $i = shift;

    if (ref($i) eq "HASH") {
    	$i->{'tool'} = shift if @_;
	return $i->{'tool'};
    } else {
	$self->getProcessingSet->[$i]->{'tool'} = shift if @_;
	return $self->getProcessingSet->[$i]->{'tool'};
    }
}

sub getProcessing {
    my ($self, $id) = @_;

    my $i = 0;


    while($self->getProcessingId($i)) {
	$i++;
    }
    return($self->getLinguisticAnnotation->[$i]);

}

sub getOrderedProcessing {
    my $self = shift;

    my $processing;
    my @OP;

    foreach $processing (sort {$self->processingOrder($a) <=> $self->processingOrder($b)} @{$self->getProcessingSet}) {
	push @OP, $processing;
    }
    return(@OP);
}

sub getOrderedWrappers {
    my $self = shift;

    my $processing;
    my @OrderedWrappers;

    foreach $processing (sort {$self->processingOrder($a) <=> $self->processingOrder($b)} @{$self->getProcessingSet}) {
	push @OrderedWrappers, $self->getNLPToolFromIndex($self->processingTool($processing))->wrapper;
	

    }
    return(@OrderedWrappers);
}

sub _printLinguisticAnnotationFull {
    my ($self,$lang) = @_;

    my $processing;
    my $tool_config;

    warn "  Section Configuration of the Linguistic processing\n";

    foreach $processing ($self->getOrderedProcessing) {
	warn "  Tool :\n";
	warn "      Id: " . $self->processingId($processing)  . "\n";
 	warn "      Order: " .  $self->processingOrder($processing) . "\n";
 	warn "      Tool: " .  $self->processingTool($processing) . "\n";
	$tool_config = $self->getNLPToolFromIndex($self->processingTool($processing));
	$tool_config->print($lang);
#  	warn "      Comments: " . $self->processingComments($processing)  . "\n\n";
    }
}

sub _printLinguisticAnnotation {
    my ($self,$lang) = @_;

    my $processing;

    warn "  Section Configuration of the Linguistic processing\n";

    foreach $processing ($self->getOrderedProcessing) {
	warn "  Tool :\n";
	warn "      Id: " . $self->processingId($processing)  . "\n";
 	warn "      Order: " .  $self->processingOrder($processing) . "\n";
 	warn "      Tool: " .  $self->processingTool($processing) . "\n";
 	warn "      Comments: " . $self->processingComments($processing)  . "\n";
    }
}

sub _printLinguisticAnnotationDOT {
    my ($self,$lang) = @_;

    my $processing;
    my %colors = ('EN'  => 'red',
		  'FR'  => 'indigo',
		  'SV'  => 'yellow',
		  'UK'  => 'blue',
		  'UA'  => 'blue',
		  'XH'  => 'burlywood',
		  'ALL' => 'black',
	);

    warn "  Section Configuration of the Linguistic processing\n";

    my @lingAnn;
    my $name;
    my $i;

    foreach $processing (sort {$self->processingOrder($a) <=> $self->processingOrder($b)} $self->getOrderedProcessing) {
	$name = $self->processingTool($processing);
	if ((!defined $lang) || $self->getNLPToolFromIndex($name)->existsLanguage($lang)) {
	    $name =~ s/ /_/g;
	    push @lingAnn, $name;
	}
    }
    if (!defined $lang) {
	$lang ="ALL";
    }
    for($i =1; $i < scalar(@lingAnn);$i++) {
	print "\t" . $lingAnn[$i-1] . " -> " . $lingAnn[$i] . " [label=\"$lang\", color=\"" . $colors{uc($lang)} . "\", fontcolor=\"" . $colors{uc($lang)} . "\"]\n";
    }
}


sub print
{
    my ($self, $lang, $params) = @_;

    print STDERR "\n****************";

    if (exists $params->{"all"}) {
	    $self->_printGeneralVariables;
	    $self->_printNLPConnectionVariables;
	    $self->_printConverters;
	    $self->_printXMLINPUTVariables;
	    $self->_printXMLOUTPUTVariables;
	    $self->_printNLPMisc;
	    $self->_printNLPTools($lang);
#    print STDERR Dumper($self->getConfigData) . "\n";;
	    $self->_printLinguisticAnnotation($lang);
    } else {
	if (exists $params->{"genVar"}) {
	    $self->_printGeneralVariables;
	}
	if (exists $params->{"cnxVar"}) {
	    $self->_printNLPConnectionVariables;
	}
	if (exists $params->{"cnvrt"}) {
	    $self->_printConverters;	    
	}
	if (exists $params->{"inVar"}) {
	    $self->_printXMLINPUTVariables;
	}
	if (exists $params->{"outVar"}) {
	    $self->_printXMLOUTPUTVariables;
	}
	if (exists $params->{"nlpMsc"}) {
	    $self->_printNLPMisc;
	}
	if (exists $params->{"nlptools"}) {
	    $self->_printNLPTools($lang);
	}
	if (exists $params->{"lingAnn"}) {
	    $self->_printLinguisticAnnotation ($lang);
	}
	if (exists $params->{"lingAnnFull"}) {
	    $self->_printLinguisticAnnotationFull($lang);
	}
    }
    print STDERR "****************\n\n";
    return(0);
}

sub printDOT
{
    my ($self, $lang, $params) = @_;

    print STDERR "\n****************";

    if (exists $params->{"all"}) {
    print "digraph qald {\n";
	    # $self->_printGeneralVariables;
	    # $self->_printNLPConnectionVariables;
	    # $self->_printConverters;
	    # $self->_printXMLINPUTVariables;
	    # $self->_printXMLOUTPUTVariables;
	    # $self->_printNLPMisc;
	    $self->_printNLPToolsDOT($lang);
#    print STDERR Dumper($self->getConfigData) . "\n";;
	    print "\n";
	    $self->_printLinguisticAnnotationDOT($lang);
    print "}\n";
    } else {
    # 	if (exists $params->{"genVar"}) {
    # 	    $self->_printGeneralVariables;
    # 	}
    # 	if (exists $params->{"cnxVar"}) {
    # 	    $self->_printNLPConnectionVariables;
    # 	}
    # 	if (exists $params->{"cnvrt"}) {
    # 	    $self->_printConverters;	    
    # 	}
    # 	if (exists $params->{"inVar"}) {
    # 	    $self->_printXMLINPUTVariables;
    # 	}
    # 	if (exists $params->{"outVar"}) {
    # 	    $self->_printXMLOUTPUTVariables;
    # 	}
    # 	if (exists $params->{"nlpMsc"}) {
    # 	    $self->_printNLPMisc;
    # 	}
     	if (exists $params->{"nlptools"}) {
	    $self->_printNLPToolsDOT($lang);
    # 	    $self->_printNLPTools($lang);
     	}
	if (exists $params->{"lingAnn"}) {
    # 	    $self->_printLinguisticAnnotation ($lang);
	    $self->_printLinguisticAnnotationDOT($lang);
    	}
    # 	if (exists $params->{"lingAnnFull"}) {
    # 	    $self->_printLinguisticAnnotationFull($lang);
    # 	}
    }
    print STDERR "****************\n\n";
    return(0);
}

1;

__END__

=head1 NAME

Lingua::Ogmios::Config - Perl extension for the configuration of the Ogmios NLP platform

=head1 SYNOPSIS

use Lingua::Ogmios::???;

my $config = Lingua::Ogmios::???::new();


=head1 DESCRIPTION


=head1 METHODS

=head2 function()

    function($rcfile);

=head1 SEE ALSO


=head1 AUTHORS

Thierry Hamon <thierry.hamon@limsi.fr>

=head1 LICENSE

Copyright (C) 2013 by Thierry Hamon

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.


=cut

