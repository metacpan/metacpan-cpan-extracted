package Lingua::Ogmios::DocumentRecord;

use strict;
use warnings;

# use XML::Simple;
use Lingua::Ogmios::Annotations;
use Lingua::Ogmios::Annotations::LogProcessing;

my $debug_devel_level = 0;

sub new {
    my ($class, $document_record, $platformConfig) = @_;

    my $doc = {
	'annotations' => Lingua::Ogmios::Annotations->new($platformConfig),
	'id' => undef,
	'attributes' => [],
    };

    bless $doc, $class;

    # Parsing the file and loading into the structures
    $doc->setId($document_record);
    $doc->_parse($document_record, $platformConfig);
    # Making the indexes

    return($doc);
}

sub setId {
    my ($self, $document_record) = @_;

    my $id;

    if (UNIVERSAL::isa($document_record, 'XML::LibXML::Element')) {
	$id = $document_record->getAttribute("id");
    } else {
	$id = $document_record;
    }

    if (defined($id)) {
	$self->getAnnotations->{'id'} = $id;
    }
    else {
	warn "No id for record for doc " . ($self->getCount + 1) . "\n";
    }
}

sub getId {
    my ($self) = @_;

    return($self->getAnnotations->{'id'});
}

sub setAttributes {
    my ($self, $attributes) = @_;
    my $attr;

    foreach $attr (@$attributes) {
	push @{$self->{'attributes'}}, {'nodeName' => $attr->nodeName,
					'value' => $attr->value,
					};
    }
}

sub getAttributes {
    my ($self) = @_;

    return($self->{'attributes'});
}

sub _parse {
    my ($self, $document_record, $platformConfig) = @_;

    my $lingAnalysisLoad = $platformConfig->linguisticAnnotationLoading;

    warn "Processing document " . $self->getId . "\n";

    my @attr = $document_record->attributes;
    $self->setAttributes(\@attr);

    my $acquisition_section_node = $document_record->getChildrenByTagName('acquisition')->get_node(1);
#    my $acquisition_section_node;
    if (defined $acquisition_section_node) {
#	$acquisition_section_node = $acquisition_section_node_orig->cloneNode(1);
	$self->getAnnotations->setAcquisitionSection($acquisition_section_node);
	$self->getAnnotations->setLanguageFromXMLAndProperties($acquisition_section_node);
	if (!defined($self->getAnnotations->getLanguage)) {
	    $self->getAnnotations->setLanguage(uc($platformConfig->getOgmiosDefaultLanguage));
	    print STDERR $self->getAnnotations->getLanguage . "\n";
	}
	$self->getAnnotations->setURLs($acquisition_section_node);
	$self->getAnnotations->loadCanonicalDocument($acquisition_section_node);
    } else {
	die "no acquisition node\n";
    }
#    for $document_record ($document_record->getChildrenByTagName('linguisticAnalysis')) {
# TODO
    if ((defined $lingAnalysisLoad) && ($lingAnalysisLoad == 1) && (defined $document_record->getChildrenByTagName('linguisticAnalysis')->get_node(1))) {
	$self->getAnnotations->loadLinguisticAnalysis($document_record->getChildrenByTagName('linguisticAnalysis')->get_node(1));
    }

    my $relevance_section_node = $document_record->getChildrenByTagName('relevance')->get_node(1);
    if (defined $relevance_section_node) {
	$self->getAnnotations->setRelevanceSection($relevance_section_node);
    }
}


sub setAnnotations {
    my ($self) = @_;
    $self->{'annotations'} = undef;
}

sub getAnnotations {
    my ($self) = @_;

    return($self->{'annotations'});
}

sub _char_type_identification {
    my ($self, $character) = @_;


    # Definition of the character types
    my $alpha="[A-Za-z\x{C0}-\x{D6}\x{D8}-\x{F6}\x{F8}-\x{FF}\x{0400}-\x{0482}\x{048A}-\x{04FF}]";
    my $num="[0-9]";
    my $sep="[ \\s\\t\\n\\r]";

    my $current_char_type;
    my $current_char_type_string;

    # default is symbol
    $current_char_type = 4;$current_char_type_string = "symb";

#     print STDERR "$character\n";

    if($character=~/$alpha/o){$current_char_type = 1;$current_char_type_string = "alpha";};
    if($character=~/$num/o){$current_char_type = 2;$current_char_type_string = "num";};
    if($character=~/$sep/o){$current_char_type = 3;$current_char_type_string = "sep";};

    return($current_char_type, $current_char_type_string);
}

