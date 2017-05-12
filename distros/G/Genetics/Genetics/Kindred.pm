# GenPerl module 
#

# POD documentation - main docs before the code

=head1 NAME

Genetics::Kindred

=head1 SYNOPSIS

  $kindred = new Genetics::Kindred(name => 'JXPed2',
				   importID => 45,
				   dateCreated => $today,
				   comment => "Litt et. al. (1994)", 
				   Keywords => [ {name => "Test Data", 
						  dataType => "Boolean", 
						  value => 1}, 
						 {name => "Disease", 
						  dataType => "String", 
						  value => "Episodic Ataxia"} ], 
				   NameAliases => [ {name => "Ped20", 
						     contactName => "J.P. Morgan"}, ], 
				   Subjects => [ {name => "EAPed20.1", importID => 42}, 
						 {name => "EAPed20.1000", importID => 43},
						 {name => "EAPed20.1001", importID => 44},
					       ], 
				  ) ;
  
See the GenPerl Tutorial for more information.

=head1 DESCRIPTION

Kindred objects represent groups of related individuals.

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

package Genetics::Kindred ;

BEGIN {
  $ID = "Genetics::Kindred" ;
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

@ATTRS = qw(isDerived DerivedFrom Subjects) ;

@REQD_ATTRS = qw(isDerived) ;

%DEFAULTS = (isDerived => 0) ;


=head1 Public methods

  printXML              Print an XML representation of the object

=cut

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
    my($class, $value, $listPtr, $hashPtr) ;

    $class = ref $self ;
    $class =~ s/.*::// ;
    
    ## Common Attributes/Elements
    $self->printGeneralXML($writer) ;
    
    ## Kindred Elements
    # Subject
    if (defined ($listPtr = $self->field('Subjects'))) {
	foreach $hashPtr (@$listPtr) {
	    $writer->startTag('SubjectRef') ;
	    defined $$hashPtr{name} and $$hashPtr{name} ne "" and 
	                      $writer->dataElement('Name', $$hashPtr{name}) ;
	    $writer->dataElement('ID', $$hashPtr{id}) ;
	    $writer->endTag('SubjectRef') ;
	}
    }
    
    $writer->endTag($class) ;

    return(1) ;
}

=head2 asHTML

  Function  : Generate an HTML representation of the object.
  Argument  : A Genetics::Kindred object and a scalar containing the name of 
              the GenPerl database in which the object is stored. 
  Returns   : Scalar containing the HTML text.
  Scope     : Public Instance Method
  Comments  : Calls Genetics::Object->_generalHTMLParam to generate HTML 
              elements common to all Genetics::Object objects.  An 
              HTML::Template object is used to actually generate the HTML.

=cut

sub asHTML {
  my($self, $db) = @_ ;
  my $tmpl = new HTML::Template(filename => "/home/slm/work/GenPerl/templates/kindred.tmpl") ;
  my(%param, $isDerived, $subjListPtr) ;

  %param = (DB => $db) ; # DB is the database the object is in.  It is used 
                         # to conscruct URL links to associated objects

  # Object data
  $self->_generalHTMLParam(\%param) ;

  # Kindred data
  $param{ISDERIVED} = $self->isDerived() ;
#    $self->isDerived() ? $param{ISDERIVED} = "Yes"
#                       : $param{ISDERIVED} = "No" ;
  if ($self->DerivedFrom()) {
    $param{PARENT} = $self->DerivedFrom->{name} ;
    $param{PARENTID} = $self->DerivedFrom->{id} ;
  }
  $subjListPtr = $self->Subjects() ;
  # add a db key/value to each subjPtr so that functional URLs linking to 
  # Subjects can be constructed
  grep { $_->{db} = $db } @$subjListPtr ;
  $param{SUBJECTS} = $subjListPtr ;

  $tmpl->param( %param ) ;

  return $tmpl->output() ;
}

1; 

