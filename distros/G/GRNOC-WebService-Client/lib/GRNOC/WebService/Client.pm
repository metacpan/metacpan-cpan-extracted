#--------------------------------------------------------------------
#----- GRNOC Web Service Client
#-----
#----- Copyright(C) 2015 The Trustees of Indiana University
#--------------------------------------------------------------------
#----- module for interacting with cosign protected grnoc web services
#---------------------------------------------------------------------

package GRNOC::WebService::Client;

use strict;
use warnings;

use GRNOC::WebService::Client::Paginator;
use HTTP::Cookies;
use HTML::Form;
use LWP::UserAgent::Determined;
use Carp qw(longmess shortmess);
use CGI;
use JSON::XS;
use Data::Dumper;
use GRNOC::Config;
use Time::HiRes qw(gettimeofday tv_interval);
use File::MMagic;
use HTTP::Request::Common;
use Fcntl qw(:flock);
use List::Util;
use Storable 'dclone';
use XML::LibXML;

$HTTP::Request::Common::DYNAMIC_FILE_UPLOAD = 1;

our $VERSION = '1.5.1';

use constant DEFAULT_LIMIT => 1000;
use constant CONTENT_PAOS => 'application/vnd.paos+xml';
use constant PAOS_HEADER => 'ver="urn:liberty:paos:2003-08";"urn:oasis:names:tc:SAML:2.0:profiles:SSO:ecp"';

=head1 NAME

    GRNOC::WebService::Client - GlobalNOC Web Service Client

=head1 SYNOPSIS

    Module to implement clients that interact with cosign protected GRNOC CDS web services.
    Default Method is GET but POST can be used as well.

    Quick summary of what the module does.

    Perhaps a little code snippet.

    use GRNOC::WebService::Client;

    my $svc = GRNOC::WebService::Client->new(
        url => "https://sherpa.grnoc.iu.edu/web-service/foobar/example.cgi",
        uid => "test_uid",
        passwd  => $password,
        realm => 'Authentication Required', # needed for HTTP basic auth
        usePost => 0,
        debug => 0
    );

    #--- get list of available methods
    my $res= $svc->help();

    if(!defined $res){
        print Dumper($svc->get_error());
    }
    else{
        print Dumper($res);
    }


    #-- get help for specific method
    my $res= $svc->help(method_name => 'echo');

    if(!defined $res){
        print Dumper($svc->get_error());
    }
    else{
        print Dumper($res);
    }


    #--- call a web service method
    my $res= $svc->echo(data => 'This is a test');

    if(!defined $res){
        print Dumper($svc->get_error());
    }
    else{
        print Dumper($res);
    }

    ...

=cut

#--- used do service name lookups, this is the place to support multiple / redundange service name services
sub _service_lookup {
    my $self    = shift;
    my $service_name  = shift;

    return $self->{'service_urls'}{$service_name};

}

#--- return one of the urls assocated with a service,  this is the place to let us randomly pick from multiple and to in
#--- recover from service instance outage
sub _setup_urls {
    my $self    = shift;
    my $service_name  = shift;

    my $res   = $self->_service_lookup($service_name);

    my $count = 0;

    if (defined $res) {
        my @sorted_by_weight = sort {$a->{'weight'} <=> $b->{'weight'}} @$res;

        foreach my $location (@sorted_by_weight) {

            my $url    = $location->{'url'};
            my $weight = $location->{'weight'};
            push(@{$self->{'urls'}{$weight}},$url);
            $count++;
        }

    }

    if ($self->{'debug'}) {
        warn "_setup_urls: found $count urls for service $service_name\n";
    }

    return $count;
}

#--- loads the default realm from the config file
sub _load_default_realm {
    
    my $self =  shift;
    
    my $config_file = $self->{'config_file'};
    my $username    = $self->{'uid'};

    #--- get the config
    my $config = GRNOC::Config->new(config_file => $config_file,
                                    force_array => 1);

    if (!defined $config) {
        $self->_set_error("unable to open $config_file: $!\n");
        return;
    }
    
    my $user_realm_mappings = $config->get('/config/match');
    
    foreach my $user_realm_mapping ( @$user_realm_mappings ) {
        
        if( $username =~ $user_realm_mapping->{'regex'} ){
            $self->{'default_realm'} = $user_realm_mapping->{'realm'};
            last;
        }
    }

    return 1;
}


