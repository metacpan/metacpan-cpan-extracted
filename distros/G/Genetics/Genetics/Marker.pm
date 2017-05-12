# GenPerl module 
#

# POD documentation - main docs before the code

=head1 NAME

Genetics::Marker

=head1 SYNOPSIS

  $marker = new Genetics::Marker(name => 'D12S91',
				 importID => 1,
				 dateCreated => $today,
				 comment => "Marker in EA critical region",
				 NameAliases => [ {name => "d12s6666"}
						], 
				 Contact => {name => "Jean Weissenbach",
					     organization => "Genethon"}, 
				 DBXReferences => [ {accessionNumber => "NT_009758.3",
						     databaseName => "GenBank"}
						  ],
				 Keywords => [ {name => "Test Data", 
						dataType => "Boolean", 
						value => 1},
					     ], 
				 chromosome => "12", 
				 malePloidy => 2,
				 femalePloidy => 2,
				 polymorphismType => "Repeat", 
				 polymorphismIndex1 => 7, 
				 polymorphismIndex2 => 11, 
				 repeatSequence => "CA",
				 Organism => {genusSpecies => "Homo sapiens"},
				 Alleles => [ {name => 1, type => "Code"}, 
					      {name => 2, type => "Code"},
					      {name => 3, type => "Code"},
					      {name => 4, type => "Code"},
					      {name => 5, type => "Code"},
					      {name => 6, type => "Code"} ],
				 ISCNMapLocations => [ {chrNumber => "12", 
							chrArm => "p", 
							band => "12.2.1", 
							bandingMethod => "Geimsa"}, ],
				 Sequence => {lengthUnits => "bp",
					      length => 17,
					      sequence => "ACGTUMRCACAWSYKVHDBXN"},
				) ;

See the GenPerl Tutorial for more information.

=head1 DESCRIPTION

Marker objects represent polymorphic genetic markers.

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

package Genetics::Marker ;

BEGIN {
  $ID = "Genetics::Marker" ;
  #$DEBUG = $main::DEBUG ;
  $DEBUG = 0 ;
  $DEBUG and warn "Debugging in $ID is on" ;
}

=head1 Imported Packages

  Genetics::Object      Superclass
  strict		Just to be anal
  vars			Global variables

=cut

use Genetics::Object ;
use strict ;
use vars qw(@ISA $ID $DEBUG @ATTRS @REQD_ATTRS %DEFAULTS) ;

require		5.004 ;

@ISA = qw(Genetics::Object) ;

@ATTRS = qw(chromosome malePloidy femalePloidy polymorphismType 
	    polymorphismIndex1 polymorphismIndex2 repeatSequence
	    Alleles Sequence ISCNMapLocations Organism 
	   ) ;

@REQD_ATTRS = qw(malePloidy femalePloidy) ;

%DEFAULTS = (malePloidy => 2, femalePloidy => 2) ;


=head1 Public methods

=head2 printXML

  Function  : Print an XML representation of the object.
  Argument  : A Genetics::Subject object and the XML::Writer object being used 
              to generate the XML.
  Returns   : N/A
  Scope     : Public Instance Method
  Comments  : Calls Genetics::Object->printGeneralXML to generate XML elements
              common to all Genetics::Object objects.

=cut

