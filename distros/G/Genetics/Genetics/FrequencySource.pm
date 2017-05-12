# GenPerl module 
#

# POD documentation - main docs before the code

=head1 NAME

Genetics::FrequencySource

=head1 SYNOPSIS

  $fs = new Genetics::FrequencySource(name => 'WICGR SNP Freqs',
				      importID => 270,
				      dateCreated => $today,
				      Keywords => [ {name => "Test Data", 
						     dataType => "Boolean", 
						     value => 1}, 
						  ], 
				      ObsAlleleFrequencies => [ {Allele => {Marker => {name => "EAEx1.1", 
										       importID => 265}, 
									    name => "T", 
									    type => "nucleotide"}, 
								 frequency => "0.64",
								},
								{Allele => {Marker => {name => "EAEx1.1", 
										       importID => 265}, 
									    name => "C", 
									    type => "nucleotide"}, 
								 frequency => "0.36",
								}
							      ], 
				      ObsHtFrequencies => [ {Haplotype => {name => '12pEA1.2',
									   importID => 269,},
							     frequency => 1.00,
							    }
							  ]
                                     ) ;
  
See the GenPerl Tutorial for more information.

=head1 DESCRIPTION

FrequencySource objects represent the allele and/or haplotype frequencies 
in a particular group of Subjects not represented in the database.  

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

package Genetics::FrequencySource ;

BEGIN {
  $ID = "Genetics::FrequencySource" ;
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

@ATTRS = qw(ObsAlleleFrequencies ObsHtFrequencies) ;

@REQD_ATTRS = qw() ;

%DEFAULTS = () ;


=head1 Public methods

=head2 getAlleleFreqsByMarkerName

  Function  : Return allele frequencies for an individual marker.
  Argument  : A Marker object and a string containing an allele type.
  Returns   : Hash reference to a hash with the following structure:
                $freqs{AlleleName} = $number
  Scope     : Public
  Comments  : This method requires that Markers are uniquely named within the 
              FrequencySource.

=cut

sub getAlleleFreqsByMarkerName {
  my($self, $markerName, $alleleType) = @_ ;
  my($oafListPtr, $oafPtr, $allelePtr, %freqs) ;

  $oafListPtr = $self->field("ObsAlleleFrequencies") ;

  foreach $oafPtr (@$oafListPtr) {
    $allelePtr = $$oafPtr{Allele} ;
    if ($$allelePtr{Marker}{name} eq $markerName and 
	                    $$allelePtr{type} eq $alleleType) {
      $freqs{$$allelePtr{name}} = $$oafPtr{frequency} ;
    }
  }

  return(\%freqs) ;
}

=head2 printXML

  Function  : Print an XML representation of the object.
  Argument  : An XML::Writer object being used to generate the XML.
  Returns   : String
  Scope     : Public Instance Method
  Comments  : Calls Genetics::Object->printGeneralXML to generate XML elements
              common to all Genetics::Object objects.

=cut

sub printXML {
    my($self, $writer) = @_ ;
    my($class, $listPtr, $hashPtr, $hashPtr2, $listPtr2) ;

    $class = ref $self ;
    $class =~ s/.*::// ;
    
    ## Common Attributes/Elements
    $self->printGeneralXML($writer) ;

    ## FrequencySource Elements
    # ObsAlleleFrequency
    if (defined ($listPtr = $self->field('ObsAlleleFrequency'))) {
	foreach $hashPtr (@$listPtr) {
	    $writer->startTag('ObsAlleleFrequency') ;
	    $hashPtr2 = $$hashPtr{Marker} ;
	    $writer->startTag('MarkerRef') ;
	    $writer->dataElement('Name', $$hashPtr2{name}) ;
	    $writer->dataElement('ID', $$hashPtr2{id}) ;
	    $writer->endTag('MarkerRef') ;
	    $hashPtr2 = $$hashPtr{Allele} ;
	    $writer->startTag('Allele') ;
	    $writer->dataElement('Name', $$hashPtr2{name}) ;
	    $writer->dataElement('Type', $$hashPtr2{type}) ;
	    $writer->endTag('Allele') ;
	    $writer->dataElement('Frequency', $$hashPtr{frequency}) ;
	    $writer->endTag('ObsAlleleFrequency') ;
	} 
    }
    # ObsGtFrequency
    if (defined ($listPtr = $self->field('ObsGtFrequency'))) {
	foreach $hashPtr (@$listPtr) {
	    $writer->startTag('ObsGtFrequency') ;
	    $hashPtr2 = $$hashPtr{Marker} ;
	    $writer->startTag('MarkerRef') ;
	    $writer->dataElement('Name', $$hashPtr2{name}) ;
	    $writer->dataElement('ID', $$hashPtr2{id}) ;
	    $writer->endTag('MarkerRef') ;
	    $listPtr2 = $$hashPtr{Allele} ;
	    foreach $hashPtr2 (@$listPtr2) {
		$writer->startTag('Allele') ;
		$writer->dataElement('Name', $$hashPtr2{name}) ;
		$writer->dataElement('Type', $$hashPtr2{type}) ;
		$writer->endTag('Allele') ;
	    }
	    $writer->dataElement('Frequency', $$hashPtr{frequency}) ;
	    $writer->endTag('ObsGtFrequency') ;
	} 
    }

    $writer->endTag($class) ;

    return(1) ;
}


1; 

