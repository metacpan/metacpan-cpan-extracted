#!perl -w
use lib "../lib/";
use FAIR::Profile;
use FAIR::Profile::Class;
use FAIR::Profile::Property;
use FAIR::NAMESPACES;


my $DragonDB_AlleleProfile = FAIR::Profile->new(
                label => 'FAIR Profile the Image portion of Allele records of DragonDB using SIO:Image classification',
		title => "FAIR Profile the Image portion of Allele records of DragonDB using SIO:Image classification", 
		description => "FAIR Profile the Image portion of Allele records of DragonDB using SIO:Image classification",
                license => "Anyone may use this freely",
                issued => "May 21, 2015",
    		organization => "wilkinsonlab.info",
		identifier => "doi:Mark.Dragon.P2",
                URI => "http://biordf.org/DataFairPort/ProfileSchemas/DragonDB_Allele_ProfileImagesSIO.rdf",
                );



# ===== Protein Class
my $AlleleClass = FAIR::Profile::Class->new(
    onClassType => "http://purl.obolibrary.org/obo/SO_0001023",  # allele
    URI => "http://biordf.org/DataFairPort/ProfileSchemas/DragonDB_Allele_ProfileImagesSIO.rdf#DragonAlleleClass",
    label => "FAIR Class of DragonDB Allele",
   );
    

    my $representedByProperty = FAIR::Profile::Property->new(
        onPropertyType => 'http://semanticscience.org/ontology/SIO_000205',
        label => "is represented by",
    );
    $representedByProperty->add_AllowedValue('http://biordf.org/DataFairPort/ConceptSchemes/SIOOntologyImage81');
    $AlleleClass->add_Property($representedByProperty);


    
    
    
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

