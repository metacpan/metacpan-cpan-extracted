# MetaMap::DataStructures::Utterance
# (Last Updated $Id: Utterance.pm,v 1.80 2016/01/07 22:49:33 btmcinnes Exp $)
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

package MetaMap::DataStructures::Utterance;  

use strict;
use warnings;

use MetaMap::DataStructures::Phrase;

#----------------------------------------
#               constructors
#----------------------------------------
#  constructor method to create a new Utterance object
#  input : $inputText <- a MetaMap Prolog Output utterance block 
#                        (or equivalent) 
#          $id <- the id of this Utterance of the form: (ab:ti).([\d]+).([\d]+) 
#                 (e.g. ab.00000.1)
#          $text <- the human readable text of this utterance
#          \@phrases <- an ordered list of phrase objects
#  output: $self <- an instance of an Utterance object
sub new {
    #create and bless self
    my $class = shift;
    my $self = {};
    bless $self, $class;

    #grab input
    $self->{inputText} = shift;
    $self->{id} = shift;
    $self->{text} = shift;
    $self->{phrases} = shift;
   
    return $self;
}

#  method creates and returns an utterance from text
#   (MetaMap Prolog Machine Output Utterance Block)
#  input : $inputText <- a MetaMap Prolog Output utterance block (or equivalent)
#  output: $self <- an instance of an Utterance object
sub createFromText {
    #grab the input
    my $self = shift; 
    my $inputText = shift;
  
    #grab negated CUIs
    $inputText =~ m/neg_list\((.*)\)./;
    my $negationsText = $1;
    my @negatedCUIs = ();
    if (defined $negationsText) {
	while ($negationsText =~ 
	       m/negation\(\w+,[^\[\]]*,\[\d+\/\d+\],\['(C\d+)':/g) {
	    push @negatedCUIs, $1;
	}
    }

    #grab the id and text
    $inputText =~ /utterance\('(.*)',"(.*)",/;
    my $id = $1;
    my $text = $2;

    #create the phrases list
    my @phraseTexts = split /phrase\(/, $inputText;
    #shift the first part off (its the part before the first phrase match
    shift @phraseTexts; 

    #create a phrase from the phrase texts (and collect the concepts)
    my @phrases = ();
    foreach my $phraseText(@phraseTexts) {
	#put 'phrase(' back on
	$phraseText = 'phrase('.$phraseText;
	#create a new phrase from text
	my $newPhrase = &MetaMap::DataStructures::Phrase::createFromText(
	    $phraseText, \@negatedCUIs);
	push @phrases, $newPhrase;
    }    

    #create and return the new utterance
    return MetaMap::DataStructures::Utterance->new(
	$inputText, $id, $text, \@phrases);
}

#  method creates and returns an utterance from text 
#   (MetaMap Prolog Machine Output Utterance Block), and uses a custom $id. 
#   This is useful when the $input text has a non-properly formatted $id 
#   (e.g. tx.0000000.1)
#  input : $inputText <-  a MetaMap Prolog Output utterance block 
#                         (or equivalent) 
#          $id <- the id to associate with this Utterance. It overrides any id 
#                 found within $inputText. $id should be of the form: 
#                 (ab:ti).([\d]+).([\d]+) (e.g. ab.00000.1)
#  output: $self <- an instance of an Utterance Object
sub createFromTextWithId {
    my $self = shift; 

    #grab the input
    my $inputText = shift;
    my $id = shift;
  
    #grab negated CUIs
    $inputText =~ m/neg_list\((.*)\)./;
    my $negationsText = $1;
    my @negatedCUIs = ();
    if (defined $negationsText) {
	while ($negationsText =~ 
	       m/negation\(\w+,[^\[\]]*,\[\d+\/\d+\],\['(C\d+)':/g) {
	    push @negatedCUIs, $1;
	}
    }

    #grab the id and text
    $inputText =~ /utterance\('(.*)',"(.*)",/;
    my $aid = $1;
    my $text = $2;

    #create the phrases list
    my @phraseTexts = split /phrase\(/, $inputText;
    #shift the first part off (its the part before the first phrase match
    shift @phraseTexts; 

    #create a phrase from the phrase texts (and collect the concepts)
    my @phrases = ();
    foreach my $phraseText(@phraseTexts) {
    #put 'phrase(' back on
    $phraseText = 'phrase('.$phraseText;
    #create a new phrase from text
    my $newPhrase = &MetaMap::DataStructures::Phrase::createFromText(
	$phraseText, \@negatedCUIs);
    push @phrases, $newPhrase;
    }    

    #create and return the new utterance
    return MetaMap::DataStructures::Utterance->new(
	$inputText, $id, $text, \@phrases);
}

#----------------------------------------
#               methods
#----------------------------------------
#  method summarizes this utterance as a string
#  input : -
#  output: $string <- a string describing $self
sub toString {
    my $self = shift;

    my $string = "utterance:\n";
    $string .= "   $self->{id}\n";
    $string .= "   $self->{text}\n";
    
    #add each phrase to the string
    foreach my $phrase(@{$self->{phrases}}) {
	$string .= "   ".$phrase->toString()."\n";
    }
    
    return $string;
}

#  method compares this utterance to another and returns 1 if the two 
#   contain identical information
#  input : $other <- the utterrance object to compare against
#  output: boolean <- 1 if $self and $other are equivalent (contain equivalent 
#                     IDs, and phrases), else 0
sub equals {
    #grab input
    my $self = shift;
    my $other = shift;

    #compare id's and text
    if ($self->{id} ne $other->{id}
	|| $self->{text} ne $other->{text}) {
	return 0;
    }

    #compare Utterances
    foreach my $phraseA(@{$self->{phrases}}){

	#check each utterance in B
	my $match = 0;
	foreach my $phraseB(@{$other->{phrases}}) {
	    if ($phraseA->equals($phraseB)) {
		$match = 1;
		last;
	    }
	}

	#utteranceA has no equivalent phrase in $other
	#   so utterances are not identical
	if ($match < 1) {
	    return 0;
	}
    }

    #all tests passed, return true
    return 1;
}

#  method determines if this utterance contains the CUI provided as input
#   returns 1 if this utterance contains the CUI, else 0
#  input : $cui <- a string CUI code
#  output: boolean <- 1 if any of $self's phrases contain $cui
sub contains {
    #grab input
    my $self = shift;
    my $cui = shift;

    #check each phrase to see if it contains the CUI
    my $containsCUI = 0;
    foreach my $phrase(@{$self->{phrases}}) {
	if ($phrase->contains($cui)) {
	    $containsCUI = 1;
	    last;
	}
    }
    
    #return the result
    return $containsCUI;
}

#  method gets the an array of concepts as they appear in the utterance. 
#  Conepts are not necassarily ordered, where ambiguity exists all possible
#  token->CUI mappings are listed adjacent to one another.
#  input : -  
#  output: \@concepts <- a list of concept objects
sub getConcepts {
    #initialize
    my $self = shift;
    my @concepts = ();

    #add concepts in sorted order
    foreach my $phrase(@{$self->{phrases}}) {
	push @concepts, @{$phrase->{concepts}};
    }
    return \@concepts;
}

#  method gets an array list  of concepts as they appear in the utterance
#  input : - 
#  output: \@conceptList <- an array of arrays, where each sub-array contains a 
#                          list of 1 or more concept objects. Where more than
#                          one concept object occurrs it means the token to 
#                          concept mapping was ambiguous. Arrays are ordered as
#                          the tokens occurr in the utterance.
sub getOrderedConcepts {
    #initialize
    my $self = shift;
    my @conceptList = ();

    #add concepts in sorted order
    foreach my $phrase(@{ $self->{phrases} }) {
	push @conceptList, @{ $phrase->{orderedConceptList} };
    }
    return \@conceptList;
}

#  method gets the an array of tokens as they appear in the utterance
#  input : -
#  output: \@tokens <- a list token objects ordered by their appearance in $self
sub getTokens {
    #initialize
    my $self = shift;
    my @tokens = ();

    #add concepts in sorted order
    foreach my $phrase(@{$self->{phrases}}) {
	push @tokens, @{$phrase->{tokens}};
    }
    return \@tokens;
}

#  method gets the an array of Mappings as they appear in the utterance
#  input : -
#  output: \@mappings <- a list of mapping objects ordered by their appearance 
#                      in $self
sub getMappings {
    #initialize
    my $self = shift;
    my @mappings = ();

    #add concepts in sorted order
    foreach my $phrase(@{$self->{phrases}}) {
	push @mappings, @{$phrase->{mappings}};
    }
    return \@mappings;
}

1;

__END__

=head1 NAME

MetaMap::DataStructure::Utterance - provides a container for the utterance 
information extracted from machine readable MetaMap mapped text. 

=head1 DESCRIPTION

This package provides a container for the utterance information extracted 
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
