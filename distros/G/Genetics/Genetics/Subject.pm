# GenPerl module 
#

# POD documentation - main docs before the code

=head1 NAME

Genetics::Subject

=head1 SYNOPSIS

  $subject = new Genetics::Subject(name => 'JXPed1-1',
				   importID => 12,
				   dateCreated => $today,
				   NameAliases => [ {name => "jb2002", 
						     contactName => "Gregor Mendel"}
						  ], 
				   Contact => {name => "J.P. Morgan, II", 
					       comment => "Referring physican"}, 
				   DBXReferences => [ {accessionNumber => "abc123",
						       databaseName => "Clinical Land",
						       schemaName => "Master",
						       comment => "Internal Clinical DB"}
						    ],
				   Keywords => [ {name => "Study Population", 
						  dataType => "String", 
						  description => "Internal study identifier.", 
						  value => "Test"},
						 {name => "Foo", 
						  dataType => "String", 
						  description => "Crap", 
						  value => "Bar"},
						 {name => "Test Data", 
						  dataType => "Boolean", 
						  value => 1}, 
					       ], 
				   gender => "Male",
				   dateOfBirth => "1937-08-18", 
				   dateOfDeath => "1997-02-15",
				   isProband => 1,
				   Mother => {name => "JXPed1-2", importID => 32}, 
				   Father => {name => "JXPed1-3", importID => 22}, 
				   Kindred => {name => "JXPed1", importID => 264}, 
				   Organism => {genusSpecies => "Homo sapiens"},
				  ) ;

See the GenPerl Tutorial for more information.

=head1 DESCRIPTION

Subject objects represent the individuals in genetic studies.

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

package Genetics::Subject ;

BEGIN {
  $ID = "Genetics::Subject" ;
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

@ATTRS = qw(gender dateOfBirth dateOfDeath isProband 
	    Mother Father Kindred Organism Haplotypes) ;

@REQD_ATTRS = qw(gender) ;

%DEFAULTS = (isProband => 0) ;


=head1 Public methods

=head2 hasParents

  Function  : Find out if a Subject has parents.
  Argument  : N/A
  Returns   : 1 if a Subject has both a Mother and Father, 0 otherwise.
  Scope     : Public
  Comments  : Only checks for references in the Mother and Father fields; 
              does not check whether or not these references point to valid 
              Subjects.

=cut

sub hasParents {
  my($self) = @_ ;
  my($hasMom, $hasDad, $momPtr, $dadPtr) ;

  #$self->print() ;
  $hasMom = $hasDad = 0 ;
  $momPtr = $self->field("Mother") ;
  $dadPtr = $self->field("Father") ;
  defined($momPtr) and $momPtr ne "" and $hasMom = 1 ;
  defined($dadPtr) and $dadPtr ne "" and $hasDad = 1 ;

  if ($hasMom and $hasDad) {
    return(1) ;
  } else {
    return(0) ;
  }

}

=head2 getMotherName

  Function  : Get a Subject's Mother's name.
  Argument  : N/A
  Returns   : String
  Scope     : Public
  Comments  : 

=cut

sub getMotherName {
  my($self) = @_ ;
  my($momPtr) ;

  $momPtr = $self->field("Mother") ;
  if ( defined($momPtr) and $momPtr ne "" ) {
    return($$momPtr{name}) ;
  } else {
    return(undef) ;
  }
}

=head2 getFatherName

  Function  : Get a Subject's Father's name.
  Argument  : N/A
  Returns   : String
  Scope     : Public
  Comments  : 

=cut

sub getFatherName {
  my($self) = @_ ;
  my($dadPtr) ;

  $dadPtr = $self->field("Father") ;
  if ( defined($dadPtr) and $dadPtr ne "" ) {
    return($$dadPtr{name}) ;
  } else {
    return(undef) ;
  }
}

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
    my($class, $value, $hashPtr) ;

    $class = ref $self ;
    $class =~ s/.*::// ;
    
    ## Common Attributes/Elements
    $self->printGeneralXML($writer) ;
    
    ## Subject Elements
    # Sex
    $writer->dataElement('Sex', $self->field('sex')) ;
    # Organism
    if (defined ($hashPtr = $self->field('Organism'))) {
	$writer->startTag('Organism') ;
	$writer->dataElement('Genus', $$hashPtr{genus}) ;
	$writer->dataElement('Species', $$hashPtr{species}) ;
	$writer->endTag('Organism') ;
    }
    # DateOfBirth
    if (defined ($value = $self->field('dateOfBirth'))) {
	$writer->dataElement('DateOfBirth', $value) ;
    }
    # DateOfDeath
    if (defined ($value = $self->field('dateOfDeath'))) {
	$writer->dataElement('DateOfDeath', $value) ;
    }
    # Father
    if (defined ($hashPtr = $self->field('FatherName'))) {
	$writer->startTag('Father') ;
	$writer->startTag('SubjectRef') ;
	$writer->dataElement('Name', $$hashPtr{name}) ;
	$writer->dataElement('ID', $$hashPtr{id}) ;
	$writer->endTag('SubjectRef') ;
	$writer->endTag('Father') ;
    }
    # Mother
    if (defined ($hashPtr = $self->field('Mother'))) {
	$writer->startTag('Mother') ;
	$writer->startTag('SubjectRef') ;
	$writer->dataElement('Name', $$hashPtr{name}) ;
	$writer->dataElement('ID', $$hashPtr{id}) ;
	$writer->endTag('SubjectRef') ;
	$writer->endTag('Mother') ;
    }
    # Kindred
    if (defined ($hashPtr = $self->field('Kindred'))) {
	$writer->startTag('KindredRef') ;
	$writer->dataElement('Name', $$hashPtr{name}) ;
	$writer->dataElement('ID', $$hashPtr{id}) ;
	$writer->endTag('KindredRef') ;
    }

    $writer->endTag($class) ;

    return(1) ;
}

