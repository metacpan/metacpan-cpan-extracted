package HTTP::OAIPMH::Validator;

=head1 NAME

HTTP::OAIPMH::Validator - OAI-PMH validator class

=head1 SYNOPSIS

Validation suite for OAI-PMH data providers that checks for responses
in accord with OAI-PMH v2
L<http://www.openarchives.org/OAI/2.0/openarchivesprotocol.htm>.

Typical use:

  use HTTP::OAIPMH::Validator;
  use Try::Tiny;
  my $val = HTTP::OAIPMH::Validator->new( base_url=>'http://example.com/oai' );
  try {
      $val->run_complete_validation;
  } catch {
      warn "oops, validation didn't run to completion: $!\n";
  };
  print "Validation status of data provider ".$val->base_url." is ".$val->status."\n";

=cut

use strict;

our $VERSION = '1.05';

use base qw(Class::Accessor::Fast);
use Data::UUID;
use Date::Manip;
use HTTP::Request;                # for rendering http queries
use HTTP::Headers;
use HTTP::Request::Common;        # makes POST easier
use HTTP::Status;                 # for checking error codes
use LWP::UserAgent;               # send http requests
use LWP::Protocol::https;         # explicit include so we fail without https support
use URI::Escape;                  # excape special characters
use XML::DOM;
use HTTP::OAIPMH::Log;

=head2 METHODS

=head3 new(%args)

Create new HTTP::OAIPMH::Validator object and initialize counters.

The following instance variables may be set via %args and have read-write
accessors (via L<Class::Accessor::Fast>):

  base_url - base URL of the data provdier being validated
  run_id - UUID identifying the run (will be generated if none supplied)
  protocol_version - protocol version supported
  admin_email - admin email extracted from Identify response
  granularity - datestamp granularity (defaults to 'days', else 'seconds')
  uses_https - set true if the validator sees an https URL at any stage

  debug - set true to add extra debugging output
  log - logging object (usually L<HTTP::OAIPMH::Log>)
  parser - XML DOM parser instance

  identify_response - string of identify response (used for registration record)
  earliest_datestamp - value extracted from earliestDatestamp in Identify response
  namespace_id - if the oai-identifier is used then this records the namespace identifier extracted
  set_names - array of all the set names reported in listSets

  example_record_id - example id used for tests that require a specific identifier
  example_set_spec - example setSpec ("&set=name") used for tests that require a set
  example_metadata_prefix - example metadataPrefix which defaults to 'oai_dc'

=cut

HTTP::OAIPMH::Validator->mk_accessors( qw( base_url protocol_version
    admin_email granularity uses_503 uses_https
    debug parser run_id ua allow_https doc save_all_responses
    response_number http_timeout max_retries max_size
    protocol guidelines
    identify_response earliest_datestamp namespace_id set_names
    example_record_id example_set_spec example_metadata_prefix
    log status
    ) );

sub new {
    my $this=shift;
    my $class=ref($this) || $this;
    my $self={
        'base_url' => undef,
        'protocol_version' => undef,
        # Repository features extracted
        'granularity' => 'days',    # can also be "seconds"
        'uses_503' => 0,            # set true if 503 responses ever used
        'uses_https' => 0,          # set to true if https is ever used
        # Control
        'debug' => 0,
        'parser' => XML::DOM::Parser->new(),
        'run_id' => undef,
        'ua' => undef,
        'allow_https' => 0,         # allow https URIs
        'doc' => undef,             # current parsed xml document
        'save_all_responses' => 0,  # set True to save all HTTP responses
        'response_number' => 1,     # initial response number
        'http_timeout' => 600,
        'max_retries' => 5,         # number of 503's in a row that we will accept
        'max_size' => 100000000,    # max response size in bytes (100MB)
        'protocol' => 'http://www.openarchives.org/OAI/2.0/openarchivesprotocol.htm',   #URL of protocol spec
        'guidelines' => 'http://www.openarchives.org/OAI/2.0/guidelines-repository.htm',  #URL of repository guidelines doc
        # Results
        'namespace_id' => undef,
        'set_names' => [],
        'example_record_id' => undef,
        'example_set_spec' => undef,
        'example_metadata_prefix' => 'oai_dc',
        'log' => HTTP::OAIPMH::Log->new(),
        'status' => 'unknown',
        @_};
    bless($self, $class);
    $self->setup_run_id if (not $self->run_id);
    $self->setup_user_agent if (not $self->ua);
    return($self);
}

=head3 setup_run_id()

Set a UUID for the run_id.

=cut

sub setup_run_id {
    my $self=shift;
    my $ug=Data::UUID->new;
    $self->run_id(lc($ug->to_string($ug->create)));
}

=head3 setup_user_agent()

Setup L<LWP::UserAgent> for the validator.

=cut

sub setup_user_agent {
    my $self=shift;
    my $ua = LWP::UserAgent->new(); # User agent, to render http requests
    $ua->timeout($self->http_timeout);              # give responses 10 minutes
    $ua->max_size($self->max_size);      # size limit ##seems to break http://eprints.soton.ac.uk/perl/oai2 [Simeon/2005-06-06]
    $ua->requests_redirectable([]); # we will do redirects manually
    $ua->agent('OAIPMH_Validator'); # set user agent
    $ua->from('https://groups.google.com/d/forum/oai-pmh');  # set a default From: address -> direct to google group for dicussion
    $self->ua($ua);
}


=head3 abort($msg)

Special purpose "die" routine because tests cannot continue. Logs
failure and then dies.

=cut

sub abort {
    my $self=shift;
    my ($msg)=@_;
    $self->log->fail('ABORT: '.$msg);
    $self->status('FAILED');
    die('ABORT: '.$msg."\n");
}


=head3 run_complete_validation($skip_test_identify)

Run all tests for a complete validation and return true is the data provider passes,
false otherwise. All actions are logged and may be accessed to provide a report
(including warnings that do not indicate failure) after the run.

Arguments:
  $skip_identify - set true to skip the text_identify() step

=cut

sub run_complete_validation {
    my $self=shift;
    my ($skip_identify)=@_;

    $self->response_number(1);
    $self->test_identify unless ($skip_identify);
    $self->test_list_sets;
    $self->test_list_identifiers;

    my $baseURL = $self->base_url;
    my ($formats, $gotDC) = $self->test_list_metadata_formats;

    # If the repository doesn't support oai_dc then this is a failure (because
    # the standard demands it) but see whether we can find another metadataPrefix
    # in order to continue the tests
    if ( $gotDC ) {
        $self->log->pass("Data provider supports oai_dc metadataPrefix");
    } else {
        if ($formats and $formats->getLength()>0) {
            $self->example_metadata_prefix( $formats->item(0)->getFirstChild->getData );
            $self->log->fail("Data provider does not support the simple Dublin Core metadata ".
                             "format with metadataPrefix oai_dc. Tests that require a ".
                             "metadataPrefix to be specified will use '".
                             $self->example_metadata_prefix."'");
        } else {
            $self->log->fail("There are no metadata formats available to use with the GetRecord ".
                             "request. The metadataPrefix ".
                             $self->example_metadata_prefix.
                             " will be used for later tests even though it seems unsupported.");
        }
    }

    my ($dateStamp)=$self->test_get_record($self->example_record_id,$self->example_metadata_prefix);
    $self->test_list_records($dateStamp,$self->example_metadata_prefix);

    # Check responses to erroneous queries
    $self->test_expected_errors($self->example_record_id);

    if ($self->protocol_version eq '2.0') {
        $self->test_expected_v2_errors($self->earliest_datestamp,$self->example_metadata_prefix);
        # As of version 2.0, data providers must support HTTP POST requests
        $self->test_post_requests($self->example_metadata_prefix);
    }
    $self->test_resumption_tokens;

    # Getting here with no failures means that the data provider is compliant
    # (there may be warnings which are not counted in num_fail)
    $self->status( $self->log->num_fail==0 ? 'COMPLIANT' : 'FAILED' );
    return($self->log->num_fail==0);
}


=head3 failures()

Return Markdown summary of failure log entries, along with the appropriate
titles and request details. Will return empty string if there are no
failures in the log.

=cut

sub failures {
    my $self=shift;
    return($self->log->failures());
}


=head3 summary()

Return summary statistics for the validation in Markdown (designed to agree
with conversion to HTML by L<Text::Markdown>).

=cut

sub summary {
    my $self=shift;

    my $sf=($self->log->num_fail>0?'failure':'success');

    my $str="\n## Summary - *$sf*\n\n";
    my $namespace_id = $self->namespace_id;
    if ($namespace_id) {
        if ($namespace_id=~/\./) { #v2.0
            $str.="  * Namespace declared for v2.0 oai-identifiers is $namespace_id\n";
        } else { #v1.1
            $str.="  * Namespace declared for v1.1 oai-identifiers (the repositoryIdentifier) is $namespace_id\n";
        }
    }
    $str.="  * Uses 503 for flow control\n" if ($self->uses_503);
    $str.="  * Uses https URIs (not specified in protocol)\n" if ($self->uses_https);
    $str.="  * Total tests passed: ".$self->log->num_pass."\n";
    $str.="  * Total warnings: ".$self->log->num_warn."\n";
    $str.="  * Total error count: ".$self->log->num_fail."\n";
    $str.="  * Validation status: ".($self->status || 'unknown')."\n";
    return($str);
}


