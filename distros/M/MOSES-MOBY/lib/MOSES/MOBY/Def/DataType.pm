#-----------------------------------------------------------------
# MOSES::MOBY::Def::DataType
# Author: Edward Kawas <edward.kawas@gmail.com>,
#         Martin Senger <martin.senger@gmail.com>
# For copyright and disclaimer see below.
#
# $Id: DataType.pm,v 1.4 2008/04/29 19:41:17 kawas Exp $
#-----------------------------------------------------------------

package MOSES::MOBY::Def::DataType;
use base qw( MOSES::MOBY::Base );
use MOSES::MOBY::Def::Relationship;
use XML::LibXML;
use strict;

# add versioning to this module
use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.4 $ =~ /: (\d+)\.(\d+)/;

=head1 NAME

MOSES::MOBY::Def::DataType - a definition of BioMoby data type

=head1 SYNOPSIS

 use MOSES::MOBY::Def::DataType;

 # create a new data type
 my $datatype = new MOSES::MOBY::Def::DataType
    ( name        => 'MySequence',
      authority   => 'www.tulsoft.org',
      email       => 'george.bush@shame.gov',
      description => 'Good moooorning, sequence!',
      parent      => 'DNASequence',
      children    => ( {memberName => 'annotation', datatype => 'Feature'} ),
    );

 # get the name of this data type
 print $datatype->name;

 # set new authority
 $datatype->authority ('www.biomoby.org');
 	
 # get this data type in XML
 my $xml = $datatype->toXML;
 print $xml->toString (2);

=cut

=head1 DESCRIPTION

A container representing a data type used in the Moby registry (in the
BioMoby speak it is called I<Object Class>). The Moby data types are
used to specify what types of inputs and outputs are needed or
produced by Moby services.

This object does not carry real data but rather a definition
(metadata) of one of the most important BioMoby entities - a data
type.

=head1 AUTHORS

 Edward Kawas (edward.kawas [at] gmail [dot] com)
 Martin Senger (martin.senger [at] gmail [dot] com)


=cut

#-----------------------------------------------------------------
# A list of allowed attribute names. See MOSES::MOBY::Base for details.
#-----------------------------------------------------------------

=head1 ACCESSIBLE ATTRIBUTES

Details are in L<MOSES::MOBY::Base>. Here just a list of them:

=over

=item B<name>

A name of this data type. For example: C<DNASequence>.

=item B<authority>

=item B<email>

=item B<description>

=item B<parent>

A name of a parent data type.

=item B<children>

A list of relationships to the children data types. Must be of type
C<MOSES::MOBY::Def::Relationship>.

=item B<lsid>

=back

=cut

{
    my %_allowed =
	(
	 name         => { type => MOSES::MOBY::Base->STRING,
			   post => sub {
			       my ($self) = shift;
			       $self->{module_name} =
				   $self->datatype2module ($self->{name}) } },
	 parent       => { type => MOSES::MOBY::Base->STRING,
			   post => sub {
			       my ($self) = shift;
			       $self->{module_parent} =
				   $self->datatype2module ($self->{parent}) } },
	 authority    => undef,
	 email        => undef,
	 description  => undef,
         children     => {type => 'MOSES::MOBY::Def::Relationship', is_array => 1},
	 lsid         => undef,

	 # used internally  (but cannot start with underscore - Template would ignore them)
	 module_name    => undef,
	 module_parent  => undef,
	 );

    sub _accessible {
	my ($self, $attr) = @_;
	exists $_allowed{$attr} or $self->SUPER::_accessible ($attr);
    }
    sub _attr_prop {
	my ($self, $attr_name, $prop_name) = @_;
	my $attr = $_allowed {$attr_name};
	return ref ($attr) ? $attr->{$prop_name} : $attr if $attr;
	return $self->SUPER::_attr_prop ($attr_name, $prop_name);
    }
}

#-----------------------------------------------------------------

=head1 SUBROUTINES

=cut

#-----------------------------------------------------------------
# init
#-----------------------------------------------------------------
sub init {
    my ($self) = shift;
    $self->SUPER::init();
    $self->children ([]);
#    $self->parent ('Object');
    $self->parent ('');
}

#-----------------------------------------------------------------
# toXML
#-----------------------------------------------------------------
sub toXML {
    my $self = shift;
    my $root = $self->createXMLElement('registerObjectClass');
    
    # objectType
    my $node = $self->createXMLElement('objectType');
    $node->appendTextNode ($self->name) if $self->name;
    $root->addChild ($node);
    
    # description
    $node = $self->createXMLElement('Description');
    $node->addChild (XML::LibXML::CDATASection->new ($self->description)) if $self->description;
    $root->addChild ($node);
    
    # authURI
    $node = $self->createXMLElement('authURI');
    $node->appendTextNode ($self->authority) if $self->authority;
    $root->addChild ($node);
    
    # email
    $node = $self->createXMLElement('contactEmail');
    $node->appendTextNode ($self->email) if $self->email;
    $root->addChild ($node);
    
    # parent - isa relationship type
    $node = $self->createXMLElement('Relationship');
    $self->setXMLAttribute ($node, 'relationshipType', ISA);
    my $type = $self->createXMLElement('objectType');
    $type->appendTextNode ( $self->parent || 'Object' );
    $node->addChild ($type);
    $root->addChild ($node);

    # children - has|hasa relationship types
    my $hasNode = $self->createXMLElement('Relationship');
    $self->setXMLAttribute ($hasNode, 'relationshipType', HAS);
    
    my $hasaNode = $self->createXMLElement('Relationship');
    $self->setXMLAttribute ($hasaNode, 'relationshipType', HASA);
    
    my $hasa_count = 0;
    my $has_count = 0;
    foreach my $relation (@{ $self->children }) {
	if ($relation->relationship eq HASA) {
	    $hasa_count++;
	    my $type = $self->createXMLElement('objectType');
	    $self->setXMLAttribute ($type, 'articleName', $relation->original_memberName);
	    $type->appendTextNode ( $relation->datatype || 'Object' );
	    $hasaNode->addChild ($type);
	} elsif ($relation->relationship eq HAS) {
	    $has_count++;
	    my $type = $self->createXMLElement('objectType');
	    $self->setXMLAttribute ($type, 'articleName', $relation->original_memberName);
	    $type->appendTextNode ($relation->datatype || 'Object' );
	    $hasNode->addChild ($type);
	}
    }
    $root->addChild ($hasaNode) if $hasa_count > 0;
    $root->addChild ($hasNode) if $has_count > 0;
    
    return $root;
}

1;
__END__
