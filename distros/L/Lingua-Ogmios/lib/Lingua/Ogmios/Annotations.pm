package Lingua::Ogmios::Annotations;

use strict;
use warnings;

use Data::Dumper;

use Lingua::Ogmios::Annotations::Level;
use Lingua::Ogmios::Annotations::Section;
use Lingua::Ogmios::Annotations::Token;
use Lingua::Ogmios::Annotations::Word;
use Lingua::Ogmios::Annotations::Sentence;
use Lingua::Ogmios::Annotations::Lemma;
use Lingua::Ogmios::Annotations::MorphosyntacticFeatures;
use Lingua::Ogmios::Annotations::Stem;
use Lingua::Ogmios::Annotations::Phrase;
use Lingua::Ogmios::Annotations::Enumeration;
use Lingua::Ogmios::Annotations::SemanticUnit;
use Lingua::Ogmios::Annotations::SyntacticRelation;
use Lingua::Ogmios::Annotations::DomainSpecificRelation;
use Lingua::Ogmios::Annotations::AnaphoraRelation;
use Lingua::Ogmios::Annotations::SemanticFeatures;

my $debug_devel_level = 2;

sub new {
    my ($class, $platformConfig) = @_;

    my $Annotations = {
	'language' => undef,
	'properties' => {},
	'Namespace' => undef,
	'urls' => undef,
	'acquisition_section' => undef,
	'relevance_section' => undef,
	'canonical_document' => undef,
	'platformConfig' => $platformConfig,
#	'canonical_document_section_positions' => [], # to delete

	'section_level' =>  => Lingua::Ogmios::Annotations::Level->new ({
	    'name' => 'section',
	    'indexes' => ['from', 'to', 'title', 'type'],
	    'XML_order' => ['id', 'from', 'to'],
									}),

	'log_level' => Lingua::Ogmios::Annotations::Level->new ({
	    'name' => 'log',
	    'indexes' => ['log_id'],
	    'XML_order' => ['log_id', 'software_name', 'command_line', 'stamp',
			    'tagset', 'comments', 'list_modified_level'],
		}),
	'token_level' => Lingua::Ogmios::Annotations::Level->new ({
	    'name' => 'token',
	    'indexes' => ['from', 'to', 'content'],
	    'XML_order' => ['id', 'type', 'content', 'from', 'to'],
								  }),
	'word_level' => Lingua::Ogmios::Annotations::Level->new ({
	    'name' => 'word',
	    'indexes' => ['list_refid_token', 'form'],
	    'XML_order' => ['id', 'log_id', 'list_refid_token', 'form'],
		}), 
	'phrase_level' => Lingua::Ogmios::Annotations::Level->new ({
	    'name' => 'phrase',
	    'indexes' => ['list_refid_components'],
	    'XML_order' => ['id', 'log_id', 'type', 'list_refid_components', 'form'],
		}),
	'enumeration_level' => Lingua::Ogmios::Annotations::Level->new ({
	    'name' => 'enumeration',
	    'indexes' => ['list_refid_components'],
	    'XML_order' => ['id', 'log_id', 'type', 'list_refid_components', 'form'],
		}),
	'sentence_level' => Lingua::Ogmios::Annotations::Level->new ({
	    'name' => 'sentence',
	    'indexes' => ['refid_start_token', 'refid_end_token'],
	    'XML_order' => ['id', 'log_id', 'refid_start_token', 'refid_end_token', 'form', 'lang'],
		}),
	'syntactic_relation_level' => Lingua::Ogmios::Annotations::Level->new ({
	    'name' => 'syntactic_relation',
	    'indexes' => ['refid_head', 'refid_modifier', 'syntactic_relation_type'],
	    'XML_order' => ['id', 'log_id', 'syntactic_relation_type', 'refid_head', 'refid_modifier'],
		}),
	'semantic_unit_level' => Lingua::Ogmios::Annotations::Level->new ({
	    'name' => 'semantic_unit',
	    'indexes' => ['refid_phrase', 'refid_word', 'list_refid_token', 'form', 'type', 'canonical_form'],
	    'XML_order' => ['id', 'log_id', 'refid_phrase', 'refid_word', 'list_refid_token',
			    'form', 'canonical_form', 'named_entity_type', 'weights', 'negation'],
									  }),
	'domain_specific_relation_level' => Lingua::Ogmios::Annotations::Level->new ({
	    'name' => 'domain_specific_relation',
	    'indexes' => ['list_refid_semantic_unit'],
	    'XML_order' => ['id', 'log_id', 'domain_specific_relation_type', 'list_refid_semantic_unit'],
		}),
	'anaphora_relation_level' => Lingua::Ogmios::Annotations::Level->new ({
	    'name' => 'anaphora_relation',
	    'indexes' => ['anaphora', 'antecent'],
	    'XML_order' => ['id', 'log_id', 'anaphora_relation_type', 'anaphora', 'antecedent'],
		}),
	'lemma_level' => Lingua::Ogmios::Annotations::Level->new ({
	    'name' => 'lemma',
	    'indexes' => ['refid_word'],
	    'XML_order' => ['id', 'log_id', 'canonical_form', 'refid_word', 'form'],
		}),
	'morphosyntactic_features_level' => Lingua::Ogmios::Annotations::Level->new ({
	    'name' => 'morphosyntactic_features',
	    'indexes' => ['refid_word', 'refid_phrase'],
	    'XML_order' => ['id', 'log_id', 'refid_word', 'refid_phrase', 'syntactic_category',
			    'category', 'type', 'gender', 'number', 'case', 'mood_vform', 'tense', 'person', 
			    'degree', 'possessor', 'formation', 'form'],
		}),
	'semantic_features_level' => Lingua::Ogmios::Annotations::Level->new ({
	    'name' => 'semantic_features',
	    'indexes' => ['refid_semantic_unit'],
	    'XML_order' => ['id', 'log_id', 'refid_semantic_unit', 'semantic_category'],
		}),
	'stem_level' => Lingua::Ogmios::Annotations::Level->new ({
	    'name' => 'stem',
	    'indexes' => ['refid_word'],
	    'XML_order' => ['id', 'log_id', 'stem_form', 'refid_word', 'form'],
								 }),

    };
    bless $Annotations, $class;
    return ($Annotations);
}

sub getLevels4Print {
    my ($self) = @_;

# 		     'section_level',

    my @levels_id = ('log_level',
		     'token_level');

    if ((defined $self->platformConfig->xmloutput_sectionLevel) &&
	($self->platformConfig->xmloutput_sectionLevel == 1)) {
	push @levels_id, 'section_level';
    }

    push @levels_id, ('word_level',
		      'sentence_level',
		      'phrase_level');
    if ((defined $self->platformConfig->xmloutput_enumerationLevel) &&
	($self->platformConfig->xmloutput_enumerationLevel == 1)) {
	push @levels_id, 'enumeration_level';
    }

    push @levels_id, ('semantic_unit_level',
		      'lemma_level',
		      'stem_level', 
		      'morphosyntactic_features_level',
		      'syntactic_relation_level',
		      'semantic_features_level',
		      'domain_specific_relation_level',
		      'anaphora_relation_level',
    );
    my $id;
    my @levels;

    foreach $id (@levels_id) {
	if ($self->{$id}->getId > 0) {
	    warn "level: $id\n";
	    push @levels, $self->{$id};
	}
    }
    return(@levels);
}

