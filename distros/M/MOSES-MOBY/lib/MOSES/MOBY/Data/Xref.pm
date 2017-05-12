#-----------------------------------------------------------------
# MOSES::MOBY::Data::Xref
# Author: Edward Kawas <edward.kawas@gmail.com>,
#         Martin Senger <martin.senger@gmail.com>
# For copyright and disclaimer see below.
#
# $Id: Xref.pm,v 1.4 2008/04/29 19:35:57 kawas Exp $
#-----------------------------------------------------------------

package MOSES::MOBY::Data::Xref;
use base qw( MOSES::MOBY::Data::Object );
use MOSES::MOBY::Tags;
use strict;

# add versioning to this module
use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.4 $ =~ /: (\d+)\.(\d+)/;

=head1 NAME

MOSES::MOBY::Data::Xref - a Moby cross-reference

=head1 SYNOPSIS

 use MOSES::MOBY::Data::Xref;

 # create a simple cross-reference
 my $simple_xref = new MOSES::MOBY::Data::Xref
    ( id        => 'At263644',
      namespace => 'TIGR'
    );

 # create an advanced cross-reference
 my $advanced_xref = new MOSES::MOBY::Data::Xref
    ( id           => 'X112345',
      namespace    => 'EMBL',
      service      => 'getEMBLRecord',
      authority    => 'www.illuminae.com',
      evidenceCode => 'IEA',
      xrefType     => 'transform'
    );

=cut

=head1 DESCRIPTION 

An object representing a cross reference. A cross reference is an
optional component of any Moby object. It can be of a simple or of an
advanced version.

A simple cross reference is a base Moby object (named 'Object') that
can have only attributes 'namespace' and 'id' (no value, no article
name, no children). In XML, it look like this:

   <Object namespace="TAIR" id="TG1989"/>

An advanced cross reference additionally includes a reference to a
Biomoby service that a creator of this cross reference (which is a
Biomoby service provider) suggests to execute in order to get more
about the cross-referenced data. Again, in XML it may look like this:

   <moby:Xref moby:namespace="EMBL" moby:id="X112345" 
       authURI="www.illuminae.com" serviceName="getEMBLRecord" 
       evidenceCode="IEA" xrefType="transform"/>

=head1 AUTHORS

 Edward Kawas (edward.kawas [at] gmail [dot] com)
 Martin Senger (martin.senger [at] gmail [dot] com)

=cut

#-----------------------------------------------------------------
# A list of allowed attribute names. See MOSES::MOBY::Base for details.
#-----------------------------------------------------------------

=head1 ACCESSIBLE ATTRIBUTES

Details are in L<MOSES::MOBY::Base>. Here just a list of them. All of them
are of type string.

=over

=item B<authority>

=item B<service>

=item B<evidenceCode>

=item B<xrefType>

=item B<description>

=back

=cut

{
    my %_allowed =
	(
	 authority    => undef,
	 service      => undef,
	 evidenceCode => undef,
	 xrefType     => undef,
	 description  => undef,
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
# toXML
#-----------------------------------------------------------------
sub toXML {
    my $self = shift;
    $self->increaseXMLCounter;

    # for simple xrefs, this is enough
    my $root = $self->SUPER::toXML;
    $root->setNodeName (MOBY_XML_NS_PREFIX  . ":" . MOBYOBJECT);

    # now for advanced xrefs
    if ($self->service and $self->authority) {

	$root->setNodeName (MOBY_XML_NS_PREFIX  . ":" . XREF);
	$root->setAttributeNS (MOBY_XML_NS, AUTHURI, $self->authority);
	$root->setAttributeNS (MOBY_XML_NS, SERVICENAME, $self->service);
	$root->setAttributeNS (MOBY_XML_NS, EVIDENCECODE, $self->evidenceCode)
	    if $self->evidenceCode;
	$root->setAttributeNS (MOBY_XML_NS, XREFTYPE, $self->xrefType)
	    if $self->xrefType;
	$root->appendText ($self->description)
	    if $self->description;
    }

    # return it  (TBD: cleaning namespaces happens several times...)
    return $self->closeXML ($root);
}

1;
__END__
