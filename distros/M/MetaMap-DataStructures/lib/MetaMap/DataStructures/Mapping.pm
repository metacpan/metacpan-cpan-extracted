# MetaMap::DataStructures::Mapping
# (Last Updated $Id: Mapping.pm,v 1.80 2016/01/07 22:49:33 btmcinnes Exp $)
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

package MetaMap::DataStructures::Mapping;  

#----------------------------------------
#               constructor
#----------------------------------------

#  constructor method to create a new Mapping object
#  input : $score <- the MMI of this Mapping
#          \@concepts <- an ordered list of  concept objects of this mapping
#  output: $self <- a new Mapping object
sub new {
    #create self
    my $class = shift;
    my $self = {};
    bless $self, $class;

    #grab the score and associated concepts
    $self->{score} = shift;
    $self->{concepts} = shift;

    return $self;
}

#----------------------------------------
#               methods
#----------------------------------------

#  method compares this mapping to another and returns 1 if the two 
#   contain identical information
#  input : $other <- the Mapping object to compare against
#  output: boolean <- 1 if $self and $other are equivalent (have the same score,
#                     and have equivalent concepts)
sub equals {
    #grab input
    my $self = shift;
    my $other = shift;

    #compare scores
    if ($self->{score} ne $other->{score}) {
	return 0;
    }

    #check that the mappings are the same
    #  since mappings are an ordered list
    #  a one-to-one comparison can be made
    if (scalar @{$self->{concepts}} != scalar @{$other->{concepts}}) {
	return 0;
    }

    #compare each concept
    for(my $i = 0; $i < scalar @{$self->{concepts}}; $i++) {
	if (!@{$self->{concepts}}[$i]->equals(@{$other->{concepts}}[$i])) {
	    return 0;
	}
    }

    #all tests passed, mappings are equivalent.
    return 1;
}

#  method summarizes this phrase as a string
#  input : -
#  output: $string <- a string describing $self
sub toString {
    my $self = shift;
    my $string = "mapping:\n";
    $string .= "   $self->{score}\n";

    #make sure concepts exist([cornea]),inputmatch(['Cornea']),tag(
    if (scalar @{$self->{concepts}} < 1) {
	$string .= "ERROR NO CONCEPTS\n";
    }

    #print each concept
    foreach $concept(@{$self->{concepts}}) {
	$string .= "   ".$concept->toString();
    }	

    return $string;
}

1;

__END__

=head1 NAME

MetaMap::DataStructure::Mapping - provides a container for the mapping 
information extracted from machine readable MetaMap mapped text. 

=head1 DESCRIPTION

This package provides a container for the mapping information extracted 
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
