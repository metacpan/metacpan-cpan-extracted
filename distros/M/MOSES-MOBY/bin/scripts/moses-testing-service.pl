#!/usr/bin/perl -w
#
# Calling a BioMoby services (with or without SOAP).
#
# $Id: moses-testing-service.pl,v 1.17 2010/01/20 14:35:58 kawas Exp $
# Contact: Martin Senger <martin.senger@gmail.com>
# -----------------------------------------------------------
BEGIN {

    # some command-line options
    use Getopt::Std;
    use vars qw/ $opt_h $opt_d $opt_v $opt_l $opt_e $opt_c $opt_a $opt_C /;
    getopts('hdvl:e:c:C:a:');

    # usage
    if ( $opt_h or ( @ARGV == 0 and ( not $opt_c or not $opt_C ) ) ) {
        print STDOUT <<'END_OF_USAGE';
Calling a BioMoby services (without using SOAP, just locally).
Usage: # calling a local module representing a service, without using SOAP
       [-vd] [-l <lib-location>] <package-name> [<input-file>]
       or
       [-vd] -c <service-url> [<input-file>]
       or
       [-vd] -C <service-url> [<input-file>]
       or
       [-vd] -e <service-url> [<input-file>]
       or
       [-vd] -a <service-url> [<input-file>]

       It also needs a location of a local cache (and potentially a
       BioMoby registry endpoint). It takes it from the
       'moby-service.cfg' configuration file.

       # calling a real service, using SOAP
       -e <service-url> <service-name> [<input-file>]

       # calling a real service, using cgi
       -c <service-url> [<input-file>]

       # calling a real service, using asynchronous cgi
       -C <service-url> [<input-file>]

       # calling a real service, using async SOAP
       -a <service-url> <service-name> [<input-file>]

    <package-name> is a full name of a called module (service)
        e.g. Service::Mabuhay

    -l <lib-location>
        A directory where is called service stored.
        Default: src/Perl/services   

    -e <service-url>
        A service endpoint
        (e.g. http://localhost/cgi-bin/MobyServer.cgi)

    -c <cgi-service-url>
        A cgi biomoby service url
        (e.g. http://localhost/cgi-bin/HelloBiomobyWorld.cgi)
        
    -C <async-cgi-service-url>
        An asynchronous cgi biomoby service url
        (e.g. http://localhost/cgi-bin/HelloBiomobyWorldAsync.cgi)

    -a <asynchronous service-url>
        An asynchronous service url
        (e.g. http://localhost/cgi-bin/AsyncMobyServer.cgi)

    <input-file>
        A BioMoby XML file with input data.
        Default: an empty BioMoby request

    -v ... verbose
    -d ... debug
    -h ... help
END_OF_USAGE
        exit(0);
    }
    use HTTP::Request;
    use LWP::UserAgent;
    use XML::LibXML;
    use MOBY::Async::WSRF;
    use MOBY::Async::LSAE;

    # use MOSES::MOBY::Base;
    # load modules, depending on the mode of calling
    if ($opt_e) {

        # calling a real service, using SOAP
        eval "use SOAP::Lite; 1;"
          or die "$@\n";
    } elsif ($opt_c) {

        # calling a real service, using cgi
        eval "use HTTP::Request; 1;"
          or die "$@\n";
        eval "use LWP::UserAgent; 1;"
          or die "$@\n";
    } elsif ($opt_C) {

        # calling a real service, using async cgi
        eval "use HTTP::Request; 1;"
          or die "$@\n";
        eval "use LWP::UserAgent; 1;"
          or die "$@\n";
        eval "use XML::LibXML; 1;"
          or die "$@\n";
        eval "use MOBY::Async::WSRF; 1;"
          or die "$@\n";
        eval "use MOBY::Async::LSAE; 1;"
          or die "$@\n";
    } else {

        # calling a local service module, without SOAP
        eval "use MOSES::MOBY::Base; 1;";

        # take the lib location from the config file
        require lib;
        lib->import( MOSES::MOBY::Config->param("generators.impl.outdir") );
        require lib;
        lib->import( MOSES::MOBY::Config->param("generators.outdir") );
        unshift( @INC, $opt_l ) if $opt_l;
        $LOG->level('INFO')  if $opt_v;
        $LOG->level('DEBUG') if $opt_d;
    }

    # load these modules always to get constants and to avoid warnings
    eval "use MOBY::Async::LSAE; 1;"
      or die "$@\n";
    eval "use MOBY::Async::WSRF; 1;"
      or die "$@\n";
}
use strict;

sub _empty_input {
    return <<'END_OF_XML';
<?xml version="1.0" encoding="UTF-8"?>
<moby:MOBY xmlns:moby="http://www.biomoby.org/moby">
  <moby:mobyContent>
    <moby:mobyData moby:queryID="job_0"/>
  </moby:mobyContent>
</moby:MOBY>
END_OF_XML
}

sub _check_status {
    my ( $status, $completed, $queryID, $opt_v ) = @_;
    if ( $status->type == LSAE_PERCENT_PROGRESS_EVENT ) {
        print "Current percentage for job $queryID: ", $status->percentage, "\n"
          if $opt_v;
        if ( $status->percentage >= 100 ) {
            $completed->{$queryID} = 1;
        } elsif ( $status->percentage < 100 ) {
            print "\tmsg: ",
              ( $status->message ? $status->message : "no message found ..." ),
              "\n"
              if $opt_v;

            #sleep(20);
        } else {
            die "ERROR:  analysis event block not well formed.\n";
        }
    } elsif ( $status->type == LSAE_STATE_CHANGED_EVENT ) {
        print "Current state for job $queryID: ", $status->new_state, "\n"
          if $opt_v;
        if (    ( $status->new_state =~ m"completed"i )
             || ( $status->new_state =~ m"terminated_by_request"i )
             || ( $status->new_state =~ m"terminated_by_error"i ) )
        {
            $completed->{$queryID} = 1;
        } elsif (    ( $status->new_state =~ m"created"i )
                  || ( $status->new_state =~ m"running"i ) )
        {
            print "\tmsg: ",
              ( $status->message ? $status->message : "no message found ..." ),
              "\n"
              if $opt_v;

            #sleep(20);
        } else {
            die "ERROR:  analysis event block not well formed.\n";
        }
    } elsif ( $status->type == LSAE_STEP_PROGRESS_EVENT ) {
        print "Steps completed for job $queryID: ", $status->steps_completed,
          "\n"
          if $opt_v;
        if ( $status->steps_completed >= $status->total_steps ) {
            $completed->{$queryID} = 1;
        } elsif ( $status->steps_completed < $status->total_steps ) {
            print "\tmsg: ",
              ( $status->message ? $status->message : "no message found ..." ),
              "\n"
              if $opt_v;

            #sleep(20);
        } else {
            die "ERROR:  analysis event block not well formed.\n";
        }
    } elsif ( $status->type == LSAE_TIME_PROGRESS_EVENT ) {
        print "Time remaining for job $queryID: ", $status->remaining, "\n"
          if $opt_v;
        if ( $status->remaining == 0 ) {
            $completed->{$queryID} = 1;
        } elsif ( $status->remaining > 0 ) {
            print "\tmsg: ",
              ( $status->message ? $status->message : "no message found ..." ),
              "\n"
              if $opt_v;

            #sleep(20);
        } else {
            die "ERROR:  analysis event block not well formed.\n";
        }
    } else {
        warn
"Whilst checking the status of our resource, we entered into a possible infinite loop ...\n";
    }
}

sub _get_query_ids {
    my $input     = shift;
    my @query_ids = ();
    my $parser    = XML::LibXML->new();
    my $doc       = $parser->parse_string($input);
    my $iterator  = $doc->getElementsByLocalName("mobyData");
    for ( 1 .. $iterator->size() ) {
        my $node = $iterator->get_node($_);
        my $id   = $node->getAttribute("queryID")
          || $node->getAttribute(
                 $node->lookupNamespacePrefix($WSRF::Constants::MOBY_MESSAGE_NS)
                   . ":queryID" );
        push @query_ids, $id;
    }
    return @query_ids;
}

# --- what service to call
my $module = shift
  unless $opt_c
      or $opt_C;    # eg. Service::Mabuhay, or just Mabuhay
my $service;
( $service = $module ) =~ s/.*::// unless $opt_c or $opt_C;

# --- call the service
if ($opt_e) {

    # calling a real service, using SOAP
    my $soap = SOAP::Lite->uri("http://biomoby.org/")->proxy($opt_e)->on_fault(
        sub {
            my $soap = shift;
            my $res  = shift;
            my $msg =
              ref $res
              ? "--- SOAP FAULT ---\n"
              . $res->faultcode . " "
              . $res->faultstring
              : "--- TRANSPORT ERROR ---\n"
              . $soap->transport->status
              . "\n$res\n";
            die $msg;
        }
    );
    my $input = '';
    if ( @ARGV > 0 ) {
        my $data = shift;    # a file name
        open INPUT, "<$data"
          or die "Cannot read '$data': $!\n";
        while (<INPUT>) { $input .= $_; }
        close INPUT;
    } else {
        $input = _empty_input;
    }
    print $soap ->$service( SOAP::Data->type( 'string' => "$input" ) )->result;
} elsif ($opt_c) {

    # calling a real service, using cgi
    my $ua    = LWP::UserAgent->new;
    my $input = '';
    if ( @ARGV > 0 ) {
        my $data = shift;    # a file name
        open INPUT, "<$data"
          or die "Cannot read '$data': $!\n";
        while (<INPUT>) { $input .= $_; }
        close INPUT;
    } else {
        $input = _empty_input;
    }
    my $req = HTTP::Request->new( POST => $opt_c );
    $req->content_type('application/x-www-form-urlencoded');
    $req->content("data=$input");
    print "\n" . $ua->request($req)->as_string . "\n";
} elsif ($opt_C) {
    my $input = '';
    if ( @ARGV > 0 ) {
        my $data = shift;    # a file name
        open INPUT, "<$data"
          or die "Cannot read '$data': $!\n";
        while (<INPUT>) { $input .= $_; }
        close INPUT;
    } else {
        $input = _empty_input;
    }

    # extract all of the query ids from $input
    my @query_ids = _get_query_ids($input);
    my %completed = ();
    print "Sending the following data to $opt_C\n$input\n";

    # post to the web service
    my $ua = LWP::UserAgent->new;
    my $req = HTTP::Request->new( POST => $opt_C );
    $req->content_type('text/xml');
    $req->content("$input");

    # get the response
    my $response = $ua->request($req);

    # do we have an error?
    die "Error calling service: " . $response->status_line
      if ( $response->code != 200 );
    my $epr    = $response->header("moby-wsrf");
    my $parser = XML::LibXML->new();
    my $doc    = $parser->parse_string($epr);
    my $ID =
      $doc->getElementsByLocalName("ServiceInvocationId")->get_node(1)
      ->textContent;
    $ID =~ s/ //gi;
    my $searchTerm = "";
    $searchTerm .=
"<wsrf-rp:GetMultipleResourceProperties xmlns:wsrf-rp='$WSRF::Constants::WSRP' xmlns:mobyws='$WSRF::Constants::MOBY'>";

    foreach my $queryID (@query_ids) {
        $searchTerm .=
            "<wsrf-rp:ResourceProperty>mobyws:status_" 
          . $queryID
          . "</wsrf-rp:ResourceProperty>";
    }
    $searchTerm .= "</wsrf-rp:GetMultipleResourceProperties>";
    my $header = _moby_wsrf_header( $opt_C, $ID );
    $header =~ s/\n//gi;

    # poll
    while (1) {

#
# Poll the service for the status of all query IDs associated with this service invocation.
#
        $req = HTTP::Request->new( POST => $opt_C . "/status" );
        $req->header( "moby-wsrf" => $header );
        $req->content_type('application/x-www-form-urlencoded');
        $req->content("data=$searchTerm");
        $response = $ua->request($req);
        my $xml    = $response->content();
        my $parser = XML::LibXML->new();
        my $doc    = $parser->parse_string($xml);

        foreach my $queryID (@query_ids) {

            # skip poll if current job completed
            next if $completed{$queryID};

           #
           # Find status of this query ID.
           #
           #my $xpath = "//*[local-name() = 'analysis_event'][\@id='$queryID']";
           #my $xpath = "//analysis_event[\@id='$queryID']";
            my $xpath = "//*[local-name() = 'analysis_event'][\@*='$queryID']";
            my $xpc   = XML::LibXML::XPathContext->new();
            my $nodes = $xpc->findnodes( $xpath, $doc->documentElement );

            # should only be one ...
            die
"Service returned unexpected/malformed resource property XML, which should contain service status info."
              unless $nodes->size() == 1;
            my $status =
              LSAE::AnalysisEventBlock->new( $nodes->get_node(1)->toString() );
            &_check_status( $status, \%completed, $queryID, $opt_v );
        }    #end foreach
        last if scalar keys(%completed) == $#query_ids + 1;
        my $interval = 20;
        print "Checking job state again in $interval seconds.\n\n" if $opt_v;
        sleep($interval);
    } #end while(1)
    #last if scalar keys(%completed) == $#query_ids + 1;

    # task is finished, obtain the result
    $searchTerm = "";
    $searchTerm .=
"<wsrf-rp:GetMultipleResourceProperties xmlns:wsrf-rp='$WSRF::Constants::WSRP' xmlns:mobyws='$WSRF::Constants::MOBY'>";
    foreach my $queryID (@query_ids) {
        $searchTerm .=
            "<wsrf-rp:ResourceProperty>mobyws:result_" 
          . $queryID
          . "</wsrf-rp:ResourceProperty>";
    }
    $searchTerm .= "</wsrf-rp:GetMultipleResourceProperties>";
    $header = _moby_wsrf_header( $opt_C, $ID );
    $header =~ s/\n//gi;
    $req = HTTP::Request->new( POST => $opt_C . "/results" );
    $req->header( "moby-wsrf" => $header );
    $req->content_type('application/x-www-form-urlencoded');
    $req->content("data=$searchTerm");
    $response = $ua->request($req);

    # create nicely formatted XML
    $parser = XML::LibXML->new();
    $doc    = $parser->parse_string( $response->content );
    print "\n" . $doc->toString(1);

    # destroy the job
    $searchTerm = '<Destroy xmlns="http://docs.oasis-open.org/wsrf/rl-2"/> ';
    $req = HTTP::Request->new( POST => $opt_C . "/destroy" );
    $req->header( "moby-wsrf" => $header );
    $req->content_type('application/x-www-form-urlencoded');
    $req->content("data=$searchTerm");
    $response = $ua->request($req);
    print "Destroying the resource returned:\n\t" . $response->content . "\n"
      if $opt_v;
} elsif ($opt_a) {

    # calling a real service, using async soap
    # call using async mode for async service ... _submit
    $service .= "_submit";

    # set up the wsrf call
    my $soap = WSRF::Lite->proxy($opt_a)->uri($WSRF::Constants::MOBY)->on_fault(
        sub {
            my $soap = shift;
            my $res  = shift;
            my $msg =
              ref $res
              ? "--- SOAP FAULT ---\n"
              . $res->faultcode . " "
              . $res->faultstring
              : "--- TRANSPORT ERROR ---\n"
              . $soap->transport->status
              . "\n$res\n";
            die $msg;
        }
    );

    # get the input
    my $input = '';
    if ( @ARGV > 0 ) {
        my $data = shift;    # a file name
        open INPUT, "<$data"
          or die "Cannot read '$data': $!\n";
        while (<INPUT>) { $input .= $_; }
        close INPUT;
    } else {
        $input = _empty_input;
    }

    # extract all of the query ids from $input
    my @query_ids = _get_query_ids($input);
    print "\nSending the following data to $service asynchronously:\n", $input,
      "\n"
      if $opt_v;

    # submit the job
    my $epr =
      ( $soap->$service( SOAP::Data->type( 'string' => "$input" ) )->result );

    # Get address from the returned Endpoint Reference
    my $address = $epr->{'EndpointReference'}->{Address};

    # Get resource identifier from the returned Endpoint Reference
    my $identifier =
      $epr->{'EndpointReference'}->{ReferenceParameters}->{ServiceInvocationId};

    # Compose the Endpoint Reference
    my $EPR = WSRF::WS_Address->new();
    $EPR->Address($address);
    $EPR->ReferenceParameters(   '<mobyws:ServiceInvocationId xmlns:mobyws="'
                               . $WSRF::Constants::MOBY . '">'
                               . $identifier
                               . '</mobyws:ServiceInvocationId>' );
    my %completed = ();
    while (1) {
        foreach my $queryID (@query_ids) {

            # skip poll if current job completed
            next if $completed{$queryID};

            # poll the service for given query ID
            my $searchTerm = "";
            $searchTerm .=
"<wsrp:ResourceProperty xmlns:wsrp='$WSRF::Constants::WSRP' xmlns:mobyws='$WSRF::Constants::MOBY'>";
            $searchTerm .= "mobyws:status_" . $queryID;
            $searchTerm .= "</wsrp:ResourceProperty>";
            $soap = WSRF::Lite->uri($WSRF::Constants::WSRP)->on_action(
                sub {
                    sprintf '%s/%s/%sRequest', $WSRF::Constants::WSRPW, $_[1],
                      $_[1];
                }
              )->wsaddress($EPR)
              ->GetMultipleResourceProperties(
                                  SOAP::Data->value($searchTerm)->type('xml') );
            my $parser = XML::LibXML->new();
            my $xml    = $soap->raw_xml;
            my $doc    = $parser->parse_string($xml);
            $soap = $doc->getDocumentElement();
            my $prop_name = "status_" . $queryID;
            my ($prop) =
              $soap->getElementsByTagNameNS( $WSRF::Constants::MOBY,
                                             $prop_name )
              || $soap->getElementsByTagName($prop_name);
            my $event = $prop->getFirstChild->toString
              unless ref $prop eq "XML::LibXML::NodeList";
            $event = $prop->pop()->getFirstChild->toString
              if ref $prop eq "XML::LibXML::NodeList";
            my $status = LSAE::AnalysisEventBlock->new($event);

            if ( $status->type == LSAE_PERCENT_PROGRESS_EVENT ) {
                if ( $status->percentage >= 100 ) {
                    $completed{$queryID} = 1;
                } elsif ( $status->percentage < 100 ) {
                    print "Current percentage: ", $status->percentage, "\n"
                      if $opt_v;
                    sleep(20);
                } else {
                    die "ERROR:  analysis event block not well formed.\n";
                }
            } elsif ( $status->type == LSAE_STATE_CHANGED_EVENT ) {
                if (    ( $status->new_state =~ m"completed"i )
                     || ( $status->new_state =~ m"terminated_by_request"i )
                     || ( $status->new_state =~ m"terminated_by_error"i ) )
                {
                    $completed{$queryID} = 1;
                } elsif (    ( $status->new_state =~ m"created"i )
                          || ( $status->new_state =~ m"running"i ) )
                {
                    print "Current State: ", $status->new_state, "\n" if $opt_v;
                    sleep(20);
                } else {
                    die "ERROR:  analysis event block not well formed.\n";
                }
            } elsif ( $status->type == LSAE_STEP_PROGRESS_EVENT ) {
                if ( $status->steps_completed >= $status->total_steps ) {
                    $completed{$queryID} = 1;
                } elsif ( $status->steps_completed < $status->total_steps ) {
                    print "Steps completed: ", $status->steps_completed, "\n"
                      if $opt_v;
                    sleep(20);
                } else {
                    die "ERROR:  analysis event block not well formed.\n";
                }
            } elsif ( $status->type == LSAE_TIME_PROGRESS_EVENT ) {
                if ( $status->remaining == 0 ) {
                    $completed{$queryID} = 1;
                } elsif ( $status->remaining > 0 ) {
                    print "Time remaining: ", $status->remaining, "\n"
                      if $opt_v;
                    sleep(20);
                } else {
                    die "ERROR:  analysis event block not well formed.\n";
                }
            }
        }
        last if scalar keys(%completed) == $#query_ids + 1;
    }
    foreach my $queryID (@query_ids) {

        # get the result
        my $searchTerm .=
"<wsrp:ResourceProperty xmlns:wsrp='$WSRF::Constants::WSRP' xmlns:mobyws='$WSRF::Constants::MOBY'>";
        $searchTerm .= "mobyws:result_" . $queryID;
        $searchTerm .= "</wsrp:ResourceProperty>";
        my $ans = WSRF::Lite->uri($WSRF::Constants::WSRP)->on_action(
            sub {
                sprintf '%s/%s/%sRequest', $WSRF::Constants::WSRPW, $_[1],
                  $_[1];
            }
          )->wsaddress($EPR)
          ->GetMultipleResourceProperties(
                                  SOAP::Data->value($searchTerm)->type('xml') );
        die "ERROR:  " . $ans->faultstring if ( $ans->fault );
        my $parser = XML::LibXML->new();
        my $xml    = $ans->raw_xml;
        my $doc    = $parser->parse_string($xml);
        $soap = $doc->getDocumentElement();
        my $prop_name = "result_" . $queryID;
        my ($prop) =
             $soap->getElementsByTagNameNS( $WSRF::Constants::MOBY, $prop_name )
          || $soap->getElementsByTagName($prop_name);
        my $result = $prop->getFirstChild->toString
          unless ref $prop eq "XML::LibXML::NodeList";
        $result = $prop->pop()->getFirstChild->toString
          if ref $prop eq "XML::LibXML::NodeList";
        print $result;
    }

    # destroy the result
    my $ans = WSRF::Lite->uri($WSRF::Constants::WSRL)->on_action(
        sub {
            sprintf '%s/ImmediateResourceTermination/%sRequest',
              $WSRF::Constants::WSRLW, $_[1];
        }
    )->wsaddress($EPR)->Destroy();
} else {

    # calling a local service module, without SOAP
    my $data;
    if ( @ARGV > 0 ) {
        $data = shift;    # a file name
    } else {
        use File::Temp qw( tempfile );
        my $fh;
        ( $fh, $data ) = tempfile( UNLINK => 1 );
        print $fh _empty_input();
        close $fh;
    }
    eval "require $module" or croak $@;
    eval {
        my $target = new $module;
        print $target->$service($data), "\n";
    } or croak $@;
}

sub _moby_wsrf_header {
    my ( $url, $id ) = @_;
    return <<"END OF XML";
<moby-wsrf>
<wsa:Action xmlns:wsa="http://www.w3.org/2005/08/addressing">http://docs.oasis-open.org/wsrf/rpw-2/GetMultipleResourceProperties/GetMultipleResourcePropertiesRequest</wsa:Action>
<wsa:To xmlns:wsu="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd" xmlns:wsa="http://www.w3.org/2005/08/addressing" wsu:Id="To">$url</wsa:To>
<mobyws:ServiceInvocationId xmlns:mobyws="http://biomoby.org/" xmlns:wsa="http://www.w3.org/2005/08/addressing" wsa:IsReferenceParameter="true">$id</mobyws:ServiceInvocationId>
</moby-wsrf>
END OF XML
}
__END__