=head2 METHODS TESTING SPECIFIC OAI-PMH VERBS

=head3 test_identify()

Check response to an Identify request. Returns false if tests cannot
continue, true otherwise.

Side effects based on values extracted:

  - $self->admin_email set to email extracted from adminEmail element
  - $self->granularity set to 'days' or 'seconds'

=cut

sub test_identify {
    my $self=shift;

    my $cantContinue=0;
    $self->log->start("Checking Identify response");

    # Send the verb request to the base URL - vet extracts the email address
    my $burl=$self->base_url;
    my $req = $burl."?verb=Identify";

    my $response = $self->make_request($req); #don't use make_request_and_validate() just do simplest thing here
    unless ($response->is_success) {
        my $r="Server at base URL '$burl' failed to respond to Identify. The HTTP GET request with URL $req received response code '".$response->code()."'.";
        if ($response->code() == 301) {
            $self->log->fail("$r HTTP code 301 'Moved Permanently' is not widely supported by ".
                             "harvesters and is anyway inappropriate for registration of a ".
                             "service. If requests must be redirected then an HTTP response 302 ".
                             "may be used as outlined in the guidelines [".
                             $self->guidelines."#LoadBalancing].");
        } else {
            $self->log->fail($r);
        }
        $self->abort("Failed to get Identify response from server at base URL '$burl'.\n");
        return;
    }

    # Parse the XML response
    unless ($self->parse_response($req,$response)) {
        $self->log->fail("Failed to parse Identify response");
        $self->abort("Failed to parse Identify response from server at base URL '$burl'.\n");
    }

    # Check that this really is a Identify response
    my $oaipmhNode=$self->doc->getFirstChild();
    # skip over and processing instructions such as XML stylesheets
    while ($oaipmhNode->getNodeType==PROCESSING_INSTRUCTION_NODE or
           $oaipmhNode->getNodeType==COMMENT_NODE) {
        $oaipmhNode=$oaipmhNode->getNextSibling();
    }
    unless (defined $oaipmhNode and $oaipmhNode->getNodeName eq 'OAI-PMH') {
        $self->log->fail("Identify response does not have OAI-PMH as root element! ".
                         "Found node named '".$oaipmhNode->getNodeName."' instead");
        $self->abort("Identify response from server at base URL '$burl' does not have ".
                     "OAI-PMH as root element!\n");
    }
    my $identifyNode=$oaipmhNode->getElementsByTagName('Identify',0);
    unless ($identifyNode->getLength()>0) {
        my $errorNode=$oaipmhNode->getElementsByTagName('error',0);
        if ($errorNode->getLength()>0) {
            # give specific message if response is and error
            $self->log->fail("Error response to Identify request!\n");
            $self->abort("Error response to Identify request from server at base URL '$burl'.\n");
            return;
        } else {
            $self->log->fail("Identify response does not contain &lt;Identify&gt; block.\n");
            $self->abort("Identify response does not contain Identify block from server at base URL '$burl'.\n");
            return;
        }
    }

    # Extract admin email and protocol version numbers, check
    my ($admin_email,$email_error)=$self->get_admin_email;
    if (not $admin_email or $email_error) {
        $self->abort(($email_error || "Failed to extract adminEmail").", aborting.\n");
        return;
    }
    $self->admin_email($admin_email);
    $self->check_protocol_version; # bails if not Version 2.0

    # URL is valid, Identify response was provided, extract content as string
    $self->identify_response( $response->content );

    my $baseURL = $self->doc->getElementsByTagName('baseURL');

    # BUG FOUND ON AUGUST 26, 2002: empty baseURL still returns length > 0
    # So it is necessary to explicity check for an empty element.
    if ( $baseURL->getLength() > 0 ) {
        $baseURL = $baseURL->item(0)->getFirstChild;
        if ( $baseURL ) { $baseURL = $baseURL->getData; }

        # $burl is the one given on the form; $baseURL is the one in the XML doc.
        if ($burl eq $baseURL) {
            $self->log->pass("baseURL supplied matches the Identify response");
        } else {
            # report the error, but keep the form URL
            # (at least it answered Identify!)
            $self->log->fail("baseURL supplied '$burl' does not match the baseURL in the ".
                             "Identify response '$baseURL'. The baseURL you enter must EXACTLY ".
                             "match the baseURL returned in the Identify response. It must ".
                             "match in case (http://Wibble.org/ does not match http://wibble.org/) ".
                             "and include any trailing slashes etc.");
            $cantContinue++;
        }
    }

    # For Version 2.0, Check for seconds granularity
    if ($self->protocol_version eq '2.0') {
        my $gran_el = $self->doc->getElementsByTagName('granularity');
        if ($self->parse_granularity($gran_el)) {
            $self->log->pass("Datestamp granularity is '".$self->granularity."'");
        } else {
            $cantContinue++;
        }
    }

    # For an exception check new to Version 2.0, extract the earliest date
    # and also check that its granularity is right
    if (my $err=$self->get_earliest_datestamp) {
        $self->log->fail("Bad earliestDatestamp: $err");
        $cantContinue++;
    } else {
        $self->log->pass("Extracted earliestDatestamp ".$self->earliest_datestamp);
    }

    # Check for OAI-identifier.  If already in use by another base URL, bump
    # the error count to avoid having this URL register.
    #
    my $oaiIds = $self->doc->getElementsByTagName('oai-identifier');
    if ($oaiIds and $oaiIds->getLength()>0) {
        if ($oaiIds->getLength()>1) {
            $self->log->fail("Found more than one oai-identifier element. The intention ".
                             "is that this declaration only be used by repositories ".
                             "declaring the use of a single identifier namespace.");
            $cantContinue++;
        } else {
            $oaiIds=$oaiIds->item(0);

            # Now find out if this is v1.1 or v2.0
            my $oai_id_version='2.0';
            if (my $xmlns=$oaiIds->getAttribute('xmlns')) { #FIXME this requires default namespace to be set to oai-id
                if ($xmlns eq 'http://www.openarchives.org/OAI/2.0/oai-identifier') {
                    $oai_id_version='2.0';
                    $self->log->pass("oai-identifier description for version $oai_id_version is being used");
                } elsif ($xmlns eq 'http://www.openarchives.org/OAI/1.1/oai-identifier') {
                    $oai_id_version='1.1';
                    $self->log->pass("oai-identifier description for version $oai_id_version is being used");
                } elsif ($xmlns) {
                    $self->log->fail("Unrecognized namespace declaration '$xmlns' for ".
                                     "oai-identifier, expected ".
                                     "http://www.openarchives.org/OAI/2.0/oai-identifier ".
                                     "(for v2.0) or ".
                                     "http://www.openarchives.org/OAI/1.1/oai-identifier ".
                                     "(for v1.1). Assuming version $oai_id_version.");
                } else {
                    $self->log->fail("No namespace declaration found for oai-identifier, expected ".
                                     "http://www.openarchives.org/OAI/2.0/oai-identifier ".
                                     "(for v2.0) or ".
                                     "http://www.openarchives.org/OAI/1.1/oai-identifier ".
                                     "(for v1.1). Assuming version $oai_id_version/");
                }
            } else {
                $self->log->fail("Can't find namespace declaration for the oai-identifier description. ".
                                 "This must be added as <oai-identifier xmlns=\"http://www.openarchives.org/OAI/2.0/oai-identifier\" ...> ".
                                 "(or 1.1), there will likely also be schema validation weeors. Will ".
                                 "assume that the oai-identifier is version $oai_id_version for ".
                                 "later tests");
            }
            my $repoIds = $oaiIds->getElementsByTagName('repositoryIdentifier');
            if ($repoIds) {
                my $temp = $repoIds->item(0);
                if (!defined($temp)) {
                    $self->log->fail("No namespace-identifier (repositoryIdentifier element) in ".
                                     "the oai-identifier block of the Identify description");
                    return;
                }
                my $nsel = $temp->getFirstChild;
                unless ( $nsel ) {
                    # Empty repositoryIdentifier element, squawk loudly
                    $self->log->fail("Empty namespace-identifier (repositoryIdentifier element) in ".
                                     "the oai-identifier block of the Identify description");
                    return;
                }
                my $namespace_id = $nsel->getData;
                # Having validated the value of namespace-identifier, we can now tell if it is v1.1 or v2.0 based
                # on whether is has a . in it (i.e. if /\./)
                if ($oai_id_version eq '2.0') {
                    #schema: <pattern value="[a-zA-Z][a-zA-Z0-9\-]*(\.[a-zA-Z][a-zA-Z0-9\-]+)+"/>
                    unless ($namespace_id=~/^[a-z][a-z0-9\-]*(\.[a-z][a-z0-9\-]+)+$/i) {
                        $self->log->fail("Bad namespace-identifier (repositoryIdentifier element) ".
                                         "'$namespace_id' in oai-identifier declaration. See section ".
                                         "2.1 of the OAI Identifier specification for details ".
                                         "(http://www.openarchives.org/OAI/2.0/guidelines-oai-identifier.htm).");
                        $cantContinue++;
                    } else {
                        $self->log->pass("namespace-identifier (repositoryIdentifier element) in oai-identifier ".
                                         "declaration is $namespace_id");
                        $self->namespace_id( $namespace_id );
                    }
                } else { #v1.1 schema: <pattern value="[a-zA-Z0-9]+"/>
                    unless ($namespace_id=~/^[a-z0-9]+$/i) {
                        $self->log->fail("Bad namespace-identifier (repositoryIdentifier element) ".
                                         "'$namespace_id' in oai-identifier declaration. See section ".
                                         "2.1 of the OAI Identifier specification for details ".
                                         "(http://www.openarchives.org/OAI/1.1/guidelines-oai-identifier.htm).");
                        $cantContinue++;
                    } else {
                        $self->log->pass("namespace-identifier (repositoryIdentifier element) in oai-identifier ".
                                         "declaration is $namespace_id");
                        $self->namespace_id( $namespace_id );
                    }
                }
            }
        }
    }
    return(not $cantContinue);
}


