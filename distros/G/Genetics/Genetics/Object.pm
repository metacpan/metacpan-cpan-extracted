# GenPerl module 
#

# POD documentation - main docs before the code

=head1 NAME

Genetics::Object

=head1 SYNOPSIS

A synopsis is not appropriate, as one would never normally instantiate 
an instance of Genetics::Object.  

See the synopses for the individual subclasses.

=head1 DESCRIPTION

This is the base class for all GenPerl objects.

For more information, see the GenPerl tutorial and the documentation for the 
individual sub-classes.  Also, see Genetics::API for a description of the GenPerl 
database interface.

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

package Genetics::Object ;

BEGIN {
  $ID = "Genetics::Object" ;
  #$DEBUG = $main::DEBUG ;
  $DEBUG = 0 ;
  $DEBUG and $| = 1 ;
  $DEBUG and warn "Debugging in $ID (v$VERSION) is on" ;
}

=head1 Imported Packages

  strict		Just to be anal
  vars			Global variables
  Carp			Error reporting
  XML::Writer           Used by generateXML methods
  HTML::Template        Used by asHTML methods

  Genetics::Cluster     Subclass
  Genetics::DNASample   Subclass
  Genetics::FrequencySource Subclass
  Genetics::Genotype    Subclass
  Genetics::Haplotype   Subclass
  Genetics::HtMarkerCollection Subclass
  Genetics::Kindred     Subclass
  Genetics::Map         Subclass
  Genetics::Marker      Subclass
  Genetics::Phenotype   Subclass
  Genetics::SNP         Subclass
  Genetics::StudyVariable Subclass
  Genetics::Subject     Subclass
  Genetics::TissueSample Subclass

=cut

use strict;
use Carp ;
use XML::Writer ;
use HTML::Template ; # Comment this out for distribution.  It's only used by the CGI app.

use Genetics::Cluster ;
use Genetics::DNASample ;
use Genetics::FrequencySource ;
use Genetics::Genotype ;
use Genetics::Haplotype ;
use Genetics::HtMarkerCollection ;
use Genetics::Kindred ;
use Genetics::Map ;
use Genetics::Marker ;
use Genetics::Phenotype ;
use Genetics::SNP ;
use Genetics::StudyVariable ;
use Genetics::Subject ;
use Genetics::TissueSample ;

require		5.004 ;

use vars qw($ID $VERSION $DEBUG $AUTOLOAD 
            @OBJ_ATTRS @OBJ_REQD_ATTRS @OBJ_XML_ATTRS 
	    $HTML_TEMPLATE_DIR) ;

@OBJ_ATTRS = qw(name id importID dateCreated dateModified url comment 
		NameAliases Contact DBXReferences Keywords) ;

@OBJ_REQD_ATTRS = qw(name) ; # an id OR importID is also required

@OBJ_XML_ATTRS = qw(name id) ;

$HTML_TEMPLATE_DIR = "/var/slm/work/GenPerl/templates" ;


=head1 Public methods

=head2 new

  Function  : Object constructor
  Arguments : Class name and hash array
  Returns   : Blessed hash
  Scope     : Public
  Called by : Main
  Comments  : Creates an empty hash, blesses it into the class name and calls
              _initialize with the arguments passed

=cut

sub new {
  my($pkg, %args) = @_ ;
  my($self) = {} ;

  bless $self, ref($pkg) || $pkg ;
  $DEBUG and carp "\n==>Creating new $ID object: $self" ;
  $self->_initialize(%args) ;

  $DEBUG and carp "==>Successfully created new $ID object: $self" ;

  return($self) ;
}

=head2 new

  Function  : Return the object type: Subject, Genotype, etc.
  Arguments : A Genetics::Object object.
  Returns   : Scalar
  Scope     : Public
  Comments  : 

=cut

sub type {
  my($self) = shift ;
  my $pkg = ref($self) ;
  my($type) = $pkg =~ /\.*::(\w+)/ ;
  
  return $type ;
}

=head2 field

  Function  : Get or set specified field data
  Argument  : Field name and value (both optional)
  Returns   : Called with a single argument, this returns the value of the field 
              named by the argument.  Called with tow argumetns, this sets the 
              value of the field named by the first argument to the value in the 
              second argument.  Called with no arguments, this returns a list of 
              all field names.
  Scope     : Public
  Called by : 
  Comments  : As an alternative to using this method, field names can be used as 
              get/set methods (see AUTOLOAD).

=cut