sub getLevels {
    my ($self) = @_;

# 		     'section_level',

    my @levels_id = ('log_level',
		     'token_level',
		     'word_level',
		     'sentence_level',
		     'phrase_level',
		     'enumeration_level',
		     'semantic_unit_level',
		     'lemma_level',
		     'stem_level', 
		     'morphosyntactic_features_level',
		     'syntactic_relation_level',
		     'semantic_features_level',
		     'domain_specific_relation_level',
		     'anaphora_relation_level',
	);
    my $id;
    my @levels;

    foreach $id (@levels_id) {
	if ($self->{$id}->getId > 0) {
	warn "level: $id\n";
	    push @levels, $self->{$id};
	}
    }
    return(@levels);
}

sub setLanguageFromXMLAndProperties {
    my $self = shift;
    my $acquisition_section_node = shift;

    print STDERR "\nSetting Language: " unless $debug_devel_level != 2;

    my $analysis = $acquisition_section_node->getChildrenByTagName('analysis')->get_node(1);
    if (defined $analysis) {
# 	my @properties = $analysis->getChildrenByTagName('property');
# 	warn join(":", @properties) . "\n";
 	my $prop;
	
# 	warn $analysis->getChildrenByTagName('property')->get_node(1)->getAttribute("name") . "\n";
	
	foreach $prop ($analysis->getChildrenByTagName('property')) {
# 	    warn "$prop\n";
	    if (defined $prop->hasAttribute("name")) {
		if ($prop->getAttribute("name") eq "language") {
# 		warn $prop->firstChild->toString . "\n";
# 		warn $prop->toString  . "\n";
		    $self->{"language"} = uc($prop->firstChild->toString);
		    warn $self->{"language"} . "\n"  unless $debug_devel_level != 2;
		}
		$self->{'properties'}->{$prop->getAttribute("name")} = $prop->firstChild->toString;
	    }
	}
    }
}

sub getLanguage {
    my $self = shift;

    return($self->{"language"});
}

sub setLanguage {
    my $self = shift;

    $self->{"language"} = shift;
    return($self->{"language"});
}

sub getProperties {
    my $self = shift;

    return($self->{"properties"});
}

sub getProperty {
    my ($self, $propertyName) = @_;

    return($self->getProperties->{$propertyName});
}

sub delProperty {
    my ($self, $propertyName) = @_;

    delete($self->getProperties->{$propertyName});
    return(undef);
}

sub setProperty {
    my ($self, $propertyName, $value, $separator) = @_;
    if (!defined $separator) {
	$separator = ";";
    }

    if (!exists $self->getProperties->{$propertyName}) {
	$self->getProperties->{$propertyName} = $value;
    } else {
	$self->getProperties->{$propertyName} .= "$separator$value";
    }

    return($self->getProperties->{$propertyName});
}

sub replaceProperty {
    my ($self, $propertyName, $value) = @_;

    $self->getProperties->{$propertyName} = $value;

    return($self->getProperties->{$propertyName});
}

sub platformConfig {
    my $self = shift;

    if (@_) {
	$self->{"platformConfig"} = shift;
    }

    return($self->{"platformConfig"});
}

sub setURLs {
    my $self = shift;
    my $acquisition_section_node = shift;

    my $url;

    print STDERR "\nSetting URLs: " unless $debug_devel_level != 2;

    my $acquisitionData = $acquisition_section_node->getChildrenByTagName('acquisitionData')->get_node(1);

     if (defined $acquisitionData) {
	 my $urls = $acquisitionData->getChildrenByTagName('urls')->get_node(1);
	 if (defined $urls) {
	     my @urls;
	     $self->{'urls'} = \@urls;
	     foreach $url ($urls->getChildrenByTagName('url')) {
# 		 warn $url->firstChild->toString . "\n";
		 push @urls, $url->firstChild->toString;
	     }
	 }
     }

}


sub getURLs {
    my $self = shift;

    return($self->{"urls"});
}

sub setCanonicalDocument {
    my ($self, $canonicalDocument) = @_;

    $self->{'canonical_document'} = $canonicalDocument;
}

sub load_LogLevel {
    my ($self, $linguistic_analysis_node) = @_;
    
    my $LogLevel = $linguistic_analysis_node->getChildrenByTagName('log_level')->get_node(1);

    my $logprocessing_node;
    my $fields;
    my $XML_order = $self->getLogLevel->getXMLorder;;
    my $element;
    my @nodes;
    my $node;

    if (defined $LogLevel) {
 	warn "Loading Log Level\n";
	foreach $logprocessing_node ($LogLevel->getChildrenByTagName('log_processing')) {
	    $fields = {};
	    foreach $element (@$XML_order) {
		@nodes = $logprocessing_node->getChildrenByTagName($element);
		# warn "$element (" . scalar(@nodes) .")\n";
		# if (scalar(@nodes) > 1) {
		if ($element =~ /^list_/) {
		    my @values;
		    foreach $node (@nodes) { 
 			# warn "$element:" . $node->textContent . "\n";
			push @values, $node->textContent;
		    }
		    $fields->{$element} = \@values;
		} else {
		    if (scalar(@nodes) > 0) {
# 			warn "$element:" . $nodes[0]->textContent . "\n";
			$fields->{$element} = $nodes[0]->textContent;
		    }
		}		
	    }
	    $self->addLogProcessing(Lingua::Ogmios::Annotations::LogProcessing->new($fields));

	}
	warn "done\n";
    }
}


sub load_TokenLevel {
    my ($self, $linguistic_analysis_node) = @_;


    my $token_level_node = $linguistic_analysis_node->getChildrenByTagName('token_level')->get_node(1);
    my $token_node;
    my $XML_order = $self->getTokenLevel->getXMLorder;
    my $element;
    my $token;
    my $fields;

    if (defined $token_level_node) {
 	warn "Loading Token Level\n";
	warn "  " . $token_level_node->getChildrenByTagName('token')->size . " to load\n";
	foreach $token_node ($token_level_node->getChildrenByTagName('token')) {
#  	    warn "$token_node\n";
	    $fields = {};
	    foreach $element (@$XML_order) {
# 		warn "$element:" . $token_node->getChildrenByTagName($element)->get_node(1)->textContent . "\n";
		$fields->{$element} = $token_node->getChildrenByTagName($element)->get_node(1)->textContent;
	    }
	    $self->addToken(Lingua::Ogmios::Annotations::Token->new($fields));
	}
	warn "done\n";
    }
    
}

