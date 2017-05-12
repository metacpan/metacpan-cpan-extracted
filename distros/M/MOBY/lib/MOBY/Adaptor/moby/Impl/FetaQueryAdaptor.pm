#!perl -wWall
use strict;
use vars qw(@ISA);
use XML::LibXML;
@ISA = qw{MOBY::Adaptor::moby::DataAdapterI}; # implements the interface

use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.3 $ =~ /: (\d+)\.(\d+)/;

=head1 NAME

MOBY::Adaptor::moby::impl::FetaQueryAdaptor.pm - FetaQueryAdaptor

=head1 DESCRIPTION

Todo

=head2 _queryServiceInstanceHash

 Title     :	_queryServiceInstanceHash
 Usage     :	my $un = $API->_queryServiceInstanceHash($xml)
 Function  :	Parses the FETA response XML and creates a hashref of a services properties
 Args      :  	FETA response XML =>		   => String
 Returns   :    hashref:
 				{service_instance_id 		   => Integer, 
				category					   => String, 
				servicename					   => String, 
				service_type_uri			   => String, 
				authority.authority_uri		   => String, 
				url							   => String, 
				service_instance.contact_email => String, 
				authoritative				   => Integer, 
				description					   => String, 
				signatureURL				   => String,
				lsid 						   => String}

=cut

sub queryServiceInstanceHash {
	my ($inputString) = @_;
	my %qsiHash;
	my $parser  = XML::LibXML->new();
	my $fetaDom = $parser->parse_string($inputString);
	my ( $value, $key );

	# add the key/value pair for service_instance_id
	$key = 'service_instance_id';
	$value = getValueByTagnameNS( $fetaDom, 'serviceName' );
	if ( defined $value ) {
		$qsiHash{$key} = $value;
	}

	# add the key/value pair for category
	$key = 'category';
	$value = getValueByTagnameNS( $fetaDom, 'Category' );
	if ( defined $value ) {
		$qsiHash{$key} = $value;
	}

	# add the key/value pair for servicename
	$key = 'servicename';
	$value = getValueByTagnameNS( $fetaDom, 'serviceName' );
	if ( defined $value ) {
		$qsiHash{$key} = $value;
	}

	# add the key/value pair for service_type_uri
	$key = 'service_type_uri';
	$value = getValueByTagnameNS( $fetaDom, 'operationTask' );
	if ( defined $value ) {
		$qsiHash{$key} = $value;
	}

	# add the key/value pair for authority.authority_uri
	$key = 'authority.authority_uri';
	$value = getValueByTagnameNS( $fetaDom, 'serviceName' );
	my @auth = split( /\,/, $value );
	if ( defined $auth[0] ) {
		$qsiHash{$key} = $auth[0];
	}

	# add the key/value pair for url
	$key = 'url';
	$value = getValueByTagnameNS( $fetaDom, 'locationURL' );
	if ( defined $value ) {
		$qsiHash{$key} = $value;
	}

	# add the key/value pair for service_instance.contact_email
	$key = 'service_instance.contact_email';
	$value = getValueByTagnameNS( $fetaDom, 'email' );
	if ( defined $value ) {
		$qsiHash{$key} = $value;
	}

	# add the key/value pair for authoritative
	$key = 'authoritative';
	$value = getValueByTagnameNS( $fetaDom, 'authoritative' );
	if ( defined $value ) {
		$qsiHash{$key} = $value;
	}

	# add the key/value pair for serviceDescriptionText
	$key = 'description';
	$value = getValueByTagnameNS( $fetaDom, 'serviceDescriptionText' );
	if ( defined $value ) {
		$qsiHash{$key} = $value;
	}

	# add the key/value pair for signatureURL
	$key = 'signatureURL';
	$value = getValueByTagnameNS( $fetaDom, 'signautureURL' );
	if ( defined $value ) {
		$qsiHash{$key} = $value;
	}

	# add the key/value pair for lsid
	$key = 'lsid';
	$value = getValueByTagnameNS( $fetaDom, 'lsid' );
	if ( defined $value ) {
		$qsiHash{$key} = $value;
	}

	#done
	return \%qsiHash;
}