sub field {
  my($self, $field, $value) = @_ ;
  my($class, $k, $v, @h) ;

  $class = ref $self ;

  @_ == 1 and return grep (/^[^_]/, sort keys %$self) ;
  @_ == 2 and ! defined $self->{$field} and return undef ;
  if (@_ == 3) {
    if (not ref $value) {
      $self->{$field} = $value ;
      $DEBUG and ($value ne "") and carp " ->Setting $class attribute '$field' to '$value'" ;
    } elsif (ref $value eq "ARRAY") {
      $self->{$field} = $value ;
      $DEBUG and carp " ->Setting $class attribute '$field' to [ ", join(", ", @$value), " ]" ;
    } elsif (ref $value eq "HASH") {
      $self->{$field} = $value ;
      if ($DEBUG) {
	while (($k,$v) = each %$value) {
	  push(@h, "$k => $v") ;
	}
	carp " ->Setting $class attribute '$field' to { ", join(", ", @h), " }" ;
      }
    } else {
      carp " ->Value of $class attribute $field is a reference to an unsupported type" ;
    }
  }
  
  return $self->{$field} ;
}

=head2 print

  Function  : Print out object in a raw format
  Argument  : N/A
  Returns   : N/A
  Scope     : Public
  Called by : Main
  Comments  : This is mostly for debugging purposes.

=cut

sub print {
    my($self) = @_ ;
    my($field, $value, $printString) ;

    print "\n$self:\n" ;
    foreach $field ($self->field()) {
	$value = $self->field($field) ;
	$printString = _attr2String($value) ;
	
	printf "%-22s:\t%s\n", $field, $printString ;
    }
    print "\n" ;

    return 1 ;
}

=head2 dump

  Function  : Same as print, but returns a string instead of printing it.
  Argument  : N/A
  Returns   : Scalar text string.
  Scope     : Public
  Called by : Main
  Comments  : This is mostly for debugging purposes.

=cut

sub dump {
    my($self) = @_ ;
    my($field, $value, $printString, $returnString) ;

    $returnString = "\n$self:\n" ;
    foreach $field (sort $self->field()) {
	$value = $self->field($field) ;
	$printString = _attr2String($value) ;
	$returnString .= sprintf "%-22s:\t%s\n", $field, $printString ;
    }
    $returnString .= "\n" ;

    return $returnString ;

}

=head2 printObjectXML

  Function  : Generate and print XML common to all Genperl objects. 
  Argument  : A Genetics::Object object and the XML::Writer object being used 
              to generate the XML.
  Returns   : N/A
  Scope     : Public Instance Method
  Called by : printXML methods of Genetics::Object subclasses.
  Comments  : 

=cut

sub printObjectXML {
    my($self, $writer) = @_ ;
    my($class, $attrName, %xmlAttr, $value, $hashPtr, $hashPtr2) ;
    
    $class = ref $self ;
    $class =~ s/.*::// ;
    
    ## Object XML Attributes ##
    foreach $attrName (@OBJ_XML_ATTRS) {
	if (defined ($self->field($attrName))) {
	    $xmlAttr{$attrName} = $self->field($attrName) ;
	}
    }
    $writer->startTag($class, %xmlAttr) ;

    ## Object XML Elements ##
    # DateCreated
    $writer->dataElement('DateCreated', $self->field('dateCreated')) ;
    # CreatedBy
    $hashPtr = $self->field('CreatedBy') ;
    $writer->startTag('CreatedBy') ;
    $writer->startTag('UserRef') ;
    $writer->dataElement('Name', $$hashPtr{name}) ;
    $writer->dataElement('ID', $$hashPtr{id}) ;
    $writer->endTag('UserRef') ;
    $writer->endTag('CreatedBy') ;
    # DateModified
    $writer->dataElement('DateModified', $self->field('dateModified')) ;
    # ModifiedBy
    $hashPtr = $self->field('ModifiedBy') ;
    $writer->startTag('ModifiedBy') ;
    $writer->startTag('UserRef') ;
    $writer->dataElement('Name', $$hashPtr{name}) ;
    $writer->dataElement('ID', $$hashPtr{id}) ;
    $writer->endTag('UserRef') ;
    $writer->endTag('ModifiedBy') ;
    # DataContainer
    if (defined ($value = $self->field('DataContainer'))) {
	$writer->dataElement('DataContainer', $value) ;
    }

    return(1) ;
}

=head2 toStone

 Function  : 
 Arguments : 
 Returns   : 
 Example   : toStone()
 Scope     : Public instance method
 Comments  : 

=cut

sub toStone {
  my($self) = @_ ;
  my($stone, $field, $value, $valueAsString, %init) ;

  use Stone ;
  
  foreach $field ($self->field()) {
    $value = $self->field($field) ;
    #$valueAsString = _attr2String($value) ;
    $field = ucfirst $field ;
    $init{$field} = $value ;
  }
  $stone = new Stone(%init) ;

  return $stone ;
}
 

