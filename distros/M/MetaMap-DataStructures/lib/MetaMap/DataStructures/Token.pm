# MetaMap::DataStructures::Token
# (Last Updated $Id: Token.pm,v 1.80 2016/01/07 22:49:33 btmcinnes Exp $)
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

package MetaMap::DataStructures::Token;  

use strict;
use warnings;

#----------------------------------------
#               constructor
#----------------------------------------
#  constructor method to create a new Token object
#  input : -
#  output: $self <- a Token object
sub new {
    #grab class and create self
    my $class = shift;
    my $self = {};
    bless $self, $class;

    #get the rest of the input
    $self->{text} = shift;
    $self->{matchedText} = shift;
    $self->{type} = shift;
    $self->{posTag} = shift;
    $self->{features} = shift;
    $self->{numWords} = shift;

    return $self;
}

#  method creates and returns a token from text 
#   (MetaMap Prolog Machine Output, single
#   syntax description after phrase)
#  input : $text <- a Metamap Prolog Machine Output single syntax description
#                   given after the phrase (or equivalent)
#  output: $self <- a Token object
sub createFromText  {
    #grab the inputs
    my $text= shift;
    
    #grab the type
    $text =~ m/(adv|aux|compl|conj|det|head|mod|modal|pastpart|prep|pron|punc|shapes|verb|not_in_lex)\(/;
    my $type = $1;

    #grab and format input match
    $text =~ m/inputmatch\(\[([^\[\]]+)\]/;
    my $inputMatchText = $1;

    #remove trailing and leading quotes and commas
    my $inputMatch = "";
    my @inputs = split /,/, $inputMatchText;
    foreach my $input(@inputs) {
	if ($input =~ m/'(.*)'/) {
	    $input = $1;
	} 
	$inputMatch .= ' '.$input;
    }
    #remove trailing and leading spaces from input match
    $inputMatch =~ s/\s*//;
    $inputMatch =~ s/^\s*//;
    $inputMatch =~ s/\s*$//;
    
    #grab the pos tag (if any)
    my $tag = '';
    if ($text =~ m/tag\(([a-z]+)\)/) {
	$tag = $1;
    }
    
    #grab the lexmatch (if any)
    my $lexMatch = '';
    if ($text =~ m/lexmatch\(\[([^\[\]]+)\]/) {
	$lexMatch = $1;
	if ($lexMatch =~ m/'(.*)'/) {
	    $lexMatch = $1;
	} 
    }

    #grab features (if any)
    my $features = '';
    if ($text =~ m/features\(\[([^\[\]]+)\]\)/) {
	$features = $1;
    }

    #Count the number of words in this token
    #   ...important for match mapping
    my $numWords = 1;
    if ($text =~ m/tokens\(\[([^\[\]]+)\]\)/) {
	my @splitToken = (split /,/, $1);
	$numWords = scalar @splitToken;
    }

    #TODO delete this (for debugging)
    #print out info about the token being created
    #print "Creating Token:\n";
    #print "text = $text\n";
    #print "inputMatch = $inputMatch\n";
    #print "lexMatch = $lexMatch\n";
    #print "type = $type\n";
    #print "tag = $tag\n";
    #print "features = $features\n";
    #print "numWords = $numWords\n";

    #create and retrun the new token
    return MetaMap::DataStructures::Token->new(
	$inputMatch, $lexMatch, $type, $tag, $features, $numWords);
}


#----------------------------------------
#              Methods
#---------------------------------------

#  method compares this token to another and returns 1 if
#   the two tokens contain identical information
#  input : $other <- the Token to comnpare against
#  output: boolean <- 1 if $self and other are equivalent (have the same field 
#                     values)
sub equals {
    #grab input
    my $self = shift;
    my $other = shift;

    #compare each field
    if ($self->{text} ne $other->{text}
	|| $self->{matchedText} ne $other->{matchedText}
	|| $self->{type} ne $other->{type}
	|| $self->{posTag} ne $other->{posTag}
	|| $self->{features} ne $other->{features}
	|| $self->{numWords} ne $other->{numWords}) {
	return 0;
    }

    #everything matches, return true
    return 1;
}

#  method summarizes this token as a string
#  input : -
#  output: $string <- a string describing $self
sub toString {
    my $self = shift;
    my $string = "token: \n";
    $string .= "   $self->{text}, $self->{matchedText}\n";
    $string .= "   $self->{type}, $self->{posTag}, $self->{numWords}\n";

    return $string;
}

1;

__END__

=head1 NAME

MetaMap::DataStructure::Token - provides a container for the token 
information extracted from machine readable MetaMap mapped text. 

=head1 DESCRIPTION

This package provides a container for the token information extracted 
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
