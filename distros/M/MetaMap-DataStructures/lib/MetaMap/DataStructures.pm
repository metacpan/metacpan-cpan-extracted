# MetaMap::DataStructures
# (Last Updated $Id: DataStructures.pm,v 1.147 2016/01/07 22:49:33 btmcinnes Exp $)
#
# Perl module that provides a container for machine readable 
# MetaMap mapped text 
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

=head1 NAME

MetaMap::DataStructure - provides a container for the information 
extracted from machine readable MetaMap mapped text.

=head1 DESCRIPTION

This package provides a container for the information extracted 
from machine readable MetaMap mapped text. 

For more information please see the MetaMap::DataStructure.pm documentation.

=head1 SYNOPSIS

add synopsis

=head1 ABSTRACT

This package provides a Perl container package to for information extracted 
from MetaMap mapped text. 

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

=head1 DESCRIPTION

This package provides a Perl containers for information 
extracted from MetaMap mapped text. 

=head1 FUNCTION DESCRIPTIONS
=cut

package MetaMap::DataStructures;

use 5.006;
use strict;
use warnings FATAL => 'all';

use MetaMap::DataStructures::Utterance;
use MetaMap::DataStructures::Citation;
use MetaMap::DataStructures::Concept;



our $VERSION = '0.03';

my $debug = 0; 
 
# -------------------- Class methods start here --------------------

#  method to create a new MetaMap::DataStructures object
#  input : $params <- reference to hash containing the parameters 
#  output: $self <- a DataStructures object
sub new {
    my $self = {};

    my $className = shift;
    return undef if(ref $className);

    my $params = shift;     
    
    # Bless object, initialize it and return it.
    bless($self, $className);

    $self->_initialize($params);

    return $self;
}
#  method to initialize the MetaMap::DataStructures object.
#  input : $parameters <- reference to a hash
#  output: - 
sub _initialize {
    my $self = shift;
    my $params = shift;

    $params = {} if(!defined $params);

    #  get some of the parameters
    my $debugoption = $params->{'debug'};

    $self->{citations} = {};

    if(defined $debugoption) { 
	$debug = 1; 
    }
}

#  print out the function name to standard error
#  input : $function <- string containing function name
#  output: - 
sub _debug {
    my $function = shift;
    if($debug) { print STDERR "In MetaMap::DataStructures::$function\n"; }
}

=head3 getCitations

description:

 returns a hash table of Citations of this DataStrucures object

input:    

 None  
	 
output:   

 hashtable reference with Citation IDs as keys and Citation object references 
   as values

example:

 use MetaMap::DataStructures; 
 my $datastructures = MetaMap::DataStructures->new(); 
 my $citations = $datastructures->getCitations(); 

=cut
sub getCitations { 
    my $self = shift; 

    my $function = "getCitations"; 
    &_debug($function);

    return $self->{citations}; 
}

=head3 getOrderedUtterances

description: 
 
 returns an ordered list of Utterances contained by the Citation. Utterances
 are ordered by title, abstract, then number in ascending order
 (e.g. ti.000.1, ti.000.2, ab.000.1, ab.000.2, ab.000.3)

input:    

 a reference to a Citation object
	 
output:   

 array reference containing references to Utterance objects

example:

 use MetaMap::DataStructures; 
 my $datastructures = MetaMap::DataStructures->new(); 
 my $citation = $dataStructures->getCitationWithID('01234567');
 my $orderedUtterances = $dataStructures->getOrderedUtterances($citation);

=cut
sub getOrderedUtterances { 
    my $self = shift;
    my $citation = shift;  
    
    return $citation->getOrderedUtterances(); 
}

=head3 getOrderedTokens

description:

 returns a list of ordered Tokens within a Citation. Tokens are ordered by 
 their appearance within the input text, with titles preceding abstracts

input:    

 a reference to a Citation object
	 
output:   

 array reference containing references to Token objects

example:

 use MetaMap::DataStructures; 
 my $datastructures = MetaMap::DataStructures->new(); 
 my $citation =  $dataStructures->getCitationWithID('01234567');
 my $orderedTokens = $dataStructures->getOrderedTokens($citation);

=cut
sub getOrderedTokens { 
    my $self = shift;
    my $citation = shift; 
    
    return $citation->getOrderedTokens(); 
}

=head3 getOrderedConcepts 

description:

 returns a list of ordered sub-arrays containing Concepts within a Citation. 
 Each sub-array contains one or more reference to Concept objects. Where 
 multiple concept objects exist is because of ambiguities. The sub-arrays are
 ordered by their Concept's appearance within the input text, with titles 
 preceding abstracts. Think of this as sequentical CUIs where the second 
 dimension is for when multiple CUIS map to the same Tokens due to ambiguity.

input:    

 a reference to a Citation object
	 
output:   

 array reference containing references arrays containing references to Concept 
 objects

example:

 use MetaMap::DataStructures; 
 my $datastructures = MetaMap::DataStructures->new(); 
 my $citation = $dataStructures->getCitationWithID('01234567');
 my $orderedConcepts = $dataStructures->getOrderedConcepts($citation);

=cut
sub getOrderedConcepts { 
    my $self = shift;
    my $citation = shift; 
    
    return $citation->getOrderedConcepts(); 
}

=head3 getUniqueConcepts

description:

 returns a hash table containing all unique Concepts with unique CUIs
 within a citation.

input:    

 a reference to a Citation object
	 
output:   

 hashtable reference with keys of CUI codes, and values of references to Concept
   objects. Where multiple concepts of the same CUI exist, the reference is to
   the last seen Concept object