=head2 AUTOLOAD

  Function  : Allow field names to be used as get/set methods instead of field().
  Argument  : Optional field value, in which case the field is set to this new 
              value (see field())
  Returns   : Field value
  Scope     : Public
  Called by : Called automatically when an undefined method - in 
              Genetics::Object, or any of its subclasses - is invoked.

=cut

sub AUTOLOAD {
  my $self = shift ;
  my $class = ref $self ;
  my($package, $methodName) = $AUTOLOAD =~ /(.+)::([^:]+)$/ ;

  no strict 'refs' ;  
  unless ( grep { $methodName eq $_ } (@OBJ_ATTRS, @{"${class}::ATTRS"}) ) {
    croak "Can't locate object method \"$methodName\" via package \"$package\".  \"$methodName\" must be a valid field in class \"$package\" in order to be invoked as a method in this way." ;
  }
  use strict 'refs' ;

  return $self->field($methodName, @_) ;
}

=head2 DESTROY

  Function  : Deallocate object storage
  Argument  : N/A
  Returns   : N/A
  Scope     : Public
  Called by : Called automatically when the object goes out of scope 
              (ie the internal reference count in the symbol table is 
              zero).  Can be called explicitly.

=cut

sub DESTROY {
    my($self) = shift ; 
    my $pkg = ref $self ;

    $DEBUG and carp "\n==>Destroyed $ID object: $self" ;
}

=head1 Private methods

=head2 _initialize

  Function  : Initialize object
  Arguments : Hash array of attributes/values passed to new()
  Returns   : N/A
  Scope     : Private
  Called by : 
  Comments  : 

=cut

sub _initialize {
  my ($self, %args) = @_;
  my ($class, $k, $v, $k2,$v2, @h) ;

  $class = ref $self ;

  #%{$self->{_arguments}} = %args ;
  no strict 'refs' ;
  while (($k,$v) = each %args) {
    if (not ref $v) {
      if ( grep { $k eq $_ } ( @OBJ_ATTRS, @{"${class}::ATTRS"} )) {
	$self->{$k} = $v ;
	$DEBUG and carp " ->Setting $class attribute '$k' to '$v'" ;
      } else {
	carp "<<- WARNING ->> Skipping invalid $class attribute '$k'" ;
	next ;
      }
    } elsif (ref $v eq "ARRAY") {
      if ( grep { $k eq $_ } ( @OBJ_ATTRS, @{"${class}::ATTRS"} )) {
	$self->{$k} = $v ;
	$DEBUG and carp " ->Setting $class attribute '$k' to [ ", join(", ", @$v), " ]" ;
      } else {
	carp "<<- WARNING ->> Skipping invalid $class attribute '$k'" ;
	next ;
      }
    } elsif (ref $v eq "HASH") {
      if ( grep { $k eq $_ } ( @OBJ_ATTRS, @{"${class}::ATTRS"} )) {
	$self->{$k} = $v ;
	if ($DEBUG) {
	  while (($k2,$v2) = each %$v) {
	    push(@h, "$k2 => $v2") ;
	  }
	  carp " ->Setting $class attribute '$k' to { ", join(", ", @h), " }" ;
	}
      } else {
	carp "<<- WARNING ->> Skipping invalid $class attribute '$k'" ;
	next ;
      }
    } else {
      carp "<<- WARNING ->> Value of $class attribute $k is a reference to an unsupported type" ;
    }
  }
  use strict 'refs' ;
  $self->_setDefaults() ;
  $self->_verifyRequired() ;
  
  $DEBUG and carp ">=>Completed initialization of object: $self" ;

  return(1) ;
}

=head2 _setDefaults

  Function  : Set default attribute values
  Arguments : 
  Returns   : N/A
  Scope     : Private
  Called by : Genetics::Object->_initialize
  Comments  : 

=cut

sub _setDefaults {
  my ($self) = @_;
  my($class, $k, $v) ;

  $class = ref $self ;
  no strict 'refs' ;
  while ( ($k,$v) = each %{"${class}::DEFAULTS"} ) {
    unless (defined $self->field($k) && $self->field($k) ne "") {
      $self->field($k, $v) ;
      $DEBUG and carp " ->Setting $ID field '$k' to default value '$v'" ;
    }
  }
  use strict 'refs' ;

  $DEBUG and carp "==>Completed setting default attributes for object: $self" ;
  
  return(1) ;
}

