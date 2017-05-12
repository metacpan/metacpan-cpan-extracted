# MetaMap::DataStructures::Concept
# (Last Updated $Id: Concept.pm,v 1.80 2016/01/07 22:49:33 btmcinnes Exp $)
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

package MetaMap::DataStructures::Concept;  
use strict;
use warnings;

#----------------------------------------
#              constructors
#---------------------------------------
#  constructor method to create a new Concept object
#   It is recomennded to create Concepts from the phrase or utterance level.
#   It is easier since text parsing is performed for you, and it is safer, since
#   the fields are garaunteed to be correct. Each of the input fields are 
#   parsed directly from the text, and are defined in more detail in the MetaMap
#   documentation, but are described in breif below.
#  input : $cui <- the CUI code of this concept (e.g. C0000000)
#          $text <- the text this concept is associated with
#          $preferredName <- the preferred name of the CUI
#          $score <- the MMI score of the token->CUI mapping 
#          $uniqueSources <- comma seperated string of the names of the 
#                            vocabularies that contain this CUI 
#          $semanticTypes <- comma seperated string of the semantic types 
#                            strings associated with this CUI
#          \@associatedTokens <- list of token objects that map to this concept
#          $involvesHead <- boolean indicating if the conept involves the head
#          $isOvermatch <- boolean indicating if the concept is overmatched
#          $matchmapText <- the matchmap text of the concept
#          $isNegated <- boolean indicating if the Concept is negated 
#  output: $self <- a Concept object
sub new {
    #create and bless self
    my $class = shift;
    my $self= {};
    bless $self, $class;

    #initialize from the input
    $self->{cui} = shift;
    $self->{text} = shift;
    $self->{preferredName} = shift;
    $self->{score} = shift;
    $self->{uniqueSources} = shift;
    $self->{semanticTypes} = shift;
    $self->{associatedTokens} = shift;
    $self->{involvesHead} = shift;
    $self->{isOvermatch} = shift;
    $self->{matchMapText} = shift;
    $self->{isNegated} = 0;

    return $self;
}

