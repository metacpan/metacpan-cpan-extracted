#-----------------------------------------------------------------
# MOSES::MOBY::Def::ServiceType
# Author: Edward Kawas <edward.kawas@gmail.com>,
#         Martin Senger <martin.senger@gmail.com>
# For copyright and disclaimer see below.
#
# $Id: ServiceType.pm,v 1.4 2008/04/29 19:41:46 kawas Exp $
#-----------------------------------------------------------------
package MOSES::MOBY::Def::ServiceType;
use base qw( MOSES::MOBY::Base );
use XML::LibXML;
use strict;

# add versioning to this module
use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.4 $ =~ /: (\d+)\.(\d+)/;

=head1 NAME

MOSES::MOBY::Def::ServiceType - a BioMoby service type definition

=head1 SYNOPSIS

 use MOSES::MOBY::Def::ServiceType;
 # create a BioMoby service type
 my $s_type = new MOSES::MOBY::Def::ServiceType
    ( name => 'Homology',
    );

 # get an LSID of a service type
 print $s_type->lsid;

 # get the service type details as a string
 print $s_type->toString;
 	
 # get the service type as a string of XML
 #(same format used to register the service type)
 print $s_type->toXML->toString (1);

=cut

=head1 DESCRIPTION

This module contains a definition of a BioMoby Service Type.  With
this module, you can create a service type, set its details and then
use the output from toXML to register this service type with a
mobycentral registry.

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

=item B<authority>

=item B<email>

=item B<description>

=item B<parent>

=item B<lsid>

=back

=cut

{
    my %_allowed =
	(
	 name        => undef,
	 authority   => undef,
	 email       => undef,
	 description => undef,
	 parent      => undef,
	 lsid        => undef,
	 );

    sub _accessible {
	my ( $self, $attr ) = @_;
	exists $_allowed{$attr} or $self->SUPER::_accessible($attr);
    }

    sub _attr_prop {
	my ( $self, $attr_name, $prop_name ) = @_;
	my $attr = $_allowed{$attr_name};
	return ref($attr) ? $attr->{$prop_name} : $attr if $attr;
	return $self->SUPER::_attr_prop( $attr_name, $prop_name );
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
    $self->parent ('Service');
}

#-----------------------------------------------------------------
# toXML
#-----------------------------------------------------------------
sub toXML {
    my $self = shift;
    my $root = $self->createXMLElement ('registerServiceType');
    
    # service type name
    my $node = $self->createXMLElement ("serviceType");
    $node->appendTextNode ($self->name) if $self->name;
    $root->addChild ($node);
    
    # email
    $node = $self->createXMLElement ("contactEmail");
    $node->appendTextNode ($self->email) if $self->email;
    $root->addChild ($node);
    
    # authURI
    $node = $self->createXMLElement ("authURI");
    $node->appendTextNode ($self->authority) if $self->authority;
    $root->addChild ($node);
    
    # description
    $node = $self->createXMLElement ("Description");
    $node->addChild (XML::LibXML::CDATASection->new ($self->description)) if $self->description;
    $root->addChild ($node);
    
    # relationship
    $node = $self->createXMLElement ("Relationship");
    $node->setAttribute ("relationshipType", "ISA");
    my $type = $self->createXMLElement ("serviceType");
    $type->appendTextNode ($self->parent) if $self->parent;
    $node->addChild ($type);
    $root->addChild ($node);

    return $root;
}

1;
__END__