=head2 _verifyRequired

  Function  : Verify that required attributes are set
  Arguments : N/A
  Returns   : N/A
  Scope     : Private
  Called by : Genetics::Object->_initialize()
  Comments  : Verify that required fields have values.

=cut

sub _verifyRequired {
  my ($self) = @_ ;
  my ($class, $field, $key, $id, $dumpStr) ;
    
  # An Object must have either an id or an importID
  unless ( (defined ($id = $self->field("id")) && $id ne "" ) or 
	   ((defined ($id = $self->field("importID")) && $id ne "" )) ) {
    croak "<<- FATAL ->> Required attribute id/importID is not defined for object $self" ;
  }

  $class = ref $self ;
  no strict 'refs' ;
  foreach $field ( @OBJ_REQD_ATTRS, @{"${class}::REQD_ATTRS"} ) {
    unless (defined $self->field($field) && $self->field($field) ne "") {
      $dumpStr = $self->dump() ;
      croak "<<- FATAL ->> Required attribute/relationship '$field' is not defined for object: $dumpStr" ;
    }
  }
  use strict 'refs' ;
  
  $DEBUG and carp "==>Completed verification of object: $self" ;
  
  return(1) ;
}

=head2 _generalHTMLParam

  Function  : Generate parameter hash, for passing to HTML::Template, 
              containing data common to all Genperl objects. 
  Argument  : A Genetics::Object object and a reference to a parameter hash.
  Returns   : N/A
  Scope     : Private Instance Method
  Called by : asHTML methods of Genetics::Object subclasses.
  Comments  : 

=cut

sub _generalHTMLParam {
  my($self, $paramPtr) = @_ ;
  my($datem, $y, $m, $d, $h, $p, $s, $naListPtr, $naPtr, @nameAliases, 
     $dbxrListPtr, $dbxrPtr, @dbXRefs, $kwListPtr, $kwPtr, @keywords) ;

  $$paramPtr{NAME} = $self->name() ;
  $$paramPtr{ID} = $self->id() ;
  $$paramPtr{DATECREATED} = $self->dateCreated() ;
  if ($datem = $self->dateModified()) {
    ($y,$m,$d,$h,$p,$s) = $datem =~ /(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})/ ;
    $$paramPtr{DATEMODIFIED} = $self->dateModified("$y-$m-$d $h:$p:$s") ;
  }
  $self->url() and $$paramPtr{URL} = $self->url() ;
  $self->comment() and $$paramPtr{COMMENT} = $self->comment() ;
  if ($naListPtr = $self->NameAliases()) {
    foreach $naPtr (@$naListPtr) {
      push @nameAliases, "$$naPtr{name}($$naPtr{contactName})" ;
    }
  }
  $$paramPtr{NAMEALIASES} = join(", ", @nameAliases) ;
  $self->Contact() and $$paramPtr{CONTACT} = ${$self->Contact()}->{name} ;
  if ($dbxrListPtr = $self->DBXReferences()) {
    foreach $dbxrPtr (@$dbxrListPtr) {
      push @dbXRefs, "$$dbxrPtr{accessionNumber }:$$dbxrPtr{databaseName}" ;
    }
  }
  $$paramPtr{DBXREFS} = join(", ", @dbXRefs) ;
  if ($kwListPtr = $self->Keywords()) {
    foreach $kwPtr (@$kwListPtr) {
      push @keywords, "$$kwPtr{name}=$$kwPtr{value}" ;
    }
  }
  $$paramPtr{KEYWORDS} = join(", ", @keywords) ;

  return 1 ;
}

=head2 _attr2String

  Function  : Convert a pointer to a complex attribute value into a string 
              for printing.
  Arguments : N/A
  Returns   : N/A
  Scope     : Private Class Method
  Called by : print().  _instantiate() and field() also call this method when 
              the debug flag is set.
  Comments  : Recurses if nested pointers exist in the data structure.

=cut

sub _attr2String {
    my($value) = @_ ;
    my($str, $k, $v, @data) ;

    if (not defined $value) {
	$str = "" ;
    } elsif (not ref $value) {
	$str = $value ;
    } elsif (ref $value eq "ARRAY") {
	foreach $v (@$value) {
	    $str = _attr2String($v) ;
	    push(@data, $str)
	}
	$str = "[ " . join(", ", @data) . " ]" ;
	
    } elsif (ref $value eq "HASH") {
	@data = () ;
	while (($k,$v) = each %$value) {
	    $str = _attr2String($v) ;
	    push(@data, "$k => $str") ;
	}
	$str = "{ " . join(", ", @data) . " }" ;
    } else {
	$str = "Reference to an unsupported type" ;
    }

    return($str) ;
}

1;