=head2 asHTML

  Function  : Generate an HTML representation of the object.
  Argument  : A Genetics::Subject object and a scalar containing the name of 
              the GenPerl database in which the object is stored. 
  Returns   : Scalar containing the HTML text.
  Scope     : Public Instance Method
  Comments  : Calls Genetics::Object->_generalHTMLParam to generate HTML 
              elements common to all Genetics::Object objects.  An 
              HTML::Template object is used to actually generate the HTML.

=cut

sub asHTML {
  my($self, $db) = @_ ;
  my $tmpl = new HTML::Template(filename => "/home/slm/work/GenPerl/templates/subject.tmpl") ;
  my(%param, $orgPtr) ;

  %param = (DB => $db) ; # DB is the database the object is in.  It is used 
                         # to conscruct URL links to associated objects

  # Object data
  $self->_generalHTMLParam(\%param) ;

  # Subject data
  if ($orgPtr = $self->Organism()) {
    $param{ORG} = $$orgPtr{genusSpecies} ;
  }
  $self->gender() and $param{GENDER} = $self->gender() ;
  $self->dateOfBirth() and $param{DATEOFBIRTH} = $self->dateOfBirth() ;
  $self->dateOfDeath() and $param{DATEOFDEATH} = $self->dateOfDeath() ;
  $self->isProband() and $param{ISPROBAND} = $self->isProband() ;
  if ($self->Mother()) {
    $param{MOTHER} = $self->Mother->{name} ;
    $param{MOTHERID} = $self->Mother->{id} ;
  }
  if ($self->Father()) {
    $param{FATHER} = $self->Father->{name} ;
    $param{FATHERID} = $self->Father->{id} ;
  }
  if ($self->Kindred()) {
    $param{KINDRED} = $self->Kindred->{name} ;
    $param{KINDREDID} = $self->Kindred->{id} ;
  }

  $tmpl->param( %param ) ;

  return $tmpl->output() ;
}

1; 

