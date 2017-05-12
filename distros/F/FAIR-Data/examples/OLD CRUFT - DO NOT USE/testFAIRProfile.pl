#!perl -w
use lib "../lib/";
use FAIR::Profile;
use FAIR::Profile::Class;
use FAIR::Profile::Property;
use FAIR::NAMESPACES;

my $MicroarrayDatasetSchema = FAIR::Profile->new(
                label => 'Microarray Deposition for Fairport Demo',
		title => "A very very simple data deposition descriptor", 
		description => "This FAIR Profile defines a schema that will have a DCAT Dataset with title, description, issued, and distribution properties",
                license => "Anyone may use this freely",
                issued => "May 26, 2014",
    		organization => "wilkinsonlab.info",
		identifier => "doi:2222222222",
                URI => "http://biordf.org/DataFairPort/ProfileSchemas/DemoMicroarrayProfileScheme.rdf",
                );

my $ORCIDSchema = FAIR::Profile->new(
                label => 'Metadata around an ORCID record',
		title => "Simple ORCID record descriptor", 
		description => "Just the ORCID ID and its resolvable URL",
                license => "Anyone may use this freely",
                issued => "May 26, 2014",
    		organization => "wilkinsonlab.info",
		identifier => "doi:33333333333",
                URI => "http://biordf.org/DataFairPort/ProfileSchemas/DemoORCIDProfileScheme.rdf",
                );


# ==  ORCID Class

my $ORCIDClass = FAIR::Profile::Class->new(
    #class_type => "http://biordf.org/DataFairPort/ProfileSchemas/DemoORCIDProfileScheme.rdf",
    URI => "http://biordf.org/DataFairPort/ProfileSchemas/DemoORCIDProfileScheme.rdf#ORCID",
    label => "ORCID Records",
    _template => 'http://biordf.org/DataFairPort/ProfileSchemas/Templates/ORCID.tt',
   );

    
    my $IDProperty = FAIR::Profile::Property->new(
        property_type => 'http://datafairport.org/examples/ProfileSchemas/Examples/ORCID_Class#orcid_id',
        label => "ORCID ID",
    );
    $IDProperty->minCount('1');
    $IDProperty->maxCount('1');
    $IDProperty->add_AllowedValue(XSD."string");
    $ORCIDClass->add_Property($IDProperty);
    
    my $ORCID_URL = FAIR::Profile::Property->new(
        property_type => 'http://datafairport.org/examples/ProfileSchemas/Examples/ORCID_Class#orcid_url',
        label => "ORCID URL",

    );
    $ORCID_URL->minCount('1');
    $ORCID_URL->maxCount('1');
    $ORCID_URL->add_AllowedValue(XSD."anyURI");
    $ORCIDClass->add_Property($ORCID_URL);


# ===== DCAT Distribution Class
my $DCATDistributionClass = FAIR::Profile::Class->new(
    class_type => FAIR."Profile",
    URI => "http://biordf.org/DataFairPort/ProfileSchemas/DemoMicroarrayProfileScheme.rdf#CoreMicroarrayDistributionMetadata",
    label => "Core Microarray Data Distribution Metadata",
    _template => 'http://biordf.org/DataFairPort/ProfileSchemas/Templates/MicroarrayDistribution.tt',
   );

    my $TitleProperty = FAIR::Profile::Property->new(
        property_type => DC.'title',
        label => "Title",
    );
    $TitleProperty->minCount('1');
    $TitleProperty->maxCount('1');
    $TitleProperty->add_AllowedValue(XSD."string");
    $DCATDistributionClass->add_Property($TitleProperty);
    
    
    my $DescrProperty = FAIR::Profile::Property->new(
        property_type => DC.'description',
        label => "Description",
    );
    $DescrProperty->minCount('1');
    $DescrProperty->maxCount('1');
    $DescrProperty->add_AllowedValue(XSD."string");
    $DCATDistributionClass->add_Property($DescrProperty);
    
    
    my $IssuedProperty = FAIR::Profile::Property->new(
        property_type => DC.'mediaType',
        label => "mediaType (controlled vocabulary)",
    );
    $IssuedProperty->minCount('1');
    $IssuedProperty->maxCount('1');
    $IssuedProperty->add_AllowedValue("http://biordf.org/DataFairPort/ConceptSchemes/EDAM_Microarray_Data_Format");
    $DCATDistributionClass->add_Property($IssuedProperty);