=head3 test_list_sets()

Check response to the ListSets verb.

Save the setSpecs for later use.

Note that the any set might be empty. So if test_list_identifiers doesn't
get a match, we need to try the second set identifier, and so on.
So keep a list of the setSpec elements.

=cut

sub test_list_sets {
    my $self=shift;

    $self->log->start("Checking ListSets response");
    my $req=$self->base_url."?verb=ListSets";
    my $response = $self->make_request_and_validate("ListSets", $req);
    unless ($response) {
        $self->log->fail("Can't check set names");
        return;
    }

    unless ($self->parse_response($req,$response)) {
        $self->log->fail("Can't parse response");
        $self->abort("failed to parse response to ListSets");
    }

    $self->set_names( [] );
    $self->example_set_spec( '' );
    my $set_elements=$self->doc->getElementsByTagName('setSpec');
    if (not defined($set_elements) or ($set_elements->getLength<1)) {
        # No setSpec elements, so there should be an <error code="noSetHierarchy"> element
        my $details={};
        if ($self->is_error_response($details)) {
            if ($details->{'noSetHierarchy'}) {
                $self->log->pass("Repository does not support sets and the is correctly reported with a ".
                                 "noSetHierarchy exception in the ListSets response");
            } else {
                $self->log->fail("Failed to extract any setSpec elements from ListSets ".
                                 "but did not find a noSetHierarchy exception. Found instead a '".
                                 join(', ',keys %{$details})."' exception(s). See <".
                                 $self->protocol."#ListSets>.");
            }
        } else {
            $self->log->fail("Failed to extract any setSpec elements from ListSets but did not ".
                             "find an exception message. If sets are not supported by the ".
                             "repository then the ListSets response must be the noSetHierarchy ".
                             "error. See <".$self->protocol."#ListSets>.");
        }
    } else {
        # Have setSpec elements, record all set names and pick an example set spec
        for (my $j=0; $j<$set_elements->getLength; $j++) {
             my $set_name=$set_elements->item($j)->getFirstChild->getData;
             ##FIXME - should validate each set name
             push(@{$self->set_names},$set_name);
        }
        # Sanity check, did we get the number we expected?
        my $num_sets=scalar(@{$self->set_names});
        if ($num_sets!=$set_elements->getLength) {
            $self->log->fail("Failed to extract the expected number of set names (got ".
                             "$num_sets, expected ".$set_elements->getLength.")");
        }
        if ($num_sets>0) {
            $self->example_set_spec( "&set=".$self->set_names->[0] );
        }
        my $msg='';
        for (my $j=0; $j<$num_sets and $j<3; $j++) { $msg.=" ".$self->set_names->[$j]; }
        $msg.=" ..." if ($num_sets>3);
        $self->log->pass("Extracted $num_sets set names: {$msg }, will use setSpec ".
                         $self->example_set_spec." in tests");
    }
}


=head3 test_list_identifiers()

Check response to ListIdentifiers and record an example record id in
$self->example_record_id to be used in other tests.

If there are no identifiers, but the response is legal, stop the test with
errors=0, number of verbs checked is three.

As of version 2.0, a metadataPrefix argument is required.  Unfortunately
we need to call test_list_identifiers first in order to get an id for
GetRecord, so we simply use oai_dc.

=cut

sub test_list_identifiers {
    my $self=shift;

    $self->log->start("Checking ListIdentifiers response");

    ### FIXME -- skip the set= restriction because this code doesn't
    ### FIXME work right for set hierarchies - 2002-10-17
    ### FIXME 2015-01-02 - put/left in, is it OK?
    my $set_spec = $self->example_set_spec;
    my $req = $self->base_url."?verb=ListIdentifiers&metadataPrefix=oai_dc".$set_spec;
    my $response = $self->make_request_and_validate("ListIdentifiers", $req);

    # Note: $response will come back null if an error code was returned
    # An error code of "noRecordsMatch" comes back if specified set is
    # empty. In that case we should drop the set and try again.
    if ( $set_spec and (! $response or $self->is_no_records_match ) ) {
        $self->log->note("Empty set made ListIdentifiers fail - trying other sets...");
        my $i=1;
        my $m = scalar(@{$self->set_names});
        while ($i<$m and not $response ) {
            $set_spec = "&set=".$self->set_names->[$i];
            $req = $self->base_url."?verb=ListIdentifiers&metadataPrefix=oai_dc".$set_spec;
            $response = $self->make_request_and_validate("ListIdentifiers", $req);
            $self->log->note("Trying set ".$set_spec);
        }
        # If we were successful then set the example_set_spec for any future tests
        if ($response) {
            $self->example_set_spec( $set_spec );
        }
    }

    # None of the sets had any identifiers in them.  Try the whole entire
    # list of identifiers.
    if ( $set_spec and !$response ) {
        $self->log->note("Last attempt is without any sets...");
        $req = $self->base_url."?verb=ListIdentifiers&metadataPrefix=oai_dc";
        $response = $self->make_request_and_validate("ListIdentifiers",$req);
    }

    # Now we are for real in trouble if $response is null
    unless ($response)  {
        $self->log->fail("No ListIdentifiers response with content");
        $self->log->note("The base URL did not respond to the ListIdentifiers verb.".
                         "Without that, we cannot proceed with the validation test. Exiting.");
        $self->abort("The base URL did not respond to the ListIdentifiers verb. Without that, we cannot proceed with the validation test. Exiting.");
    }

    # Grab the first identifier for later use
    unless ($self->parse_response($req,$response)) {
        $self->log->fail("Can't parse ListIdentifiers response");
        $self->abort("unable to parse response");
    }
    #
    # Now look for the identifier of a non-deleted record
    # If there are no identifiers to be harvested, we cannot complete the
    # validation test.
    #
    # FIXME - this still doesn't solve the problem that there may be no
    # non-deleted items listed in the particular response or partial
    # response that we are looking at [Simeon/2005-07-20]
    #
    my $headers = $self->doc->getElementsByTagName('header');
    my $h;
    my $record_id;
    for ($h=0; $h<$headers->getLength(); $h++) {
        my $hdnode=$headers->item($h);
        my $idnode=$hdnode->getElementsByTagName('identifier',0);
        next unless ($idnode and $idnode->getLength()==1);
        $record_id=$idnode->item(0)->getFirstChild->getData;
        last unless ($hdnode->getAttribute('status') and $hdnode->getAttribute('status') eq 'deleted');
       $self->log->warn("Identifier ".($h+1).", '$record_id', is for a deleted record, skipping");
    }
    if ($h==$headers->getLength()) {
        # No identifiers were in the ListIdentifiers response.  Further testing
        # is not possible.
        $self->log->fail("The response to the ListIdentifiers verb with metadataPrefix oai_dc ".
                         "contained no identifiers. Without at least one identifier, we cannot ".
                         "proceed with the validation tests.");
        $self->abort("No identifiers in response to ListIdentifiers. Without an identifier ".
                     "we cannot proceed with validation tests.");
    }
    $self->log->pass("Good ListIdentifiers response, extracted id '$record_id' for use in future tests.");
    $self->example_record_id( $record_id );
}


=head3 test_list_metadata_formats()

Vet the verb as usual, and then make sure that Dublin Core in included
In particular, we will check the metadata formats available for "record_id",
obtained from checking the ListIdentifier verb.
Side effect: save available formats for later use (global "formats").
NOTE:if there are no formats, error will be picked up by getRecord

=cut

