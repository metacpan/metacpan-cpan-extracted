package FAIR::AccessorBase;
$FAIR::AccessorBase::VERSION = '1.001';




# ABSTRACT: The core Accessor functions


use Moose;
use URI::Escape;
use JSON;
use FAIR::AccessorConfig;
use RDF::Trine::Parser 0.135;
use RDF::Trine::Model 0.135;
use RDF::Trine::Statement 0.135;
use RDF::Trine::Node::Resource;
use RDF::Trine::Node::Literal;
use Scalar::Util 'blessed';
use Log::Log4perl;


with 'FAIR::CoreFunctions';

has 'Configuration' => (
    isa => 'FAIR::AccessorConfig',
    is => 'rw',
);


around BUILDARGS => sub {
      my %return;
      $return{'Configuration'} = FAIR::AccessorConfig->new(@_);
      return \%return;
  };





# ============================================
#  All Daemons must implement this method
sub Container {
	my ( @args ) = @_;

	# user-specific implementation will override this method
}

# ============================================
#  Some Daemons may implement this method

sub MetaRecord {
	my ( @args ) = @_;

	# user-specific implementation will override this method
}

# =============================================



# ===============  STAGE 1 Subroutines

sub manageContainerGET {
    my ($self, %args) = @_;  # %args  are PATH => '/some/path'
    
    unless ($ENV{'SCRIPT_NAME'}) {print STDERR "your servers implementation of CGI does not capture the SCRIPT_NAME; defaulting to REQUEST_URI!";}
    my $SCRIPT_NAME = $ENV{'SCRIPT_NAME'}?$ENV{'SCRIPT_NAME'}:$ENV{REQUEST_URI};  # best guess!  
    $SCRIPT_NAME =~ s/^\///;   # if it is there, get rid of the leading /
    
    my $BASE_URL = "http://" . $ENV{'SERVER_NAME'} . "/$SCRIPT_NAME";
    $BASE_URL .= $ENV{'PATH_INFO'}  if $ENV{'PATH_INFO'} ;
    my $store = RDF::Trine::Store::Memory->new();
    my $model = RDF::Trine::Model->new($store);
    my $ns = $self->Configuration->Namespaces;
        
    $self->callAccessorContainer($BASE_URL, $model);  

    my $statement = statement($BASE_URL, $ns->rdf("type"), $ns->ldp("BasicContainer")); 
    $model->add_statement($statement);
    
    unless ($model->count_statements(RDF::Trine::Node::Resource->new($BASE_URL), RDF::Trine::Node::Resource->new($ns->dc("title")))){
      $statement = statement($BASE_URL, $ns->dc("title"), $self->Configuration->{'title'}); 
      $model->add_statement($statement); 
    }
    $self->serializeThis($model);

}

sub makeSensibleStatement {
      my ($self, $s, $p, $o) = @_;
	my ($subject, $predicate, $object);
      my $NS = $self->Configuration->Namespaces();
      
      if (($s =~ /^http:/) || ($s =~ /^https:/)) {
		$subject = $s;
      } else {
             my ($ns, $sub) = split /:/, $s;
             $subject = $NS->$ns($sub);   # add the namespace   
      }
      
      if (($p =~ /^http:/) || ($p =~ /^https:/)) {
	$predicate = $p;
      } else {
             my ($ns, $pred) = split /:/, $p;
             $predicate = $NS->$ns($pred);   # add the namespace   
      }
         
      if (($o =~ /^http:/) || ($o =~ /^https:/)) {  # if its a URL
            $object = $o
      } elsif ((!($o =~ /\s/)) && ($o =~ /\S+:\S+/)){  # if it looks like a qname tag
            my ($ns,$obj) = split /:/, $o;
            if ($NS->$ns($obj)) {
                  $object =  $NS->$ns($obj);   # add the namespace               
            }
      } else {
		$object = $o
	}
         
      my $statement = statement($subject,  $predicate, $object); 
      
      return $statement;
      
}


