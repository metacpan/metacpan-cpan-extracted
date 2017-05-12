# GenPerl module 
#

# POD documentation - main docs before the code

=head1 NAME

Genetics::Map

=head1 SYNOPSIS

  $map = new Genetics::Map(name => 'Chr12 2 PO',
			   importID => 121,
			   dateCreated => $today,
			   comment => "Stupid 2-marker map.", 
			   Keywords => [ {name => "Test Data", 
					  dataType => "Boolean", 
					  value => 1}, 
				       ], 
			   chromosome => "12",
			   orderingMethod => "Relative",
			   distanceUnits => "cM",
			   Organism => {genusSpecies => "Pongo pongo"},
			   OrderedMapElements => [ {SeqObj => {name => "D12S91", importID => 1},
						    distance => 1.3},
						   {SeqObj => {name => "EAEx1.1", importID => 265}}
						 ],
			  ) ;
  
See the GenPerl Tutorial for more information.

=head1 DESCRIPTION

Map objects represent an ordered list of Markers and the distances 
between them.

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

package Genetics::Map ;

BEGIN {
  $ID = "Genetics::Map" ;
  $DEBUG = 0 ;
  #$DEBUG = $main::DEBUG ;
  $DEBUG and warn "Debugging in $ID is on" ;
}

=head1 Imported Packages

  Genetics::Object      Superclass
  strict		Just to be anal
  vars			Global variables

=cut

use Genetics::Object ;
use strict ;
use vars qw(@ISA $ID $VERSION $DEBUG @ATTRS @REQD_ATTRS %DEFAULTS) ;

require		5.004 ;

@ISA = qw(Genetics::Object) ;

@ATTRS = qw(chromosome orderingMethod distanceUnits 
	    Organism OrderedMapElements) ;

@REQD_ATTRS = qw(orderingMethod distanceUnits OrderedMapElements) ;

%DEFAULTS = (orderingMethod => "Relative",
	     distanceUnits => "cM") ;


=head1 Public methods

  printXML              Write an XML representation of an object

=cut

=head2 printXML

  Function  : Print an XML representation of the object.
  Argument  : A XML::Writer object that will be used to generate the XML.
  Returns   : String
  Scope     : Public
  Called by : Calls Genetics::Object->printGeneralXML to generate XML elements
              common to all Genetics::Object objects.

=cut

sub printXML {
    my($self, $writer) = @_ ;
    my($class, $value, $genus, $species, $subjectID, $markerDistanceListRef, 
       $markerNameID, $distance, $markerName, $markerImportID, $elementID, $i) ;

    $class = ref $self ;
    $class =~ s/.*::// ;

    # Initialize variable for MapElement id attributes
    $i = 1 ;
    $elementID = "MapElement" . $i ;

    # Scientific Object Attributes/Elements
    $self->writeGeneralXML($writer) ;
    # Organism
    ($genus, $species) = split($self->field('Organism')) ;
    $writer->startTag('Organism') ;
    $writer->dataElement('Genus', $genus) ;
    $writer->dataElement('Species', $species) ;
    $writer->endTag('Organism') ;
    # Chromosome
    $writer->dataElement('Chromosome', $self->field('Chromosome')) ;
    # Source
    if (defined ($value = $self->field('Source'))) {
	$writer->startTag('ContactSource') ;
	$writer->dataElement('Name', $value) ;
	$writer->endTag('ContactSource') ;
    }
    # Distance Units
    $writer->dataElement('MapDistanceUnits', $self->field('DistanceUnits')) ;
    # OrderedMapElements
    if (defined ($markerDistanceListRef = $self->field('MarkersAndDistances'))) {
	while (($markerNameID, $distance) = splice(@$markerDistanceListRef, 0, 2)) {
	    ($markerName, $markerImportID) = $markerNameID =~ /(\w+):(\w+)/ ;
	    $writer->startTag('OrderedMapElement', 'id' => $elementID) ;
	    $writer->dataElement('Name', $markerName) ;
	    $writer->startTag('SeqObjRef') ;
	    $writer->dataElement('Name', $markerName) ;
	    $writer->dataElement('ImportID', $markerImportID) ;
	    $writer->endTag('SeqObjRef') ;
	    $writer->dataElement('Type', "Framework") ;
	    $writer->dataElement('DistanceToNext', $distance) ;
	    $writer->endTag('OrderedMapElement') ;
	    $elementID = "MapElement" . ++$i ;
	}
    }
    # MapFeatures
    # MapCorrelations
    # HomologousRegions
    # MapFunction
    # Gender
    $writer->dataElement('Gender', $self->field('Gender')) ;
    # Length
    # MapLiklihood
    # PopSample
    # MappingPanel
    $writer->endTag($class) ;

    return(1) ;
}

1; 