#  method creates and returns a conept from text 
#   (MetaMap Prolog Machine Output, ev section)
#  input : $text <- a Metamap Prolog Machine Output ev section block or 
#                   equivalent
#          \@tokens <- a list of token objects in the same phrase as this 
#                      utterance. The matchmap text is read, and tokens 
#                      from list list are selected as the assocaited tokens
#  output: $self <- a Concept object
sub createFromText {
    #grab the input
    my $text = shift;
    my $tokensRef = shift;
    
    #match the text
    $text =~ m/
ev\((-*\d+)        #score $1
,'?(C\d+)'?,       #cui $2
(.*),        #string $3
(.*),              #preferredName $4
\[[^\]\[]+\],      #   skip
\[([^\]\[]+)\],    #semanticTypes $5
(\[[\[\]\d,]+\]),  #matchMapText $6
([a-zA-Z]+),       #involvesHead 
([a-zA-Z]+),       #isOvermatch
\[([^\]\[]+)\],    #uniqueSources
\[[\d\/,]+\],      #   skip
\d+,               #   skip
\d+/x;             #   skip



#ev\((-*\d+),'?(C\d+)'?,([^\]\[]+),([^\]\[]+),\[[^\]\[]+\],\[([^\]\[]+)\],(\[[\[\]\d,]+\]),([a-zA-Z]+),([a-zA-Z]+),\[([^\]\[]+)\],\[[\d\/,]+\],\d+,\d+
    
    #grab values
    my $score = $1;
    my $cui = $2;
    my $string = $3;
    my $preferredName = $4;
    my $semanticTypes = $5;
    my $matchMapText = $6;
    my $involvesHead = $7;
    my $isOvermatch = $8;
    my $uniqueSources = $9;

    #TODO delete this - once you are SURE everything works, will quit if values are not being properly parsed with the regex
    #check if everythingis defined
    if (defined $score
	&& defined $cui
	&& defined $string
	&& defined $preferredName
	&& defined $semanticTypes
	&& defined $matchMapText
	&& defined $involvesHead
	&& defined $isOvermatch
	&& defined $uniqueSources) {
	#DO NOTHING
   }
   else {
	print "SOMETHING UNDEFINED:\n";
	print "1 - $text\n";
	print "2 - $score\n";
	print "3 - $cui\n";
	print "4 - $string\n";
	print "5 - $preferredName\n";
	print "7 - $semanticTypes\n";
	print "8 - $matchMapText\n";
	print "9 - $involvesHead\n";
	print "10 - $isOvermatch\n";
	print "11 - $uniqueSources\n";
	exit;
   }

    #remove trailing/leading quotes
    if ($string =~ m/'(.*)'/) {
	$string = $1;
    }
    if ($preferredName =~ m/'(.*)'/) {
	$preferredName = $1;
    }

    #convert text to bools (involvesHead and isOvermatch)
    if ($involvesHead eq 'yes') {
	$involvesHead = 1;
    } 
    else {
	$involvesHead = 0;
    } 
    if ($isOvermatch eq 'yes') {
	$isOvermatch = 1;
    } 
    else {
	$isOvermatch = 0;
    }

    #Map the Concept to its associated Tokens
    my @associatedTokens = ();
    while($matchMapText =~ m/\[(\d+),(\d+)\],\[\d+,\d+\],\d+/g) {
	#grab the token start and end indeces
	my $startWordNumber = $1;
	my $endWordNumber = $2;
	
	#add the correct tokens to the list of associated tokens
	my $wordNumber = 1;
	for (my $tokenIndex = 0; $tokenIndex < scalar @{$tokensRef}; $tokenIndex++) {
	 
	    #add the token if the words are within range
	    my $wordsInToken = ${$tokensRef}[$tokenIndex]->{numWords};
	    if (($wordNumber + $wordsInToken) > $endWordNumber) {
		push @associatedTokens, ${$tokensRef}[$tokenIndex];
	    }

	    #incrememt word number and see if your done
	    $wordNumber += $wordsInToken;
	    if ($wordNumber > $endWordNumber) {
		last;
	    }
	}
    }

    #TODO delete this (for debugging)
    #----------------------------------------------
    #print "Creating Concept from Text\n";
    #print "1 - $text\n";
    #print "2 - $score\n";
    #print "3 - $cui\n";
    #print "4 - $string\n";
    #print "5 - $preferredName\n";
    #print "7 - $semanticTypes\n";
    #print "8 - $matchMapText\n";
    #print "9 - $involvesHead\n";
    #print "10 - $isOvermatch\n";
    #print "11 - $uniqueSources\n";
    #print "12 - Associated Tokens:\n";
    #foreach my $token(@associatedTokens) {
    # 	print $token->toString();
    # }
    #---------------------------------------------

    #create and return the new concept
    return MetaMap::DataStructures::Concept->new($cui, $string, $preferredName,
			$score, $uniqueSources, $semanticTypes, 
			\@associatedTokens, $involvesHead, 
			$isOvermatch, $matchMapText);
    
}


#----------------------------------------
#              Methods
#---------------------------------------
#  method determines if this concept maps to the same tokens as another concept
#     (i.e. if the two tokens are ambiguities of the same text), returns a 1 if 
#     true, 0 otherwise.
#  input : $other <- a concept object
#  output: boolean <- 1 if $self and $other have equivalent associated tokens, 
#                     else 0
sub mapsToSameTokens {
    #grab input
    my $self = shift;
    my $other = shift;

     #check each associated Token for equality
    foreach my $tokenA(@{$self->{associatedTokens}}) {

	#check if there is a token match for this token
	#   in token B (need to check all because there
	#   is no garauntee that the token list is ordered)
	my $match = 0;
	foreach my $tokenB(@{$other->{associatedTokens}}) {
	    if ($tokenA->equals($tokenB)) {
		$match = 1;
		last;
	    }
	}

	#tokenB isn't associated with this token
	#   so concepts are not identical
	if ($match < 1) {
	    return 0;
	}
    }

    #all tokens equal, return true
    return 1;
}

#  method compares this concept to another and returns 1 if the two 
#   contain identical information
#  input : $other <- a concept object to compare against
#  output: boolean <- 1 if $self and $other contain equivalent fields, and map
#                     to the same tokens, else 0.
sub equals {
    #grab input
    my $self = shift;
    my $other = shift;

    #check each field for equality
    if ($self->{cui} ne $other->{cui}
	|| $self->{text} ne $other->{text}
	|| $self->{preferredName} ne $other->{preferredName}
	|| $self->{score} ne $other->{score}
	|| $self->{uniqueSources} ne $other->{uniqueSources}
	|| $self->{semanticTypes} ne $other->{semanticTypes}
	|| $self->{involvesHead} ne $other->{involvesHead}
	|| $self->{isOvermatch} ne $other->{isOvermatch}
	|| $self->{matchMapText} ne $other->{matchMapText}
	|| $self->{isNegated} ne $other->{isNegated}) {
	return 0;
    }
    #fields are passed

    #check that the token mapping is the same
    return $self->mapsToSameTokens($other);
}

#  method summarizes this concept as a string
#  input : -
#  output: $string <- a string describing $self
sub toString {
    my $self = shift;

    #add info about the concept
    my $string = "concept:\n";
    $string .= "   $self->{cui}, $self->{text}, $self->{preferredName}, $self->{score}\n";
    $string .= "   $self->{involvesHead}, $self->{isOvermatch}, $self->{isNegated}\n";
    $string .= "   $self->{semanticTypes}\n";
    $string .= "   $self->{uniqueSources}\n";

    $string .= "   $self->{matchMapText}\n";

    #ensure tokens are associated
    if (scalar @{$self->{associatedTokens}} < 1) {
	$string .= "ERROR NO TOKENS ASSOCIATED\n";
    }

    #add the associated tokens
    foreach my $token(@{$self->{associatedTokens}}) {
	$string .= "   ".$token->toString();
    }

    return $string;
}

1;


__END__

=head1 NAME

MetaMap::DataStructure::Concept - provides a container for the concept 
information extracted from machine readable MetaMap mapped text. 

=head1 DESCRIPTION

This package provides a container for the concept information extracted 
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
