#-----------------------------------------------------------------
# MOSES::MOBY::Def::Namespace
# Author: Edward Kawas <edward.kawas@gmail.com>,
#         Martin Senger <martin.senger@gmail.com>
# For copyright and disclaimer see below.
#
# $Id: Namespace.pm,v 1.4 2008/04/29 19:41:25 kawas Exp $
#-----------------------------------------------------------------
package MOSES::MOBY::Def::Namespace;
use base qw( MOSES::MOBY::Base );
use XML::LibXML;
use strict;

# add versioning to this module
use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.4 $ =~ /: (\d+)\.(\d+)/;

=head1 NAME

MOSES::MOBY::Def::Namespace - a definition of a BioMoby Namespace

=head1 SYNOPSIS

 use MOSES::MOBY::Def::Namespace;

 # create a new BioMoby namespace definition
 my $namespace = new MOSES::MOBY::Def::Namespace
    ( name         => 'NCGR',
      authority    => 'generationcp.org',
      email        => 'yes@no',
      description  => 'This is a namespace that...',
    );

 # get an LSID of a namespace
 print $namespace->lsid;

 # get the namespace details as a string
 print $namespace->toString;
 	
 # get the namespace as a string of XML
 # (same format used to register the namespace)
 my $xml = $namespace->toXML->toString (1);

=cut

=head1 DESCRIPTION

This module contains a definition of a BioMoby Namespace.  With this
module, you can create a namespace, set its details and then use the
output from toXML to register this namespace with a mobycentral
registry.

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

=item B<lsid>

=back

=cut

{
    my %_allowed =
	(
	 name         => undef,
	 authority    => undef,
	 email        => undef,
	 description  => undef,
	 lsid         => undef,
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
#sub init {
#    my ($self) = shift;
#    $self->SUPER::init();
#}

#-----------------------------------------------------------------
# toXML
#-----------------------------------------------------------------
sub toXML {
    my $self = shift;
    my $root = $self->createXMLElement ('registerNamespace');
    
    # namespace name
    my $node = $self->createXMLElement ("namespaceType");
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
    
    return $root;
}

1;
__END__