#-- this loads config which contains the nameserver urls, basically bootstrapping.
sub _load_config {
    my $self    = shift;

    #----- get the config
    my $config_file = $self->{'service_cache_file'};

    my $cfg = GRNOC::Config->new(config_file => $config_file);

    if (!defined $cfg) {
        $self->_set_error("unable to open $config_file: $!\n");
        return undef;
    }

    #--- clean out any previous urls
    $self->{'service_urls'} = undef;

    my $clouds = $cfg->get("/config/cloud");

    foreach my $cloud (@$clouds) {

        my $cloud_id = $cloud->{'id'};
        my @classes  = keys %{$cloud->{'class'}};

        foreach my $class_id (@classes) {

            my $versions = $cloud->{'class'}->{$class_id}->{'version'};

            foreach my $version (@$versions) {

                my $version_number = $version->{'value'};
                my @services = keys %{$version->{'service'}};

                foreach my $service_name (@services) {

                    my @locations    = @{$version->{'service'}->{$service_name}->{'location'}};

                    foreach my $location (@locations) {

                        my $weight = $location->{'weight'};
                        my $url    = $location->{'url'};

                        my $full_name = "urn:publicid:IDN+grnoc.iu.edu:" . $cloud_id . ":" . $class_id . ":" . $version_number . ":" . $service_name;
                        push(@{$self->{'service_urls'}{$full_name}}, {'weight' => $weight,
                                                                      'url'    => $url});

                    }
                }
            }
        }
    }

    return 1;
}

sub _ns_service_lookup {

    my $self = shift;
    my $service_name = $self->{'service_name'};
    for my $url (@{$self->{'name_services'}}) {

        if ($self->{'debug'}) {
            warn "trying to lookup $service_name using: $url\n";
        }
        my $ns = GRNOC::WebService::Client->new(
            url     => $url,
            uid     => $self->{'uid'},
            passwd  => $self->{'passwd'},
            debug   => $self->{'debug'},
            );

        my $res =  $ns->get_locations_by_urn(urn => $service_name);

        $self->{'service_urls'}{$self->{'service_name'}} = $res->{'results'};
    }
}

#--protected method which sets a new error and prints it to stderr

sub _set_error {

    my $self        = shift;
    my $error       = shift;

    if ($self->{'debug'}) {
        #--- printing out full stack trace might reveal passwords to the constructor
        #--- so we should only drop the stack trace in debug
        $self->{'error'} = Carp::longmess("$0 $error");
    }
    else {
        $self->{'error'} = Carp::shortmess("$0 $error");
    }

    if ($self->{'debug'}){
        warn $self->{'error'};
    }

}

sub _redirect_timing {
    my $self = shift;

    return sub {
        my ($response, $ua, $h) = @_;

        if ($self->{'timing'} && $response->header("location")){
            $self->_do_timing("Redirect to " . $response->header("location"));
        }

	return;
    }
}

sub _do_timing {
    my $self    = shift;
    my $message = shift;

    my $timestamp = [gettimeofday];
    my $elapsed   = tv_interval($self->{'start_time'}, $timestamp);
    my $diff;

    if ($self->{'last_timestamp'}){
        $diff = tv_interval($self->{'last_timestamp'}, $timestamp);
    }

    $self->{'last_timestamp'} = $timestamp;

    my $str = "$message ... elapsed time = $elapsed seconds";

    if ($diff){
        $str .= " (+ $diff)";
    }

    print $str . "\n";
}


#--- protected method used to get content. Can traverse cosign, basic auth, and unprotected
#--- resources transparently.
sub _fetch_url {

    my $self        = shift;
    my $request     = shift;      #--- reference to HTTP::Request object
    my $username    = $self->{'uid'};
    my $passwd      = $self->{'passwd'};
    my $realm       = $self->{'realm'};
    my $cookieJar   = $self->{'cookieJar'};
    my $ua          = $self->{'ua'};

    #--- if we did not pass realm explicitly
    #--- use realm from the config file
    if( !defined( $self->{'realm'} )) {
        $self->{'realm'} = $self->{'default_realm'};
    }

    #--- set credentials for basic auth if given
    #--- this does not use LWP::UserAgent->credentials because that appears to do two requests
    #--- because it won't send credentials until it gets challenged, so we set the creds
    #--- directly on the request
    if (defined $self->{'uid'} && defined $self->{'passwd'} && defined $self->{'realm'}){
      # --- Is this a Shibboleth ECP realm?
      if ($self->{'realm'} =~ m|^https://|){
        # Then set PAOS accept/header to tell SP we want to ECP
        $request->header('Accept' => "*/*; @{[CONTENT_PAOS]}");
        $request->header('PAOS' => PAOS_HEADER);
      }
      else {
        # Otherwise do basic auth
        $request->authorization_basic($self->{'uid'}, $self->{'passwd'});
      }

    }

    if ($self->{"timing"}) {
        $self->{'start_time'}     = [gettimeofday];
        $self->{'last_timestamp'} = undef;
        print "Request is initiated...\n";
    }

    my $timed_out = 0; #timeout check for $request
    local $SIG{ALRM} = sub {
        #request has timed out
        $timed_out = 1;
    };
    if(defined $self->{'timeout'}){
        #if timeout is defined
        alarm $self->{'timeout'};
    }
    else{
        # don't alarm
        alarm 0;
    }
    #--- get the initial URL
    my $result = $ua->request($request);
    alarm 0;
    if($timed_out){
        #Request timed out--->alarm
        $self->_set_error("Request timeout.." . $request->uri());
        return undef;
    }
    if ($result->is_success && !defined($result->header('x-died'))){

        my $content = $result->content;

        #--- We're at cosign
        if ($content =~ /<form action=\".*cosign-bin\/cosign\.cgi/mi){
          return $self->_do_cosign_login($request, $content, $result);

        }
        #--- We're at Shib ECP
        elsif (defined($result->header('content-type')) && $result->header('content-type') eq CONTENT_PAOS) {
          return $self->_do_ecp_login($request, $content);
        }
        #--- We're not at cosign or doing ECP login, this must be the final result.
        else {
            if ($self->{"timing"}) {
                $self->_do_timing("Success");
            }

            $self->{'content_type'} = $result->header('content-type');
            $self->{'headers'}      = $self->_parse_headers($result);

            return $content;
        }
    }
    #--- Failure
    else {
        if ($self->{"timing"}) {
            $self->_do_timing("Failed");
        }

	my $error = $result->header('x-died') || $result->message;

        $self->_set_error("HTTP Error: $error : " . $request->uri());
        return undef;
    }

}