sub _tokenCreation {
    my ($self,$current_token_string, $current_token_string_length, $previous_char_type_string, $offset) = @_;

    # code for the character types
    # 1: alphabetic
    # 2: numeric
    # 3: separator
    # 4: symbol
    # 0 : not defined
#     warn "add token: $current_token_string\n";


#     warn "Creation of new token\n";
    my $token = Lingua::Ogmios::Annotations::Token->new(
	{'content' => $current_token_string,
	 'type' => $previous_char_type_string,
	 'from' => $offset,
	 'to' => $offset + $current_token_string_length - 1,
	});
#     $token->print;
    return($token);
}

sub tokenisation {
    my ($self) = @_;

    if ($self->getAnnotations->getTokenLevel->getSize != 0) {
	warn "tokens exist - no tokenisation required\n";
	return(0);
    }

    warn "[LOG] Tokenisation (" . $self->getId . ")\n";

    my $canonicalDocument = $self->getAnnotations->getCanonicalDocument;

#     warn $self->getId . "\n";
#     warn $canonicalDocument . "\n";

    my @characters = split //, $canonicalDocument;

    if (scalar @characters) {

	my $character;

	my $current_token_string = "";
	my $current_token_string_length = 0;
	my $current_token_type = 0;
	my $current_char_type = 0;
	my $current_char_type_string = "";
	my $previous_char_type = 0;
	my $previous_char_type_string = "";
	my $offset = 0;

	my $current_id;
	my $current_token;

	$character = $characters[0];
	($current_char_type, $current_char_type_string) = $self->_char_type_identification($character);
	$current_token_string_length = 1;
	$current_token_string = $character;
	$previous_char_type = $current_char_type;
	$previous_char_type_string = $current_char_type_string;

	if ($current_char_type == 4) {
	    $current_token = $self->_tokenCreation($character, 1, $current_char_type_string, $offset);
	    $current_id = $self->getAnnotations->addToken($current_token);
	    $current_token_string = "$character";
	    $current_token_string_length = 1;
	    $previous_char_type = $current_char_type;
	    $previous_char_type_string = $current_char_type_string;
	    $offset += $current_token_string_length;
	}
	my $i;
	for($i=1;$i<scalar(@characters);$i++) {
	    $character = $characters[$i];
	    # identification of the type of the current character

	    ($current_char_type, $current_char_type_string) = $self->_char_type_identification($character);

	    if (($current_char_type == $previous_char_type) && ($current_char_type != 4) && 
		(!($self->getAnnotations->getSectionLevel->existsElementFromIndex('from', $offset + $current_token_string_length ))) && 
		(!($self->getAnnotations->getSectionLevel->existsElementFromIndex('to', $offset + $current_token_string_length - 1)))) {
		$current_token_string .= $character;
		$current_token_string_length++;
	    } else {
		if ($previous_char_type != 4) {
		    $current_token = $self->_tokenCreation($current_token_string, $current_token_string_length, $previous_char_type_string, $offset);
		    $current_id = $self->getAnnotations->addToken($current_token);
		    $offset += $current_token_string_length;
		}
		if ($current_char_type == 4) {
		    $current_token_string = $character;
		    $current_token_string_length = 1;		
		    $current_token = $self->_tokenCreation($current_token_string, $current_token_string_length, $current_char_type_string, $offset);
		    $current_id = $self->getAnnotations->addToken($current_token);
		    $offset += $current_token_string_length;
		}
		# and create a new token string
		$previous_char_type = $current_char_type;
		$previous_char_type_string = $current_char_type_string;
		$current_token_string = $character;
		$current_token_string_length = 1;
	    }
	}
	if ($current_char_type != 4) {
	    $current_token = $self->_tokenCreation($current_token_string, $current_token_string_length, $previous_char_type_string, $offset);
	    $current_id = $self->getAnnotations->addToken($current_token);
	}
    } else {
	$self->getAnnotations
    }
    
    $self->getAnnotations->getSectionLevel->rebuildIndex();
    
    $self->getAnnotations->addLogProcessing(
	Lingua::Ogmios::Annotations::LogProcessing->new(
	    { 'comments' => 'Found ' . $self->getAnnotations->getTokenLevel->getSize .  ' tokens\n',
	      'list_modified_level' => ["token_level"],
	    }
	)
	);
#     $self->getAnnotations->addLogProcessing(
# 	Lingua::Ogmios::Annotations::LogProcessing->new(
# 	    { 'comments' => 'Found ' . $self->getAnnotations->getSectionLevel->getSize .  ' sections\n',
# 	    }
# 	)
# 	);
    $self->getAnnotations->addLogProcessing(Lingua::Ogmios::Annotations::LogProcessing->new(
						{ 'software_name' => 'internal processing',
						  'comments' => 'Tokenisation. Can not be change\n',
						  'list_modified_level' => ["token_level"],
						}));
    warn "[LOG] Check merging identification of the end and start position (1)\n";
}

