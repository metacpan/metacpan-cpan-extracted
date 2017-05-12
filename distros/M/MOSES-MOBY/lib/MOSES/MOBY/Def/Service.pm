#-----------------------------------------------------------------
# MOSES::MOBY::Def::Service
# Author: Edward Kawas <edward.kawas@gmail.com>,
#         Martin Senger <martin.senger@gmail.com>
# For copyright and disclaimer see below.
#
# $Id: Service.pm,v 1.5 2009/08/27 19:39:26 kawas Exp $
#-----------------------------------------------------------------
package MOSES::MOBY::Def::Service;
use base qw( MOSES::MOBY::Base );
use XML::LibXML;
use strict;

# add versioning to this module
use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.5 $ =~ /: (\d+)\.(\d+)/;

=head1 NAME

MOSES::MOBY::Def::Service - a BioMoby service definition

=head1 SYNOPSIS

 use MOSES::MOBY::Def::MobyService;

 # create a new BioMoby service definition
 my $service = new MOSES::MOBY::Def::Service
    ( name        => 'myService',
      authority   => 'www.tulsoft.org',
      email       => 'george.bush@shame.gov',
      description => 'Hello world service!',
      url         => 'http://my.service.com/endpoint',
      signatureURL=> 'http://my.service.com/path/to/rdf,'
      category 	  => 'moby',
      type        => 'retrival',
      inputs      => ( {memberName => 'annotation', datatype => 'Feature'} ),
      outputs     => ( {memberName => 'annotation', datatype => 'Feature'} ),
      secondarys  => ( {memberName => 'annotation', datatype => 'Feature'} ),
    );

 # get the LSID of this service
 print $service->lsid;

 # get the service details as a string
 print $service->toString;
 	
 # get the service as a string of XML
 # (same format used to register the service)
 my $xml = $service->toXML->toString (1);

=cut

=head1 DESCRIPTION

This module contains a definition of a BioMoby Service. With this
module, you can create a service definition, set its details and then
use the output from toXML to register this service with a mobycentral
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

A name of this service.

=item B<authority>

=item B<email>

=item B<description>

=item B<type>

=item B<url>

=item B<signatureURL>

=item B<category>

The category of service. Must be one of moby, cgi, or wsdl.

=item B<inputs>

A list of inputs for this service. Must be of type
C<MOSES::MOBY::Def::PrimaryData>.

=item B<outputs>

A list of outputs for this service. Must be of type
C<MOSES::MOBY::Def::PrimaryData>.

=item B<secondarys>

A list of secondary parameters for this service. Must be of type
C<MOSES::MOBY::Def::SecondaryData>.

=item B<lsid>

=back

=cut

{
    my %_allowed =
	(
	 name          => { type => MOSES::MOBY::Base->STRING,
			    post => \&_create__module_name },
	 authority     => { type => MOSES::MOBY::Base->STRING,
			    post => \&_create__module_name },
	 email         => undef,
	 description   => undef,
	 signatureURL  => undef,
	 url           => undef,
 	 rdf           => undef,
 	 category      => { type => MOSES::MOBY::Base->STRING,
			   post => \&_check_category },
 	 authoritative => {type => MOSES::MOBY::Base->BOOLEAN },
 	 type          => undef,
	 inputs        => {type => 'MOSES::MOBY::Def::PrimaryData', is_array => 1},
	 outputs       => {type => 'MOSES::MOBY::Def::PrimaryData', is_array => 1},
	 secondarys    => {type => 'MOSES::MOBY::Def::SecondaryData', is_array => 1},
	 lsid          => undef,

	 # used internally  (but cannot start with underscore - Template would ignore them)
	 module_name   => undef,
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

sub _create__module_name {
    my ($self) = shift;
    $self->{module_name} =
	$self->service2module ($self->{authority}, $self->{name});
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
    $self->inputs ([]);
    $self->outputs ([]);
    $self->secondarys ([]);
    $self->category ('moby');
    $self->authoritative('true');
}

#-----------------------------------------------------------------
# toXML
#-----------------------------------------------------------------
sub toXML {
    my $self = shift;
    my $root = $self->createXMLElement ('registerService');
    
    # category
    my $node = $self->createXMLElement ("Category");
    $node->appendTextNode ($self->category) if $self->category;
    $root->addChild ($node);

    # service name
    $node = $self->createXMLElement ("serviceName");
    $node->appendTextNode ($self->name) if $self->name;
    $root->addChild ($node);
    
    # service type
    $node = $self->createXMLElement ("serviceType");
    $node->appendTextNode ($self->type) if $self->type;
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
    
    # signature url
    $node = $self->createXMLElement ("signatureURL");
    $node->appendTextNode ($self->signatureURL) if $self->signatureURL;
    $root->addChild ($node);
    
    # URL
    $node = $self->createXMLElement ("URL");
    $node->appendTextNode ($self->url) if $self->url;
    $root->addChild ($node);
    
    # authoritative
    $node = $self->createXMLElement ("authoritativeService");
    $node->appendTextNode ($self->authoritative ? '1' : '0');
    $root->addChild ($node);
    
    # add inputs
    $node = $self->createXMLElement ("Input");
    foreach my $input (@{ $self->inputs }) {
	$node->addChild ($input->toXML);
    }
    $root->addChild ($node);
    
    # add secondaries
    $node = $self->createXMLElement ("secondaryArticles");
    foreach my $sec (@{ $self->secondarys }) {
	$node->addChild ($sec->toXML);
    }
    $root->addChild ($node);
    
    # add outputs
    $node =$self->createXMLElement ("Output");
    foreach my $output (@{ $self->outputs }) {
	$node->addChild ($output->toXML);
    }
    $root->addChild ($node);
    
    return $root;
}

#-----------------------------------------------------------------
# Checking service type.
#-----------------------------------------------------------------
sub _check_category {
    my ($self, $attr) = @_;
    $self->throw ('Invalid service category: ' . $self->category)
	unless $self->category =~ /^cgi|wsdl|moby|moby\-async|post|cgi\-async$/i;
}

1;
__END__