sub _do_cosign_login {
    my $self      = shift;
    my $request   = shift;
    my $content   = shift;
    my $result    = shift;
    my $username  = $self->{'uid'};
    my $passwd    = $self->{'passwd'};
    my $ua        = $self->{'ua'};
    my $timed_out = 0;

    if ($self->{timing}) {
        $self->_do_timing("Request is redirected to Cosign");
    }

    my $form = HTML::Form->parse($content, $result->base());

    if (!defined $form) {
        $self->_set_error("Redirected to something I can't parse:\n" . $content . "\n");
        return undef;
    }

    #--- fill out login parameters
    $form->value("login",$username);
    $form->value("password",$passwd);
    my $request2 = $form->click;
    local $SIG{ALRM} = sub {
        #request2 timed out
        $timed_out = 1;
    };
    if(defined $self->{'timeout'}){
        alarm $self->{'timeout'};
    }
    else{
        alarm 0;
    }
    #--- submit form
    my $result2 = $ua->request($request2);
    alarm 0;
    if($timed_out){
        #request2 timed out----> alarm
        $self->_set_error("Request timeout while authing to cosign.." . $request2->uri());
        return undef;
    }
    if ($self->{"timing"}) {
        $self->_do_timing("Sent credentials to Cosign");
    }

    #--- Got another 200 back
    if ($result2->is_success && !defined($result2->header('x-died'))){

        my $content2 = $result2->content;

        #--- Are we back at Cosign? If so, we're unauthorized.
        if ($content2 =~ /<form action=\".*cosign-bin\/cosign\.cgi\"/mi){
            $self->_set_error( "Error: Authorization failed for: " . $request->uri());
            return undef;
        }

        #--- Otherwise we're good, return content
        $self->{'content_type'} = $result2->header('content-type');
        $self->{'headers'}      = $self->_parse_headers($result2);

        return $content2;
    }
    else {
        #--- Something went wrong in getting the final url after cosign auth succeeded
        my $error = $result2->header('x-died') || $result2->message;
        $self->_set_error("HTTP Error after logging into Cosign: $error");
        return undef;
    }
}

