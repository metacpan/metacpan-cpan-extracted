# MetaMap::DataStructures::Phrase
# (Last Updated $Id: Phrase.pm,v 1.80 2016/01/07 22:49:33 btmcinnes Exp $)
#
# Perl module that provides a perl interface to the
# Unified Medical Language System (UMLS)
#
# Copyright (c) 2016
#
# Sam Henry, Virginia Commonwealth University 
# henryst at vcu.edu 
#
# Bridget T. McInnes, Virginia Commonwealth University 
# btmcinnes at vcu.edu 
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to
#
# The Free Software Foundation, Inc.,
# 59 Temple Place - Suite 330,
# Boston, MA  02111-1307, USA.

package MetaMap::DataStructures::Phrase;  
use strict;
use warnings;

use MetaMap::DataStructures::Token;
use MetaMap::DataStructures::Mapping;
use MetaMap::DataStructures::Concept;

#----------------------------------------
#               constructor
#----------------------------------------
#  constructor method to create a new Phrase object. It is recommended to 
#      construct Phrase objects from createFromText, since it is easier and 
#      garauntees all data structures are created properly.
#  input : $text <- the human-readable text of the Phrase
#          \@mappings <- mapping objects of this Phrase
#          \@orderedConceptList <- concepts object list in sequential order.
#                                  Where there is disambiguation (and therefore
#                                  multiple concepts mappings to a single term
#                                  a vertical dimension is created. This is 
#                                  therefore an array of arrays, where each 
#                                  array contains 1 or more concept objects.
#          \@concepts <- concept objects ordered as they are read in, not 
#                        necassarily sequential.
#          \@tokens <- tokens objects ordered as read in
#  output: $self <- a new instance of a Phrase Object
sub new {
    #create and bless self
    my $class = shift;
    my $self = {};
    bless $self, $class;

    #grab variables
    $self->{text} = shift;
    $self->{mappings} = shift; #sequential mappings
    $self->{orderedConceptList} = shift; #ordered 2-D array of concepts
    $self->{concepts} = shift;  #ordered as read in (not sequential)
       #These are unique concept objects but necassarily unique CUIs
    $self->{tokens} = shift;

    return $self;
}