sub printXML {
    my($self, $writer) = @_ ;
    my($class, $value, $hashPtr, $hashPtr2) ;

    $class = ref $self ;
    $class =~ s/.*::// ;
    
    ## Common Attributes/Elements
    $self->printGeneralXML($writer) ;
    
    ## Marker Elements
    # SeqAttributes 
    $hashPtr = $self->field('SeqAttributes') ;
    $writer->startTag('SeqAttributes') ;
    if (defined ($hashPtr2 = $$hashPtr{Organism})) {
	$writer->startTag('Organism') ;
	$writer->dataElement('Genus', $$hashPtr2{genus}) ;
	$writer->dataElement('Species', $$hashPtr2{species}) ;
	$writer->endTag('Organism') ;
    }
    if (defined ($hashPtr2 = $$hashPtr{Chromosome})) {
	$writer->startTag('Chromosome') ;
	$writer->dataElement('Name', $$hashPtr2{name}) ;
	$writer->endTag('Chromosome') ;
    }
    if (defined ($hashPtr2 = $$hashPtr{NtSequence})) {
	$writer->startTag('NucleotideSeq') ;
	$writer->dataElement('LengthUnits', $$hashPtr2{lengthUnits}) ;
	$writer->dataElement('Length', $$hashPtr2{length}) ;
	$writer->dataElement('NtSequence', $$hashPtr2{ntSequence}) ;
	$writer->endTag('NucleotideSeq') ;
    }
    if (defined ($hashPtr2 = $$hashPtr{Source})) {
	$writer->startTag('ContactSource') ;
	    $writer->dataElement('Name', $$hashPtr2{name}) ;
	    $writer->dataElement('Comment', $$hashPtr2{comment}) ;
	    $writer->endTag('ContactSource') ;
    }
    $writer->endTag('SeqAttributes') ;
    # ISCNMapLocation
    if (defined ($hashPtr = $self->field('ISCNMapLocation'))) {
	$writer->startTag('ISCNMapLocation') ;
	$writer->dataElement('ChrNumber', $$hashPtr{chrNumber}) ;
	$writer->dataElement('ChrArm', $$hashPtr{chrArm}) ;
	$writer->dataElement('Band', $$hashPtr{band}) ;
	$writer->dataElement('BandingMethod', $$hashPtr{bandingMethod}) ;
	$writer->endTag('ISCNMapLocation') ;
    }
    # ProbeChar
    if (defined ($hashPtr = $self->field('ProbeChar'))) {
	$writer->startTag('ProbeChar') ;
	$writer->dataElement('ProbeCharType', $$hashPtr{characteristic}) ;
	$writer->dataElement('Comment', $$hashPtr{comment}) ;
	$writer->endTag('ProbeChar') ;
    }
    # MalePloidy
    $writer->dataElement('MalePloidy', $self->field('malePloidy')) ;
    # FemalePloidy
    $writer->dataElement('FemalePloidy', $self->field('femalePloidy')) ;
    # Allele
    if (defined ($value = $self->field('Allele'))) {
	foreach $hashPtr (@$value) {
	    $writer->startTag('Allele') ;
	    $writer->dataElement('Name', $$hashPtr{name}) ;
	    $writer->dataElement('Type', $$hashPtr{type}) ;
	    $writer->endTag('Allele') ;
	}
    }
    # PolymophismType
    if (defined ($value = $self->field('polymorphismType'))) {
	$writer->dataElement('PolymophismType', $value) ;
    }
    # NtRepeatUnit
    if (defined ($value = $self->field('nucleotideRepeatUnit'))) {
	$writer->dataElement('NtRepeatUnit', $value) ;
    }
    # RepeatSequence
    if (defined ($value = $self->field('repeatSequence'))) {
	$writer->dataElement('RepeatSequence', $value) ;
    }
    # GtAssayMethodTemplate

    $writer->endTag($class) ;

    return(1) ;
}

=head2 asHTML

  Function  : Generate an HTML representation of the object.
  Argument  : A Genetics::Marker object and a scalar containing the name of 
              the GenPerl database in which the object is stored. 
  Returns   : Scalar containing the HTML text.
  Scope     : Public Instance Method
  Comments  : Calls Genetics::Object->_generalHTMLParam to generate HTML 
              elements common to all Genetics::Object objects.  An 
              HTML::Template object is used to actually generate the HTML.

=cut

sub asHTML {
  my($self, $db) = @_ ;
  my $tmpl = new HTML::Template(filename => "/home/slm/work/GenPerl/templates/marker.tmpl") ;
  my(%param, $alleleListPtr, $allelePtr, @alleles, $orgPtr, $seqPtr, 
     $iscnListPtr, $iscnPtr, @iscnLoc) ;

  %param = (DB => $db) ; # DB is the database the object is in.  It is used 
                         # to conscruct URL links to associated objects

  # Object data
  $self->_generalHTMLParam(\%param) ;
  
  # Marekr data
  $alleleListPtr = $self->Alleles() ;
  foreach $allelePtr (@$alleleListPtr) {
    push @alleles, "$$allelePtr{name}($$allelePtr{type})" ;
  }
  $param{ALLELES} = join(", ", @alleles) ;
  if ($orgPtr = $self->Organism()) {
    $param{ORG} = $$orgPtr{genusSpecies} ;
  }
  $self->chromosome() and $param{CHR} = $self->chromosome() ;
  $self->malePloidy() and $param{MPLOIDY} = $self->malePloidy() ;
  $self->femalePloidy() and $param{FPLOIDY} = $self->femalePloidy() ;
  $self->polymorphismType() and $param{POLYTYPE} = $self->polymorphismType() ;
  $self->repeatSequence() and $param{RPTSEQ} = $self->repeatSequence() ;
  $self->polymorphismIndex1() and $param{POLYIDX1} = $self->polymorphismIndex1() ;
  $self->polymorphismIndex2() and $param{POLYIDX2} = $self->polymorphismIndex2() ;
  if ($seqPtr = $self->Sequence()) {
    $param{SEQUENCE} = $$seqPtr{sequence} ;
  }
  if ($iscnListPtr = $self->ISCNMapLocations()) {
    foreach $iscnPtr (@$iscnListPtr) {
      push @iscnLoc, "$$iscnPtr{chrNumber }$$iscnPtr{hrArm}$$iscnPtr{band}" ;
    }
    $param{ISCNLOC} = join(", ", @iscnLoc) ;
  }
  $tmpl->param( %param ) ;

  return $tmpl->output() ;
}

1; 

