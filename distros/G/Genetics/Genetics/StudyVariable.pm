# GenPerl module 
#

# POD documentation - main docs before the code

=head1 NAME

Genetics::StudyVariable

=head1 SYNOPSIS

  $sv = new Genetics::StudyVariable(name => 'EA Aff Stat',
				    importID => 445,
				    dateCreated => $today,
				    Keywords => [ {name => "Test Data", 
						   dataType => "Boolean", 
						   value => 1}, 
						], 
				    description => "EA Trait Locus", 
				    category => "AffectionStatus", 
				    format => "Code", 
				    isXLinked => 0, 
				    Codes => [ {code => 0,
						description => "Unknown EA Status"},
					       {code => 1,
						description => "EA Unaffected"},
					       {code => 2,
						description => "EA Affected"},
					     ], 
				    AffStatDef => {name => 'EA',
						   diseaseAlleleFreq => 0.001,
						   pen11 => 0.0,
						   pen12 => 0.0,
						   pen22 => 1.0,
						   AffStatElements => [ {code => 0,
									 type => "Unknown",
									 formula => "'EA Aff Stat' = 0"}, 
									{code => 1,
									 type => "Unaffected",
									 formula => "'EA Aff Stat' = 1"}, 
									{code => 2,
									 type => "Affected",
									 formula => "'EA Aff Stat' = 2"}, 
								      ],
						  },
				    LCDef => {name => 'EA Default LC',
					      LiabilityClasses => [ {code => 0,
								     description => "Unknown Age",
								     pen11 => 0.0,
								     pen12 => 0.0,
								     pen22 => 1.0,
								     formula => "'Age' = ''"}, 
								    {code => 1,
								     description => "Age less than 40",
								     pen11 => 0.0,
								     pen12 => 0.2,
								     pen22 => 1.0,
								     formula => "'Age' < 40"}, 
								    {code => 2,
								     description => "Age less than 50",
								     pen11 => 0.0,
								     pen12 => 0.3,
								     pen22 => 1.0,
								     formula => "'Age' < 50"}, 
								    {code => 3,
								     description => "Age grater than or equal to 60",
								     pen11 => 0.0,
								     pen12 => 0.4,
								     pen22 => 1.0,
								     formula => "'Age' >= 60"}, 
								  ],
					     },
				   ) ;
  
See the GenPerl Tutorial for more information.

=head1 DESCRIPTION

StudyVariable objects represent definitions of physical traits, affection 
status loci, environmental exposure, or drug treatments.

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

package Genetics::StudyVariable ;

BEGIN {
  $ID = "Genetics::StudyVariable" ;
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

@ATTRS = qw(description category format isXLinked lowerBound upperBound 
	    Codes AffStatDef LCDef) ;

@REQD_ATTRS = qw(category format isXLinked) ;

%DEFAULTS = (category => "Trait", 
	     isXLinked => 0
	    ) ;


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
    my($class, $value, $hashPtr, $hashPtr2) ;

    $class = ref $self ;
    $class =~ s/.*::// ;
    
    ## Common Attributes/Elements
    $self->printGeneralXML($writer) ;
    
    ## StudyVariable Elements
    # Format
    $writer->dataElement('Format', $self->field('format')) ;
    # Category
    $writer->dataElement('Category', $self->field('category')) ;
    # IsXLinked
    $writer->dataElement('IsXLinked', $self->field('isXLinked')) ;
    # Description
    if (defined ($value = $self->field('description'))) {
	$writer->dataElement('Description', $value) ;
    }
    # LowerBound
    if (defined ($value = $self->field('lowerBound'))) {
	$writer->dataElement('LowerBound', $value) ;
    }
    # UpperBound
    if (defined ($value = $self->field('upperBound'))) {
	$writer->dataElement('UpperBound', $value) ;
    }
    # DecimalPlaces
    if (defined ($value = $self->field('decimalPlaces'))) {
	$writer->dataElement('DecimalPlaces', $value) ;
    }
    # PtAssayMethodTemplate
    
    
    $writer->endTag($class) ;

    return(1) ;
}

=head2 asHTML

  Function  : Generate an HTML representation of the object.
  Argument  : A Genetics::StudyVariable object and a scalar containing the 
              name of the GenPerl database in which the object is stored. 
  Returns   : Scalar containing the HTML text.
  Scope     : Public Instance Method
  Comments  : Calls Genetics::Object->_generalHTMLParam to generate HTML 
              elements common to all Genetics::Object objects.  An 
              HTML::Template object is used to actually generate the HTML.

=cut

sub asHTML {
  my($self, $db) = @_ ;
  my $tmpl = new HTML::Template(filename => "/home/slm/work/GenPerl/templates/studyvar.tmpl") ;
  my(%param, $codeListPtr, $codePtr, @codes, $asdPtr, ) ;

  %param = (DB => $db) ; # DB is the database the object is in.  It is used 
                         # to conscruct URL links to associated objects

  # Object data
  $self->_generalHTMLParam(\%param) ;
  
  # Study Variable data
  $param{CATEGORY} = $self->category() ;
  $param{FORMAT} = $self->format() ;
  $param{ISXLINKED} = $self->isXLinked() ;
  $self->description() and $param{DESC} = $self->description() ;
  $self->lowerBound() and $param{LBOUND} = $self->lowerBound() ;
  $self->upperBound() and $param{UBOUND} = $self->upperBound() ;
  if ($self->format() eq "Code") {
    $codeListPtr = $self->Codes() ;
    if ($self->category() eq "StaticLiabilityClass") {
      # Need to get penetrance values and include them with the codes
      $param{SLC} = 1 ;
      $param{LCCODES} = $codeListPtr ;
    } else {
      foreach $codePtr (@$codeListPtr) {
	push @codes, "$$codePtr{code} ($$codePtr{description})" ;
      }
      $param{CODES} = join("<br>", @codes) ;
    }
  }
  if ($self->category() eq "StaticAffectionStatus") {
    $param{ASD} = 1 ;
    $asdPtr = $self->AffStatDef() ;
    $param{DISFREQ} = $$asdPtr{diseaseAlleleFreq} ;
    $param{PEN11} = $$asdPtr{pen11} ;
    $param{PEN12} = $$asdPtr{pen12} ;
    $param{PEN22} = $$asdPtr{pen22} ;
    if ($self->isXLinked()) {
      $param{MALEPEN1} = $$asdPtr{malePen1} ;
      $param{MALEPEN2} = $$asdPtr{malePen2} ;
    }
  }

  $tmpl->param( %param ) ;

  return $tmpl->output() ;
}

1; 