sub test_list_metadata_formats {
    my $self=shift;

    $self->log->start("Checking ListMetadataFormats response");

    # Do we have an example record id to check with?
    my $record_id = $self->example_record_id;
    unless ($record_id) {
        $self->log->fail("Cannot check ListMetadataFormats as we do not have an example id");
        return;
    }

    my $req = $self->base_url."?verb=ListMetadataFormats&identifier=".url_encode($record_id);
    my $response = $self->make_request_and_validate("ListMetadataFormats",$req);
    unless ($response) {
        $self->log->fail("Can't check metadataFormats available for item $record_id, no ".
                         "response to ListMetadataFormats request.");
        return;
    }

    # Check for Dublin Core
    unless ($self->parse_response($req,$response)) {
        $self->log->fail("Can't parse response to ListMetadataFormats request for item $record_id.");
        return;
    }

    my $formats = $self->doc->getElementsByTagName('metadataPrefix');
    unless ($formats->getLength() > 0) {
        $self->log->fail("No metadata formats are listed in the response to a ListMetadataFormats ".
                         "request for item $record_id.");
        return;
    }

    if ($self->debug) {
        $self->log->note("debug: ".$formats->getLength()." formats supported for identifier '$record_id'");
    }
    my $gotDC=0;
    for my $i (0..$formats->getLength()-1) {
        my $format = $formats->item($i);
        #assume this node has only one child, and its data for a format
        if ( $format->getFirstChild->getData =~ /^\s*oai_dc\s*$/ ) {
            $gotDC = 1;
            last;
        }
    }
    if ($gotDC) {
        $self->log->pass("Good ListMetadataFormats response, includes oai_dc");
    } else {
        $self->log->pass("Good ListMetadataFormats response, BUT DID NOT FIND oai_dc");
    }
    return($formats, $gotDC);
}


=head3 test_get_record($record_id, $format)

Try to get record $record_id in $format.

If either $record_id or $format are undef then we have an error
right off the bat. Else make the request and return the
datestamp of the record.

=cut

sub test_get_record {
    my $self=shift;
    my ($record_id, $format)=@_;

    $self->log->start("Checking GetRecord response");

    unless (defined $format) {
        $self->log->fail("Skipping GetRecord test as no metadata format is listed as being available.");
        return;
    }
    unless (defined $record_id) {
        $self->log->fail("Skipping GetRecord test as no items are listed as having metadata available.");
        return;
    }

    my $numerr=0; #count up non-fatal errors

    my $req = $self->base_url."?verb=GetRecord&identifier=".url_encode($record_id)."&metadataPrefix=".url_encode($format);
    my $response = $self->make_request_and_validate("GetRecord", $req);
    unless ($response) {
        $self->log->fail("Can't complete datestamp check for GetRecord");
        $self->abort("Can't complete datestamp check for GetRecord");
    }

    # Save the datestamp for later use by ListRecords
    # As of version 2.0, Identify response can have a granularity and the
    # datestamp MUST be in the finest granularity supported by the repository
    unless ($self->parse_response($req,$response)) {
        $self->log->fail("Can't parse response");
        $self->abort("Unable to parse response from GetRecord");
    }

    if (my $msg=$self->is_error_response) {
        $self->log->fail("The response to the GetRecord verb was the OAI exception $msg. ".
                         "It is this not possible to extract a valid datestamp for remaining tests");
        $self->abort("Unexpected OAI exception response");
    }

    my $datestamps = $self->doc->getElementsByTagName('datestamp');
    # If there is no <record> there is no datestamp ... but there should be a record
    unless ( $datestamps->getLength() > 0 ) {
        $self->log->fail("The response to the GetRecord verb did not have a datestamp, which is ".
                         "needed to continue checking verbs.");
        $self->abort("No datestamp in the response for GetRecord");
    }

    my $datestamp=undef;
    eval {
        $datestamp = $datestamps->item(0)->getFirstChild->getData;
    };
    if (not defined($datestamp)) {
        $self->log->fail("Failed to extract datestamp from the GetRecord response. See <".
                         $self->protocol."#Dates>.");
        $numerr++;
    } elsif ( my $granularity=$self->get_datestamp_granularity($datestamp) ) {
        $self->log->pass("Datestamp in GetRecord response ($datestamp) has the correct form for ".
                         "$granularity granularity.");
        if ( $granularity eq $self->granularity ) {
            # The granularity in v2.0 must match the finest granularity supported (see sec3.3.2)
            $self->log->pass("Datestamp in GetRecord response ($datestamp) matched the ".
                             $self->granularity." granularity specified in the Identify response. ");
        } else {
            $self->log->fail("Datestamp in GetRecord response ($datestamp) is not consistent ".
                             "with the ".$self->granularity." granularity specified in the ".
                             "Identify response");
            $numerr++;
        }
    } else {
        $self->log->fail("Datestamp in GetRecord response ($datestamp) is not valid. See <".
                         $self->protocol."#Dates>.");
        $numerr++;
    }

    # As of OAI-PMH Version 2.0, GetRecord must return a set spec if the
    # repository supports sets and the item is in a set
    if (not $self->example_set_spec) {
        $self->log->pass("Valid GetRecord response") unless ($numerr>0);
        return($datestamp);
    }

    my $set_list = $self->doc->getElementsByTagName('setSpec');
    my $set_value = $self->example_set_spec;
    $set_value =~ s/&set=//;
    $self->log->note("Looking for set '".$set_value."' or a descendant set.") if $self->debug;
    my $i;
    my $subset_str = '';
    for ($i=0; $i<$set_list->getLength; $i++) {
        my $s = $set_list->item($i)->getFirstChild->getData;
        last if ($s eq $set_value);
    if ($s =~ m/^${set_value}:/) {
        $subset_str = " (implied by a descendant setSpec)";
        last;
        }
    }
    if ($i==$set_list->getLength) {         # error
        $self->log->fail("Expected setSpec was missing from the response. The GetRecord ".
                         "response for identifier $record_id did not contain a set ".
                         "specification for $set_value");
    } else {
        $self->log->pass("Expected setSpec was returned in the response".$subset_str);
    }
    return($datestamp);
}


=head3 test_list_records($datestamp,$metadata_prefix)

Test the response for the ListRecords verb.  In addition, if there is
no Dublin Core available for this repository, this is an error.
(And the error has already been counted in test_get_record)
We can still test the verb, however, with one of the available
formats found by testGetMetadataFormats.  Since the output of
ListRecords is likely to be large, use the datestamp of the one
record we did retrieve to limit the output.

=cut

sub test_list_records {
    my $self=shift;
    my ($datestamp,$metadata_prefix)=@_;

    $self->log->start("Checking ListRecords response");

    my $req = $self->base_url."?verb=ListRecords";
    if ($datestamp) {
        $req.="&from=".$datestamp."&until=".$datestamp;
    } else {
        $self->log->warn("Omitting datestamp parameter as none was obtained from earlier test");
    }
    $req.="&metadataPrefix=".$metadata_prefix;
    my $list_not_complete=1;

    while ($list_not_complete) {
        $list_not_complete=0;
        my $response = $self->make_request_and_validate("ListRecords", $req);
        unless ($response) {
            #Nothing else to say since we don't do other tests
            return;
        }

        if ($self->parse_response($req,$response)) {
            $self->log->pass("Response is well formed");
        } else {
            $self->log->fail("The ListRecords response was not well formed XML");
        }

        # Now check to make sure that we got back the record for the identifier
        # $self->example_record_id if there is one specified, else fail that
        # test.
        my $record_id=$self->example_record_id;
        unless ($record_id) {
            $self->log->fail("Cannot check for correct record inclusion without an example record id");
            return;
        }
        my $details={};
        if ($self->is_error_response($details)) {
            if ($details->{'noRecordsMatch'}) {
                $self->log->fail("ListRecords response gave a noRecordsMatch error when it should ".
                                 "have included at least the record with identifier $record_id. ".
                                 "The from and until parameters of the request were set to the ".
                                 "datestamp of this record ($datestamp). The from and until parameters ".
                                 "are inclusive, see protocol spec section 2.7.1. The message ".
                                 "included in the error response was: '".
                                 $details->{'noRecordsMatch'}."'");
            } else {
                my @txt=();
                foreach my $k (keys %$details) {
                    push(@txt,"$k (".$details->{$k}.")");
                }
                $self->log->fail("ListRecords gave an unexpected error response to a request using ".
                                 "from and until datestamps taken from the previous GetRecord response: ".
                                 join(', ',@txt));
            }
        } else {
            my $id_list = $self->doc->getElementsByTagName('identifier');
            my $i;
            my $badly_formed=0;
            for ($i=0; $i<$id_list->getLength; $i++) {
                if (my $child=$id_list->item($i)->getFirstChild()) {
                    last if ($id_list->item($i)->getFirstChild->getData eq $record_id);
                } else {
                    $badly_formed++;
                    last;
                }
            }
            if ($badly_formed) {
                $self->log->fail("ListRecords response badly formed, identifier element for record ".
                                 ($i+1)." is empty");
            } elsif ($i<$id_list->getLength) {
                $self->log->pass("ListRecords response correctly included record with identifier $record_id");
            } elsif (my $token=$self->get_resumption_token) {
                # More responses to come, may just not have got to the
                # record yet... roll around for more:
                $self->log->pass("ListRecords response includes resumptionToken. Haven't found ".
                                 "record with identifier $record_id yet, will continue with resumptionToken...");
                $list_not_complete=1;
                $req = $self->base_url."?verb=ListRecords&resumptionToken=".url_encode($token);
            } else {
                $self->log->fail("ListRecords response did not include the identifier $record_id ".
                                 "which should have been included because both the from and until ".
                                 "parameters were set to the datestamp of this record ($datestamp). ".
                                 "The from and until parameters are inclusive, see protocol spec ".
                                 "section 2.7.1");
            }
        }
    }
}


