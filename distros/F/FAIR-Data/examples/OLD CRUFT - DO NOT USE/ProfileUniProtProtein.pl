#!perl -w
use lib "../lib/";
use FAIR::Profile;
use FAIR::Profile::Class;
use FAIR::Profile::Property;
use FAIR::NAMESPACES;

my $UniProtProteinProfile = FAIR::Profile->new(
                label => 'FAIR Profile of UniProt Protein',
		title => "FAIR Profile of UniProt Protiens", 
		description => "This FAIR Profile represents the Protein annotations from UniProt's RDF",
                license => "Anyone may use this freely",
                issued => "April 2, 2015",
    		organization => "wilkinsonlab.info",
		identifier => "doi:2222222222",
                URI => "http://biordf.org/DataFairPort/ProfileSchemas/ProfileUniProtProtein.rdf",
                );



# ===== Protein Class
my $UPProteinClass = FAIR::Profile::Class->new(
    onClassType => "http://purl.uniprot.org/core/Protein",
    URI => "http://biordf.org/DataFairPort/ProfileSchemas/ProfileUniProtProtein.rdf#UPProteinClass",
    label => "FAIR Class of UniProt Protein",
   );

    my $seeAlsoProperty = FAIR::Profile::Property->new(
        onPropertyType => RDFS.'seeAlso',
        label => "see also",
    );
    $seeAlsoProperty->minCount('1');
    $seeAlsoProperty->add_AllowedValue("http://biordf.org/DataFairPort/ProfileSchemas/ProfileUniProtHGNC.rdf");
    $UPProteinClass->add_Property($seeAlsoProperty);
    
    
    $UniProtProteinProfile->add_Class($UPProteinClass);

# ========================
# ========================
# ========================
# ========================



#  HGNC FAIR Profile
my $UniProtHGNCProfile = FAIR::Profile->new(
                label => 'FAIR Profile of UniProt HGNC',
		title => "FAIR UniProt HGNC", 
		description => "This FAIR Profile represents the HGNC annotations from UniProt's RDF",
                license => "Anyone may use this freely",
                issued => "April 2, 2015",
    		organization => "wilkinsonlab.info",
		identifier => "doi:2222222223",
                URI => "http://biordf.org/DataFairPort/ProfileSchemas/ProfileUniProtHGNC.rdf",
                );

# =====HGNC Class
my $UPHGNCClass = FAIR::Profile::Class->new(
    onClassType => "http://openlifedata.org/hgnc_vocabulary:Resource",  # http://purl.uniprot.org/core/Resource also, but...
    URI => "http://biordf.org/DataFairPort/ProfileSchemas/ProfileUniProtHGNC.rdf#UPHGNCClass",
    label => "FAIR Class of UniProt HGNC",
   );

# ===== uniprot:database Property
    my $databaseProperty = FAIR::Profile::Property->new(
        onPropertyType => "http://purl.uniprot.org/core/database",
        label => "database",
    );
    
    $databaseProperty->minCount('1');
    $databaseProperty->add_AllowedValue("http://biordf.org/DataFairPort/ProfileSchemas/ProfileUniProtDatabase.rdf");
    $UPHGNCClass->add_Property($databaseProperty);
    

    $UniProtHGNCProfile->add_Class($UPHGNCClass);

# ================
# ================
# ================



#  Database FAIR Profile
my $UniProtDatabaseProfile = FAIR::Profile->new(
                label => 'FAIR Profile of UniProt Database',
		title => "FAIR UniProt Databasde", 
		description => "This FAIR Profile represents the Database Class from UniProt's RDF",
                license => "Anyone may use this freely",
                issued => "April 2, 2015",
    		organization => "wilkinsonlab.info",
		identifier => "doi:2222222224",
                URI => "http://biordf.org/DataFairPort/ProfileSchemas/ProfileUniProtDatabase.rdf",
                );

my $UPDatabaseClass = FAIR::Profile::Class->new(
    onClassType => "http://purl.uniprot.org/core/Database",  # http://purl.uniprot.org/core/Resource also, but...
    URI => "http://biordf.org/DataFairPort/ProfileSchemas/ProfileUniProtDatabase.rdf#UPDatabaseClass",
    label => "FAIR UniProt Database Class",
   );
    
    $UniProtDatabaseProfile->add_Class($UPDatabaseClass);

# ================
# ================
# ================


foreach ($UniProtProteinProfile, $UniProtHGNCProfile, $UniProtDatabaseProfile){
    my $filename = $_->URI;
    die "no match $filename\n" unless ($filename =~ /.*\/(\S+)/);
    $filename = $1;
    my $schemardf =  $_->serialize;

    open(OUT, ">$filename") or die "Can't open the output file to write the profile $filename!\n";
    print $schemardf, "\n\n================================\n\n";
    print OUT $schemardf;
    close OUT;
}