#------------------------------

# ==== Extended Authorship Class
my $ExtendedAuthorshipClass = FAIR::Profile::Class->new(
    class_type => "http://biordf.org/DataFairPort/ProfileSchemas/DemoMicroarrayProfileScheme.rdf#ExtendedAuthorship",
    URI => "http://biordf.org/DataFairPort/ProfileSchemas/DemoMicroarrayProfileScheme.rdf#ExtendedAuthorship",
    label => "Extended Authorship Information",
    _template => 'http://biordf.org/DataFairPort/ProfileSchemas/Templates/ExtendedAuthorship.tt',
   );

    my $AuthorProperty = FAIR::Profile::Property->new(
        property_type => DC.'Creator',
        label => "Creator (free)",
    );
    $AuthorProperty->minCount('1');
    $AuthorProperty->maxCount('1');
    $AuthorProperty->add_AllowedValue(XSD."string");
    $ExtendedAuthorshipClass->add_Property($AuthorProperty);
    
    
    my $ExtendedAuthorProperty = FAIR::Profile::Property->new(
        property_type => "http://datafairport.org/examples/ProfileSchemas/ExtendedAuthorshipMetadata.rdf#author_details",
        label => "Author ORCID",
    );
    $ExtendedAuthorProperty->minCount('1');
    $ExtendedAuthorProperty->maxCount('1');
    $ExtendedAuthorProperty->add_AllowedValue("http://biordf.org/DataFairPort/ProfileSchemas/DemoORCIDProfileScheme.rdf");
    $ExtendedAuthorshipClass->add_Property($ExtendedAuthorProperty);
#----------------------------


#============= Microarray Metadata

my $MicroarrayMetadataClass = FAIR::Profile::Class->new(
    class_type => "http://biordf.org/DataFairPort/ProfileSchemas/DemoMicroarrayProfileScheme.rdf#MicroarrayMetadata",
    URI => "http://biordf.org/DataFairPort/ProfileSchemas/DemoMicroarrayProfileScheme.rdf#MicroarrayMetadata",
    label => "Microarray Generation Protocol Metadata",
    _template => 'http://biordf.org/DataFairPort/ProfileSchemas/Templates/MicroarrayMetadata.tt',

   );

    
    my $ProtocolProperty = FAIR::Profile::Property->new(
        property_type => 'http://datafairport.org/examples/ProfileSchemas/MicroarrayMetadata.rdf#generated_by_protocol',
        label => "generated by protocol (free text)",
    );
    $ProtocolProperty->minCount('1');
    $ProtocolProperty->maxCount('1');
    $ProtocolProperty->add_AllowedValue(XSD."string");
    $MicroarrayMetadataClass->add_Property($ProtocolProperty);
    
    my $ProtocolType = FAIR::Profile::Property->new(
        property_type => 'http://datafairport.org/examples/ProfileSchemas/MicroarrayMetadata.rdf#protocol_type',
        label => "generated by prootocol type (limited by EFO ontology)",
    );
    $ProtocolType->add_AllowedValue('http://biordf.org/DataFairPort/ConceptSchemes/EFO_Gene_Expression_Protocol');
    $MicroarrayMetadataClass->add_Property($ProtocolType);
#-----------------------


# add the three metadata classes to the Microarray profile
$MicroarrayDatasetSchema->add_Class($MicroarrayMetadataClass);
$MicroarrayDatasetSchema->add_Class($ExtendedAuthorshipClass);
$MicroarrayDatasetSchema->add_Class($DCATDistributionClass);

my $schemardf =  $MicroarrayDatasetSchema->serialize;
open(OUT, ">DemoMicroarrayProfileScheme.rdf") or die "Can't open the output file to write the profile schema$!\n";
print $schemardf, "\n\n================================\n\n";
print OUT $schemardf;
close OUT;

#-------------

# add the single metadata class to the ORCID profile
$ORCIDSchema->add_Class($ORCIDClass);

my $schema2rdf =  $ORCIDSchema->serialize;
open(OUT, ">DemoORCIDProfileScheme.rdf") or die "Can't open the output file to write the profile schema$!\n";
print $schema2rdf, "\n";
print OUT $schema2rdf;
close OUT;
    