#-- helper for handling Shib ECP login
sub _do_ecp_login {
    my $self    = shift;
    my $request = shift;
    my $content = shift;

    my $ua        = $self->{'ua'};
    my $timed_out = 0;

    if ($self->{timing}) {
        $self->_do_timing("Request is wanting ECP login");
    }
    my $doc;
    # Convert ECP response to what we send to IdP
    eval{$doc = $self->{'xmlparser'}->parse_string($content);};
    if ($@) {
        $self->_set_error("Unable to parse ECP XML: " . $@);
        return undef;
    }

    my @tmp = $self->{'xpath'}->findnodes('//S:Envelope/S:Header/ecp:RelayState', $doc);
    if (!(scalar @tmp == 1)) {
        $self->_set_error("Unable to find RelayState");
        return undef;
    }
    my $relaystate = $tmp[0];

    my $responseconsumer = $self->{'xpath'}->findvalue('//S:Envelope/S:Header/paos:Request/@responseConsumerURL', $doc);

    @tmp = $self->{'xpath'}->findnodes('//S:Envelope', $doc);
    if (!(scalar @tmp == 1)) {
        $self->_set_error("Unable to find Envelope");
        return undef;
    }
    my $envelope = $tmp[0];
    @tmp = $self->{'xpath'}->findnodes('//S:Envelope/S:Header', $doc);
    if (!(scalar @tmp == 1)) {
        $self->_set_error("Unable to find Header");
        return undef;
    }
    my $header = $tmp[0];
    $envelope->removeChild($header);

    my $idpreq = HTTP::Request::Common::POST($self->{'realm'},
        Content_Type => 'text/xml',
        Content      => $doc->toStringC14N);
    # Add basic auth to request
    $idpreq->authorization_basic($self->{'uid'}, $self->{'passwd'});
    # Launch request
    local $SIG{ALRM} = sub {
        #request2 timed out
        $timed_out = 1;
    };
    if(defined $self->{'timeout'}){
        alarm $self->{'timeout'};
    }
    else{
        alarm 0;
    }
    my $idpres = $ua->request($idpreq);
    alarm 0;
    if($timed_out){
        #request2 timed out----> alarm
        $self->_set_error("Request timeout while authing to IdP.." . $idpreq->uri());
        return undef;
    }

    $content = $idpres->content;
    my $doc2;
    eval{$doc2 = $self->{'xmlparser'}->parse_string($content);};
    if ($@) {
        $self->_set_error("Unable to parse IdP XML: " . $@);
        return undef;
    }

    my $loginstatus = $self->{'xpath'}->findvalue('//S:Envelope/S:Body/saml2p:Response/saml2p:Status/saml2p:StatusCode/@Value', $doc2);

    if (!defined($loginstatus) || $loginstatus ne 'urn:oasis:names:tc:SAML:2.0:status:Success') {
        $self->_set_error("Authentication failed.");
        return undef;
    }
    # Check for Error

    my $idpresponseconsumer = $self->{'xpath'}->findvalue('//S:Envelope/S:Header/ecp:Response/@AssertionConsumerServiceURL', $doc2);
    if ($idpresponseconsumer ne $responseconsumer) {
        $self->_set_error("ACS from SP ($responseconsumer) does not match ACS from IdP ($idpresponseconsumer). Something bad happened.");
        return undef;
    }
    @tmp = $self->{'xpath'}->findnodes('//S:Envelope/S:Header', $doc2);
    if (!(scalar @tmp == 1)) {
        $self->_set_error("Unable to find Header");
        return undef;
    }
    my $SOAPHeader = $tmp[0];

    $SOAPHeader->removeChildNodes();
    $SOAPHeader->appendChild($relaystate);

    # Send back to SP
    my $spreq = HTTP::Request::Common::POST($responseconsumer,
        Content_Type => CONTENT_PAOS,
        Content      => $doc2->toStringC14N);
    local $SIG{ALRM} = sub {
        #request2 timed out
        $timed_out = 1;
    };
    if(defined $self->{'timeout'}){
        alarm $self->{'timeout'};
    }
    else{
        alarm 0;
    }
    my $spres = $ua->request($spreq);
    alarm 0;
    if($timed_out){
        #request2 timed out----> alarm
        $self->_set_error("Request timeout while returning to SP.." . $idpreq->uri());
        return undef;
    }
    if ($self->{timing}) {
        $self->_do_timing("Returned to SP");
    }
    #--- Got another 200 back
    if ($spres->is_success && !defined($spres->header('x-died'))){

        my $spcontent = $spres->content;

        $self->{'content_type'} = $spres->header('content-type');
        $self->{'headers'}      = $self->_parse_headers($spres);

        return $spcontent;
    }
    else {
        if ($self->{"timing"}) {
            $self->_do_timing("Failed");
        }
	my $error = $spres->header('x-died') || $spres->message;
        $self->_set_error("HTTP Error: $error : " . $request->uri());
        return undef;
    }
}

#--- utility to extract all the header name/values from the response
sub _parse_headers {
    my $self     = shift;
    my $response = shift;

    my @header_names = $response->header_field_names;

    my @headers;

    foreach my $name (@header_names){
        my $value = $response->header($name);
        push(@headers, {name => $name, value => $value});
    }

    return \@headers;
}

#--- Used to bind remote web services methods to local object.

