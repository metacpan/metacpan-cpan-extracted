# MetaMap::DataStructures::Citation
# (Last Updated $Id: Citation.pm,v 1.80 2016/01/07 22:49:33 btmcinnes Exp $)
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

package MetaMap::DataStructures::Citation;  
use strict;
use warnings;

use MetaMap::DataStructures::Utterance;

#----------------------------------------
#               constructors
#----------------------------------------
#  constructor method to create a new Citation object
#  input : -
#  output: $self <- a instance of a Citation object
sub new {
    #create and bless self
    my $class = shift;
    my $self = {};
    bless $self, $class;

    #grab input and initialize
    $self->{id} = shift;
    $self->{utterances} = {};

    return $self;
}

#-----------------------------------------------------------------
#                              methods
#-----------------------------------------------------------------

#  method summarizes this utterance as a string
#  input : -
#  output: $string <- a string describing $self
sub toString {
    my $self = shift;

    #initiliaze the string
    my $string = "citation:\n";
    $string .= "   $self->{id}\n";
    
    #add each utterance to the string
    my %utterances = %{$self->{utterances}};
    foreach my $key(keys %utterances) {
	$string .= "   ".$utterances{$key}->toString()."\n";
    }
    return $string;
}

#  method to compare this citation to another and returns 1 if the two 
#   contain identical information
#  input : $other <- the citation object to compare against
#  output: boolean <- 1 if $self and $other are equivalent (contain equivalent 
#                     ID's and utterances), else 0
sub equals {
    #grab input
    my $self = shift;
    my $other = shift;

    #compare id's
    if ($self->{id} ne $other->{id}) {
	return 0;
    }

    #compare Utterances
    foreach my $keyA(sort _by_utterance keys %{$self->{utterances}}){
	my $utteranceA = $self->{utterances}{$keyA};

	#check each utterance in B
	my $match = 0;
	foreach my $keyB(sort _by_utterance keys %{$other->{utterances}}) {
	    my $utteranceB = $self->{utterances}{$keyB};
	    if ($utteranceA->equals($utteranceB)) {
		$match = 1;
		last;
	    }
	}

	#citationA has no equivalent citation in $other
	#   so citations are not identical
	if ($match < 1) {
	    return 0;
	}
    }

    #all tests passed, return true
    return 1;
}

#  method to determine if this citation contains the CUI provided as input
#   returns 1 if this citation contains the CUI, else 0
#  input : $cui <- a string CUI code
#  output: boolean <- 1 if any of $self's utterances contain $cui
sub contains {
    #grab input
    my $self = shift;
    my $cui = shift;

    #check each phrase to see if it contains the CUI
    my $containsCUI = 0;
    foreach my $key(keys %{$self->{utterances}}) {
	if ($self->{utterances}{$key}->contains($cui)) {
	    $containsCUI = 1;
	    last;
	}
    }
    
    #return the result
    return $containsCUI;
}

#  method to add a new utterance to the citation
#  input : $newUtterance <- the utterance to add to $self
#  output: -
sub addUtterance {
    my $self = shift;
    my $newUtterance = shift;

    if($newUtterance->{id} =~ /((ti|ab)\.[\d]+)/) {
	$self->{utterances}{$1} = $newUtterance;
    }
    else {
	print STDERR "error adding utterance to citation: $newUtterance->{id}\n";
    }
}

#  method to sort the utterances by order they appear (title followed 
#  by abstract, number ascending) 
#  (e.g. ti.000.1, ti.000.2, ab.000.1, ab.000.2, ab.000.3)
#  input : $a, $b <- implicit sort variables, the keys in a hash of utterances
#      which are the utterance IDs (e.g. ti.0000000.1)
#  output: integer <- -1 if a is before b, 0 if a and b are same order, 
#      1 if a is after b
sub _by_utterance {
    #get the utterance type
    my $a_ab = ($a =~ /ab/);
    my $b_ab = ($b =~ /ab/);
    
    #check if both are abstracts or titles
    if ($a_ab == $b_ab) {
        $a =~ /(ti|ab)\.([\d]+)/;
	my $aNum = ($2);

	$b =~ /(ti|ab)\.([\d]+)/;
	return $aNum <=> $2;
    }

    #check if one is abstract, the other is title
    if ($a_ab && !$b_ab) {
	return 1;
    }
    if (!$a_ab && $b_ab) {
	return -1;
    }
}