=head2 _querySimpleInputHash

 Title     :	_querySimpleInputHash
 Usage     :	my $un = $API->_querySimpleInputHash($xml)
 Function  :	
 Args      :    FETA response xml => String,
 Returns   :    listref of hashrefs:
 				[{object_type_uri		 => String,
     		 	namespace_type_uris	 => String,
      			article_name		 => String,
      			service_instance_id	 => Integer}, ...]
=cut

sub querySimpleInputHash {
	my ($inputString) = @_;
	my %qsiHash;
	my $parser  = XML::LibXML->new();
	my $fetaDom = $parser->parse_string($inputString);
	my $nodes = $fetaDom->getElementsByTagName('operationInputs/parameter');

#					<parameter >
#						<parameterName>articleName1</parameterName>
#						<isConfigurationParameter>false</isConfigurationParameter>
#						<semanticType>http://biomoby.org/RESOURCES/MOBY-S/Objects#DNASequence</semanticType>
#						<transportDataType>String</transportDataType>
#						<collectionSemanticType>Simple</collectionSemanticType>
#					</parameter>

}

=head2 _querySimpleOutputHash

 Title     :	_querySimpleOutputHash
 Usage     :	my $un = $API->_querySimpleOutputHash($xml)
 Function  :	Parses the FETA response xml and creates a hashref describing the output simples
 Args      :    FETA response xml => String,
 Returns   :    listref of hashrefs:
 				[{object_type_uri		 => String,
     		 	namespace_type_uris	 => String,
      			article_name		 => String,
      			service_instance_id	 => Integer}, ...]
 Notes     : 	Only allows querying by lsid or type term, so service_instance_id is retrieved from lsid or term

=cut

sub _querySimpleOutputHash {

}

=head2 _queryCollectionInputHash

 Title     :	_queryCollectionInputHash
 Usage     :	my $un = $API->_queryCollectionInputHash($xml)
 Function  :	get the collection input information for a given service from the FETA response XML
 Args      :    FETA response xml => String,
 Returns   :    listref of hashrefs:
                [{collection_input_id => Integer
                article_name        => String}, ...]
		one hashref for each collection that service consumes

=cut

sub _queryCollectionInputHash {
}

=head2 _queryCollectionOutputHash

 Title     :	_queryCollectionOutputHash
 Usage     :	my $un = $API->_queryCollectionOutputHash($xml)
 Function  :	get the collection output information for a given service from the FETA response XML
 Args      :    FETA response xml => String,
 Returns   :    listref of hashrefs:
                [{collection_output_id => Integer
                article_name        => String}, ...]
		one hashref for each collection that service consumes

=cut

sub _queryCollectionOutputHash {
}