=head3 test_resumption_tokens()

Request an unlimited ListRecords. If there is a resumption token, see
if it works.  It is an error if resumption is there but doesn't work.
Empty resumption tokens are OK -- this ends the list.

CGI takes care of URL-encoding the resumption token.

=cut

sub test_resumption_tokens {
    my $self=shift;

    $self->log->start("Checking for correct use of resumptionToken (if used)");

    my $req = $self->base_url."?verb=ListRecords&metadataPrefix=oai_dc";
    my $response = $self->make_request($req);

    # was there a resumption token?
    unless ($self->parse_response($req,$response)) {
        $self->log->fail("Can't parse malformed XML in response to ListRecords request. ".
                         "Cannot complete test for correct use of resumptionToken (if used)");
        return;
    }

    my $tokenList = $self->doc->getElementsByTagName('resumptionToken');
    if ( !$tokenList or $tokenList->getLength()==0 ) {
        $self->log->pass("resumptionToken not used");
        return;
    }
    if ( $tokenList->getLength()>1 ) {
        $self->log->fail("More than one resumptionToken in response!");
        return;
    }

    # Dig out the resumption token from the document
    my $tokenElement = $tokenList->item(0);

    # Try getting the resumption token, $token will be will be undefined
    # unless the element has content
    my $token = $tokenElement->getFirstChild;
    my $tokenString;
    if ($token) {
       $tokenString = $token->getData;
    }
    unless ($tokenString) {
       $self->log->fail("Empty resumption token in response to $req There should never ".
                        "be an empty resumptionToken in response to a request without a ".
                        "resumptionToken argument");
       return;
    }

    # If there us a 'cursor' value given then check that it is
    # correct. It must have the value 0 in the first response
    my $usingCursor=0;
    if (my $cursor=$tokenElement->getAttribute('cursor')) {
        $usingCursor=1;
        if ($cursor==0) {
            $self->log->pass("A cursor value was supplied with the resumptionToken and it ".
                             "correctly had the value zero in the first response");
        } else {
            $self->log->fail("A cursor value was supplied with the resumptionToken but it ".
                             "did not have the correct value zero for the first response. ".
                             "The value was '$cursor'.");
        }
    }

    $self->log->note("Got resumptionToken ".$tokenString);

    # Try using the resumption token.  Before including a resumptionToken in
    # the URL of a subsequent request, we must encode all special characters
    # getData in this version of XML::DOM expands entitities
    $req = $self->base_url."?verb=ListRecords&resumptionToken=".url_encode($tokenString);
    $response = $self->make_request($req);
    unless ( $response ) {
        $self->log->fail("Site failed to respond to request using resumptionToken: $req");
        return;
    }
    unless ( $self->parse_response($req,$response)) {
        $self->log->fail("Response to request is using resumptionToken not valid XML: $req");
        return;
    }

    my $errorList = $self->doc->getElementsByTagName('error');
    if ( $errorList and $errorList->getLength() > 0 ) {
        $self->log->fail("Response to request using resumptionToken was an error code: $req");
        return;
    }

    ###FIXME: put in test for cursor again, should be number of items returned in the
    ###FIXME: first response [Simeon/2005-10-11]

    $self->log->pass("Resumption tokens appear to work");
}


=head2 METHODS CHECKING ERRORS AND EXCEPTIONS

=head3 test_expected_errors($record_id)

Each one of these requests should get a 400 response in OAI-PHM v1.1,
or a 200 response in 2.0, along with a Reason_Phrase.  Bump error_count
if this does not hold. Return the number of errorneous responses.

$record_id is a valid record identifier to be used in tests that require
one.

=cut

sub test_expected_errors {
    my $self=shift;
    my ($record_id)=@_;

    $self->log->start("Checking exception handling (errors)");

    my @request_list = (
        [ 'junk', [ 'badVerb' ], '', '' ],
        [ 'verb=junk', [ 'badVerb' ], '', '' ],
        [ 'verb=GetRecord&metadataPrefix=oai_dc', [ 'badArgument' ], '', '' ],
        [ 'verb=GetRecord&identifier='.$record_id, [ 'badArgument' ], '', '' ],
        [ 'verb=GetRecord&identifier=invalid"id&metadataPrefix=oai_dc', [ 'badArgument','idDoesNotExist' ], 'An XML parsing error may be due to incorrectly including the invalid identifier in the <request> element of your XML error response; only valid arguments should be included. A response that includes <request verb="GetRecord" identifier="invalid"id" metadataPrefix="oai_dc">..baseURL..</request> is not well-formed XML because of the quotation mark (") in the identifier.', 'Either the badArgument or idDoesNotExist error codes would be appropriate to report this case.' ],
        [ 'verb=ListIdentifiers&until=junk', [ 'badArgument' ], '', '' ],
        [ 'verb=ListIdentifiers&from=junk', [ 'badArgument' ], '', '' ],
        [ 'verb=ListIdentifiers&resumptionToken=junk&until=2000-02-05', [ 'badArgument','badResumptionToken' ], '', 'Either the badArgument and/or badResumptionToken error codes may be reported in this case. If only one is reported then the badArgument error is to be preferred because the resumptionToken and until parameters are exclusive.' ],
        [ 'verb=ListRecords&metadataPrefix=oai_dc&from=junk', [ 'badArgument' ], '', '' ],
        [ 'verb=ListRecords&resumptionToken=junk', [ 'badResumptionToken' ], '', '' ],
        [ 'verb=ListRecords&metadataPrefix=oai_dc&resumptionToken=junk&until=1990-01-10', [ 'badArgument','badResumptionToken' ] , '', 'Either the badArgument and/or badResumptionToken error codes may be reported in this case. If only one is reported then the badArgument error is to be preferred because the resumptionToken and until parameters are exclusive.' ],
        [ 'verb=ListRecords&metadataPrefix=oai_dc&until=junk', [ 'badArgument' ], '', '' ],
        [ 'verb=ListRecords', [ 'badArgument' ], '', '' ]
    );

    my $n=0;
    foreach my $rrr ( @request_list ) {
        my ($request_string, $error_codes, $xml_reason, $reason)=@$rrr;
        my $req = $self->base_url.'?'.$request_string;
        my $ok_errors=join(' or ',@$error_codes);

        my $response=$self->make_request($req);

        # TBD: $response->status_line should also be checked? see output from
        # physnet.uni-oldenburg.de/oai/oai.php
        if ($self->protocol_version eq "1.1") {
            if ($response->code ne "400") {
                $self->log->note("Invalid requests which failed to return 400:") if $n == 0;
                $n++;
                $self->log->fail("Expected 400 from: $request_string");
            }
        } elsif ($self->protocol_version eq "2.0") {
            # The document must contain the proper error code
            unless ($self->parse_response($req,$response,$xml_reason)) {
                $self->log->fail("Can't parse malformed response. ".html_escape($xml_reason));
                $n++;
                next;
            }
            # check that the error code is in the error_list
            my $error_elements = $self->doc->getElementsByTagName('error');
            if (my $matching_code=$self->error_elements_include($error_elements, $error_codes)) {
                $self->log->pass("Error response correctly includes error code '$matching_code'");
            } else {
                $self->log->fail("Exception/error response did not contain error code ".
                                 "'$ok_errors' ".html_escape($reason));
                $n++;
                next;
            }
        } else {
            $self->log->fail("Invalid protocol version returned");
            $self->abort("test_expected_errors - invalid protocol version");
        }
    }
    my $total = scalar @request_list;
    if ($n==0) {
        $self->log->pass("All $total error requests properly handled");
    } else {
        $self->log->warn("Only ".($total-$n)." out of $total error requests properly handled");
    }
    return($n);
}


=head3 test_expected_v2_errors($earliest_datestamp,$metadata_prefix)

There are some additional exception tests for OAI-PMH version 2.0.

=cut

sub test_expected_v2_errors {
    my $self=shift;
    my ($earliest_datestamp,$metadata_prefix)=@_;

    $self->log->start("Checking for version 2.0 specific exceptions");

    my $too_early_date=one_year_before($earliest_datestamp);

    # format of entries: [ request_string, [error_codes_accepable], resaon ]
    my @request_list = (
        [ "verb=ListRecords&metadataPrefix=".url_encode($metadata_prefix)."&from=2002-02-05&until=2002-02-06T05:35:00Z", ['badArgument'],
          'The request has different granularities for the from and until parameters.' ],
        [ "verb=ListRecords&metadataPrefix=".url_encode($metadata_prefix)."&until=$too_early_date" , ['noRecordsMatch'],
          'The request specified a date one year before the earliestDatestamp given in the Identify response. '.
          'There should therefore not be any records with datestamps on or before this date and a noRecordsMatch '.
          'error code should be returned.' ]
    );

    foreach my $rrr ( @request_list ) {
        my ($request_string,$error_codes,$reason)=@$rrr;

        my $req=$self->base_url."?$request_string";
        my $response = $self->make_request($req);
        # parse the response content for the desired error code
        unless ( $self->parse_response($req,$response) ) {
            $self->log->fail("Error in parsing XML response to exception request: $request_string");
            next;
        }
        # check that there is at least the desired error code
        my $ok_errors=join(' or ',@$error_codes);
        my $error_elements = $self->doc->getElementsByTagName('error');
        if ( !$error_elements or $error_elements->getLength==0 ) {
            $self->log->fail("Failed to extract error code from the response to request: ".
                             "$request_string $reason");
        } elsif (my $matching_code=$self->error_elements_include($error_elements, $error_codes) ) {
            $self->log->pass("Error response correctly includes error code '$matching_code'");
        } else {
            $self->log->fail("Error code $ok_errors not found in response but should be given ".
                             "to the request: $request_string $reason");
        }
    }
    return;
}


