package HTTP::OAI::Metadata::OAI_Identifier;

use strict;
use warnings;

use Carp;
use XML::LibXML;
use HTTP::OAI::Metadata;

use vars qw( @ISA );
@ISA = qw( HTTP::OAI::Metadata );

our $VERSION = '4.12';

sub new {
	my $self = shift->SUPER::new(@_);
	my %args = @_;
	my $dom = XML::LibXML->createDocument();
	$dom->setDocumentElement(my $root = $dom->createElementNS('http://www.openarchives.org/OAI/2.0/oai-identifier','oai-identifier'));
#	$root->setAttribute('xmlns','http://www.openarchives.org/OAI/2.0/oai-identifier');
	$root->setAttribute('xmlns:xsi','http://www.w3.org/2001/XMLSchema-instance');
	$root->setAttribute('xsi:schemaLocation','http://www.openarchives.org/OAI/2.0/oai-identifier http://www.openarchives.org/OAI/2.0/oai-identifier.xsd');
	for(qw( scheme repositoryIdentifier delimiter sampleIdentifier )) {
		Carp::croak "Required argument $_ is undefined" unless defined($args{$_});
		$root->appendChild($dom->createElement($_))->appendChild($dom->createTextNode($args{$_}));
	}
	$self->dom($dom);
	$self;
}

1;
