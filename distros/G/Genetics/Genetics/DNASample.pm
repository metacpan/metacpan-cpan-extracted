# GenPerl module 
#

# POD documentation - main docs before the code

=head1 NAME

Genetics::DNASample

=head1 SYNOPSIS

  $sample = new Genetics::DNASample(name => 'SM20.1-3',
                                    importID => 272,
                                    dateCreated => $today,
                                    comment => "Third attempt to get DNA from this Sample", 
                                    Keywords => [ {name => "Test Data", 
                                                   dataType => "Boolean", 
                                                   value => 1}, 
                                                ], 
                                    dateCollected => "2001-01-18",
                                    amount => 3.26,
                                    amountUnits => "mg",
                                    concentration => 1.1,
                                    concUnits => "mg/ml",
                                    Subject => {name => 'EAPed20.1',
                                                importID => 12},
                                    Genotypes => [ {name => '1-D12S91',
                                                    importID => 13},
                                                   {name => '1-EAEx1.1',
                                                    importID => 14},
                                                 ],
                                   ) ;
  
See the GenPerl Tutorial for more information.

=head1 DESCRIPTION

DNASample objects represent the laboratory samples of extracted DNA.

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

package Genetics::DNASample ;

BEGIN {
  $ID = "Genetics::DNASample" ;
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

@ATTRS = qw(dateCollected amount amountUnits concentration concUnits
	    Subject Genotypes) ;

@REQD_ATTRS = qw() ;

%DEFAULTS = () ;


=head1 Public methods

  printXML              Write an XML representation of the object

=cut

=head2 printXML

  Function  : Write an XML representation of the object according to GnomML.dtd.
  Argument  : An XML::Writer object that will be used to generate the XML.
  Returns   : String
  Scope     : Public
  Comments  : Calls Genetics::Object->printGeneralXML to generate XML elements
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
    $writer->dataElement('Name', "YY") ;
    $writer->endTag('XX') ;

    $writer->endTag($class) ;

    return(1) ;
}

1; 