sub makeElementRefFromId {
    my ($self, $fields) = @_;
    my $element;

    # print STDERR Dumper($fields) . "\n";

    if (exists $fields->{'list_refid_token'}) {
	my @element_list;
	foreach $element (@{$fields->{'list_refid_token'}}) {
	    push @element_list, $self->getTokenLevel->getElementById($element);
	}
	$fields->{'list_refid_token'} = \@element_list;
    }
    if (exists $fields->{'refid_word'}) {
	my @element_list;
	if (ref($fields->{'refid_word'}) eq "ARRAY") {
	    foreach $element (@{$fields->{'refid_word'}}) {
		push @element_list, $self->getWordLevel->getElementById($element);
	    }
	    $fields->{'refid_word'} = \@element_list;
	} else {
	    $fields->{'refid_word'} = $self->getWordLevel->getElementById($fields->{'refid_word'});
	}
    }
    if (exists $fields->{'refid_phrase'}) {
	my @element_list;
	if (ref($fields->{'refid_phrase'}) eq "ARRAY") {
	    foreach $element (@{$fields->{'refid_phrase'}}) {
		push @element_list, $self->getPhraseLevel->getElementById($element);
	    }
	    $fields->{'refid_phrase'} = \@element_list;
	} else {
	    $fields->{'refid_phrase'} = $self->getPhraseLevel->getElementById($fields->{'refid_phrase'});
	}
    }
    if (exists $fields->{'refid_semantic_unit'}) {
	my @element_list;
	if (ref($fields->{'refid_semantic_unit'}) eq "ARRAY") {
	    foreach $element (@{$fields->{'refid_semantic_unit'}}) {
		push @element_list, $self->getSemanticUnitLevel->getElementById($element);
	    }
	    $fields->{'refid_semantic_unit'} = \@element_list;
	} else {
	    $fields->{'refid_semantic_unit'} = $self->getSemanticUnitLevel->getElementById($fields->{'refid_semantic_unit'});
	}
    }
    if (exists $fields->{'refid_start_token'}) {
	$fields->{'refid_start_token'} = $self->getTokenLevel->getElementById($fields->{'refid_start_token'});
    }
    if (exists $fields->{'refid_end_token'}) {
	$fields->{'refid_end_token'} = $self->getTokenLevel->getElementById($fields->{'refid_end_token'});
    }
    # print STDERR Dumper($fields) . "\n";
}


sub load_Level {
    my ($self, $linguistic_analysis_node, $level_name, $node_name, $XML_order) = @_;

    my $word_node;
#    my $XML_order = $self->getWordLevel->getXMLorder;
    my $element;
#    my $fields;
    my @nodes;
    my $node;
    my $inner_node;

    my @nodeList;
    my $inner_element;

    my $level_node = $linguistic_analysis_node->getChildrenByTagName($level_name)->get_node(1);
    if (defined $level_node) {
#  	warn "Loading $node_name Level\n";
# 	warn "  " . $level_node->getElementsByTagName($node_name)->size . " to load\n";
	foreach $node ($level_node->getElementsByTagName($node_name)) {
	    my $fields = {};
	    foreach $element (@$XML_order) {
		@nodes = $node->getChildrenByTagName($element);
#  		warn "\tnb nodes: " . scalar(@nodes) . "\n";
		if (scalar(@nodes) > 1) {
#  		    warn "+++++\n";
		    my @values;
		    foreach $inner_node (@nodes) { 
#   			warn "$element (1):" . $inner_node->textContent . "\n";
			push @values, $inner_node->textContent;
		    }
		    $fields->{$element} = \@values;
		} else {
		    if (scalar(@nodes) == 1) {
#  			warn "    => " . $nodes[0]->nodeName . "\n";
#   			warn "$element (2): " . $nodes[0]->hasChildNodes . "\n";
#   			warn "$element (2): " . $nodes[0]->textContent . "\n";
# childNodes
			if ($nodes[0]->hasChildNodes) {
			    # hasAttribute

# 			    warn "=> " . $nodes[0]->childNodes . "\n";
#			    warn "=>(NT) " . $nodes[0]->nodeType . "\n";
			    if ((scalar(@{$nodes[0]->childNodes}) == 1) && ($nodes[0]->childNodes->get_node(1)->nodeName eq "#text")){
# 				warn "----->" . $nodes[0]->childNodes->[0]->textContent . "\n";
				$fields->{$element} = $nodes[0]->childNodes->get_node(1)->textContent;
#  			    } else {
# 				warn "===> " . $nodes[0]->childNodes->get_node(1)->nodeName . "\n";
# 				if (($nodes[0]->childNodes->get_node(1)->nodeName ne "#text") &&
# 				    ($nodes[0]->childNodes->get_node(1)->hasAttribute)) {
# # 				if (($nodes[0]->childNodes->get_node(1)->nodeName ne "#text") &&
# # 				    ($nodes[0]->childNodes->get_node(1)->hasAttribute)) {
# # 				    my %values;
# 				    warn "===> " . $nodes[0]->childNodes->get_node(1)->textContent . "\n";
# 				    warn "\tAttributes\n";
# 				    warn "\t" . Dumper($node->attributes()) . "\n";
# # 				    foreach $inner_node ($nodes[0]->childNodes) { 
# # 					warn "====\n";
# # 					warn "    " . $inner_node->nodeName . "\n";
# # 					if ($inner_node->hasChildNodes) {
# # 					    warn $inner_node->nodeName . " (3):" . $inner_node->textContent . "\n";
# # 					    warn "     (NT) " . $inner_node->nodeType . "\n";
# # 					    $values{$nodes[0]->childNodes->getAttribute} = $inner_node->textContent;
# # 					}
# # 				    }
# # 				    $fields->{$element} = \%values;
				    
				} else {
				    my @values_t;
				    my %values_h;
				    my $nodetmp = $nodes[0];
# 				    warn "===>>>>$element\n";
				    if ($element eq "semantic_category") {
# 					warn "+++++++++\n";
					$nodetmp = $nodetmp->getChildrenByTagName("list_refid_ontology_node")->get_node(1);
				    }
				    foreach $inner_node ($nodetmp->childNodes) { 
# 					warn "====\n";
# 					warn "    " . $inner_node->nodeName . "\n";
					if ($inner_node->hasChildNodes) {
					    $inner_element = $inner_node->nodeName;
# 					    warn $inner_node->nodeName . " ($element -- 3):" . $inner_node->textContent . "\n";
					    if ($inner_node->hasAttributes) {
						my @tmp = $inner_node->attributes();
						foreach my $a (@tmp) {
# 						    warn "\tAttributes: " . ($a->getValue) . "\n";
# 						    warn "\tAttributes: " . ($a->getName) . "\n";
						    $values_h{$a->getValue} = $inner_node->textContent;
						}
					    } else {
 						if ($element eq "semantic_category") {
 						    my @semf = split /\//, $inner_node->textContent;
 						    push @values_t, \@semf;
 						} else {
						    push @values_t, $inner_node->textContent;
 						}
					    }
					}
				    }
				    if (scalar(@values_t) == 0) {
					$fields->{$element} = \%values_h;
				    } else {
					if (($element eq "list_refid_components") ||
					    ($element eq "list_refid_semantic_unit") ||
					    ($element eq "list_refid_ontology_node")) {
# 					    warn ">>>>$inner_element\n";
					    $fields->{$inner_element} = \@values_t;
					} elsif ($element eq "refid_head") {
					    $fields->{$inner_element. "_head"} = \@values_t;

					} elsif ($element eq "refid_modifier") {
					    $fields->{$inner_element. "_modifier"} = \@values_t;
					} else {
					    $fields->{$element} = \@values_t;
					}
 				    }
#				}
			    }
			} else {
			    $fields->{$element} = $nodes[0]->textContent;
			}
		    }
 		}		
# 		$fields->{$element} = $node->getChildrenByTagName($element)->get_node(1)->textContent;
# 		warn "--------------------\n";
	    }
	    push @nodeList, $fields;
#	    $self->addWord(Lingua::Ogmios::Annotations::Word->new($fields));
	}
	warn "Loading $level_node done\n";
    }
    return(@nodeList);
}