sub callAccessorContainer {
      my ($self, $subject, $model) = @_;
      
      my ($Container) = $self->Container(); # this subroutine is provided by the end-user in the Accessor script on the web
      die "Not a FAIR::Accessor::Container" unless $Container->isa("FAIR::Accessor::Container");


      $model->begin_bulk_ops();
      my %metadata = %{$Container->MetaData};

      my $temprdf;  # doing this to make the import more efficient... I hope!
      
      # ADD THE METADATA key/value|array pairs
      foreach my $CDE(keys %metadata){
      
            next unless $metadata{$CDE}; # if it is blank, ignore it
            
            my $values = $metadata{$CDE};
            $values = [$values] unless (ref($values) =~ /ARRAY/);
            foreach my $value(@$values){
                  my $statement = $self->makeSensibleStatement($subject, $CDE, $value);
                  my $str = $statement->as_string;  # almost n3 format... need to fix it a bit...
                  $str =~ s/^\(triple\s//;
                  $str =~ s/\)$/./;
                  $temprdf .= "$str\n";  # this is RDF in n3 format
            }
   
      }
      
      # ADD THE RECORD IDS with "contains"
      my @records = @{$Container->Records};
      foreach my $rec(@records){
            my $statement = $self->makeSensibleStatement($subject, "ldp:contains", $rec);
            my $str = $statement->as_string;  # almost n3 format... need to fix it a bit...
            $str =~ s/^\(triple\s//;
            $str =~ s/\)$/./;
            $temprdf .= "$str\n";  # this is RDF in n3 format
      }

      my $parser     = RDF::Trine::Parser->new( 'ntriples' );
      $parser->parse_into_model( "http://example.org/", $temprdf, $model );
      
      
      $model->end_bulk_ops();
            

      if ($Container->FreeFormRDF && blessed($Container->FreeFormRDF) && $Container->FreeFormRDF->isa("RDF::Trine::Model")) {  # if they are doing this, they know what they are doing!  (we assume)
            my $iterator = $Container->FreeFormRDF->statements;
            while (my $stm = $iterator->next()) {
                 $model->add_statement($stm);
           }
      }            

}
# ====================== END OF STAGE1 SUBROUTINES




# ==================  Stage 2 subroutines =============

sub manageResourceGET {  # $self->manageResourceGET('PATH' => $path, 'ID' => $id);
    my ($self, %ARGS) = @_;
    my $ID = $ARGS{'ID'};
    
    my $store = RDF::Trine::Store::Memory->new();
    my $model = RDF::Trine::Model->new($store);
          
    $self->callDataAccessor($model, $ID);

    $self->serializeThis($model);

}


sub callDataAccessor {
      my ($self, $model, $ID) = @_;
      
      # call out to user-provided subroutine
      my ($MetaRecord) = $self->MetaRecord('ID' => $ID);  # this method is provided (hopefully) by the service provider's Accessor script.
      # TODO - this should be a catch, not a call...
      
      
      my $subject = "http://" . $ENV{'SERVER_NAME'} . $ENV{'REQUEST_URI'};
      my $NS = $self->Configuration->Namespaces();

      #----------------------------------------------------------------------------------
      #  GENERIC METADATA----------------------------------------------------------------
      #----------------------------------------------------------------------------------

      my %metadata = %{$MetaRecord->MetaData};      
      foreach my $CDE(keys %metadata){            
            next unless $metadata{$CDE}; # if it is blank, ignore it
            
            my $values = $metadata{$CDE};
            $values = [$values] unless (ref($values) =~ /ARRAY/);
            foreach my $value(@$values){
                  my $statement = $self->makeSensibleStatement($subject, $CDE, $value);
                  $model->add_statement($statement);
            }
      }
      
      
      #----------------------------------------------------------------------------------      
      # DISTRIBUTION METADATA ---------------------------------------------
      #----------------------------------------------------------------------------------

      my $distributions = $MetaRecord->Distributions();
      foreach my $Dist(@$distributions){
            my $downloadURL = $Dist->downloadURL();
            my $statement = $self->makeSensibleStatement($subject, $NS->dcat('distribution'), $downloadURL);
            $model->add_statement($statement);
            my $projector = 0;
            foreach my $type($Dist->types){
                  $statement = $self->makeSensibleStatement($downloadURL, $NS->rdf('type'), $type);
                  $model->add_statement($statement);
                  $projector = 1 if ($type =~ /Projector/);  # flag it as a projector for the if block below                  
            }
            
	    foreach my $form(@{$Dist->availableformats}){
	            $statement = $self->makeSensibleStatement($downloadURL, $NS->dc('format'), $form);
	            $model->add_statement($statement);            
		}
      
            $statement = $self->makeSensibleStatement($downloadURL, $NS->dcat('downloadURL'), $downloadURL);
            $model->add_statement($statement);
            
            if ($projector) {
                  my $projectionmodel = $Dist->ProjectionModel();
                  $model->add_iterator($projectionmodel->as_stream);
            }
            
      }
}



