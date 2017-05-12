package FAIR::Accessor;
$FAIR::Accessor::VERSION = '1.001';



# ABSTRACT: all this does is assign the HTTP call to the correct routine



use base 'FAIR::AccessorBase';

#  for testing at the command-line...
unless ($ENV{REQUEST_METHOD}){  # if running from command line

    if ($ARGV[0]) {  # if there are any user-supplied arguments
        $ENV{REQUEST_METHOD} = $ARGV[0];
        $ENV{'SERVER_NAME'} = $ARGV[1] ;
        $ENV{'REQUEST_URI'} = $ARGV[2];
        $ENV{'SCRIPT_NAME'} = $ARGV[2];
        $ENV{'PATH_INFO'} = $ARGV[3] ;
    } else {
        $ENV{REQUEST_METHOD} = "GET";
        $ENV{'SERVER_NAME'} =  "example.net";
        $ENV{'REQUEST_URI'} = "/SemanticPHIBase/Metadata";
        $ENV{'SCRIPT_NAME'} = "/SemanticPHIBase/Metadata";
        $ENV{'PATH_INFO'} = "/INT_00000";
    }
}


sub handle_requests {

    my $self = shift;
    my $base = $self->Configuration->basePATH();  # $base is a regular expression that separates the "path" from the "id" portion of the PATH_INFO environment variable
    $base ||= "";
    # THIS ROUTINE WILL BE SHARED BY ALL SERVERS
    if ($ENV{REQUEST_METHOD} eq "HEAD") {
        $self->manageHEAD();
        exit;
    } elsif ($ENV{REQUEST_METHOD} eq "OPTIONS"){
        $self->manageHEAD();
        exit;
    }  elsif ($ENV{REQUEST_METHOD} eq "GET") {
        unless ($ENV{'REQUEST_URI'} =~ /$base/){
            print "Status: 500\n"; 
            print "Content-type: text/plain\n\nThe configured basePATH argument $base does not match the request URI  $ENV{'REQUEST_URI'}\n\n";
            exit 0;
        }
        my $id = $ENV{'PATH_INFO'};
        $id =~ s/^\///;  # get rid of leading /
        
        if ($id) {  #$ENV{'PATH_INFO'} this is a request like  /Allele/dip21  where the user is asking for a specific individual
                $self->printResourceHeader();
                $self->manageResourceGET('ID' => $id);
        } else {  # this is a request like /Allele  or /Allele/  where the user is asking for the container
                $self->printContainerHeader();
                $self->manageContainerGET();
        }
    } else {
        print "Status: 405 Method Not Allowed\n"; 
        print "Content-type: text/plain\n\nYou can only request HEAD, OPTIONS or GET from this LD Platform Server\n\n";
        exit 0;
    }

}



 






1;

__END__

=pod

=encoding UTF-8

=head1 NAME

FAIR::Accessor - all this does is assign the HTTP call to the correct routine

=head1 VERSION

version 1.001

=head1 SYNOPSIS