sub load_WordLevel {
    my ($self, $linguistic_analysis_node) = @_;

    my @nodeList;
    my $fields;
    my $token;
    my @token_list;

    warn "[LOG] Word Level Loading\n";

    @nodeList = $self->load_Level($linguistic_analysis_node, "word_level", 'word', $self->getWordLevel->getXMLorder);

    foreach $fields (@nodeList) {

	$self->makeElementRefFromId($fields);
# 	my @token_list;
# 	foreach $token (@{$fields->{'list_refid_token'}}) {
# 	    push @token_list, $self->getTokenLevel->getElementById($token);
# 	}
# 	$fields->{'list_refid_token'} = \@token_list;

	$self->addWord(Lingua::Ogmios::Annotations::Word->new($fields));
    }

    warn "\tdone\n";
}

# sub load_WordLevel1 {
#     my ($self, $linguistic_analysis_node) = @_;

#     my $word_node;
#     my $XML_order = $self->getWordLevel->getXMLorder;
#     my $element;
#     my $word;
#     my $fields;
#     my @nodes;
#     my $node;

#     my $word_level_node = $linguistic_analysis_node->getChildrenByTagName('word_level')->get_node(1);
#     if (defined $word_level_node) {
#  	warn "Loading Word Level\n";
# 	warn "  " . $word_level_node->getChildrenByTagName('word')->size . " to load\n";
# 	foreach $word_node ($word_level_node->getChildrenByTagName('word')) {
# 	    $fields = {};
# 	    foreach $element (@$XML_order) {
# # 		warn "element: $element\n";
# 		@nodes = $word_node->getChildrenByTagName($element);
# # 		warn "\tnb nodes: " . scalar(@nodes) . "\n";
# 		if (scalar(@nodes) > 1) {
# # 		    warn "===\n";
# 		    my @values;
# 		    foreach $node (@nodes) { 
# #  			warn "$element (1):" . $node->textContent . "\n";
# 			push @values, $node->textContent;
# 		    }
# 		    $fields->{$element} = \@values;
# 		} else {
# 		    if (scalar(@nodes) == 1) {
# # 			warn "    => " . $nodes[0]->nodeName . "\n";
# #  			warn "$element (2): " . $nodes[0]->hasChildNodes . "\n";
# #  			warn "$element (2): " . $nodes[0]->textContent . "\n";
# # childNodes
# 			if ($nodes[0]->hasChildNodes) {
# 			    my @values;
# # 			    warn "=> " . $nodes[0]->childNodes . "\n";
# # 			    warn "=>(NT) " . $nodes[0]->nodeType . "\n";
# 			    if ((scalar(@{$nodes[0]->childNodes}) == 1) && ($nodes[0]->childNodes->get_node(1)->nodeName eq "#text")){
# # 				warn $nodes[0]->childNodes->[0]->textContent . "\n";
# 				$fields->{$element} = $nodes[0]->childNodes->get_node(1)->textContent;
# 			    } else {
# 				foreach $node ($nodes[0]->childNodes) { 
# # 				    warn "====\n";
# # 				    warn "    " . $node->nodeName . "\n";
# 				    if ($node->hasChildNodes) {
# # 					warn $node->nodeName . " (3):" . $node->textContent . "\n";
# # 					warn "     (NT) " . $node->nodeType . "\n";
# 					push @values, $node->textContent;
# 				    }
# 				}
# 				$fields->{$element} = \@values;
# 			    }
# 			} else {
# 			    $fields->{$element} = $nodes[0]->textContent;
# 			}
# 		    }
#  		}		
# # 		$fields->{$element} = $word_node->getChildrenByTagName($element)->get_node(1)->textContent;
# # 		warn "--------------------\n";
# 	    }
# 	    $self->addWord(Lingua::Ogmios::Annotations::Word->new($fields));
# 	}
# 	warn "done\n";
#     }
# }

sub load_PhraseLevel {
    my ($self, $linguistic_analysis_node) = @_;

    my @nodeList;
    my $fields;

    my $element;
    my $elemnt_list;

    warn "[LOG] Phrase Level Loading\n";

    @nodeList = $self->load_Level($linguistic_analysis_node, "phrase_level", 'phrase', $self->getPhraseLevel->getXMLorder);

    foreach $fields (@nodeList) {
	$self->makeElementRefFromId($fields);
	$self->addPhrase(Lingua::Ogmios::Annotations::Phrase->new($fields));
    }

    warn "\tdone\n";
}

sub load_EnumerationLevel {
    my ($self, $linguistic_analysis_node) = @_;

    my @nodeList;
    my $fields;

    my $element;
    my $elemnt_list;

    warn "[LOG] Enumeration Level Loading (CODE NOT CHECK)\n";

    @nodeList = $self->load_Level($linguistic_analysis_node, "enumeration_level", 'enumeration', $self->getEnumerationLevel->getXMLorder);

    foreach $fields (@nodeList) {
	$self->makeElementRefFromId($fields);
	$self->addEnumeration(Lingua::Ogmios::Annotations::Enumeration->new($fields));
    }

    warn "\tdone\n";
}

sub load_SentenceLevel {
    my ($self, $linguistic_analysis_node) = @_;

    my @nodeList;
    my $fields;

    warn "[LOG] Sentence Level Loading\n";

    @nodeList = $self->load_Level($linguistic_analysis_node, "sentence_level", 'sentence', $self->getSentenceLevel->getXMLorder);

    warn "Make Sentences (" . scalar(@nodeList) . ")\n";
    foreach $fields (@nodeList) {
	$self->makeElementRefFromId($fields);
	$self->addSentence(Lingua::Ogmios::Annotations::Sentence->new($fields));
    }

    warn "\tdone\n";

}