=head2 METHODS TO TEST USE OF HTTP POST

=head3 test_post_requests()

Test responses to POST requests. Do both the simplest possible -- the Identify
verb -- and a GetRecord request which uses two additional parameters.

=cut

sub test_post_requests {
    my $self=shift;
    my ($metadata_prefix)=@_;

    $self->log->start("Checking that HTTP POST requests are handled correctly");

    $self->test_post_request(1,{verb => "Identify"});

    my $record_id=$self->example_record_id;
    if ($record_id) {
        $self->test_post_request(2,{verb => "GetRecord", 'identifier' => $record_id, 'metadataPrefix' => $metadata_prefix});
    } else {
        $self->log->fail("Cannot test GetRecord via POST without and example record identifier");
    }
}


# Called just by test_post_requests to actually run the test
#
sub test_post_request {
    my $self=shift;
    my ($num, $post_data) = @_;
    my $response = $self->make_request($self->base_url, $post_data);
    if ($response->is_success) {
        my $verb = $post_data->{verb};
        if ( $self->is_verb_response($response,$verb) ) {
            $self->log->pass("POST test $num for $verb was successful");
        } elsif ( $self->check_error_response($response) ) {
            $self->log->fail("POST test $num for $verb was unsuccessful, an OAI error ".
                             "response was received");
        } else {
            $self->log->fail("POST test $num for $verb was unsuccessful, got neither a ".
                             "valid response nor an error");
        }
    } else {
        $self->log->fail("POST test $num was unsuccessful. Server returned HTTP Status: '".
                         $response->status_line."'");
    }
}


=head2 METHODS CHECKING ELEMENTS WITHIN VERB AND ERROR RESPONSES

=head3 check_response_date($req, $doc)

Check responseDate for being in UTC format
(should perhaps also check that it is at least the current day?)

=cut

sub check_response_date {
    my $self=shift;
    my ($req, $doc) = @_;

    my $elements = $self->doc->getElementsByTagName('responseDate');
    # assume rest of validity already checked, just take first
    my $item;
    my $child;
    if ($elements and $item=$elements->item(0) and $child=$item->getFirstChild()) {
        my $date = $child->getData();
        if ($date=~/\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\dZ/) {
            $self->log->pass("responseDate has correct format: $date");
        } else {
            $self->log->fail("Bad responseDate of $date, this is not in UTC DateTime ".
                             "(YYYY-MM-DDThh:mm:ssZ) format");
        }
    } else {
       $self->log->fail("Failed to extract responseDate");
    }
}


=head3 check_schema_name($req, $doc)

Given the response to one of the OAI verbs, make sure that it it
going to be validated against the "official" OAI schema, and not
one that the repository made up for itself.  If the response can't
be parsed, or if there is no OAI-PMH element, or if the schema is
incorrect, print an error message and bump the error_count.

Return true if the schema name and date check out, else return undef

=cut

sub check_schema_name {
    my $self=shift;
    my ($req, $doc) = @_;

    my $namespace = 'http://www.openarchives.org/OAI/2.0/';
    my $location = 'http://www.openarchives.org/OAI/2.0/OAI-PMH.xsd';

    my $elements = $self->doc->getElementsByTagName('OAI-PMH');   #NodeList
    unless ( $elements->getLength() > 0 ) {
        $self->log->fail("Response to $req did not contain a OAI-PMH element");
        return(0);
    }
    my $attributes = $elements->item(0)->getAttributes;  #Node->NamedNodeMap
    my $attr = $attributes->getNamedItem('xsi:schemaLocation');  #Node
    unless ( $attr ) {
        $self->log->fail("No xsi:schemaLocation attribute for the OAI-PMH element was ".
                         "found, expected xsi:schemaLocation=\"$namespace $location\"");
        return(0);
    }
    $attr = $attributes->getNamedItem('xsi:schemaLocation');     #Node
    my $pair = $attr->getNodeValue();    # must pair OAI namespace with schema
    unless ( $pair =~ /^\s?$namespace\s*$location/ ) {
        $self->log->fail("Error in pairing OAI namespace with schema location, expected: ".
                         "xsi:schemaLocation=\"$namespace $location\" but got $pair");
        return(0);
    }
    return(1);
}


=head3 check_protocol_version

Extract the protocol version being used from the Identify response, check that it is
valid and then abort unless 2.0.

=cut

sub check_protocol_version {
    my $self=shift;
    my $doc;
    # Extract the version number of the validator to run
    my $x = $self->doc->getElementsByTagName('protocolVersion');
    if (not $x) {
        $self->abort("Unknown protocol version, failed to extract protocolVersion element from Identify response");
    }
    my $protocol_version = $x->item(0)->getFirstChild->getData;
    if ($protocol_version ne '2.0' and
        $protocol_version ne '1.1' and
        $protocol_version ne '1.0') {
        $self->abort("Invalid protocol version ($protocol_version)");
    }
    $self->protocol_version( $protocol_version );
    if ($protocol_version ne '2.0') {
        $self->abort("Repository reports OAI-PMH protocol version $protocol_version and will not be validated. Guidelines for upgrading to 2.0 can be found at http://www.openarchives.org/OAI/2.0/migration.htm\n\n");
    }
    $self->log->pass("Correctly reports OAI-PMH protocol version 2.0");
}


=head2 is_verb_response($reponse,$verb)

Return true if $response is a response for the specified $verb.

FIXME -- need better checks!

=cut

sub is_verb_response {
    my $self=shift;
    my ($response,$verb) = @_;
    my $doc;
    eval { $doc=$self->parser->parse($response->content); };
    return unless $doc; # We can't parse it so it isn't a valid doc
    my $verb_elements = $doc->getElementsByTagName($verb);
    return(1) if ( $verb_elements and $verb_elements->getLength==1 );
    return;  # not the one element we expected
}


=head3 error_elements_include($error_elements,$error_codes)

Determine whether the list of error elements ($error_elements) includes at least
one of the desired codes. Return string with first matching error code, else
return false/nothing.

Does a sanity check on $error_list to check that it is set and has length>0
before trying to match, so cose calling it can simply do a
getElementsByTagName or similar before caling.

=cut

sub error_elements_include {
    my $self=shift;
    my ($error_elements, $error_codes) = @_;
    # sanity check
    return if (!$error_elements or $error_elements->getLength==0);
    for (my $i=0; $i<$error_elements->getLength; $i++) {
        foreach my $ec (@$error_codes) {
            my $code = $error_elements->item($i)->getAttribute('code') || 'no-code-attribute';
            $self->log->note("$code =? $ec") if ($self->debug);
            return($ec) if ($code eq $ec);
        }
    }
    return;
}



=head3 check_error_response($response)

Given the response to an HTTP request, make sure it is not an
OAI-PMH error message.  The $response is a success.  If it is an
OAI error message, return 2; if the response cannot be parsed, return
-1; otherwise return undef (it must be a real Identify response).

FIXME -- need better checks!

FIXME -- need to merge thic functionality in with is_error_response

=cut

sub check_error_response {
    my $self=shift;
    my ($response) = @_;
    my $doc;
    eval { $doc=$self->parser->parse($response->content); };
    return unless $doc;   # We can't parse it so it isn't a valid error
    my $error_elements = $doc->getElementsByTagName('error');
    return(1) if ( $error_elements and $error_elements->getLength() > 0 );
    return;  # no error codes so not an error response
}


=head3  get_earliest_datestamp()

A new exception check for Version 2.0 raises noRecordsMatch errorcode
if the set of records returned by ListRecords is empty.  This requires
that we know the earliest date in the repository.  Also check that the
earliest date matches the specified granularity.

Called only for version 2.0 or greater.

Since the Identify response has already been validated, we know
there is exactly one earliestDatestamp element in the current document.
Extract this value, check it, and if it looks good then set
$self->earliest_datestamp and return false.

If there is an error then return string explaining that.

=cut

