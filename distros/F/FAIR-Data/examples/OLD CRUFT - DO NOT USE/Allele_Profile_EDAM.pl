#!perl -w
use lib "../lib/";
use FAIR::Profile;
use FAIR::Profile::Class;
use FAIR::Profile::Property;
use FAIR::NAMESPACES;

my $URL = "http://biordf.org/DataFairPort/ProfileSchemas/Allele_Profile_EDAM.rdf";
my $AlleleProfile = FAIR::Profile->new(
                label => 'FAIR Profile Allele Images (EDAM)',
		title => "FAIR Profile the Image portion of an Allele record", 
		description => "FAIR Profile the Image portion of an Allele record using EDAM:Image classification",
                license => "Anyone may use this freely",
                issued => "May 21, 2015",
    		organization => "wilkinsonlab.info",
		identifier => "doi:Mark.Dragon.P3",
                URI => "$URL#Profile",
                );



# ===== Protein Class
my $AlleleClass = FAIR::Profile::Class->new(
    onClassType => "http://purl.obolibrary.org/obo/SO_0001023",  # allele
    URI => "$URL",
    label => "FAIR Class of Allele",
   );
    

    my $representedByProperty = FAIR::Profile::Property->new(
        onPropertyType => 'http://semanticscience.org/ontology/SIO_000205',
        label => "is represented by",
    );
    $representedByProperty->add_AllowedValue('http://biordf.org/DataFairPort/ConceptSchemes/EDAMOntologyImage2968');
    $AlleleClass->add_Property($representedByProperty);


    
    
    
    $AlleleProfile->add_Class($AlleleClass);


# ========================
# ========================
# ========================
# ========================



foreach ($AlleleProfile){
    my $filename = $_->URI;
    die "no match $filename\n" unless ($filename =~ /.*\/(\S+)[#\b]/);
    $filename = $1;
    my $schemardf =  $_->serialize;

    open(OUT, ">$filename") or die "Can't open the output file to write the profile $filename!\n";
    print $schemardf, "\n\n================================\n\n";
    print OUT $schemardf;
    close OUT;
}