sub load_Syntactic_relationLevel {
    my ($self, $linguistic_analysis_node) = @_;

    my @nodeList;
    my $fields;

    my $element;
    my $elemnt_list;

    warn "[LOG] Syntatic Relation Level Loading\n";

    @nodeList = $self->load_Level($linguistic_analysis_node, "syntactic_relation_level", 'syntactic_relation', $self->getSyntacticRelationLevel->getXMLorder);

    foreach $fields (@nodeList) {
	$self->makeElementRefFromId($fields);
	$self->addSyntacticRelation(Lingua::Ogmios::Annotations::SyntacticRelation->new($fields));
    }

    warn "\tdone\n";

}

sub load_Semantic_unitLevel {
    my ($self, $linguistic_analysis_node) = @_;

    my @nodeList;
    my $fields;
    my $type;

    warn "[LOG] Semantic Unit Level Loading\n";

    for $type ('named_entity', 'term', 'undefined') {
# 'semantic_unit'
	@nodeList = $self->load_Level($linguistic_analysis_node, "semantic_unit_level", $type, $self->getSemanticUnitLevel->getXMLorder);
	
	foreach $fields (@nodeList) {
#  	    print STDERR Dumper($fields) . "\n";
	    $fields->{'type'} = $type;
	    $self->makeElementRefFromId($fields);
	    $self->addSemanticUnit(Lingua::Ogmios::Annotations::SemanticUnit->new($fields));
	}
    }
    warn "\tdone\n";
}

sub load_Domain_specific_relationLevel {
    my ($self, $linguistic_analysis_node) = @_;

    my @nodeList;
    my $fields;

    my $element;
    my $elemnt_list;

    warn "[LOG] Domain Specific Relation Level Loading (CODE NOT CHECK)\n";

    @nodeList = $self->load_Level($linguistic_analysis_node, "domain_specific_relation_level", 'domain_specific_relation', $self->getDomainSpecificRelationLevel->getXMLorder);

    foreach $fields (@nodeList) {
	$self->makeElementRefFromId($fields);
	$self->addDomainSpecificRelation(Lingua::Ogmios::Annotations::DomainSpecificRelation->new($fields));
    }

    warn "\tdone\n";
}

sub load_Anaphora_relationLevel {
    my ($self, $linguistic_analysis_node) = @_;

    my @nodeList;
    my $fields;

    my $element;
    my $elemnt_list;

    warn "[LOG] Anaphora Relation Level Loading (CODE NOT CHECK)\n";

    @nodeList = $self->load_Level($linguistic_analysis_node, "anaphora_relation_level", 'anaphora_relation', $self->getAnaphoraRelationLevel->getXMLorder);

    foreach $fields (@nodeList) {
	$self->makeElementRefFromId($fields);
	$self->addAnaphoraRelation(Lingua::Ogmios::Annotations::AnaphoraRelation->new($fields));
    }

    warn "\tdone\n";

}

sub load_LemmaLevel {
    my ($self, $linguistic_analysis_node) = @_;

    my @nodeList;
    my $fields;

    warn "[LOG] Lemma Level Loading\n";

    @nodeList = $self->load_Level($linguistic_analysis_node, "lemma_level", 'lemma', $self->getLemmaLevel->getXMLorder);

    foreach $fields (@nodeList) {
	$self->makeElementRefFromId($fields);
	$self->addLemma(Lingua::Ogmios::Annotations::Lemma->new($fields));
    }

    warn "\tdone\n";
}

sub load_Morphosyntactic_featuresLevel {
    my ($self, $linguistic_analysis_node) = @_;

    my @nodeList;
    my $fields;

    warn "[LOG] Morphosyntactic Features Level Loading\n";

    @nodeList = $self->load_Level($linguistic_analysis_node, "morphosyntactic_features_level", 'morphosyntactic_features', $self->getMorphosyntacticFeaturesLevel->getXMLorder);

    foreach $fields (@nodeList) {
	$self->makeElementRefFromId($fields);
	$self->addMorphosyntacticFeatures(Lingua::Ogmios::Annotations::MorphosyntacticFeatures->new($fields));
    }

    warn "\tdone\n";
}

sub load_Semantic_featuresLevel {
    my ($self, $linguistic_analysis_node) = @_;

    my @nodeList;
    my $fields;

    my $element;
    my $elemnt_list;

    warn "[LOG] Semantic Features Level Loading\n";

    @nodeList = $self->load_Level($linguistic_analysis_node, "semantic_features_level", 'semantic_features', $self->getSemanticFeaturesLevel->getXMLorder);

    warn "Make Semantic Features (" . scalar(@nodeList) . ")\n";
    foreach $fields (@nodeList) {
	$self->makeElementRefFromId($fields);
	# warn ref($fields->{'semantic_category'}) . "\n";
	if (ref($fields->{'semantic_category'}) eq "ARRAY") {
	    $self->addSemanticFeatures(Lingua::Ogmios::Annotations::SemanticFeatures->new($fields));
	}
    }

    warn "\tdone\n";

}

sub load_StemLevel {
    my ($self, $linguistic_analysis_node) = @_;


    my @nodeList;
    my $fields;

    warn "[LOG] Stem Level Loading\n";

    @nodeList = $self->load_Level($linguistic_analysis_node, "stem_level", 'stem', $self->getStemLevel->getXMLorder);

    foreach $fields (@nodeList) {
	$self->makeElementRefFromId($fields);
	$self->addStem(Lingua::Ogmios::Annotations::Stem->new($fields));
    }

    warn "\tdone\n";

}

sub loadLinguisticAnalysis {
    my ($self, $linguistic_analysis_node) = @_;
#     my ($self, $document_record_node) = @_;

#     my $linguistic_analysis_node = $document_record_node->getChildrenByTagName('linguisticAnalysis')->get_node(1);

    if (defined $linguistic_analysis_node) {
	warn "Load existing linguistic annotations\n";

	# load token level
	$self->load_TokenLevel($linguistic_analysis_node);
	$self->load_WordLevel($linguistic_analysis_node);
	$self->load_PhraseLevel($linguistic_analysis_node);
	$self->load_SentenceLevel($linguistic_analysis_node);
	$self->load_Semantic_unitLevel($linguistic_analysis_node);
	$self->load_LemmaLevel($linguistic_analysis_node);
	$self->load_LogLevel($linguistic_analysis_node);
	$self->load_Morphosyntactic_featuresLevel($linguistic_analysis_node);
	$self->load_StemLevel($linguistic_analysis_node);
	$self->load_Syntactic_relationLevel($linguistic_analysis_node);
	$self->load_Semantic_featuresLevel($linguistic_analysis_node);
	$self->load_EnumerationLevel($linguistic_analysis_node);
	$self->load_Domain_specific_relationLevel($linguistic_analysis_node);
	$self->load_Anaphora_relationLevel($linguistic_analysis_node);
    }
}