sub AUTOLOAD {
    my $self = shift;

    #--- figure out the callled method
    my $name = our $AUTOLOAD;
    my @stuff = split('::',$name);
    $name = pop(@stuff);

    # clear error from last call
    $self->{'error'} = undef;

    #---- figure out retries and retry interval
    my $retries = $self->{'retries'};
    my $retry_interval= $self->{'retry_interval'};
    my $retry_string;

    #---- ("3,3,3") : retry 3 times with 3 secs interval for each request
    if ( $retries > 0 ){
        $retry_string = join(",", ("$retry_interval") x $retries );

        #set the number of retires with retry interval for each
        $self->{'ua'}->timing( $retry_string );
    }
    else{
        #if no retries, do not set retry interval
        $self->{'ua'}->timing("");
    }

    #--- set up the parameters
    my $params = {
        @_
    };

    # did they specify a limit/offset parameter?
    my $limit = $params->{'limit'} || DEFAULT_LIMIT;
    my $offset = $params->{'offset'} || 0;

    # if pagination is enabled, just return a new paginator object instead
    if ( $self->{'use_pagination'} ) {

        return GRNOC::WebService::Client::Paginator->new( websvc => $self,
                                                          limit  => $limit,
                                                          offset => $offset,
                                                          method => $name,
                                                          params => $params );
    }

    if (defined $params->{$self->{'method_parameter'}}) {
        $self->_set_error($self->{'method_parameter'} . " is a reserved parameter name\n");
        return;
    }

    $params->{$self->{'method_parameter'}} = $name;

    my $action = "GET";

    if ($self->{'usePost'}) {
        $action = "POST";
    }

    # set each undef value to empty string
    my @keys = keys( %$params );

    foreach my $key ( @keys ) {

        my $values = $params->{$key};

        # handle single scalar value
        if ( !ref( $values ) ) {

            $params->{$key} = "" if ( !defined( $values ) );
        }

        # handle arrayref of values
        elsif ( ref( $values ) eq 'ARRAY' ) {

            foreach my $value ( @$values ) {

                $value = "" if ( !defined( $value ) );
            }
        }
    }

    if (!defined $self->{'urls'}) {
        #--- no valid urls found
        return;
    }

    foreach my $weight (sort {$a <=> $b} keys %{$self->{'urls'}}) {

        my @urls = @{$self->{'urls'}{$weight}};

        # If we have more than one URL randomly reorder them so that we
        # get some equal cost RR effect
        @urls = List::Util::shuffle(@urls) if (@urls > 1);

        foreach my $base (@urls){

            #--- iterate through the list of urls, this will obey
            #--- cost and provide reundancy
            if ($self->{'debug'}) {
                warn "attempting to retrieve: $base as $action request: ".Dumper($params);
            }

            my $req;

            if ($action eq "POST") {
                #--- ok this royally sucks we need to at some point further optimize this
                #--- cosign breaks if you just sent a post first time without a cookie
                my $hack =  HTTP::Request->new();
                $hack->uri($base."?method=help");
                $hack->method("GET");
                $self->_fetch_url($hack);

                my @arr;

                foreach my $key (@keys){
                    next if (! $key);

                    my $val = $params->{$key};

                    # Since some arguments might come through as arrays (ie multiple values) and some as
                    # single values, treat everything as an array to simplify code
                    if (ref($val) ne 'ARRAY'){
                        $val = [$val];
                    }

                    foreach my $value (@$val){

                        # is this a special object?
                        if (ref($value) eq "HASH"){
                            if ($value->{'type'} eq "file"){
                                my $filename = $value->{'path'};

                                my @datum = ($filename);

                                # If we're specifying a name other than the filename, use that
                                my $name = $value->{'name'} || undef;
                                push(@datum, $name);

                                # Figure out mimetype either based on what we're told or by guessing
                                # on the file
                                my $mime_type;

                                if (exists $value->{'mime_type'}){
                                    $mime_type = $value->{'mime_type'};
                                }
                                else{
                                    my $mm = new File::MMagic;
                                    $mime_type = $mm->checktype_filename($filename);
                                }

                                push(@datum, Content_Type => $mime_type);

                                push(@arr, $key => \@datum);
                            }
                            else {
                                $self->_set_error("Unknow type $value->{'type'}");
                                return;
                            }
                        }
                        # otherwise just push it onto the form data fields
                        else{
                            push(@arr, $key => $value);
                        }
                    }
                }

                # Make our request as a POST
                $req = HTTP::Request::Common::POST($base,
                                                   Content_Type => 'form-data',
                                                   Content      => \@arr);
            }
            elsif ($action eq "GET") {
                my $query       = new CGI($params);
                my $query_str   = $query->query_string();
                $req = HTTP::Request->new(GET => $base . "?" . $query_str);
            }

            my $res = $self->_fetch_url($req);

            #--- we have a successful result
            if (defined $res) {

                #--- in the event of a successful response, automatically save the cookies.
                #--- HTTP::Cookies has this behavior but when we implemented our own save_cookies
                #--- with flock support this behavior changed. This re-adds it using our mechanism
                $self->save_cookies();

                #--- if user has asked for raw output, just return it exactly as we got it
                #--- can't do error detection here
                if ($self->{'raw_output'}) {
                    return $res;
                }

                #--- default is to return json hash
                # <editorialize>
                # @#$*(@#$%($% library functions should always return unless there
                # is a hardware fault or the end of the world(tm) is neigh.
                # JSON:XS doesn't do this. Hence the eval.
                # </editorialize>
                my $str;
                eval { $str = decode_json( $res ) };
                if(! $@)
                {
                    #--- detect an error flag set on the result
                    if (ref($str) eq "HASH" && $str->{'error'} && $self->{'error_callback'}){
                        &{$self->{'error_callback'}}($self, $res);
                    }

                    return( $str );
                }
                else
                {
                    $self->_set_error($@);
                }
            }
        }

    }

    #--- couldn't get a result, call error handler
    if ($self->{'error_callback'}){
        &{$self->{'error_callback'}}($self, undef);
    }

    return undef;
}




=head1 FUNCTIONS

    The list of methods available is dependent upon the web service you have bound to.  Use get_methods() to retrieve
    the list of available methods. Only the methods implemented in the client library are listed here.


=head2 new()

    constructor that takes four named parameters: .

=over

=item url

    the url that directly indentifies a servcie

=cut


=item service_name

    the GlobalNOC service identifier, with this client will consult the service
    naming service to resolve, best URL to use.

=cut

=item service_cache_file

    the location of the service cache file to use on disk (if not specified does direct nameservice queries)

=cut

=item name_services

    array containing the locations of nameservices to use

=cut

=item uid

    user id for authentication

=cut

=item passwd

    user password

=cut

=item timeout

    timeout value in seconds for the connection, if no activity observed in this time period LWP will abort.

