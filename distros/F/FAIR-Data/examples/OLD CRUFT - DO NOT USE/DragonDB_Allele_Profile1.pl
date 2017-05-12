#!perl -w
use strict;
use FAIR::Profile;
use FAIR::Profile::Class;
use FAIR::Profile::Property;
use FAIR::NAMESPACES;

my $DragonDB_AlleleProfile = FAIR::Profile->new(
                label => 'FAIR Profile the Allele records of DragonDB using textual descriptions and links to Gene Records',
		title => "FAIR Profile the Allele records of DragonDB using textual descriptions and links to Gene Records", 
		description => "FAIR Profile the Allele records of DragonDB using textual descriptions and links to Gene Records",
                license => "Anyone may use this freely",
                issued => "May 21, 2015",
    		organization => "wilkinsonlab.info",
		identifier => "doi:Mark.Dragon.P1",
                URI => "http://biordf.org/DataFairPort/ProfileSchemas/DragonDB_Allele_ProfileAlleleDescriptions.rdf",
                );



# ===== Protein Class
my $AlleleClass = FAIR::Profile::Class->new(
    onClassType => "http://purl.obolibrary.org/obo/SO_0001023",  # allele
    URI => "http://biordf.org/DataFairPort/ProfileSchemas/DragonDB_Allele_ProfileAlleleDescriptions.rdf#DragonAlleleClass",
    label => "FAIR Class of DragonDB Allele",
   );

    my $DescriptionProperty = FAIR::Profile::Property->new(
        onPropertyType => DC.'description',
        label => "description",
    );
    $DescriptionProperty->add_AllowedValue(XSD.'string');
    $AlleleClass->add_Property($DescriptionProperty);
    

    my $variantofProperty = FAIR::Profile::Property->new(
        onPropertyType => 'http://purl.obolibrary.org/obo/so_variant_of',
        label => "variant of",
    );
    $variantofProperty->minCount('1');
    $variantofProperty->maxCount('1');
    $variantofProperty->add_AllowedValue('http://biordf.org/DataFairPort/ConceptSchemes/SequenceOntologyGene704');
    $AlleleClass->add_Property($variantofProperty);


    
    
    
    $DragonDB_AlleleProfile->add_Class($AlleleClass);

# ========================
# ========================
# ========================
# ========================


foreach ($DragonDB_AlleleProfile){
    my $filename = $_->URI;
    die "no match $filename\n" unless ($filename =~ /.*\/(\S+)/);
    $filename = $1;
    my $schemardf =  $_->serialize;

    open(OUT, ">$filename") or die "Can't open the output file to write the profile $filename!\n";
    print $schemardf, "\n\n================================\n\n";
    print OUT $schemardf;
    close OUT;
}