sub get_earliest_datestamp {
    my $self=shift;

    my $earliest = $self->doc->getElementsByTagName('earliestDatestamp');
    my $el = $earliest->item(0);
    return("Can't get earliestDatestamp element from Identify response.") unless ($el);
    return("earliestDatestamp element is empty in Identify response.") unless ($el->getFirstChild);

    my $error='';
    my $earliest_datestamp = $el->getFirstChild->getData;
    $self->log->note("Earliest datestamp in repository is $earliest_datestamp") if $self->debug;

    $earliest_datestamp =~ /^([0-9]{4})-([0-9][0-9])-([0-9][0-9])(.*)$/;
    if ($1 eq '' || $2 eq '' || $3 eq '') {
        $error="is not in ISO8601 format";
    } elsif ( $4 eq '' and $self->granularity eq 'seconds') {
        $error="must have seconds granularity (format YYYY-MM-DDThh:mm:ssZ) to match ".
               "the granularity for the repository. The granularity has been set to seconds ".
               "by the granularity element of the Identify response.\n";
    } elsif ( $4 ne '' and $self->granularity eq 'days') {
        $error="must have days granularity (format YYYY-MM-DD) to match the granularity for ".
               "the repository. The granularity has been set to days by the granularity ".
               "element of the Identify response (or that element is bad/missing).\n";
    } elsif ( $self->granularity eq 'seconds' and $4 !~ /^T\d\d:\d\d:\d\d(\.\d+)?Z$/ ) {
        $error="does not have the correct format for the time part of the UTCdatetime. The ".
               "overall format must be YYYY-MM-DDThh:mm:ssZ.\n";
    }
    if ($error) {
        # Sanitize for error message
        return("The earliestDatestamp in the identify response (".
               sanitize($earliest_datestamp).") $error");
    } else {
        $self->earliest_datestamp($earliest_datestamp);
        return;
    }
}


=head3 parse_granularity($granularity_element)

Parse contents of the granularity element of the Identify response. Returns either
'days', 'seconds' or nothing on failure. Sets $self->granularity if valid, otherwise
does not change setting.

As of v2.0 the granularity element is mandatory, see:
http://www.openarchives.org/OAI/openarchivesprotocol.html#Identify

=cut

sub parse_granularity {
    my $self=shift;
    my ($gran) = @_;
    if (!$gran or $gran->getLength==0) {
        $self->log->fail("Missing granularity element");
        return;
    } elsif ($gran->getLength>1) {
        $self->log->fail("Multiple granularity elements");
        return;
    }
    #schema validation guarantees that there is a spec here
    my $el=$gran->item(0)->getFirstChild->getData;
    if ($el eq 'YYYY-MM-DD') {
        $self->granularity('days');
        return($self->granularity);
    } elsif ($el eq 'YYYY-MM-DDThh:mm:ssZ') {
        $self->granularity('seconds');
        return($self->granularity);
    } else {
        $self->log->fail("Bad value for the granularity element '$el', must be either ".
                         "YYYY-MM-DD or YYYY-MM-DDThh:mm:ssZ");
        return;
   }
}


=head3 get_datestamp_granularity($datestamp)

Parse the datestamp supplied and return 'days' if it is valid with granularity
of days, 'seconds' if it is valid for seconds granularity, and nothing if it is not
valid.

# FIXME - should add more validation

=cut

sub get_datestamp_granularity {
    my $self=shift;
    my ($datestamp)=@_;
    if ($datestamp=~/^(\d\d\d\d)-(\d\d)-(\d\d)$/) {
        return 'days' if ($2>=1 and $2<=12 and $3>=1 and $3<=31);
    } elsif ($datestamp=~/^(\d\d\d\d)-(\d\d)-(\d\d)T(\d\d):(\d\d):(\d\d)(\.\d+)?Z$/) {
        return 'seconds' if ($2>=1 and $2<=12 and $3>=1 and $3<=31 and $4<24 and $5<60);
    }
    return;
}


=head3 is_no_records_match

Returns true if the current document contains and error code element with the code "noRecordsMatch"

### FIXME - should be merged into an extended is_error_response

=cut

sub is_no_records_match {
    my $self=shift;
    my $error_elements = $self->doc->getElementsByTagName('error');
    return( $self->error_elements_include($error_elements, ['noRecordsMatch']) );
}


=head3 get_resumption_token()

See if there is a resumptionToken with this response, return
value if present, empty if not or if there is some other error.

=cut

sub get_resumption_token {
    my $self=shift;

    my $tokenList = $self->doc->getElementsByTagName('resumptionToken');
    if ( !$tokenList or $tokenList->getLength()==0 ) {
        return; #no resumptionToken
    }

    # Dig out the resumption token from the document
    my $token = $tokenList->item(0)->getFirstChild();

    # Try getting the resumption token, $token will be will be undefined
    # unless the element has content
    if ($token) {
        return($token->getData());
    }
    return;
}


=head3 is_error_response($details)

Look at the parsed response in $self->doc to see if it is an error response,
parse data and return true if it is.

Returns true (a printable string containing the error messages) if response was a valid
OAI_PMH error response, codes in %$details if a hash reference is passed in.

=cut

sub is_error_response {
    my $self=shift;
    my ($details)=@_;
    $details={} unless (ref($details) eq 'HASH'); #dummy hash unless one supplied
    #
    my $error_elements = $self->doc->getElementsByTagName('error');
    if ($error_elements and $error_elements->getLength()>=1) {
        my $msg='';
        for (my $i=0; $i<$error_elements->getLength; $i++) {
            my $code=$error_elements->item($i)->getAttribute("code");
            my $child=$error_elements->item($i)->getFirstChild();
            unless ($child) {
                # Warn about no content unless it is the special case of noSetHierarchy
                # where the error code really is sufficient
                unless  ($code eq 'noSetHierarchy') {
                    $self->log->warn("No human readable message included in error element for ".
                                     "$code error, this is discouraged");
                }
                $details->{$code}='[NO MESSAGE RETURNED]';
                $msg.="[$code] ";
            } else {
                $details->{$code}=$child->getData();
                $msg.="[$code: $details->{$code}] ";
            }
        }
        return($msg);
    } else {
        return;
    }
}


=head3 get_admin_email()

Extract admin email from a parsed Identify response in $self->doc).
Also note that the email target may have been set via form option

Returns the pair of ($email,$error) where $email is the combined
set of email addresses (comma separated). $error will be undef
or a string with error message to users.

=cut

sub get_admin_email {
    my $self=shift;

    my $adminEmailElements = $self->doc->getElementsByTagName('adminEmail');
    my @emails=();
    my $n = $adminEmailElements->getLength;
    if ($n > 0) {
        my $name_node = $adminEmailElements->item(0)->getFirstChild;
        if ($name_node) {
            for (my $i=0; $i<$n; $i++) {
            my $e=$adminEmailElements->item($i)->getFirstChild->getData;
            if ($e=~s/mailto://g) {
                $self->log->warn("Stripped mailto: prefix from adminEmail address, this ".
                                 "should not be included.");
            }
            if (my $msg=$self->bad_admin_email($e)) {
                return(undef,$msg);
            }
            push(@emails,$e);
            }
        }  else {
            $self->log->fail("adminEmail element is empty!");
            return(undef);
        }
    } else {
        $self->log->fail("No adminEmail element!");
        return(undef);
    }
    my $email=join(',',@emails);
    $self->log->pass("Administrator email address is '$email'");
    return($email);
}


=head3 bad_admin_email($admin_email)

Check for some stupid email addresses to avoid so much bounced email.
Returns a string (True) if bad, else nothing.

=cut

sub bad_admin_email {
    my $self=shift;
    my ($admin_email)=@_;
    if ($admin_email=~/\@localhost$/) {
        $self->log->fail("adminEmail '$admin_email' is local. This must be corrected to a ".
                         "valid globally resolvable email address before tests can continue");
        return("local adminEmail");
    } elsif ($admin_email!~/^\w[\w\-\.]+\@[a-zA-Z0-9\-\.]+\.[a-z]{2,}$/) {
        $self->log->fail("adminEmail '$admin_email' looks bogus. This must be corrected to ".
                         "a valid email address before tests can continue");
        return("looks like bogus adminEmail");
    }
    return;
}


=head2 METHODS FOR MAKING REQUESTS AND PARSING RESPONSES

=head3 make_request_and_validate($verb, $req)

Given the base URL that we are validating, the Verb that we are checking
and the complete query to be sent to the OAI server, get the response to
the verb.  Validation has already been done, so we need only do some
special checks here.  Return the response to the OAI verb,
or undef if the OAI server failed to respond to that verb.

Side effects: errors may be printed and error_count bumped.
If the verb involved is "Identify" then set the version number and the
email address, assuming that some response has been obtained.

Simple well-formedness is checked by this routine. An undef exit means
that any calling code should fail the test but need not report 'no response'.

If the response is true then $self->doc contains a parsed XML
document.

This is the usual way we make requests with integrated parsing and error
checking. This method is built around calls to L<make_request> and
L<parse_response>.

=cut

sub make_request_and_validate {
    my $self=shift;
    my ($verb, $req) = @_;

    my $response = $self->make_request($req);

    unless ( $response->is_success ) {
        my $status = $response->status_line;
        my $age = $response->current_age;
        my $lifetime = $response->freshness_lifetime;
        my $is_fresh = $response->is_fresh;
        $self->log->fail("Server failed to respond to the $verb request (HTTP header ".
                         "values: status=$status, age=$age, lifetime=$lifetime, ".
                         "is fresh:=$is_fresh)");
        return;
    }

    unless ($self->parse_response($req, $response)) {
        $self->log->fail("Failed to parse response");
        return;
    }

    # Check that the responseDate is in UTC format
    $self->check_response_date($req,$self->doc);
    # Check that the response refers to the "official" OAI schema
    $self->check_schema_name($req,$self->doc);

    return($response);
}