#------------------------------ Get Components ------------------------------
#  method to returns an ordered list of Utterances contained by the Citation. 
#     Utterances are ordered by title, abstract, then number in ascending order
#     (e.g. ti.000.1, ti.000.2, ab.000.1, ab.000.2, ab.000.3)
#  input : -
#  output: \@utterances <- $self's utterances ordered as they appear in the 
#      original text of $self
sub getOrderedUtterances {
    #initialize
    my $self = shift;
    my @utterances = ();

    #add concepts in sorted order
    foreach my $key(sort _by_utterance keys %{$self->{utterances}}) {
	push @utterances, $self->{utterances}{$key};
    }
    return \@utterances;
}

#  method to get an array of concepts that appear in the citation 
#  (not necassarily ordered).  Use this method if order doesn't matter for 
#  increased performance.
#  input : - 
#  output: \@concepts <- a list of concept objects
sub getConcepts {
    #initialize
    my $self = shift;
    my @concepts = ();

    #add concepts in sorted order
    foreach my $key(keys %{$self->{utterances}}) {
	push @concepts, @{ $self->{utterances}{$key}->getConcepts() };
    }
    return \@concepts;
}

#  method to get the unique concepts and return a hash of 
#  concepts, CUIs are the keys
#  input : -
#  output: \%concepts <- $self's unique concepts with the key as the concept's 
#      CUI. CUIs are considered unique by their CUI code only (e.g. C0000000 
#      and C0000000 are considered the same even if there are two different 
#      Concept.pm objects associated with them)
sub getUniqueConcepts {
    my $self = shift;
    my %concepts = ();

    #update concepts
    foreach my $key(keys %{$self->{utterances}}) {
	my $utteranceConceptsRef =  $self->{utterances}{$key}->getConcepts();
	foreach my $concept(@{ $utteranceConceptsRef }) {
	    my $cui = $concept->{cui};
	    if (!exists $concepts{$cui}) {
		$concepts{$cui} = $concept;
	    }
	}
    }
    return \%concepts;
}

#  method to get the an array of concepts that appear in the citation
#   concepts are ordered as they appear in the utterance
#   however where there are multiple mappings for a single
#   token those two concepts will appear adjacent to one another
#  input : -
#  output: \@conceptList <- an array of arrays, where each sub-array contains a 
#                          list of 1 or more concept objects. Where more than
#                          one concept object occurrs it means the token to 
#                          concept mapping was ambiguous. Arrays are ordered as
#                          the tokens occurr in the utterance.
sub getOrderedConcepts {
    #initialize
    my $self = shift;
    my @conceptsList = ();

    #add concepts in sorted order
    foreach my $key(sort _by_utterance keys %{$self->{utterances}}) {
	push @conceptsList, @{ $self->{utterances}{$key}->getOrderedConcepts() };
    }
    return \@conceptsList;
}

#  method to get a list of ordered mappings. There may be multiple 
#  mappings for a single utterance, but they will appear in correct 
#  utterance order
#  input : -
#  output: \@mappings <- a list of mapping objects ordered by their occurence in
#                        $self.
sub getOrderedMappings {
    #initialize
    my $self = shift;
    my @mappings = ();
    
    #add mappings in sorted order
    foreach my $key(sort _by_utterance keys %{$self->{utterances}}) {
	push @mappings, @{ $self->{utterances}{$key}->getMappings() };
    }
    return \@mappings;
}