=cut

=item usePost

    boolean value for whether or not we are using http POST style or not

=cut

=item use_keep_alive

    boolean value for whether or not to try and use keep_alives

=cut

=item use_pagination

    boolean value for wether or not to use a GRNOC::WebService::Client::Paginator object to iterate through results

=cut

=item user_agent

    string to use as the User-Agent string in request headers, defaults to $0

=cut

=item verify_hostname

    If set to 1 then ssl certs are validated. Set to 0 when working with untrusted or self-signed certs. Defaults to 1.

=cut

=item retry_error_codes

    hash of http error codes to retry the request on if the request fails

=cut

=back

=cut

sub new {

    my $that  = shift;
    my $class =ref($that) || $that;

    my %args = (
        debug          => 0,
        timeout        => 15,
        usePost        => 0,
        use_keep_alive => 1,
        raw_output     => 0,
        timing         => 0,
        user_agent     => $0,
        oldstyle_urls  => 0,
        cookieJar        => undef,
        method_parameter => "method",
        use_pagination   => 0,
        verify_hostname  => 1,
        retry_error_codes => { '408' => 1,
                               '503' => 1,
                               '502' => 1,
                               '500' => 1,
                               '504' => 1},
        config_file    => "/etc/grnoc/webservice_client/config.xml",
        default_realm  => undef,
        @_,
        );


    my $self = \%args;
    bless $self,$class;

    if (!defined $self->{'url'} && defined $self->{'service_name'}) {
        #ISSUE=3454
        my $t0;
        if ($self->{timing}) {
            $t0 = [gettimeofday];
            print "URL is not provided, start looking up the URL to be requested...\n";
        }

        #first check to see if either name_services or service_cache_file
        if (defined($self->{'service_cache_file'})) {
            #--- load the client config
            if (!$self->_load_config()) {
                #--- cant find the config?
                return $self;
            }

            if (! $self->_setup_urls($self->{'service_name'})) {
                #-- no url provided and none resolved from service name
                $self->_set_error("Unable to find a usable URL for URN = " . $self->{'service_name'} . " in cache file \"" . $self->{'service_cache_file'} . "\"\n");
                return $self;
            }

            if ($self->{timing}) {
                my $elapsed = tv_interval ($t0, [gettimeofday]);
                print "Took $elapsed seconds to look up from the config file\n"
            }
        }
        elsif (defined($self->{'name_services'})) {
            # get the NameService locations
            $self->_ns_service_lookup();

            if ($self->{timing}) {
                my $elapsed = tv_interval ($t0, [gettimeofday]);
                print "Took $elapsed seconds to look up from the Name Service\n"
            }

            if (! $self->_setup_urls($self->{'service_name'})) {
                #-- no url provided and none resolved from service name
                $self->_set_error("Unable to find a usable URL for URN = " . $self->{'service_name'} . " in name services: " . Dumper($self->{'name_services'}) . "\n");
                return $self;
            }
        }
        else {
            $self->_set_error("Unable to find a usable URL: Neither name_services or service_cache_file were specified\n");
        }

        #ISSUE=3454
        if ($self->{timing}) {
            print "URLs:\n";
            foreach my $weight (sort {$a <=> $b} keys %{$self->{'urls'}}) {
                foreach my $base (@{$self->{'urls'}{$weight}}) {
                    print "$base\n";
                }
            }
            print "\n";
        }

    }
    else {
        #--- defined url input means we dont do service lookup
        $self->{'urls'}{'0'}[0] = $self->{'url'};
    }

    {
        # In older versions of LWP::UserAgent::Determined the ssl_opts
        # parameter is not defined, and a warning is logged to the
        # command line. Setting $^W to zero surpresses these warnings
        # within this block.
        local ($^W) = 0;

        $self->{'ua'} = LWP::UserAgent::Determined->new(
            agent      => $self->{'user_agent'},
            ssl_opts   => {verify_hostname => $self->{'verify_hostname'}},
            keep_alive => $self->{'use_keep_alive'}
        );
    }

    #---- check to see if we need to use old style urls. This allows us to use web services that don't parse semicolons the same as ampersands.
    if($self->{'oldstyle_urls'}) {
        CGI->import(qw/ -oldstyle_urls /);
    }

    #---- set the timeout
    $self->{'ua'}->timeout($self->{'timeout'});

    #---- cookies to be automatically dealt with
    $self->set_cookie_jar($self->{'cookieJar'});

    #---- turn on auto redirects
    $self->{'ua'}->requests_redirectable(['GET', 'HEAD', 'POST', 'OPTIONS']);

    if ($self->{'timing'}){
        if ($self->{'ua'}->can("add_handler")){
            $self->{'ua'}->add_handler("response_redirect", $self->_redirect_timing());
        }
    }

    #--- verify error handler
    my $callback = $self->{'error_callback'};
    if (defined $callback && (!ref($callback) || ref $callback ne "CODE")){
        $self->{'error_callback'} = undef;
        $self->_set_error("error_callback argument must be a code ref");
    }

    #set retries to 0 initially
    $self->set_retries( 0 );

    #set retry interval to 5s by default
    $self->set_retry_interval( 5 );

    #set the retry http error codes
    my $retry_codes = dclone $self->{'retry_error_codes'};
    $self->{'ua'}->codes_to_determinate( $retry_codes );

    # XML processors for ECP
    $self->{'xmlparser'} = XML::LibXML->new();
    $self->{'xpath'} = XML::LibXML::XPathContext->new();
    $self->{'xpath'}->registerNs('S' => 'http://schemas.xmlsoap.org/soap/envelope/');
    $self->{'xpath'}->registerNs('paos' => 'urn:liberty:paos:2003-08');
    $self->{'xpath'}->registerNs('ecp' => 'urn:oasis:names:tc:SAML:2.0:profiles:SSO:ecp');
    $self->{'xpath'}->registerNs('saml' => 'urn:oasis:names:tc:SAML:2.0:assertion');
    $self->{'xpath'}->registerNs('saml2p' => 'urn:oasis:names:tc:SAML:2.0:protocol');

    #load the default realm from config file             
    $self->_load_default_realm() if( -e $self->{'config_file'} );

    return $self;
}