sub loadCanonicalDocument {
    my ($self, $acquisition_section_node) = @_;

    my $canonical_document;
    my $canonical_document_section_positions;
    my $canonical_document_node = $acquisition_section_node->getChildrenByTagName('canonicalDocument')->get_node(1);
    my $section;

    if (defined $canonical_document_node) {
	($canonical_document, $canonical_document_section_positions) = $self->_parseCanonicalDocument($canonical_document_node);
	$self->setCanonicalDocument($canonical_document);
	foreach $section (@$canonical_document_section_positions) {
	    $self->addSection($section);
	    warn "section from " . $section->getFrom . " to " . $section->getTo . "\n" unless $debug_devel_level != 1;
	}
# 	$self->setCanonicalDocument_SectionPosition($canonical_document_section_positions);
    } else {
	warn "no canonicalDocument (" . $self->getId . ")\n";
    }
}

sub _parseCanonicalDocument_SectionPosition {

    my ($self, $canonical_document_node) = @_;

    my @sections;
    my $canonicalDocumentString = "";

    return(\@sections);
}


sub _parseCanonicalDocument {

    my ($self, $canonical_document_node) = @_;

#     warn "in parseCanonicalDocument\n";

    my @sections;
    my @section_starts;
    my @section_ends;
    my $canonicalDocumentString = "";
    my @canonicalDocument_sections;
    my $section;
    my $start_position;
    my $end_position;

    my $i;

    $canonicalDocumentString = $canonical_document_node->toString;
    

    $canonicalDocumentString =~ s/[\s\n]*<\/?canonicalDocument>\s*//go;

    my $temp_canonicalDocumentString = $canonicalDocumentString;

    my @section_infos;
    my $section_string;

    while($temp_canonicalDocumentString =~ /<section[^>]*>|<list>|<item>/o) {
	push @canonicalDocument_sections, $`; #` }
	$temp_canonicalDocumentString = $';


        $section_string = $&; # '
	 #    warn "section string: $section_string\n";
         # warn $temp_canonicalDocumentString . "\n\n";
        my %tmp;
	$tmp{'type'} = "empty";
	$tmp{'title'} = "empty";
	if ($section_string =~ /<item>/o) {
	    $tmp{'type'} = "item";
	    $tmp{'title'} = undef;
	} else {
	    if ($section_string =~ /<list>/o) {
		$tmp{'type'} = "list";
		$tmp{'title'} = undef;
	    } else {
		$tmp{'type'} = "narrative";
		if ($section_string =~ /<section(\s+sectionType=\"(?<st>[^"]+)\")?(\s+title=\"(?<t>[^"]+)\")?>/o) { #"
		    $tmp{'type'} = $+{st};
		    $tmp{'title'} = $+{t};
		} else {
		    $tmp{'title'} = undef;
	        } 
	    }
        }
	push @section_infos, \%tmp;
    }
    push @canonicalDocument_sections, $temp_canonicalDocumentString;

    shift @canonicalDocument_sections; # what is before the first section cannot be into the document
    
#     shift @section_infos;

    $start_position = 0;
    $end_position = 0;

    warn "[LOG] Identifying start position of the sections\n";

    my $j;
    for($j=0;$j < scalar(@canonicalDocument_sections);$j++) {
	$section = $canonicalDocument_sections[$j];
	# warn "-> $section\n";
# 	push @section_starts, $start_position;
	my @tmp = ($start_position, $section_infos[$j], $section);
	push @section_starts, \@tmp;
	$section =~ s/<[^>]+>//go;
	# warn "$section\n";
	# warn "\t" . length(Lingua::Ogmios::Annotations::Element->_xmldecode($section)) . "\n";
	$start_position += length(Lingua::Ogmios::Annotations::Element->_xmldecode($section));
	# warn "\t" . $start_position . "\n";
    }

    warn "\n[LOG] Identifying end position of the sections\n";

    @canonicalDocument_sections = split m!</section>|</list>|</item>!, $canonicalDocumentString;

    foreach $section (@canonicalDocument_sections) {
	if ($section eq "") {
	    # warn "empty section content ($end_position)\n";
	    if ($end_position != 0) {
		push @section_ends, $end_position-1;
	    } else {
		push @section_ends, $end_position;
	    }
	} else {
	    # warn "-> $section\n";
	    # warn "\t" . $end_position . "(a)\n";
	    # if ($section =~ /([^<]*)<[^>]+>/os) {
	    #     $end_position += length($1);
	    # }
	    while($section =~ s/([^<]*)<[^>]+>//os) {
		$end_position += length($1);
	    }
	    # warn "\t" . $end_position . "(b)\n";
	    # $section =~ s/<[^>]+>//go;
	    # warn "$section\n";
	    # warn "\t" . length(Lingua::Ogmios::Annotations::Element->_xmldecode($section)) . "\n";
	    $end_position += length(Lingua::Ogmios::Annotations::Element->_xmldecode($section));
	    $end_position--;
	    # warn "\t" . $end_position . "(c)\n";
	    push @section_ends, $end_position;
	    $end_position++;
#	push @section_ends, $section_starts[$#section_ends + 1] + length(Lingua::Ogmios::Annotations::Element->_xmldecode($section)) - 1;
	}
    }

    # as empty trailing fields are deleted with split, put empty
    # string instead to get the same number of start and end section
    # position

    for($i = scalar(@section_ends); $i < scalar @section_starts; $i++) {
	$section_ends[$i] = $section_ends[$#section_ends];
    }



    $canonicalDocumentString =~ s/<[^>]+>//go;

    $canonicalDocumentString = Lingua::Ogmios::Annotations::Element->_xmldecode($canonicalDocumentString);

    warn "[LOG] Merging identification of the end and start position\n";
    $start_position = 0;
    $end_position = 0;
    &_merge_sections(\@section_starts, \@section_ends, \$start_position, \$end_position, \@sections, \@section_infos, 0, undef);

    # if ($debug_devel_level == 1) {
	# warn "[LOG/$debug_devel_level] Check merging identification of the end and start position\n";
	
	# foreach $section (@sections) {
	#     ($start_position, $end_position) = ($section->getFrom, $section->getTo);
 	#     warn "[LOG/$debug_devel_level] Section from $start_position to $end_position\n";
	#     print STDERR "\t" . substr($canonicalDocumentString, $start_position, $end_position - $start_position + 1) . "\n";
	# }
    # }

#     exit;

    return($canonicalDocumentString, \@sections);
}

sub _merge_sections {

    my ($start_position_ref, $end_position_ref, $i_start_ref, $i_end_ref, $sections_ref, $section_infos_ref, $depth, $parent_section) = @_;

    my $section;
    my $current_start_position = $$i_start_ref;

    my @child_sections;
    my $i;
    my $newparent_section;
    my @created_sections;

    my $rank = 0;

    while(($$i_start_ref < scalar(@$start_position_ref)) && ($start_position_ref->[$$i_start_ref]->[0] < $end_position_ref->[$$i_end_ref])) {
	$$i_start_ref++;

	my @tmp;
	$section = Lingua::Ogmios::Annotations::Section->new({
	    'from' => $start_position_ref->[$current_start_position]->[0],
	    'to' => $end_position_ref->[$$i_end_ref],
	    'title' => $start_position_ref->[$current_start_position]->[1]->{'title'},
	    'type' => $start_position_ref->[$current_start_position]->[1]->{'type'},
# 	    'title' => $section_infos_ref->[$current_start_position]->{'title'},
# 	    'type' => $section_infos_ref->[$current_start_position]->{'type'},
	    'parent_section' => $parent_section,
	    'child_sections' => \@tmp,
# 	    'child_sections' => \@child_sections,
	    'rank' => $rank++,
							     }
	    );

	push @created_sections, $section;
	$newparent_section = $section;

	push @{$section->child_sections}, &_merge_sections($start_position_ref, $end_position_ref, $i_start_ref, $i_end_ref, $sections_ref, $section_infos_ref , $depth + 1, $newparent_section);

	$section->setTo($end_position_ref->[$$i_end_ref]);
	push @$sections_ref, $section;
	$current_start_position = $$i_start_ref;

	$$i_end_ref++;

    }
    return(@created_sections);
}