sub printResourceHeader {
	my ($self) = @_;
        my $ETAG = $self->Configuration->ETAG_Base();
	my $entity = $ENV{'PATH_INFO'};
	$entity =~ s/^\///;
#	print "Content-Type: text/turtle\n";
	print "Content-Type: application/rdf+xml\n";
	print "ETag: \"$ETAG"."_"."$entity\"\n";
	print "Allow: GET,OPTIONS,HEAD\n";
	print 'Link: <http://www.w3.org/ns/ldp#Resource>; rel="type"'."\n\n";

}

sub printContainerHeader {
	my ($self) = @_;
        my $ETAG = $self->Configuration->ETAG_Base();
#	print "Content-Type: text/turtle\n";
	print "Content-Type: application/rdf+xml\n";
	print "ETag: \"$ETAG\"\n";
	print "Allow: GET,OPTIONS,HEAD\n";
	print 'Link: <http://www.w3.org/ns/ldp#BasicContainer>; rel="type",'."\n";
	print '      <http://www.w3.org/ns/ldp#Resource>; rel="type"'."\n\n";
	#    print "Transfer-Encoding: chunked\n\n";

}

sub manageHEAD {
	my ($self) = @_;
        my $ETAG = $self->Configuration->ETAG_Base();
	
	print "Content-Type: text/turtle\n";
	print "ETag: \"$ETAG\"\n";
	print "Allow: GET,OPTIONS,HEAD\n\n";
	print 'Link: <http://www.w3.org/ns/ldp#BasicContainer>; rel="type",'."\n";
	print '      <http://www.w3.org/ns/ldp#Resource>; rel="type"'."\n\n";
    
}

sub serializeThis{
    my ($self, $model) = @_;
#    my $serializer = RDF::Trine::Serializer->new('turtle');  # the turtle serializer is simply too slow to use...
    my $serializer = RDF::Trine::Serializer->new('rdfxml');  # TODO - this should work with content negotiation
    print $serializer->serialize_model_to_string($model);
}



#
## returns the request content type
## defaults to application/rdf+xml
#sub get_request_content_type {
#	my ($self) = @_;
#    my $CONTENT_TYPE = 'application/rdf+xml';
#    if (defined $ENV{CONTENT_TYPE}) {
#        $CONTENT_TYPE = 'text/rdf+n3' if $ENV{CONTENT_TYPE} =~ m|text/rdf\+n3|gi;
#        $CONTENT_TYPE = 'text/rdf+n3' if $ENV{CONTENT_TYPE} =~ m|text/n3|gi;
#        $CONTENT_TYPE = 'application/n-quads' if $ENV{CONTENT_TYPE} =~ m|application/n\-quads|gi;
#        
#    }
#    return $CONTENT_TYPE;
#}
#
## returns the response requested content type
## defaults to application/rdf+xml
#sub get_response_content_type {
#    my ($self) = @_;
#    my $CONTENT_TYPE = 'application/rdf+xml';
#    if (defined $ENV{HTTP_ACCEPT}) {
#        $CONTENT_TYPE = 'text/rdf+n3' if $ENV{HTTP_ACCEPT} =~ m|text/rdf\+n3|gi;
#        $CONTENT_TYPE = 'text/rdf+n3' if $ENV{HTTP_ACCEPT} =~ m|text/n3|gi;
#        $CONTENT_TYPE = 'application/n-quads' if $ENV{HTTP_ACCEPT} =~ m|application/n\-quads|gi;
#        
#    }
#    return $CONTENT_TYPE;
#}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

FAIR::AccessorBase - The core Accessor functions

=head1 VERSION

version 1.001

=head1 AUTHOR

Mark Denis Wilkinson (markw [at] illuminae [dot] com)

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Mark Denis Wilkinson.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