The following code is a complete implementation of a 'Hello, World!' FAIR Accessor

 C<##!/usr/local/bin/perl -w

 package MyFirstAccessor;  # this should be the same as your filename!
 use FindBin;                # where was script installed?
 use lib "$FindBin::Bin";      # use that dir for libs, too
 use strict;
 use warnings;
 use JSON;
 use FAIR::Accessor::Distribution;
 use FAIR::Accessor::Container;
 use FAIR::Accessor::MetaRecord;


 #-----------------------------------------------------------------
 # Configuration and Daemon
 #-----------------------------------------------------------------

 use base 'FAIR::Accessor';

 my $config = {
   title => 'Example FAIR Accessor',
   serviceTextualDescription => 'Bare-bones FAIR Accessor',
   textualAccessibilityInfo => "The information from this server requries no authentication; HTTP GET is sufficient",  # this could also be a $URI describing the accessibiltiy
   mechanizedAccessibilityInfo => "",  # this must be a URI to an RDF document
   textualLicenseInfo => "CC0",  # this could also be a URI to the license info
   mechanizedLicenseInfo =>  "https://creativecommons.org/choose/zero/", # this must be a URI to an RDF document
   ETAG_Base => "SomeIdentifierOfMyAccessor", # this is a unique identificaiton string for the service (required by the LDP specification)
   localNamespaces => {
	pfund => 'http://vocab.ox.ac.uk/projectfunding#term_',
	up => 'http://uniprot.org/ontology/core#', 
	},  # add a few new namespaces to the list of known namespaces....
   basePATH => 'cgi-bin/Accessors/MyFirstAccessor', # REQUIRED regexp to match the PATH part of the URL, before the ID number

 };
            
 my $service = UniProtAccessor->new(%$config);

 # start daemon
 $service->handle_requests;


 #-----------------------------------------------------------------
 # Accessor Implementation
 #-----------------------------------------------------------------


 #------------- Container Resource --------------

 sub Container {    REQUIRED SUBROUTINE NAME!!!!

   my ($self, %ARGS) = @_;
   
   my $Container = FAIR::Accessor::Container->new(NS => $self->Configuration->Namespaces);
    
   my $BASE_URL = "http://" . $ENV{'SERVER_NAME'} . $ENV{'REQUEST_URI'};

   my @recordIDs = (1,2,3,4,5,6,7);
   my @recordURLs;
   foreach my $ID (@recordIDs) {
      push @recordURLs, "$BASE_URL/$ID";   # need to make a URL for each of the meta-records, based on the ID of the PHIBase record, push it onto a list
   }
  
   $Container->addRecords(\@recordURLs); # the listref of record ids
   $self->fillContainerMetadata($Container);

   return $Container;
 }

 # --------------------MetaRecord Resource ---------------

 sub MetaRecord {   REQUIRED SUBROUTINE NAME
   my ($self, %ARGS) = @_;

   my $ID = $ARGS{'ID'};

   my $MetaRecord = FAIR::Accessor::MetaRecord->new(ID => $ID,
                                                    NS => $self->Configuration->Namespaces);
   $self->fillMetaRecordMetadata($MetaRecord);
   
   $MetaRecord->addDistribution(availableformats => ['text/html'],
                                downloadURL => "http://www.uniprot.org/uniprot/$ID.html");
   $MetaRecord->addDistribution(availableformats => ['application/rdf+xml'],
                                downloadURL => "http://www.uniprot.org/uniprot/$ID.rdf");

   
   my $encodedsubject = urlencode("http://identifiers.org/uniprot/$ID");
   my $encodedpredicate = urlencode("http://purl.uniprot.org/core/organism");
   my $TPF = "http://my.TPF.server.org/fragments?subject=$encodedsubject&predicate=$encodedpredicate";  
   $MetaRecord->addDistribution(
         availableformats => ["application/x-turtle", "application/rdf+xml", "text/html"],
         downloadURL => $TPF,
         source => "http://identifiers.org/uniprot/$ID",
         subjecttemplate =>  "http://identifiers.org/uniprot/{ID}",
         subjecttype => "http://purl.uniprot.org/core/organism",
         predicate => "http://purl.uniprot.org/core/organism",
         objecttemplate => "http://identifiers.org/taxon/{TAX}",
         objecttype => "http://edamontology.org/data_1179",      
   );
   
   return $MetaRecord;

 }

 sub fillContainerMetadata {
   my ($self, $Container) = @_;
   $Container->addMetadata({
      'dc:title' => "Generic FAIR Accessor example",
      'dcat:description' => "For Example",
      'dcat:identifier' => "http://linkeddata.systems/cgi-bin/Accessors/MyFirstAccessor",  # NOTE the filename and path!  set in the top-level %config hash!
      'dcat:keyword' => ["Go", "FAIR"],
      'dc:license' => 'https://creativecommons.org/choose/zero',
      'rdf:type' => ['prov:Collection', 'dctypes:Dataset'],
   });
 }

 sub fillMetaRecordMetadata {
  my ($self, $MetaRecord) = @_;
  my $ID = $MetaRecord->ID;
  $MetaRecord->addMetadata({
      'foaf:primaryTopic' => "http://my.database.org/records/$ID",
      'dc:title' => "Record $ID",
      'dcat:identifier' => "http://my.database.org/records/$ID",
      'dcat:keyword' => ["Go", "FAIR"],
      'dc:creator' => 'Me',
      'dc:bibliographicCitation' => "Joe Bloggs (2016). How to write a FAIR Accessor, Online Journal 4:3.",
      'void:inDataset' => 'http://linkeddata.systems/cgi-bin/Accessors/UniProtAccessor/',
      'dc:license' => 'https://creativecommons.org/choose/zero',
	});
 
 }

 sub urlencode {
    my $s = shift;
    $s =~ s/ /+/g;
    $s =~ s/([^A-Za-z0-9\+-])/sprintf("%%%02X", ord($1))/seg;
    return $s;
 }

>

=head1 DESCRIPTION

FAIR Accessors are inspired by the W3Cs Linked Data Platform "Containers".

FAIR Accessors follow a two-stage interaction, where the first stage
retrieves metadata about the repository "Container"), and (optionally)
a series of URLs representing 'MetaRecords' for every record in
that repository (or whatever slice of the repository is being served).
This is accomplished by the B<Container> subroutine.  These URLs
will generally point back at this same Accessor script (e.g. with the
record number appended to the URL:  I<http://this.host/thisscript/12345>).

The second stage involves retrieving metadata about individual recoreds.
The metadata is up to you, but optimally it would include the available
DCAT distributions and their file formats.  The second stage can be accomplished
by this same Accessor script, using the Distributions subroutine.

The two subroutine names - B<Container>  and  B<MetaRecord> - are not flexible, as they are
called by-name, by the Accessor libraries.

You B<MUST> create the B<Container> subroutine, at a minimum, and it should return some metadata.
It does not have to return a list of known records (in which case it simply acts as a metadata
descriptor of the repository in general, nothing more... which is fine!... and there will be no
second stage interaction.  In this case, you do not need to provide a B<MetaRecord> subroutine.)

=head1 NAME

    FAIR::Accessor - Module for creating Linked Data Platform Accessors for the FAIR Data project

=head1 Command-line testing

If you wish to test your Accessor server at the command line, you can run it with the following commandline arguments (in order):

 Method (always GET, at the moment)
 Domain
 Request URI (i.e. the path to this script, including the script name)
 PATH_INFO  (anything that should appear in the PATH_INFO variable of the webserver)

  perl  myAccessorScript  GET  example.net  /this/myAccessorScript /1234567

=head1 AUTHOR

Mark Denis Wilkinson (markw [at] illuminae [dot] com)

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Mark Denis Wilkinson.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