sub getCanonicalDocument {
    my ($self) = @_;

    return($self->{'canonical_document'});
}

# sub setCanonicalDocument_SectionPosition {
#     my ($self, $canonicalDocument_SectionPosition) = @_;

#     $self->{'canonical_document_section_position'} = $canonicalDocument_SectionPosition;
# }

# sub getCanonicalDocument_SectionPosition {
#     my ($self) = @_;

#     return($self->{'canonical_document_section_position'});
# }

sub setRelevanceSection {
    my ($self, $relevance_section) = @_;

    $self->{'relevance_section'} = $relevance_section->toString;
}

sub getRelevanceSection {
    my ($self) = @_;

    return($self->{'relevance_section'});
}

sub setAcquisitionSection {
    my ($self, $acquisition_section) = @_;

    $self->{'acquisition_section'} = $acquisition_section->cloneNode(1); #->toString;
}

sub getAcquisitionSection {
    my ($self) = @_;

    return($self->{'acquisition_section'});
}

sub getNamespace
{
    my $self;
    if (UNIVERSAL::isa($_[0], 'Lingua::Ogmios::Annotations')) {
	$self = shift;
    } else {
	$self = Lingua::Ogmios::Annotations->new;
    }
    my $file = shift;

    my $line;
    my $xmlns = undef;

    open FILE, $file;
    binmode(FILE);

    while(($line=<FILE>)){
	if ($line =~ /xmlns=\"?([^\"]+)\"?/) {
            $xmlns = $1;
	    next;
        }
    };
    close FILE;

    $self->setNamespace($xmlns);

    return($xmlns);
}

sub setNamespace {
    my ($self, $ns) = @_;

    $self->{"Namespace"} = $ns;
}

sub getSectionLevel {
    my ($self) = @_;

    return($self->{'section_level'});
}

sub getTokenLevel {
    my ($self) = @_;

    return($self->{'token_level'});
}

sub getWordLevel {
    my ($self) = @_;

    return($self->{'word_level'});
}

sub getPhraseLevel {
    my ($self) = @_;

    return($self->{'phrase_level'});
}

sub getEnumerationLevel {
    my ($self) = @_;

    return($self->{'enumeration_level'});
}

sub getSentenceLevel {
    my ($self) = @_;

    return($self->{'sentence_level'});
}

sub getSyntacticRelationLevel {
    my ($self) = @_;

    return($self->{'syntactic_relation_level'});
}

sub getSemanticUnitLevel {
    my ($self) = @_;

    return($self->{'semantic_unit_level'});
}

sub getDomainSpecificRelationLevel {
    my ($self) = @_;

    return($self->{'domain_specific_relation_level'});
}

sub getAnaphoraRelationLevel {
    my ($self) = @_;

    return($self->{'anaphora_relation_level'});
}

sub getLemmaLevel {
    my ($self) = @_;

    return($self->{'lemma_level'});
}

sub getLogLevel {
    my ($self) = @_;

    return($self->{'log_level'});
}

sub getMorphosyntacticFeaturesLevel {
    my ($self) = @_;

    return($self->{'morphosyntactic_features_level'});
}

sub getSemanticFeaturesLevel {
    my ($self) = @_;

    return($self->{'semantic_features_level'});
}

sub getStemLevel {
    my ($self) = @_;

    return($self->{'stem_level'});
}

sub addSection {
    my ($self, $section, $parentSection) = @_;

    my $parentSection2;

    my $id = $self->getSectionLevel->addElement($section);

    if (defined $parentSection) {
	if (ref($parentSection) eq "") {
	    if ($self->getSectionLevel->existsElement($parentSection)) {
		$parentSection2 = $self->getSectionLevel->getElement($parentSection);
	    }
	} else {
	    $parentSection2 = $parentSection;
	}
	if (defined $parentSection2) {
	    $section->parent_section($parentSection2);
	    push @{$parentSection2->child_sections}, $section;
	}
    }

    warn "section $id added\n" unless $debug_devel_level != 1;
    return($id);
}

sub addToken {
    my ($self, $token) = @_;

    my $id = $self->getTokenLevel->addElement($token);
    warn "token $id added\n" unless $debug_devel_level != 1;
    return($id);
}

sub addWord {
    my ($self, $word) = @_;


    my $id = $self->getWordLevel->addElement($word);
    warn "word $id added\n" unless $debug_devel_level != 1;
    return($id);
}

sub addSentence {
    my ($self, $sentence) = @_;

    my $id = $self->getSentenceLevel->addElement($sentence);
    warn "sentence $id added\n" unless $debug_devel_level != 1;
    return($id);
}


sub addAnaphoraRelation {
    my ($self, $anaphorarelation) = @_;

    my $id = $self->getAnaphoraRelationLevel->addElement($anaphorarelation);
    warn "Anaphora relation $id added\n" unless $debug_devel_level != 1;
    return($id);
}


 

sub addDomainSpecificRelation {
    my ($self, $domainspecificrelation) = @_;

    my $id = $self->getDomainSpecificRelationLevel->addElement($domainspecificrelation);
    warn "Domain specific relation $id added\n" unless $debug_devel_level != 1;
    return($id);
}

sub addLemma {
    my ($self, $lemma) = @_;

    my $id = $self->getLemmaLevel->addElement($lemma);
    warn "Lemma $id added\n" unless $debug_devel_level != 1;
    return($id);
}

 
sub addMorphosyntacticFeatures {
    my ($self, $morphosyntacticfeatures) = @_;

    my $id = $self->getMorphosyntacticFeaturesLevel->addElement($morphosyntacticfeatures);
    warn "Morphosyntactic features $id added\n" unless $debug_devel_level != 1;
    return($id);
}


sub addPhrase {
    my ($self, $phrase) = @_;

#    warn "AddPhrase\n";
    my $id = $self->getPhraseLevel->addElement($phrase);
#    warn "Phrase $id added\n"; # unless $debug_devel_level != 1;
    return($id);
}