example:

 use MetaMap::DataStructures; 
 my $datastructures = MetaMap::DataStructures->new(); 
 my $citation = $dataStructures->getCitationWithID('01234567');
 my $uniqueConcepts = $dataStructures->getUniqueConcepts($citation);
 

=cut
sub getUniqueConcepts { 
    my $self = shift;
    my $citation = shift; 
    
    return $citation->getUniqueConcepts();
}

=head3 getCitationWithId

description:

 returns a Citation with the specified ID

input:    

 string of the Citation ID 
	 
output:   

 reference to a Citation object

example:

 use MetaMap::DataStructures; 
 my $datastructures = MetaMap::DataStructures->new(); 
 my $citation = $dataStructures->getCitationWithId('01234567');

=cut
sub getCitationWithId { 
    my $self = shift;
    my $id = shift; 

    my $function = "getCitationsWithId"; 
    &_debug($function);

    return $self->{citations}{$id}; 
}



=head3 getOrderedMappings

description:

 returns a list of ordered Mappings within a Citation. Mappings are ordered by 
 their appearance within the input text, with titles preceding abstracts

input:    

 a reference to a Citation object
	 
output:   

 array reference containing references to Mapping objects

example:

 use MetaMap::DataStructures; 
 my $datastructures = MetaMap::DataStructures->new(); 
 my $citation = $dataStructures->getCitationWithId('01234567');
 my $orderedMappings = $dataStructures->getOrderedMappings($citation);

=cut
sub getOrderedMappings { 
    my $self = shift;
    my $citation = shift; 
    
    return $citation->getOrderedMappings(); 
}

=head3 hasTitle

description:

 returns 1 if a Citation contains a title Utterance (ID contains 'ti') 
 else 0

input:    

 a reference to a Citation object
	 
output:   

 boolean

example:

 use MetaMap::DataStructures; 
 my $datastructures = MetaMap::DataStructures->new(); 
 my $citation = $dataStructures->getCitationWithId('01234567');
 my $hasTitle = $dataStructures->hasTitle($citation);

=cut
sub hasTitle { 
    my $self = shift;
    my $citation = shift; 
    
    return $citation->hasTitle(); 
}

=head3 hasAbstract

description:

 returns 1 if a Citation contains an abstract Utterance (ID contains 'ab') 
 else 0
 
input:    

 a reference to a Citation object
	 
output:   

 boolean

example:

 use MetaMap::DataStructures; 
 my $datastructures = MetaMap::DataStructures->new(); 
 my $citation = $dataStructures->getCitationWithId('01234567');
 my $hasAbstract = $dataStructures->hasAbstract($citation);

=cut
sub hasAbstract { 
    my $self = shift;
    my $citation = shift;
    
    return $citation->hasAbstract(); 
}


=head3 createFromText

description:

 updates MetaMap Data structures with the text of the input string
 
input:    

 string of MetaMap Prolg Output containing an utterance, or list of utterances
	 
output:   

 None

example:

 use MetaMap::DataStructures; 
 my $datastructures = MetaMap::DataStructures->new(); 
 $datastructures->createFromText($text);

=cut
sub createFromText { 
    my $self = shift;
    my $input = shift; 
    
    my $function = "createFromText"; 
    &_debug($function);

    #create the new utterance
    my $newUtterance = 
	MetaMap::DataStructures::Utterance->createFromText($input);
    
    #add to a citation
    $input =~ /utterance\('([\d]+)\./;
    my $pmid = $1;
    
    if($debug) { print STDERR "  Processing $pmid\n"; }

    #create a new citation (if needed)
    if (!(exists $self->{citations}{$pmid})) {
	$self->{citations}{$pmid} =
	    MetaMap::DataStructures::Citation->new($pmid);
	if($debug) { 
	    print STDERR "  Additing Citation: $pmid\n";
	}
    }
    #add utterance to the citations
    $self->{citations}{$pmid}->addUtterance($newUtterance);
}

=head3 createFromTextWithId

description:

 updates MetaMap Data structures with the text of the input string, and gives 
   the addition the ID provided

input:    

 string of MetaMap Prolg Output containing an utterance, or list of utterances
 string ID of the utterance or list of utterances to add
	 
output:   

 None

example:

 use MetaMap::DataStructures; 
 my $datastructures = MetaMap::DataStructures->new(); 
 $datastructures->createFromTextWithID($text,'01234567');

=cut
sub createFromTextWithId { 
    my $self = shift;
    my $input = shift; 
    my $id = shift; 
    
    my $function = "createFromTextWithId"; 
    &_debug($function);

    #create the new utterance
    my $newUtterance = 
	MetaMap::DataStructures::Utterance->createFromTextWithId($input, $id);
    
    if($debug) { print STDERR "  Processing $id\n"; }

    #create a new citation (if needed)
    if (!(exists $self->{citations}{$id})) {
	$self->{citations}{$id} = MetaMap::DataStructures::Citation->new($id);
	if($debug) { 
	    print STDERR "  Additing Citation: $id\n";
	}
    }
    #add utterance to the citations
    $self->{citations}{$id}->addUtterance($newUtterance);
}

1;


=head1 SEE ALSO

=head1 AUTHOR

Sam Henry <henryst@vcu.edu>
Bridget T McInnes <btmcinnes@vcu.edu> 

=head1 COPYRIGHT

 Copyright (c) 2016
 Sam Henry, Virginia Commonwealth University 
 henryst at vcu.edu 

 Bridget T. McInnes, Virginia Commonwealth University 
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

=cut
