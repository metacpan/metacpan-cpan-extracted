# GenPerl module 
#

# POD documentation - main docs before the code

=head1 NAME

Genetics::Phenotype

=head1 SYNOPSIS

  $pt = new Genetics::Phenotype(name => 'JXPed1-1-Age',
				importID => 266,
				dateCreated => $today,
				dateCollected => "1987-03-17",
				Keywords => [ {name => "Test Data", 
					       dataType => "Boolean", 
					       value => 1}, 
					    ], 
				Subject => {name => "JXPed1-1", importID => 12},
				StudyVariable => {name => "Age", importID => 444},
				AssayAttrs => [ {name => "Clinic Name",
						 dataType => "String",
						 value => "Sister of Gracious Mercy and Hope"},
					      ],
				value => 12,
				isActive => 1,
			       ) ;
  
See the GenPerl Tutorial for more information.

=head1 DESCRIPTION

Phenotype objects represent the experimentally determined value an 
individual has for a trait, affection status, environmental exposure, 
or drug treatment.

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

package Genetics::Phenotype ;

BEGIN {
  $ID = "Genetics::Phenotype" ;
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

@ATTRS = qw(value isActive dateCollected 
	    Subject StudyVariable AssayAttrs) ;

@REQD_ATTRS = qw(isActive value 
		 Subject StudyVariable) ;

%DEFAULTS = () ;


=head1 Public methods

  printXML              Print an XML representation of the object

=cut

=head2 printXML

  Function  : Print an XML representation of the object.
  Argument  : A Genetics::Genotype object and the XML::Writer object being used 
              to generate the XML.
  Returns   : String
  Scope     : Public
  Comments  : Calls Genetics::Object->printGeneralXML to generate XML elements
              common to all Genetics::Object objects.

=cut

sub printXML {
    my($self, $writer) = @_ ;
    my($class, $value, $hashPtr, $attrListPtr, $tag, $typeVal, $type, $val) ;

    $class = ref $self ;
    $class =~ s/.*::// ;
    
    ## Common Attributes/Elements
    $self->printGeneralXML($writer) ;
    
    ## Phenotype Elements
    # SubjectRef
    $hashPtr = $self->field('Subject') ;
    $writer->startTag('SubjectRef') ;
    $writer->dataElement('Name', $$hashPtr{name}) ;
    $writer->dataElement('ID', $$hashPtr{id}) ;
    $writer->endTag('SubjectRef') ;
    # StudyVarRef
    $hashPtr = $self->field('StudyVariable') ;
    $writer->startTag('StudyVarRef') ;
    $writer->dataElement('Name', $$hashPtr{name}) ;
    $writer->dataElement('ID', $$hashPtr{id}) ;
    $writer->endTag('StudyVarRef') ;
    # IsActive
    $writer->dataElement('IsActive', $self->field('isActive')) ;
    # PhenotypetAssayMethod

    # PtValue
    if (defined ($value = $self->field('value'))) {
	$writer->startTag('PtValue') ;
	$writer->dataElement('Value', $value) ;
	if (defined ($attrListPtr = $self->field('Attr'))) {
	    foreach $hashPtr (@$attrListPtr) {
		$writer->startTag('Attribute') ;
		while (($tag, $typeVal) = each(%$hashPtr)) {
		    ($type, $val) = split(/\s*=\s*/, $typeVal) ;
		    $writer->dataElement('Name', $tag) ;
		    $writer->dataElement('DataType', $type) ;
		    $writer->dataElement('Value', $val) ;
		}
		$writer->endTag('Attribute') ;
	    }
	}
	$writer->endTag('PtValue') ;
    }
    $writer->endTag($class) ;

    return(1) ;
}

=head2 asHTML

  Function  : Generate an HTML representation of the object.
  Argument  : A Genetics::Phenotype object and a scalar containing the name 
              of the GenPerl database in which the object is stored. 
  Returns   : Scalar containing the HTML text.
  Scope     : Public Instance Method
  Comments  : Calls Genetics::Object->_generalHTMLParam to generate HTML 
              elements common to all Genetics::Object objects.  An 
              HTML::Template object is used to actually generate the HTML.

=cut

sub asHTML {
  my($self, $db) = @_ ;
  my $tmpl = new HTML::Template(filename => "/home/slm/work/GenPerl/templates/phenotype.tmpl") ;
  my(%param) ;

  %param = (DB => $db) ; # DB is the database the object is in.  It is used 
                         # to conscruct URL links to associated objects

  # Object data
  $self->_generalHTMLParam(\%param) ;

  # Phenotype data
  $param{ISACTIVE} = $self->isActive() ;
  $param{VALUE} = $self->value() ;
  $self->dateCollected() and $param{DATECOLL} = $self->dateCollected() ;
  $param{SUBJECT} = $self->Subject->{name} ;
  $param{SUBJECTID} = $self->Subject->{id} ;
  $param{STUDYVAR} = $self->StudyVariable->{name} ;
  $param{STUDYVARID} = $self->StudyVariable->{id} ;

  $tmpl->param( %param ) ;

  return $tmpl->output() ;
}

1; 