#  method to get all the mappings of the citation (not necassarily ordered)
#  input : - 
#  output: \@mappings <- a list of mapping objects
sub getMappings {
    #initialize
    my $self = shift;
    my @mappings = ();
    
    #add mappings in sorted order
    foreach my $key(keys %{$self->{utterances}}) {
	push @mappings, @{ $self->{utterances}{$key}->getMappings() };
    }
    return \@mappings;
}

#  method to get an array of ordered tokens as they appear in the citation
#  input : -
#  output: \@tokens <- a list of token objects ordered by their appearance in
#                      $self
sub getOrderedTokens
{
    #initialize
    my $self = shift;
    my @tokens = ();
    
    #add words in sorted order
    foreach my $key(sort _by_utterance keys %{$self->{utterances}}) {
	push @tokens, @{ $self->{utterances}{$key}->getTokens() };
    }
    return \@tokens;
}

#  method to get an array of tokens. Tokens are not necassarily in order
#  input : -
#  output: \@tokens <- a list of token objects
sub getTokens
{
    #initialize
    my $self = shift;
    my @tokens = ();
    
    #add words in sorted order
    foreach my $key(keys %{$self->{utterances}}) {
	push @tokens, @{ $self->{utterances}{$key}->getTokens() };
    }
    return \@tokens;
}

#---------------------- Has Parts (title or abstract) -------------------------
#  method to determine if the citation contains any title utterances
#  input : -
#  output: boolean <- 1 if $self contains a title utterance, else 0
sub hasTitle
{
    my $self = shift;
    return $self->_hasPart('ti');
}

#  method to determine if the citation contains any abstract utterances
#  input : -
#  output: boolean <- 1 if $self contains an abstract utterance, else 0
sub hasAbstract
{
    my $self = shift;
    return $self->_hasPart('ab');
}

#  method to determine if the citation contains any utterances of the 
#  tag ('ti' or 'ab')
#  input : $tag <- the utterance tag to check for, should be 'ti' or 'ab'
#  output: boolean <- 1 if $self contains an utterance with the $tag, else 0
sub _hasPart
{
    my $self = shift;
    my $tag = shift;

    #get the utterances that match the tag
    foreach my $key(keys %{$self->{utterances}}) {
	if ($key =~ /(ti|ab)/) {
	    if ($1 eq $tag) {
		#tag found, returning true
		return 1;
	    }
	}
    }
    #no matching tags found, returning false
    return 0;
}
#----------------------------------------------------------------------------


#------------------ Get Parts (Title or Abstract)  ---------------------
#  method to create a new citation containing just the title of this citation
#  input : -
#  output: $part <- a citation object containing all utterances of $self's title
sub getTitle
{
    my $self = shift;
    return $self->_getPart('ti');
}

#  method to create a new citation containing just the abstract of this citation
#  input : -
#  output: $part <- a citation object containing all utterances of $self's
#                   abstract
sub getAbstract
{
    my $self = shift;
    return $self->_getPart('ab');
}

#  method to get a part of this citation (title or abstract)
#  input is a match string, either 'ti' or 'ab'
#  input : $tag <- the utterance tag to extract, should be 'ti' or 'ab'
#  output: $part <- a citation object containing all utterance of $self 
#                   containing the $tag in their ID
sub _getPart
{
    my $self = shift;
    my $tag = shift;
    
    #get the utterances that match the tag
    my $part = MetaMap::DataStructures::Citation->new($self->{id});
    foreach my $key(keys %{$self->{utterances}}) {
	if($key =~ /(ti|ab)/) {
	    if ($1 eq $tag) {
		$part->addUtterance($self->{utterances}{$key});
	    }
	}
    }
    #return the title citation
    return $part;
}
#-----------------------------------------------------------------------

1;

__END__

=head1 NAME

MetaMap::DataStructure::Citation - provides a container for the citation 
information extracted from machine readable MetaMap mapped text. 

=head1 DESCRIPTION

This package provides a container for the citation information extracted 
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
