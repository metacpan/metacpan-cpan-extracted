package HTTP::OAI::Metadata::OAI_Eprints;

use strict;
use warnings;

use Carp;
use XML::LibXML;
use HTTP::OAI::Metadata;

use vars qw( @ISA );
@ISA = qw( HTTP::OAI::Metadata );

our $VERSION = '4.04';

sub new {
	my $self = shift->SUPER::new(@_);
	my %args = @_;
	my $dom = XML::LibXML->createDocument();
	$dom->setDocumentElement(my $root = $dom->createElementNS('http://www.openarchives.org/OAI/1.1/eprints','eprints'));
#	$root->setAttribute('xmlns','http://www.openarchives.org/OAI/2.0/oai-identifier');
	$root->setAttribute('xmlns:xsi','http://www.w3.org/2001/XMLSchema-instance');
	$root->setAttribute('xsi:schemaLocation','http://www.openarchives.org/OAI/1.1/eprints http://www.openarchives.org/OAI/1.1/eprints.xsd');
	for(qw( content metadataPolicy dataPolicy submissionPolicy )) {
		Carp::croak "Required argument $_ undefined" if !defined($args{$_}) && $_ =~ /metadataPolicy|dataPolicy/;
		next unless defined($args{$_});
		my $node = $root->appendChild($dom->createElement($_));
		$args{$_}->{'URL'} ||= [];
		$args{$_}->{'text'} ||= [];
		foreach my $value (@{$args{$_}->{'URL'}}) {
			$node->appendChild($dom->createElement('URL'))->appendChild($dom->createTextNode($value));
		}
		foreach my $value (@{$args{$_}->{'text'}}) {
			$node->appendChild($dom->createElement('text'))->appendChild($dom->createTextNode($value));
		}
	}
	$args{'comment'} ||= [];
	for(@{$args{'comment'}}) {
		$root->appendChild($dom->createElement('comment'))->appendChild($dom->createTextNode($_));
	}
	$self->dom($dom);
	$self;
}

1;