sub DESTROY{

}



=head2   get_error()

    gets the last error encountered or undef.

=cut

sub get_error{
    my $self        = shift;
    return $self->{'error'};
}

=head2 get_content_type

    Returns the Content-Type header of the last issue request

=cut

sub get_content_type {

    my $self = shift;

    return $self->{'content_type'};
}


=head2 get_headers

    Returns all the headers as an array of objects from the last request

=cut

sub get_headers {
    my $self = shift;

    return $self->{'headers'};
}

=head2 get_retries

    Returns the number of retries

=cut

sub get_retries {

    my $self = shift;

    return $self->{'retries'};

}

=head2 get_retry_interval

    Returns the retry interval in seconds

=cut

sub get_retry_interval {

    my $self = shift;

    return $self->{'retry_interval'};

}

=head2 set_retries

    Sets the number of retries if the initial request fails

=cut

sub set_retries {

    my $self   = shift;
    my $retries = shift;

    if( !defined $retries ){
        return undef;
    }

    $self->{'retries'} = $retries;

    return 1;
}

=head2 get_realm

    Returns the realm set

=cut

sub get_realm {
    
    my $self = shift;
    
    return $self->{'realm'};
    
}

=head2 set_retry_interval

    Sets the retry interval in seconds

=cut

sub set_retry_interval {

    my $self   = shift;
    my $retry_interval = shift;

    if( !defined $retry_interval ){
        return undef;
    }

    $self->{'retry_interval'} = $retry_interval;

    return 1;
}

=head2 set_raw_output

    Disables or enables returning the raw output instead of attempting to decode JSON.  This method
    should be passed 1 to enable raw output and 0 to disable raw output.  Raw output is disabled by
    default--is can also be set by passing the raw_output parameter in the constructor.

=cut

sub set_raw_output {

    my ($self, $raw_output) = @_;

    $self->{'raw_output'} = $raw_output;
}

=head2 set_timeout

    Changes the timeout value in the underlying LWP object. Can only be set by passing timeout in the constructor
    call.

=cut

sub set_timeout {

    my ($self, $timeout) = @_;

    $self->{'timeout'} = $timeout;
    $self->{'ua'}->timeout($timeout);
}

=head2 set_cookie_jar

    Updates the cookie jar associated with the underlying LWP object. This can be passed a string representing
    a file on disk or an HTTP::Cookies object.

=cut

sub set_cookie_jar {
    my ($self, $new_cookies) = @_;

    $self->{'cookieJar'} = $new_cookies;

    #---- if an http::cookies object was passed in then pass it directly to useragent.
    if(defined( $new_cookies ) && ref($new_cookies) eq "HTTP::Cookies"){
        $self->{'ua'}->cookie_jar($new_cookies);
    }
    #---- assume they passed in a string filename for the cookie jar location.
    elsif ( defined( $new_cookies ) ) {

	# make sure we have a stable state while reading cookies in
	my $fh;
	if (-e $new_cookies){
	    if (! open($fh, "<", $new_cookies)){
                $self->_set_error("Couldn't open $new_cookies: $!");
                return;
            }
            if (! flock($fh, LOCK_SH)){
                $self->_set_error("Couldn't share lock cookie file: $!");
                return;
            }
	}

        my $cookie_jar = new HTTP::Cookies(
            file           => $new_cookies,
            autosave       => 0,
            ignore_discard => 1,
            );

        if(! $cookie_jar) {
            $self->_set_error("Unable to create cookie jar: $!");
            return;
        }

        $self->{'ua'}->cookie_jar($cookie_jar);

	if ($fh){
	    $fh->close();
	}
    }

    # use default in-memory cookie jar instead
    else {

        my $cookie_jar = new HTTP::Cookies(
            autosave       => 0,
            ignore_discard => 1,
            );

        if(! $cookie_jar) {
            $self->_set_error("Unable to create cookie jar: $!");
            return;
        }

        $self->{'ua'}->cookie_jar($cookie_jar);
    }

    return 1;
}