sub getValueByTagnameNS {
	my ( $dom, $tagname, $ns ) = @_;
	unless ($ns) {
		$ns = '';
	}
	my $node = $dom->getElementsByTagNameNS( $ns, $tagname );
	if ( $node->size == 1 ) {
		my $string = $node->get_node(1)->textContent();
		return $string;
	}
	return undef;
}
my $string = <<END_QUOTE;
<?xml version = "1.0" encoding = "UTF-8"?>
<serviceDescriptions>
	<serviceDescription >
		<serviceName>test.suite.com,myfirstservice</serviceName>
		<locationURL>http://illuminae/cgi-bin/service.pl</locationURL>
		<serviceDescriptionText>This service is my first service and does nothing</serviceDescriptionText>
		<operations >
			<serviceOperation >
				<operationName>test.suite.com,myfirstservice</operationName>
				<operationDescriptionText>This service is my first service and does nothing</operationDescriptionText>
				<operationInputs >
					<parameter >
						<parameterName>myInputDNASequence</parameterName>
						<isConfigurationParameter>false</isConfigurationParameter>
						<semanticType>http://biomoby.org/RESOURCES/MOBY-S/Objects#DNASequence</semanticType>
						<transportDataType>String</transportDataType>
						<collectionSemanticType>Simple</collectionSemanticType>
					</parameter>
					<parameter >
						<parameterName>myInputGFF2</parameterName>
						<isConfigurationParameter>false</isConfigurationParameter>
						<semanticType>http://biomoby.org/RESOURCES/MOBY-S/Objects#GFF2</semanticType>
						<transportDataType>String</transportDataType>
						<collectionSemanticType>Simple</collectionSemanticType>
					</parameter>
					<parameter >
						<parameterName>myInputCollection</parameterName>
						<isConfigurationParameter>false</isConfigurationParameter>
						<semanticType>http://biomoby.org/RESOURCES/MOBY-S/Objects#BasicGFFSequenceFeature</semanticType>
						<transportDataType>String</transportDataType>
						<collectionSemanticType>Collection</collectionSemanticType>
					</parameter>
					<parameter >
						<parameterName>myInputCollection</parameterName>
						<isConfigurationParameter>false</isConfigurationParameter>
						<semanticType>http://biomoby.org/RESOURCES/MOBY-S/Objects#Integer</semanticType>
						<transportDataType>String</transportDataType>
						<collectionSemanticType>Collection</collectionSemanticType>
					</parameter>
					<parameter >
						<parameterName>myInputCollectionOfObject</parameterName>
						<isConfigurationParameter>false</isConfigurationParameter>
						<semanticType>http://biomoby.org/RESOURCES/MOBY-S/Objects#Object</semanticType>
						<transportDataType>String</transportDataType>
						<collectionSemanticType>Collection</collectionSemanticType>
					</parameter>
					<parameter >
						<parameterName>myBag</parameterName>
						<isConfigurationParameter>false</isConfigurationParameter>
						<semanticType>http://biomoby.org/RESOURCES/MOBY-S/Objects#BasicGFFSequenceFeature</semanticType>
						<transportDataType>String</transportDataType>
						<collectionSemanticType>Collection</collectionSemanticType>
					</parameter>
					<parameter >
						<parameterName>myInputCollection</parameterName>
						<isConfigurationParameter>false</isConfigurationParameter>
						<semanticType>http://biomoby.org/RESOURCES/MOBY-S/Objects#Float</semanticType>
						<transportDataType>String</transportDataType>
						<collectionSemanticType>Collection</collectionSemanticType>
					</parameter>
				</operationInputs>
				<operationOutputs >
					<parameter >
						<parameterName>myOutputCollection</parameterName>
						<isConfigurationParameter>false</isConfigurationParameter>
						<semanticType>http://biomoby.org/RESOURCES/MOBY-S/Objects#GFF</semanticType>
						<transportDataType>String</transportDataType>
						<collectionSemanticType>Collection</collectionSemanticType>
					</parameter>
					<parameter >
						<parameterName>myOutputCollection</parameterName>
						<isConfigurationParameter>false</isConfigurationParameter>
						<semanticType>http://biomoby.org/RESOURCES/MOBY-S/Objects#GFF2</semanticType>
						<transportDataType>String</transportDataType>
						<collectionSemanticType>Collection</collectionSemanticType>
					</parameter>
					<parameter >
						<parameterName>myOutputObject</parameterName>
						<isConfigurationParameter>false</isConfigurationParameter>
						<semanticType>http://biomoby.org/RESOURCES/MOBY-S/Objects#Object</semanticType>
						<transportDataType>String</transportDataType>
						<collectionSemanticType>Simple</collectionSemanticType>
					</parameter>
				</operationOutputs>
				<operationTask>Retrieval</operationTask>
			</serviceOperation>
		</operations>
		<serviceType>BioMOBY service</serviceType>
	</serviceDescription>
</serviceDescriptions>
END_QUOTE

my $hash_ref = queryServiceInstanceHash($string);
while ( my ( $key, $value ) = each(%$hash_ref) ) {
	print "$key => $value\n";
}