sub tokenisation2 {
    my ($self) = @_;

    warn "[LOG] Tokenisation2 (" . $self->getId . ")\n";

    my $canonicalDocument = $self->getAnnotations->getCanonicalDocument;

    my @characters = split //, $canonicalDocument;

    my $character;

    my $current_token_string = "";
    my $current_token_string_length = 0;
    my $current_token_type = 0;
    my $current_char_type = 0;
    my $current_char_type_string = "";
    my $previous_char_type = 0;
    my $previous_char_type_string = "";
    my $offset = 0;

    my $current_id;
    my $current_token;

    $self->getAnnotations->addLogProcessing(Lingua::Ogmios::Annotations::LogProcessing->new(
	{ 'software_name' => 'internal processing',
	  'comments' => 'Tokenisation. Can not be change\n',
        }));
    $character = $characters[0];
    ($current_char_type, $current_char_type_string) = $self->_char_type_identification($character);
    $current_token_string_length = 1;
    $current_token_string = $character;
    $previous_char_type = $current_char_type;
    $previous_char_type_string = $current_char_type_string;

    if ($current_char_type == 4) {
	$current_token = $self->_tokenCreation($character, 1, $current_char_type_string, $offset);
	$current_id = $self->getAnnotations->addToken($current_token);
	$current_token_string = "$character";
	$current_token_string_length = 1;
	$previous_char_type = $current_char_type;
	$previous_char_type_string = $current_char_type_string;
	if ($self->getAnnotations->getSectionLevel->existsElementFromIndex('from', $offset)) {
	    $self->getAnnotations->getSectionLevel->changeRefFromIndexField('from', $offset, $current_token);
	}
	$offset += $current_token_string_length;
	if ($self->getAnnotations->getSectionLevel->existsElementFromIndex('to', $offset)) {
	    $self->getAnnotations->getSectionLevel->changeRefFromIndexField('to', $offset, $current_token);
	}
    }
    my $i;
    for($i=1;$i<scalar(@characters);$i++) {
	$character = $characters[$i];
	# identification of the type of the current character

	($current_char_type, $current_char_type_string) = $self->_char_type_identification($character);

	if (($current_char_type == $previous_char_type) && ($current_char_type != 4) && 
	    (!($self->getAnnotations->getSectionLevel->existsElementFromIndex('from', $offset + $current_token_string_length ))) && 
	    (!($self->getAnnotations->getSectionLevel->existsElementFromIndex('to', $offset + $current_token_string_length )))) {
	    $current_token_string .= $character;
	    $current_token_string_length++;
	} else {
	    if ($previous_char_type != 4) {
		$current_token = $self->_tokenCreation($current_token_string, $current_token_string_length, $previous_char_type_string, $offset);
		$current_id = $self->getAnnotations->addToken($current_token);
 	    if ($self->getAnnotations->getSectionLevel->existsElementFromIndex('from', $offset)) {
 		$self->getAnnotations->getSectionLevel->changeRefFromIndexField('from', $offset, $current_token);
 	    }
 	    if ($self->getAnnotations->getSectionLevel->existsElementFromIndex('to', $offset + $current_token_string_length)) {
 		$self->getAnnotations->getSectionLevel->changeRefFromIndexField('to', $offset + $current_token_string_length, $current_token);
 	    }
		$offset += $current_token_string_length;
	    }
	    if ($current_char_type == 4) {
		$current_token_string = $character;
		$current_token_string_length = 1;		
		$current_token = $self->_tokenCreation($current_token_string, $current_token_string_length, $current_char_type_string, $offset);
		$current_id = $self->getAnnotations->addToken($current_token);
 	    if ($self->getAnnotations->getSectionLevel->existsElementFromIndex('from', $offset)) {
 		$self->getAnnotations->getSectionLevel->changeRefFromIndexField('from', $offset, $current_token);
 	    }
 	    if ($self->getAnnotations->getSectionLevel->existsElementFromIndex('to', $offset + $current_token_string_length)) {
 		$self->getAnnotations->getSectionLevel->changeRefFromIndexField('to', $offset + $current_token_string_length, $current_token);
 	    }
		$offset += $current_token_string_length;
	    }
	    # and create a new token string
	    $previous_char_type = $current_char_type;
	    $previous_char_type_string = $current_char_type_string;
	    $current_token_string = $character;
	    $current_token_string_length = 1;
	}
    }
    if ($current_char_type != 4) {
	$current_token = $self->_tokenCreation($current_token_string, $current_token_string_length, $previous_char_type_string, $offset);
	$current_id = $self->getAnnotations->addToken($current_token);
    }
    if ($self->getAnnotations->getSectionLevel->existsElementFromIndex('from', $offset + $current_token_string_length)) {
	$self->getAnnotations->getSectionLevel->changeRefFromIndexField('from', $offset + $current_token_string_length, $current_token);
    }
    if ($self->getAnnotations->getSectionLevel->existsElementFromIndex('to', $offset + $current_token_string_length)) {
	$self->getAnnotations->getSectionLevel->changeRefFromIndexField('to', $offset + $current_token_string_length, $current_token);
    }

    $self->getAnnotations->getSectionLevel->rebuildIndex();

    if ($self->getAnnotations->getTokenLevel->getSize == 0) {

	$self->getAnnotations->addLogProcessing(
	    Lingua::Ogmios::Annotations::LogProcessing->new(
		{ 'comments' => 'Found ' . $self->getAnnotations->getTokenLevel->getSize .  ' tokens\n',
		}
	    )
	    );
	$self->getAnnotations->addLogProcessing(
	    Lingua::Ogmios::Annotations::LogProcessing->new(
		{ 'comments' => 'Found ' . $self->getAnnotations->getSectionLevel->getSize .  ' sections\n',
		}
	    )
	    );
    }
	warn "[LOG] Check merging identification of the end and start position (2)\n";
}

