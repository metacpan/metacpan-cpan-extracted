# GenPerl module 
#

# POD documentation - main docs before the code

=head1 NAME

Genetics::Haplotype

=head1 SYNOPSIS
 
  $ht = new Genetics::Haplotype(name => '12pEA1.1',
				importID => 268,
				dateCreated => $today,
				Keywords => [ {name => "Test Data", 
					       dataType => "Boolean", 
					       value => 1}, 
					    ], 
				MarkerCollection => {name => "12pEA1", importID => 267},
				Alleles => [ {name => 2, type => "code"}, 
					     {name => "C", type => "nucleotide"} ], 
                               ) ;

See the GenPerl Tutorial for more information.

=head1 DESCRIPTION

Haplotype objects represent a specific combination of alleles that are known, or 
predicted, to be segregating togehter.  The alleles in a haplotype may be experimentally 
determined or predicted statistically.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

=head1 FEEDBACK

Currently, all feedback should be sent directly to the author.

=head1 AUTHOR - Steve Mathias

Email: mathias@genomica.com

Phone: (720) 565-4029

Address: Genomica Corporation 
         1745 38th Street
         Boulder, CO 80301

=head1 DETAILS

The rest of the documentation describes each of the object variables and 
methods. The names of internal variables and methods are preceded with an
underscore (_).

=cut

##################
#                #
# Begin the code #
#                #
##################

package Genetics::Haplotype ;

BEGIN {
  $ID = "Genetics::Haplotype" ;
  #$DEBUG = $main::DEBUG ;
  $DEBUG = 0 ;
  $DEBUG and warn "Debugging in $ID is on" ;
}

=head1 Imported Packages

 Genetics::Object       Superclass
 strict			Just to be anal
 vars			Global variables

=cut

use Genetics::Object ;
use strict ;
use vars qw(@ISA $ID $DEBUG @ATTRS @REQD_ATTRS %DEFAULTS) ;

require		5.004 ;

@ISA = qw(Genetics::Object) ;

@ATTRS = qw(MarkerCollection Alleles) ;

@REQD_ATTRS = qw(MarkerCollection Alleles) ;

%DEFAULTS = () ;


=head1 Public methods

=head2 printXML

  Function  : Print an XML representation of the object.
  Argument  : A Genetics::StudyVariable object and the XML::Writer object being 
              used to generate the XML.
  Returns   : String
  Scope     : Public Instance Method
  Comments  : Calls Genetics::Object->printGeneralXML to generate XML elements
              common to all Genetics::Object objects.

=cut

sub printXML {
    my($self, $writer) = @_ ;
    my($class, $listPtr, $hashPtr) ;

    $class = ref $self ;
    $class =~ s/.*::// ;
    
    ## Common Attributes/Elements
    $self->printGeneralXML($writer) ;

    ## Haplotype Elements
    # HMCRef
    $hashPtr = $self->field('HMC') ;
    $writer->startTag('HMCRef') ;
    $writer->dataElement('Name', $$hashPtr{name}) ;
    $writer->dataElement('ID', $$hashPtr{id}) ;
    $writer->endTag('HMCRef') ;
    # HtAlleles
    $listPtr = $self->field('HtAlleles') ;
    $writer->startTag('HtAlleles') ;
    foreach $hashPtr (@$listPtr) {
	$writer->startTag('Allele') ;
	$writer->dataElement('Name', $$hashPtr{name}) ;
	$writer->dataElement('Type', $$hashPtr{type}) ;
	$writer->endTag('Allele') ;
    }
    $writer->endTag('HtAlleles') ;
    # HtRecombination
    if (defined ($listPtr = $self->field('HtRecombination'))) {
	$writer->startTag('HtRecombination') ;
	foreach $hashPtr (@$listPtr) {
	    $writer->startTag('MarkerRef') ;
	    $writer->dataElement('Name', $$hashPtr{name}) ;
	    $writer->dataElement('ID', $$hashPtr{id}) ;
	    $writer->endTag('MarkerRef') ;
	}
	$writer->endTag('HtRecombination') ;
    }
    # SubjectRef
    if (defined ($listPtr = $self->field('Subject'))) {
	foreach $hashPtr (@$listPtr) {
	    $writer->startTag('SubjectRef') ;
	    $writer->dataElement('Name', $$hashPtr{name}) ;
	    $writer->dataElement('ID', $$hashPtr{id}) ;
	    $writer->endTag('SubjectRef') ;
	}
    }
    
    $writer->endTag($class) ;

    return(1) ;
}


1; 