=head3 make_request($url,$post_data)

Routine to GET or POST a request, handle 503's, and return the response

Second parameter, $post_data, must be hasfref to POST data to indicate that
the request should be an HTTP POST request instead of a GET.

=cut

sub make_request {
    my $self=shift;
    my ($url,$post_data) = @_;

    # Is this https and do we allow that?
    if (is_https_uri($url)) {
        $self->uses_https(1);
        if (not $self->allow_https) {
            $self->abort("URI $url is https. Use of https URIs is not allowed ".
                         "by the OAI-PMH v2.0 specification");
        }
    }

    my $request;
    if ($post_data) {
        my $content_msg=''; #nice string to report
        # Sort keys in alpha order for consistent behavior
        foreach my $k (sort keys(%$post_data)) {
            my $v=$post_data->{$k};
            $content_msg.="$k:$v ";
        }
        $self->log->request($url,'POST',$content_msg);
        $request = POST($url,'Content'=>$post_data);
    } else {
        $self->log->request($url,'GET');
        $request = GET($url);
    }
    my $response;
    my $tries=0;
    my $try_again = 1;
    while  ( $try_again ) {
        #$ua->max_redirect(0);
        $response = $self->ua->request($request);
        #
        # Write response if requested
        if ($self->save_all_responses) {
            my $response_file="/tmp/".$self->run_id.".".$self->response_number;
            open(my $fh,'>',$response_file) || $self->abort("Can't write response $response_file: $!");
            print {$fh} $response->content();
            $self->log->note("Response saved as $response_file") if ($self->debug);
            close($fh);
            $self->{response_number}++;
        }
        $tries++;
        if ($tries > $self->max_retries) {
            $self->abort("Too many 503 Retry-After or 302 Redirect responses received in a row");
        }
        #
        # Check response for 503 and 302
        if ($response->code eq '503') {
            # 503 (Retry-After), expect to get a time too
            $self->uses_503(1);
            if (defined  $response->header("Retry-After")) {
                my $retryAfter=$response->header("Retry-After");
                if ($retryAfter=~/^\d+$/) {
                    if ($retryAfter<=3600) {
                        ###FIXME: Should check the Retry-After value carefully and barf if bad
                        my $sleep_time = 1 + $response->header("Retry-After");
                        $self->log->note("Status: ".$response->code().
                                         " -- going to sleep for $sleep_time seconds.");
                        sleep $sleep_time;
                    } else {
                        $self->abort("503 response with Retry-After > 1hour (3600s), aborting");
                    }
                } else {
                    $self->log->fail("503 response with bad (non-numeric) Retry-After time, ".
                                     "will wait 10s");
                    sleep 10;
                }
            } else {
                $self->log->warn("503 response without Retry-After time, will wait 10s");
                sleep 10;
            }
        } elsif ($response->code eq '302') {
            # 302 (Found) redirect
            my $loc=$response->header('Location');
            if ($loc!~m%^http://([^\?&]+)%) {
                if (is_https_uri($loc)) {
                    $self->uses_https(1);
                    if (not $self->allow_https) {
                        $self->abort("Redirect URI specified in 302 response is https. Use of ".
                                     "https URIs is not allowed by the OAI-PMH v2.0 specification");
                    }
                } else {
                    $self->abort("Bad redirect URI specified in 302 response");
                }
            }
            # Make new request
            if ($post_data and $loc!~/\?/) { #don't do POST if new Location includes ?
                $request = POST($loc,'Content'=>$post_data);
            } else {
                $request = GET($loc);
            }
        } elsif ($response->code eq '501') {
            $self->abort("Got 501 Not Implemented response which may either have come from ".
                         "the server or have been generated within the validator because the ".
                         "request type (perhaps https) is not supported.");
        } else {
            $try_again=0;
        }
    }
    # Check for oversize limit (indicated by X-Content-Range header)
    if (defined $response->header('X-Content-Range')) {
        $self->log->fail("Response to <$url> exceeds maximum size limit (".$self->max_size." bytes), discarded. ".
                         "While this limit is set only in this validation program you should not use excessively ".
                         "large responses as service providers will likely have problems parsing the XML. You ".
                         "should split the responses using the resumptionToken mechanism. (X-Content-Range: '".
                         $response->header('X-Content-Range')."' Content-Length: '".$response->content_length."')\n");
        $response->content('');
    }
    return $response;
}


=head3 parse_response($request_url,$response,$xml_reason)

Attempt to parse the HTTP response $response, examining both the response code
and then attempting to parse the content as XML.

If $xml_reason is specified then this is added to the failure message, if
nothing is specified then a standard message about UTF-8 issues is 
added.

Returns true on success and sets $self->doc with the parsed XML document.
If unsuccessful, log an error message, bump the error count, and
return false.

=cut

sub parse_response {
    my $self=shift;
    my ($request_url,$response,$xml_reason) = @_;
    $xml_reason='' unless (defined $xml_reason);
    #
    # Fail if reponse=undef, else check to see if response is ref to
    # response object or is string
    if (!defined($response) or not ref($response)) {
        $self->log->warn("Bad response from server");
        return;
    }
    # Unpack the bits we want from response object
    my $code=$response->code;
    my $content=$response->content;
    # Check return code (if given)
    if ($code and $code=~/^[45]/) {
        $self->log->warn("Bad HTTP status code from server: $code");
        return;
    }
    #
    # Check content
    my $doc;
    eval { $doc=$self->parser->parse($content); };
    unless ( $doc ) {
        my $err=$@;
        $err=~s/^\s+//;
        $err=~s%at\s+/usr/lib/perl.*%%i; #trim stuff about our perl installation
        if ($request_url) {
            unless ($xml_reason) {
                $xml_reason="The most common reason for malformed responses is illegal bytes in ".
                            "UTF-8 streams (e.g. the inclusion of Latin1 characters with codes>127 ".
                            "without creating proper UTF-8 mutli-byte sequences). You might find ".
                            "the utf8conditioner, found on the OAI tools page helpful for debugging.";
            }
            $self->log->warn("Malformed response: $err. $xml_reason");
        }
        return;
    }
    # Set parsed document
    $self->doc( $doc );
    return(1);
}


=head2 UTILITY FUNCTIONS

=head3 html_escape($str)

Escapes characters which have special meanings in HTML

=cut

sub html_escape {
    my $string = shift;
    $string =~ s/&/&amp;/g;   #must be first!
    $string =~ s/</&lt;/g;
    $string =~ s/>/&gt;/g;
    $string =~ s/"/&quot;/g;
    $string =~ s/'/&apos;/g;
    return $string;
}

=head3 one_year_before($date)

Assumes properly formatted date, decrements year by one
via string manipulation and returns date.

=cut

sub one_year_before {
    my ($date)=@_;
    my ($year) = $date =~ /^([0-9]{4})/;
    my $year_minus_one = sprintf('%04d',($year - 1)); #make sure we get leading zeros
    $date =~ s/^$year/$year_minus_one/;
    return($date);
}

=head3 url_encode($str)

Escape/encode any characters that aren't in the small safe set for URLs

=cut

sub url_encode {
    my $str=shift;
    $str =~ s/([^\w\/\,\- ])/sprintf("%%%02X",ord($1))/eg;
    $str =~ tr/ /+/;
    return($str);
}


=head3 is_https_uri($uri)

Return true if the URI is an https URI, false otherwise.

=cut

sub is_https_uri {
  my $uri=shift;
  return($uri=~m%^https:%);
}


=head3 sanitize($str)

Return a sanitized version of $str that doesn't contain odd
characters and it not over 80 chars long. Will have the
string '(sanitized)' appended if changed.

=cut

sub sanitize {
    my ($str)=@_;
    my $out=$str;
    $out=~s/[^\w\-:;.!@#%^*\(\) ]/_/g;
    $out=substr($out,0,80);
    if ($out ne $str) {
        $out.='(sanitized)';
    }
    return($out);
}


=head1 SUPPORT

Please report any bugs of questions about validation via the
OAI-PMH discussion list at  L<https://groups.google.com/d/forum/oai-pmh>.
Be sure to make it clear that you are talking about the
HTTP::OAIPMH::Validator module.

=head1 AUTHORS

Simeon Warner, Donna Bergmark

=head1 HISTORY

This module is based on an OAI-PMH validator first written by Donna Bergmark
(Cornell University) in 2001-01 for the OAI-PMH validation and registration
service (L<http://www.openarchives.org/data/registerasprovider.html>).
Simeon Warner (Cornell University) took over the validator and operation of
the registration service in 2004-01, and then did a significant tidy/rework
of the code. That code ran the validation and registration service with
few changes through 2015-01. Some of the early work on the OAI-PMH validation
service was supported through NSF award number 0127308.

Code was abstracted into this module 2015-01 by Simeon Warner and is
used for the OAI-PMH validation and registration service on
L<http://www.openarchives.org/pmh/>.

=head1 COPYRIGHT

Copyright 2001..2017 by Simeon Warner, Donna Bergmark.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;