sub addEnumeration {
    my ($self, $enumeration) = @_;

#    warn "AddEnumeration\n";
    my $id = $self->getEnumerationLevel->addElement($enumeration);
#    warn "Enumeration $id added\n"; # unless $debug_devel_level != 1;
    return($id);
}

 
sub addSemanticFeatures {
    my ($self, $semanticfeatures) = @_;

    my $id = $self->getSemanticFeaturesLevel->addElement($semanticfeatures);
    warn "Semantic features $id added\n" unless $debug_devel_level != 1;
    return($id);
}

sub delSemanticFeaturesFromTermId {
    my ($self, $semanticUnit) = @_;

    my $id;
    my $semanticFeatures ;

    my @tmp;

    my $i = 0;
    # warn "#SemF: " . scalar(@{$self->getSemanticFeaturesLevel->getElementFromIndex("refid_semantic_unit", $semanticUnit->getId)}) . "\n";

    foreach $semanticFeatures (@{$self->getSemanticFeaturesLevel->getElementFromIndex("refid_semantic_unit", $semanticUnit->getId)}) {
	if (defined $semanticFeatures) {
	    # warn "=>" . $semanticFeatures->getId . " (" . $i++ . ")\n";
	    $id = $self->getSemanticFeaturesLevel->delElement($semanticFeatures);
	    warn "semantic features $id deleted\n" unless $debug_devel_level != 1;
	    push @tmp, $id;
	} else {
#	    warn "No semantic features\n";
	}
    }
    return(\@tmp);
}



sub addStem {
    my ($self, $stem) = @_;

    my $id = $self->getStemLevel->addElement($stem);
    warn "stem $id added\n" unless $debug_devel_level != 1;
    return($id);
}

sub addSyntacticRelation {
    my ($self, $syntacticrelation) = @_;

    my $id = $self->getSyntacticRelationLevel->addElement($syntacticrelation);
    warn "Syntactic relation $id added\n" unless $debug_devel_level != 1;
    return($id);
}

sub addLogProcessing {
    my ($self, $logprocessing) = @_;

    my $id = $self->getLogLevel->addElement($logprocessing);
    warn "Log processing $id added\n" unless $debug_devel_level != 1;
}

sub addSemanticUnit {
    my ($self, $semanticUnit) = @_;

    my $id = $self->getSemanticUnitLevel->addElement($semanticUnit);
    warn "semantic unit $id added\n" unless $debug_devel_level != 1;
    return($id);
}

sub delSemanticUnit {
    my ($self, $semanticUnit) = @_;

    # warn "del : " . $semanticUnit->getId . "\n";
    $self->delSemanticFeaturesFromTermId($semanticUnit);
    # warn "OK\n";
    my $id = $self->getSemanticUnitLevel->delElement($semanticUnit);
    # warn "End\n";
#      if ($semanticUnit->reference_name eq "refid_phrase") {
#  	warn "remove " . $semanticUnit->reference . "\n";
#  	$self->getSemanticUnitLevel->delElementToIndexes($semanticUnit->reference);
#      }


    warn "semantic unit $id deleted\n" unless $debug_devel_level != 1;
    return($id);
}

sub delEnumeration {
    my ($self, $enumeration) = @_;

    my $id = $self->getEnumerationLevel->delElement($enumeration);

#      if ($semanticUnit->reference_name eq "refid_phrase") {
#  	warn "remove " . $semanticUnit->reference . "\n";
#  	$self->getSemanticUnitLevel->delElementToIndexes($semanticUnit->reference);
#      }


    warn "semantic unit $id deleted\n" unless $debug_devel_level != 1;
    return($id);
}


sub XMLout {
    my ($self) = @_;
    my $level;

    my $str;

    $str = $self->getAcquisitionSection->toString;
    $str .= "\n    <linguisticAnalysis>\n";
    foreach $level ($self->getLevels4Print) {
#	warn "$level\n";
	$str .= $level->XMLout;
    }
    $str .= "    </linguisticAnalysis>\n";
    if (defined $self->getRelevanceSection) {
	$self->getRelevanceSection; #->toString;
    }

    return($str);
}

sub getNamedEntitiesByType {
    my ($self, $type) = @_;

    my $element;
    my @tmp;

    foreach $element (@{$self->getSemanticUnitLevel->getElements}) {
	if (($element->isNamedEntity) && ($element->NEtype eq $type)){
	    push @tmp, $element;
	}
    }
    return(\@tmp);
}

sub getTermsByType {
    my ($self, $type) = @_;

    my $element;
    my @tmp;
    my $semf;

    foreach $element (@{$self->getSemanticUnitLevel->getElements}) {
	if ($element->isTerm) {
	    if ($self->getSemanticFeaturesLevel->existsElementFromIndex("refid_semantic_unit", $element->getId)) {
	    $semf = $self->getSemanticFeaturesLevel->getElementFromIndex("refid_semantic_unit", $element->getId)->[0];
	    if ($semf->first_node_first_semantic_category eq $type) {
		push @tmp, $element;
	    }
	    }
	}
    }
    return(\@tmp);
}

sub existsSectionLevel {
    my ($self) = @_;

    return($self->{'section_level'}->getSize != 0);
}

sub existsTokenLevel {
    my ($self) = @_;

    return($self->{'token_level'}->getSize != 0);
}

sub existsWordLevel {
    my ($self) = @_;

    return($self->{'word_level'}->getSize != 0);
}

sub existsPhraseLevel {
    my ($self) = @_;

    return($self->{'phrase_level'}->getSize != 0);
}

sub existsEnumerationLevel {
    my ($self) = @_;

    return($self->{'enumeration_level'}->getSize != 0);
}

sub existsSentenceLevel {
    my ($self) = @_;

    return($self->{'sentence_level'}->getSize != 0);
}

sub existsSyntacticRelationLevel {
    my ($self) = @_;

    return($self->{'syntactic_relation_level'}->getSize != 0);
}

sub existsSemanticUnitLevel {
    my ($self) = @_;

    return($self->{'semantic_unit_level'}->getSize != 0);
}

sub existsDomainSpecificRelationLevel {
    my ($self) = @_;

    return($self->{'domain_specific_relation_level'}->getSize != 0);
}

sub existsAnaphoraRelationLevel {
    my ($self) = @_;

    return($self->{'anaphora_relation_level'}->getSize != 0);
}

sub existsLemmaLevel {
    my ($self) = @_;

    return($self->{'lemma_level'}->getSize != 0);
}

sub existsLogLevel {
    my ($self) = @_;

    return($self->{'log_level'}->getSize != 0);
}

sub existsMorphosyntacticFeaturesLevel {
    my ($self) = @_;

    return($self->{'morphosyntactic_features_level'}->getSize != 0);
}

sub existsSemanticFeaturesLevel {
    my ($self) = @_;

    return($self->{'semantic_features_level'}->getSize != 0);
}

sub existsStemLevel {
    my ($self) = @_;

    return($self->{'stem_level'}->getSize != 0);
}


1;

__END__

=head1 NAME

Lingua::Ogmios::Annotations - Perl extension for representing the annotations in the Ogmios platform.

=head1 SYNOPSIS

use Lingua::Ogmios::???;

my $annotations = Lingua::Ogmios::???::new();

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

