# GenPerl module 
#

# POD documentation - main docs before the code

=head1 NAME

Genetics::TissueSample

=head1 SYNOPSIS

  $sample = new Genetics::TissueSample(name => 'SM20.1',
				       importID => 273,
				       dateCreated => $today,
				       comment => "Hard to make DNA from this", 
				       Keywords => [ {name => "Test Data", 
						      dataType => "Boolean", 
						      value => 1}, 
						   ], 
				       tissue => "Muscle",
				       dateCollected => "2001-01-18",
				       amount => 150,
				       amountUnits => "g",
				       Subject => {name => 'EAPed20.1',
						   importID => 12},
				       DNASamples => [ {name => 'SM20.1-3',
							importID => 272},
						     ]
				      ) ;
  
See the GenPerl Tutorial for more information.

=head1 DESCRIPTION

TissueSample objects represent the laboratory tissue samples.

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

package Genetics::TissueSample ;

BEGIN {
  $ID = "Genetics::TissueSample" ;
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

@ATTRS = qw(tissue dateCollected amount amountUnits 
	    Subject Genotypes DNASamples) ;

@REQD_ATTRS = qw(tissue) ;

%DEFAULTS = () ;


=head1 Public methods

  printXML              Write an XML representation of the object

=cut

=head2 printXML

  Function  : Write an XML representation of the object according to GnomML.dtd.
  Argument  : A XML::Writer object that will be used to generate the XML.
  Returns   : String
  Scope     : Public
  Comments  : Calls Genetics::Object->writeGeneralXML to generate XML elements
              common to all Genetics::Object objects.

=cut

sub printXML {
    my($self, $writer) = @_ ;
    my($class, $field) ;

    $class = ref $self ;
    $class =~ s/.*::// ;
    
    ## Common Attributes/Elements
    $self->printGeneralXML($writer) ;
    
    $writer->startTag('XX') ;	
    $writer->dataElement('Name', "ZZ") ;
    $writer->endTag('XX') ;

    $writer->endTag($class) ;

    return(1) ;
}

1; 