#  method creates and returns a concept from text 
#  input : $inputText <- a MetaMap Prolog Machine Output Phrase block or 
#                        equivalent.
#          \@negatedCUIs <- a list of negated CUIs within the phrase, empty 
#                          is ok.
#  output: $self <- a new instance of a Phrase Object
sub createFromText {
    #grab the input
    my $inputText = shift;
    my $negatedCUIsRef = shift;

    #grab the full text
    $inputText =~ /phrase\((.*),\[(.*)\],(\d+)\/\d+,\[.*\]\)\./;
    my $text = $1;  #the text of the phrase
    my $syntaxText = $2;  #text containing the syntactic info
    my $phraseStartIndex = $3;  #character number the phrase begins at

    #remove trailing and leading quotes
    if ($text =~ m/'(.*)'/) {
	$text = $1;
    }

    #----- Token Creation -------------------------
    #get each token text
    my @tokenTexts = split /(adv|aux|compl|conj|det|head|mod|modal|pastpart|prep|pron|punc|shapes|verb|not_in_lex)\(/, $syntaxText;
    shift @tokenTexts;  #shift empty position 0 off

    #loop through each token text
    my @tokens = ();
    for (my $i = 0; $i < scalar @tokenTexts; $i+=2) {

	#get the type and token text
	my $type = $tokenTexts[$i];
	my $tokenText = $tokenTexts[$i+1];

	#add a new token to the list of tokens
	push @tokens, &MetaMap::DataStructures::Token::createFromText(
	    $type.'('.$tokenText);
    }

    #----- Mappings and Concept  Creation --------------
    #gets each mapping text and orders the concepts
    #   iterates through each mapping, and creates a new mapping
    #   for each mapping text.  For each new concept that is found
    #   it compares it with existing ordered concepts and sees if it 
    #   should add it to a 2-D array of ordered concepts.  The second
    #   dimension of the orderedConcepts array indicates multiple
    #   mappings for the token at that index
    #get each mapping text
    $inputText =~ m/mappings\(\[(.*)\)\./;
    my @mappingsTexts = split /map\(-/, $1;
    #remove the first element (text matched before 'map'
    shift @mappingsTexts;
    
    #loop through each mapping text
    my @orderedConcepts = ();  #an array of arrays of ordered concepts.  
    #   Where multiple mappings occur a new vertical dimension is added
    my @mappings = ();
    my @concepts = ();  #an array of unique concepts
    foreach my $mappingText(@mappingsTexts) {
	#add the map back on (from the split)
	$mappingText = 'map(-'.$mappingText;

	#grab the mapping score
	$mappingText =~ m/map\((-?\d+)/;
	my $mappingScore = $1;

	#grab the concepts associated with the mapping
	my @conceptTexts = split /ev\(-/, $mappingText;
	shift @conceptTexts;  #shift off the leading text

	#loop through each concept
	my @mappingConcepts = ();  # = a list of concepts by mapping 
                                   #   (as they appear when read in)
	foreach my $conceptText(@conceptTexts) {

	    #create the concept (put ev back on the front)
	    my $newConcept = &MetaMap::DataStructures::Concept::createFromText(
		'ev(-'.$conceptText, \@tokens);

	    #see where to place this concept within the context of the 
            # ordered concepts also see if the concept already exists 
            # (mappings repeat concepts) if it exists use the instance of 
            # that concept (oldConcept) in this mapping 
	    my $conceptExists = 0;
	    my $conceptIndex = -1;
	    for (my $i = 0; $i < scalar @orderedConcepts; $i++) {
		for (my $j = 0; $j < scalar @{ $orderedConcepts[$i] }; $j++) {
		    #grab the existing concept
		    my $oldConcept = $orderedConcepts[$i][$j];
		    
		    #check if an instance of the concept already exists
		    #   or if it is a new mapping of an existing concept
		    if ($newConcept->equals($oldConcept)) {
			#an instance of this concept alread exists, stop looping
			$conceptExists = 1;
			$newConcept = $oldConcept;
			last;
		    }
		    elsif ($newConcept->mapsToSameTokens($oldConcept)) {
			#this concept maps to the same tokens as an existing 
			#   concept record index, so must continue checking 
                        #   though to see if the concept already exists
			$conceptIndex = $i;
		    }  

		} #end inner ordered concept loop
		
		#check if you can quit early
		if ($conceptExists) {
		    last;  #an instance of this concept already exists, done
		}
		if ($conceptIndex >= 0) {
		    #this concept maps to the same token as an existing 
		    #   concept, your done
		    last;
		}
	    }  #end outer ordered concept loop

	    #done searching through existing concepts, update data structures
	     if (!$conceptExists) {
		 #update unordered concepts
		 push @concepts, $newConcept;
		 
		 if ($conceptIndex >= 0) {
		     #add to existing CUI list
		     push @{ $orderedConcepts[$conceptIndex] }, $newConcept;
		 }
		 else {
		     #create a new CUI list
		     #new concept, append ordered concepts with a new array
		     my @newArray = [ $newConcept ];
		     push @orderedConcepts, @newArray;
		     
		     my $index = (scalar @orderedConcepts)-1;
		 }
	    }

	    #add the concept to the list of mapping concepts
	    push @mappingConcepts, $newConcept;

	}#end concept text loop

	#create and save the new mapping
	push @mappings, MetaMap::DataStructures::Mapping->new(
	    $mappingScore, \@mappingConcepts);
    }   

    #----- Concept Negation ---------------------------
    #TODO possible problem with negations.  If a single phrase contains
    #   the same CUI multiple times how do I distinguish between the negated
    #   and non-negated one?
    for (my $i = 0; $i < scalar @orderedConcepts; $i++) {
	for (my $j = 0; $j < scalar @{ $orderedConcepts[$i] }; $j++) {
	    my $concept = $orderedConcepts[$i][$j];

	    #see if it is negated
	    foreach my $negatedCUI(@{$negatedCUIsRef}) {
		if ($concept->{cui} eq $negatedCUI) {
		    $concept->{isNegated} = 1;
		}
	    }
	}
    }

    #create and return the new phrase
    return MetaMap::DataStructures::Phrase->new(
	$text, \@mappings, \@orderedConcepts, \@concepts, \@tokens);
}


#----------------------------------------
#               methods
#----------------------------------------
#  method summarizes this phrase as a string
#  input : -
#  output: $string <- a string describing $self
sub toString {
    my $self = shift;
 
    #create head
    my $string = "Phrase:\n";
    $string .= "   $self->{text}\n";

    #add each token text
    $string .= "   tokens:*";
    foreach my $token(@{$self->{tokens}}) {
	$string .= $token->{text}."*";
    }
    $string .= "\n";
    
    #add each concept text
    $string .= "   concepts:*";
    foreach my $concept(@{$self->{concepts}}) {
	$string .= $concept->{text}."*";
    }
    $string .= "\n";
	
    #add each mapping to the string
    $string .= "   mappings:\n";
    foreach my $mapping(@{$self->{mappings}}) {
	$string .=  "   ".$mapping->toString()."\n";
    }

    return $string;
}

#  method compares this phrase to another and returns 1 if the two 
#   contain identical information
#  input : $other <- the Phrase object to compare against
#  output: boolean <- 1 if $self and $other are equivalent (equivalent texts, 
#          mappings, concepts, and tokens), else 0
sub equals {
    #grab input
    my $self = shift;
    my $other = shift;

    #compare texts
    if ($self->{text} ne $other->{text}) {
	return 0;
    }

    #compare mappings
    foreach my $mappingA(@{$self->{mappings}}){

	#check each mapping in B
	my $match = 0;
	foreach my $mappingB(@{$other->{mappings}}) {
	    if ($mappingA->equals($mappingB)) {
		$match = 1;
		last;
	    }
	}

	#mappingA has no equivalent mapping in $other
	#   so phrases are not identical
	if ($match < 1) {
	    return 0;
	}
    }

    #compare Concepts
    foreach my $conceptA(@{$self->{concepts}}){

	#check each concept in B
	my $match = 0;
	foreach my $conceptB(@{$other->{concepts}}) {
	    if ($conceptA->equals($conceptB)) {
		$match = 1;
		last;
	    }
	}

	#conceptA has no equivalent concept in $other
	#   so phrases are not identical
	if ($match < 1) {
	    return 0;
	}
    }

    #compare Tokens
    foreach my $tokenA(@{$self->{tokens}}){

	#check each token in B
	my $match = 0;
	foreach my $tokenB(@{$other->{tokens}}) {
	    if ($tokenA->equals($tokenB)) {
		$match = 1;
		last;
	    }
	}

	#tokenA has no equivalent mapping in $other
	#   so phrases are not identical
	if ($match < 1) {
	    return 0;
	}
    }

    #all fields are equivalent, return true
    return 1;
} 

#  method determines if this phrase contains the CUI provided as input
#   returns 1 if this phrase contains the CUI, else 0
#  input : $cui <- a string CUI code
#  output: boolean <- 1 if any $self contains the $cui
sub contains {
    #grab input
    my $self = shift;
    my $cui = shift;

    #check concept to see if it is the CUI
    my $containsCUI = 0;
    foreach my $concept(@{$self->{concepts}}) {
	if ($concept->{cui} eq $cui) {
	    $containsCUI = 1;
	    last;
	}
    }
    
    #return the result
    return $containsCUI;
}

1;

__END__

=head1 NAME

MetaMap::DataStructure::Phrase - provides a container for the phrase 
information extracted from machine readable MetaMap mapped text. 

=head1 DESCRIPTION

This package provides a container for the phrase information extracted 
from machine readable MetaMap mapped text. 

For more information please see the MetaMap::DataStructure.pm documentation.

=head1 SYNOPSIS

Add synopsis

=head1 INSTALL

To install the module, run the following magic commands:

    perl Makefile.PL
    make
    make test
    make install

This will install the module in the standard location. You will, most
probably, require root privileges to install in standard system
directories. To install in a non-standard directory, specify a prefix
during the 'perl Makefile.PL' stage as:

    perl Makefile.PL PREFIX=/home/sam

It is possible to modify other parameters during installation. The
details of these can be found in the ExtUtils::MakeMaker
documentation. However, it is highly recommended not messing around
with other parameters, unless you know what you're doing.

=head1 AUTHOR
    Sam Henry <henryst@vcu.edu>
    Bridget T McInnes <bmcinnes@vcu.edu> 

=head1 COPYRIGHT

    Copyright (c) 2016
    Sam Henry, Virginia Commonwealth Univesrity 
    henryst at vcu.edu

    Bridget T. McInnes, Virginia Commonwealth Univesrity 
    btmcinnes at vcu.edu

This program is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation; either version 2 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
this program; if not, write to

    The Free Software Foundation, Inc.,
    59 Temple Place - Suite 330,
    Boston, MA  02111-1307, USA.
