# GenPerl module 
#

# POD documentation - main docs before the code

=head1 NAME

Genetics::HtMarkerCollection

=head1 SYNOPSIS

  $hmc = new Genetics::HtMarkerCollection(name => '12pEA1',
					  importID => 267,
					  dateCreated => $today,
					  Keywords => [ {name => "Test Data", 
							 dataType => "Boolean", 
							 value => 1}, 
						      ], 
					  Markers => [ {Marker => {name => "D12S91", 
								   importID => 1}, 
							distToNext => "1.2"}, 
						       {Marker => {name => "EAEx1.1", 
								   importID => 265},
						       }
						     ], 
					  distanceUnits => "cM",
					 ) ;
  
See the GenPerl Tutorial for more information.

=head1 DESCRIPTION

HtMarkerCollection objects represent an ordered set of genetic markers from 
which haplotypes can be constructed.

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

package Genetics::HtMarkerCollection ;

BEGIN {
  $ID = "Genetics::HtMarkerCollection" ;
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

@ATTRS = qw(distanceUnits Markers) ;

@REQD_ATTRS = qw(Markers) ;

%DEFAULTS = () ;


=head1 Public methods

  printXML              Print an XML representation of the object

=cut

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
    my($class, $listPtr, $hashPtr, $value) ;

    $class = ref $self ;
    $class =~ s/.*::// ;
    
    ## Common Attributes/Elements
    $self->printGeneralXML($writer) ;

    ## HMC Elements
    # HMCMarkerRef
    $listPtr = $self->field('HMCMarkerRef') ;
    foreach $hashPtr (@$listPtr) {
	$writer->startTag('HMCMarkerRef') ;
	$writer->startTag('MarkerRef') ;
	$writer->dataElement('Name', $$hashPtr{name}) ;
	$writer->dataElement('ID', $$hashPtr{id}) ;
	$writer->endTag('MarkerRef') ;
	$writer->dataElement('DistToNext', $$hashPtr{distToNext}) ;
	$writer->endTag('HMCMarkerRef') ;
    }
    # DistanceUnits
    if (defined ($value = $self->field('distanceUnits'))) {
	$writer->dataElement('DistanceUnits', $value) ;
    }

    $writer->endTag($class) ;

    return(1) ;
}

1; 

