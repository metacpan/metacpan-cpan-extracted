package MOBY::RDF::Predicates::FETA;

use strict;
use warnings;

BEGIN {
	use vars qw /$VERSION/;
	$VERSION = sprintf "%d.%02d", q$Revision: 1.3 $ =~ /: (\d+)\.(\d+)/;

	use constant FETA_PREFIX => 'myGrid';

	use constant FETA_URI => 'http://www.mygrid.org.uk/mygrid-moby-service#';

################################
## Predicates for FETA        ##
################################

	use constant isAlive            => FETA_URI . 'isAlive';
	use constant hasOperation       => FETA_URI . 'hasOperation';
	use constant parameterNamespace => FETA_URI . 'parameterNamespace';
	use constant operationType      => FETA_URI . 'operationType';
	use constant serviceDescription => FETA_URI . 'serviceDescription';
	use constant operationTask      => FETA_URI . 'operationTask';
	use constant name               => FETA_URI . 'name';
	use constant inNamespaces       => FETA_URI . 'inNamespaces';
	use constant objectType         => FETA_URI . 'objectType';
	use constant authoritative      => FETA_URI . 'authoritative';
	use constant description        => FETA_URI . 'description';
	use constant locationURI        => FETA_URI . 'locationURI';
	use constant hasCollectionType  => FETA_URI . 'hasCollectionType';
	use constant hasDefaultValue    => FETA_URI . 'hasDefaultValue';
	use constant hasFormat          => FETA_URI . 'hasFormat';
	use constant hasOrganisationDescriptionText => FETA_URI . 'hasOrganisationDescriptionText';
	use constant hasOrganisationNameText => FETA_URI . 'hasOrganisationNameText';
	use constant hasParameterDescriptionText => FETA_URI . 'hasParameterDescriptionText';
	use constant hasParameterNameText      => FETA_URI . 'hasParameterNameText';
	use constant hasParameterType          => FETA_URI . 'hasParameterType';
	use constant hasSchemaType             => FETA_URI . 'hasSchemaType';
	use constant min                       => FETA_URI . 'min';
	use constant max                       => FETA_URI . 'max';
	use constant enum                      => FETA_URI . 'enum';
	use constant hasServiceDescriptionText => FETA_URI . 'hasServiceDescriptionText';
	use constant hasServiceNameText        => FETA_URI . 'hasServiceNameText';
	use constant hasServiceDescriptionLocation => FETA_URI . 'hasServiceDescriptionLocation';
	use constant hasServiceType              => FETA_URI . 'hasServiceType';
	use constant hasOperationDescriptionText => FETA_URI . 'hasOperationDescriptionText';
	use constant hasOperationNameText     => FETA_URI . 'hasOperationNameText';
	use constant hasTransportType         => FETA_URI . 'hasTransportType';
	use constant inputParameter           => FETA_URI . 'inputParameter';
	use constant outputParameter          => FETA_URI . 'outputParameter';
	use constant datatype                 => FETA_URI . 'datatype';
	use constant isConfiguration          => FETA_URI . 'isConfiguration';
	use constant providedBy               => FETA_URI . 'providedBy';
	use constant mygInstance              => FETA_URI . 'mygInstance';
	use constant performsTask             => FETA_URI . 'performsTask';
	use constant usesMethod               => FETA_URI . 'usesMethod';
	use constant operationMethod          => FETA_URI . 'operationMethod';
	use constant isFunctionOf             => FETA_URI . 'isFunctionOf';
	use constant operationApplication     => FETA_URI . 'operationApplication';
	use constant usesResource             => FETA_URI . 'usesResource';
	use constant operationResource        => FETA_URI . 'operationResource';
	use constant hasResourceContent       => FETA_URI . 'hasResourceContent';
	use constant operationResourceContent => FETA_URI . 'operationResourceContent';
	use constant collection          => FETA_URI . 'collection';
	use constant service             => FETA_URI . 'service';
	use constant operation           => FETA_URI . 'operation';
	use constant organisation        => FETA_URI . 'organisation';
	use constant parameter           => FETA_URI . 'parameter';
	use constant simpleParameter     => FETA_URI . 'simpleParameter';
	use constant collectionParameter => FETA_URI . 'collectionParameter';
	use constant secondaryParameter  => FETA_URI . 'secondaryParameter';
	# unit test predicates
	use constant hasUnitTest         => FETA_URI . "hasUnitTest";
	use constant unitTest            => FETA_URI . "unitTest";
	use constant exampleInput        => FETA_URI . "exampleInput";
	use constant validOutputXML      => FETA_URI . "validOutputXML";
	use constant validREGEX          => FETA_URI . "validREGEX";
	use constant validXPath          => FETA_URI . "validXPath";

}
1;
