#-----------------------------------------------------------------
# MOSES::MOBY::Data::ProvisionInformation
# Author: Edward Kawas <edward.kawas@gmail.com>,
#         Martin Senger <martin.senger@gmail.com>
# For copyright and disclaimer see below.
#
# $Id: ProvisionInformation.pm,v 1.4 2008/04/29 19:35:57 kawas Exp $
#-----------------------------------------------------------------

package MOSES::MOBY::Data::ProvisionInformation;
use base ("MOSES::MOBY::Base");
use MOSES::MOBY::Tags;
use strict;

# add versioning to this module
use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.4 $ =~ /: (\d+)\.(\d+)/;

=head1 NAME

MOSES::MOBY::Data::ProvisionInformation - a provision information block (PIB)

=head1 SYNOPSIS

 use MOSES::MOBY::Data::ProvisionInformation;
 my $provision = new MOSES::MOBY::Data::ProvisionInformation
    ( dbComment => 'a comment here',
      dbName    => 'myDBname',
      dbVersion => 'myVersion',
    );
 
 # get the version
 print $provision->dbVersion();

 # add software specific info
 $provision->softwareComment ('a comment here');
 print $provision->softwareComment();

 # add a comment about your service
 $provision->serviceComment ('a comment here');
 
 # retrieve an XML representation of the PIB
 print $provision->toXML->toString (2);

=cut

=head1 DESCRIPTION 

This module encapsulates a Moby PIB, thus allowing you to create a
syntacticly correct PIB block.  For more information regarding the PIB
block, please visit the biomoby.org website and read the Moby-S API.

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

=item B<softwareName>

=item B<softwareVersion>

=item B<softwareComment>

=item B<dbName>

=item B<dbVersion>

=item B<dbComment>

=item B<serviceComment>

=back

=cut

{
    my %_allowed =
	(
	 softwareName    => undef,
	 softwareVersion => undef,
	 softwareComment => undef,
	 dbName          => undef,
	 dbVersion       => undef,
	 dbComment       => undef,
	 serviceComment  => undef,
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
# toXML
#-----------------------------------------------------------------

=head2 toXML

Return an XML::LibXML::Element representing this data object.

=cut

sub toXML {
    my $self = shift;
    $self->increaseXMLCounter;

    my $root =
	XML::LibXML::Element->new (PROVISIONINFORMATION);
    $root->setNamespace (MOBY_XML_NS, MOBY_XML_NS_PREFIX);

    my $software = $root->addNewChild (MOBY_XML_NS, SERVICESOFTWARE);
    $software->setAttributeNS (MOBY_XML_NS, SOFTWARENAME, $self->softwareName)
	if $self->softwareName;
    $software->setAttributeNS (MOBY_XML_NS, SOFTWAREVERSION, $self->softwareVersion)
	if $self->softwareVersion;
    $software->setAttributeNS (MOBY_XML_NS, SOFTWARECOMMENT, $self->softwareComment)
	if $self->softwareComment;

    my $db = $root->addNewChild (MOBY_XML_NS, SERVICEDATABASE);
    $db->setAttributeNS (MOBY_XML_NS, DATABASENAME, $self->dbName)
	if $self->dbName;
    $db->setAttributeNS (MOBY_XML_NS, DATABASEVERSION, $self->dbVersion)
	if $self->dbVersion;
    $db->setAttributeNS (MOBY_XML_NS, DATABASECOMMENT, $self->dbComment)
	if $self->dbComment;
    
    $root->appendTextChild (SERVICECOMMENT, $self->serviceComment)
	if $self->serviceComment;

    # return it  (TBD: cleaning namespaces happens several times...)
    return $self->closeXML ($root);
}

1;

__END__