sub computeSectionFromToken {
    my ($self, $record_log) = @_;

    warn "[LOG] Compute Section Ref From Tokens (" . $self->getId . ")\n";

    my $token;
    my $lasttoken = $self->getAnnotations->getTokenLevel->getLastElement;
    my $section;
    foreach $section (@{$self->getAnnotations->getSectionLevel->getElements}) {
 	# warn "check for section " . $section->getId . " (" . $section->getFrom . " - " . $section->getTo . ")\n";
	if ($self->getAnnotations->getTokenLevel->existsElementFromIndex('from', $section->getFrom)) {
	    $token = $self->getAnnotations->getTokenLevel->getElementFromIndex('from', $section->getFrom)->[0];
	    $self->getAnnotations->getSectionLevel->changeRefFromIndexField('from', $token->getFrom, $token);
	# } else {
	#     die "==> " . $section->getFrom . "\n";
	}
 	if ($self->getAnnotations->getTokenLevel->existsElementFromIndex('to', $section->getTo)) {
	    $token = $self->getAnnotations->getTokenLevel->getElementFromIndex('to', $section->getTo)->[0];
  	    #warn "in to\n";
 	    $self->getAnnotations->getSectionLevel->changeRefFromIndexField('to', $token->getTo, $token);
 	} else {
 		if ($self->getAnnotations->getTokenLevel->existsElementFromIndex('from', $section->getTo)) {
		    $token = $self->getAnnotations->getTokenLevel->getElementFromIndex('from', $section->getTo)->[0];
		    if (defined $token->previous) {
			$self->getAnnotations->getSectionLevel->changeRefFromIndexField('to', $token->getFrom, $token->previous);
		    } else {
			$self->getAnnotations->getSectionLevel->changeRefFromIndexField('to', $token->getFrom, $token);
		    }
		    warn "ok\n";
 		} else {
		    if (ref($section->getTo) eq "Lingua::Ogmios::Annotations::Token") {
#			$self->getAnnotations->getSectionLevel->addElementToIndex($section->getTo,'to');
		    } else {
			if ($self->getAnnotations->getTokenLevel->existsElementFromIndex('to', $section->getTo - 1)) {
			    $token = $self->getAnnotations->getTokenLevel->getElementFromIndex('to', $section->getTo - 1)->[0];
			    $self->getAnnotations->getSectionLevel->changeRefFromIndexField('to', $section->getTo, $token);
			    # } elsif ($self->getAnnotations->getTokenLevel->existsElementFromIndex('to', $section->getTo + 1)) {
			    # 	$token = $self->getAnnotations->getTokenLevel->getElementFromIndex('to', $section->getTo + 1)->[0];
			    # 	$self->getAnnotations->getSectionLevel->changeRefFromIndexField('to', $section->getTo, $token);
			    warn "ok2\n";
			} elsif ($self->getAnnotations->getTokenLevel->existsElementFromIndex('to', $section->getTo + 1)) {
			    $token = $self->getAnnotations->getTokenLevel->getElementFromIndex('to', $section->getTo + 1)->[0];
			    $self->getAnnotations->getSectionLevel->changeRefFromIndexField('to', $section->getTo, $token);
			    } else {
				warn "set to last token\n";
				$self->getAnnotations->getSectionLevel->changeRefFromIndexField('to', $section->getTo, $lasttoken);
			    # 	    die "==> " . $section->getTo->getContent . "\n";
			}
		    }
		}
# 	    } else {
# 		warn "not defined\n";
# 	    }
 	}
 	# warn "Check for corrected section " . $section->getId . " (" . $section->getFrom . " - " . $section->getTo . ")\n";

 	# warn "Last token  " . $lasttoken->getId . " (" . $lasttoken->getFrom . " - " . $lasttoken->getTo . ")\n";
 	# warn "Check for corrected section " . $section->getId . " (" . $section->getFrom . " - " . $section->getTo . ")\n";
	# warn ".\n";
    }
    # exit;
    # warn "===\n";
    $self->getAnnotations->getSectionLevel->rebuildIndex();
    # warn "+++\n";
    if ($record_log) {
    $self->getAnnotations->addLogProcessing(
	Lingua::Ogmios::Annotations::LogProcessing->new(
	    { 'comments' => 'Found ' . $self->getAnnotations->getSectionLevel->getSize .  ' sections\n',
	      'list_modified_level' => ["section_level"],
	    }
	)
	);
    }
    warn "[LOG] Check merging identification of the end and start position (3)\n";
}


sub XMLout {
    my ($self) = @_;

    my $str;
    my $attr;

    $str = '  <documentRecord';
    foreach $attr (@{$self->getAttributes}) {
	$str .= " " . $attr->{'nodeName'} . '="' . $attr->{'value'} . '"';
    }
    $str .= ">\n";

    $str .= $self->getAnnotations->XMLout;
    $str .= "  </documentRecord>\n";

    return($str);
}


1;

__END__
    

=head1 NAME

Lingua::Ogmios::DocumentRecord - Perl extension for managing a document in the Ogmios platform

=head1 SYNOPSIS

use Lingua::Ogmios::???;

my $docRecord = Lingua::Ogmios::???::new();


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