=head2 save_cookies

    Method to ask the underlying LWP UserAgent to save any cookies it might have.

=cut

sub save_cookies {
    my $self = shift;

    my $cookie_jar = $self->{'ua'}->cookie_jar;

    if ($cookie_jar && $cookie_jar->{'file'}){

	my $cookie_path = $cookie_jar->{'file'};

	# we can't flock something that doesn't exist so if it doesn't
	# just go ahead and 'touch' the file
	if (! -e $cookie_path){
	    if ( ! open(FH, ">>", $cookie_path)){
                $self->_set_error("Failed to touch new cookie file $cookie_path: $!");
                return;
            }
            close(FH);
	}

	# open the file for read/write so that we don't clobber the contents before
	# we have a chance to flock it
	if (! open(FH, "+<", $cookie_path) ){
            $self->_set_error("Failed to open $cookie_path: $!");
            return;
        }

	if (! flock(FH, LOCK_EX) ){
            $self->_set_error("Failed to flock during save: $!");
            return;
        }

	# Now that we have the filehandle exlusively locked we can
	# blow away the contents without fear that something will read it
	# in the meantime
	seek(FH, 0, 0);
	truncate(FH, 0);

	# taken from the HTTP::Cookies save method, we're implementing a flock
	# friendly version here
	print FH "#LWP-Cookies-1.0\n";
	print FH $cookie_jar->as_string(!$cookie_jar->{ignore_discard});

	# closing the FH releases the flock
	close(FH);
    }

    return 1;
}


=head2 set_url

    interface to change URL of an existing client, useful in stateful mod_perl.
Note: This wipes out any existing URLs that may have been loaded from a service identifier

=cut

sub set_url {
    my $self = shift;
    my $url  = shift;
    my $cost = shift;

    # some defaulting
    $cost = '0' unless $cost;

    $self->{'urls'}{$cost}[0] = $url;

    return 1;
}

=head2 clear_urls

    Wipes out all knowledge the client has about URLs, useful if trying to use one client persistently
    for multiple requests such as the proxy service

=cut

sub clear_urls {
    my $self = shift;

    $self->{'urls'} = undef;
}

=head2 set_service_identifier

    interface to change what service identifier we are using.
Note: This wipes out any existing URLs that may have been loaded from a service identifier

=cut

sub set_service_identifier {

    my $self = shift;
    my $sid  = shift;

    #--- need to clean out old urls first or they could be queried instead of the one we need.
    $self->clear_urls();

    $self->{'service_name'} = $sid;

    # we might have been initialized without a service identifier in which case we wouldn't have
    # any service_urls loaded yet so try to load them if that's the case
    if ($self->{'service_cache_file'})
    {
        if (! $self->_load_config()) {
            $self->_set_error("No service urls found and unable to load config.");
            return undef;
        }

        # figure out what URLs to know about based on the passed in service identifier or bail
        if (! $self->_setup_urls($self->{'service_name'}))
        {
            $self->_set_error("Unable to find a usable URL for URN = " . $self->{'service_name'} . " in service cache file \"" . $self->{'service_cache_file'} . "\"\n");
            return undef;
        }
    }
    elsif (defined($self->{'name_services'}))
    {
        #get the NameService locations
        $self->_ns_service_lookup();

        if (! $self->_setup_urls($self->{'service_name'}))
        {
            #-- no url provided and none resolved from service name
            $self->_set_error("Unable to find a usable URL for URN = " . $self->{'service_name'} . " in name services: " . Dumper($self->{'name_services'}) . "\n");
            return undef;
        }
    }
    else
    {
        $self->_set_error("Unable to find a usable URL: Neither name_services or service_cache_file were specified\n");
        return undef;
    }
    return 1;
}

=head2 set_credentials

    interface to change the username, password, and/or realm of the client

=cut

sub set_credentials {
    my $self = shift;
    my %args = @_;

    $self->{'uid'}    = $args{'uid'} if ($args{'uid'});
    $self->{'realm'}  = $args{'realm'} if ($args{'realm'});
    $self->{'passwd'} = $args{'passwd'} if ($args{'passwd'});

    return 1;
}

=head2 set_cookies

    interface to change cookies of an existing client, useful in stateful mod_perl. Object given must be a HTTP::Cookies object

=cut

sub set_cookies {
    my $self        = shift;
    my $cookies_obj = shift;

    if (!defined $cookies_obj) {
        return undef;
    }

    $self->{'ua'}->cookie_jar($cookies_obj);

    return 1;
}


=head1 AUTHOR

    GRNOC Systems Engineering, C<< <syseng at grnoc.iu.edu> >>

=head1 BUGS

    Please report any bugs or feature requests to C<< <syseng at grnoc.iu.edu> >>





=head1 SUPPORT

    You can find documentation for this module with the perldoc command.

    perldoc GRNOC::WebService::Client


=head1 ACKNOWLEDGEMENTS

=cut

1;
