package Lemonldap::NG::Portal::Lib::CAS;

use strict;
use Mouse;
use Lemonldap::NG::Common::FormEncode;
use POSIX qw(strftime);
use Hash::MultiValue;
use HTTP::Request;
use XML::LibXML;
use Lemonldap::NG::Common::UserAgent;
use URI;
use Crypt::URandom;

our $VERSION = '2.21.0';

# PROPERTIES

# return LWP::UserAgent object
has ua => (
    is      => 'rw',
    lazy    => 1,
    builder => sub {

        # TODO : LWP options to use a proxy for example
        my $ua = Lemonldap::NG::Common::UserAgent->new( $_[0]->{conf} );
        $ua->env_proxy();
        return $ua;
    }
);

has casSrvList   => ( is => 'rw', default => sub { {} }, );
has casAppList   => ( is => 'rw', default => sub { {} }, );
has srvRules     => ( is => 'rw', default => sub { {} }, );
has spLevelRules => ( is => 'rw', default => sub { {} }, );
has spRules      => ( is => 'rw', default => sub { {} }, );
has spMacros     => ( is => 'rw', default => sub { {} }, );

# XML parser
has parser => (
    is      => 'rw',
    builder => sub {
        return XML::LibXML->new( load_ext_dtd => 0, expand_entities => 0 );
    }
);

# RUNNING METHODS

# Load CAS server list
sub loadSrv {
    my ($self) = @_;
    unless ( $self->conf->{casSrvMetaDataOptions}
        and %{ $self->conf->{casSrvMetaDataOptions} } )
    {
        $self->logger->error("No CAS servers found in configuration");
        return 0;
    }
    $self->casSrvList( $self->conf->{casSrvMetaDataOptions} );

    # Set rule
    foreach ( keys %{ $self->conf->{casSrvMetaDataOptions} } ) {
        my $cond = $self->conf->{casSrvMetaDataOptions}->{$_}
          ->{casSrvMetaDataOptionsResolutionRule};
        if ( length $cond ) {
            my $rule_sub =
              $self->p->buildRule( $cond, "CAS server resolution" );
            if ($rule_sub) {
                $self->srvRules->{$_} = $rule_sub;
            }
        }
    }
    return 1;
}

# Load CAS application list
sub loadApp {
    my ($self) = @_;
    unless ( $self->conf->{casAppMetaDataOptions}
        and %{ $self->conf->{casAppMetaDataOptions} } )
    {
        $self->logger->info("No CAS apps found in configuration");
    }

    foreach ( keys %{ $self->conf->{casAppMetaDataOptions} } ) {

        my $valid = 1;

        # Load access rule
        my $rule =
          $self->conf->{casAppMetaDataOptions}->{$_}
          ->{casAppMetaDataOptionsRule};
        if ( length $rule ) {
            $rule = $self->p->buildRule( $rule, "access rule for App $_" );
            unless ($rule) {
                $valid = 0;
            }
        }

        # Required authentication level rule
        my $levelrule = $self->conf->{casAppMetaDataOptions}->{$_}
          ->{casAppMetaDataOptionsAuthnLevel} || 0;
        $levelrule = $self->p->buildRule( $levelrule,
            "required authentication level" . " rule for App $_" );
        unless ($levelrule) {
            $valid = 0;
        }

        # Load per-application macros
        my $macros         = $self->conf->{casAppMetaDataMacros}->{$_};
        my $compiledMacros = {};
        for my $macroAttr ( keys %{$macros} ) {
            my $macroRule = $macros->{$macroAttr};
            if ( length $macroRule ) {
                $macroRule = $self->p->HANDLER->substitute($macroRule);
                if ( $macroRule = $self->p->HANDLER->buildSub($macroRule) ) {
                    $compiledMacros->{$macroAttr} = $macroRule;
                }
                else {
                    $self->logger->error(
"Unable to build macro $macroAttr for CAS Application $_: "
                          . $self->p->HANDLER->tsv->{jail}->error );
                    $valid = 0;
                }
            }
        }

        if ($valid) {
            $self->casAppList->{$_} =
              $self->conf->{casAppMetaDataOptions}->{$_};
            $self->spRules->{$_}      = $rule;
            $self->spLevelRules->{$_} = $levelrule;
            $self->spMacros->{$_}     = $compiledMacros;
        }
        else {
            $self->logger->error(
                "CAS Application $_ has errors and will be ignored");

        }
    }
    return 1;
}

sub sendSoapResponse {
    my ( $self, $req, $s ) = @_;
    $self->logger->debug("Send response: $s");
    return [
        200,
        [
            'Content-Length' => length($s),
            'Content-Type'   => 'application/soap+xml',
        ],
        [$s]
    ];
}

# Try to recover the CAS session corresponding to id and return session data
# If id is set to undef, return a new session
sub getCasSession {
    my ( $self, $id, $info, $hs ) = @_;

    my %storage = (
        storageModule        => $self->conf->{casStorage},
        storageModuleOptions => $self->conf->{casStorageOptions},
    );
    unless ( $storage{storageModule} ) {
        %storage = (
            storageModule        => $self->conf->{globalStorage},
            storageModuleOptions => $self->conf->{globalStorageOptions},
        );
    }

    my $casSession = Lemonldap::NG::Common::Session->new( {
            %storage,
            cacheModule        => $self->conf->{localSessionStorage},
            cacheModuleOptions => $self->conf->{localSessionStorageOptions},
            id                 => $id,
            kind               => $self->sessionKind,
            ( $info ? ( info => $info ) : () ),
            hashStore => $hs // $self->conf->{hashedSessionStore},
        }
    );

    if ( $casSession->error ) {
        if ($id) {
            $self->userLogger->notice("CAS session $id isn't yet available");
        }
        else {
            $self->logger->error("Unable to create new CAS session");
            $self->logger->error( $casSession->error );
        }
        return undef;
    }

    return $casSession;
}

# Return an error for CAS VALIDATE request
sub returnCasValidateError {
    my ( $self, $req ) = @_;

    return [ 200, [ 'Content-Length' => 4 ], ["no\n\n"] ];
}

# Return success for CAS VALIDATE request
sub returnCasValidateSuccess {
    my ( $self, $req, $username, $pgtIou, $proxies, $attributes ) = @_;

    return $self->sendSoapResponse( $req, "yes\n$username\n" );
}

# Return an error for CAS SERVICE VALIDATE request
sub returnCasServiceValidateError {
    my ( $self, $req, $code, $text ) = @_;

    $code ||= 'INTERNAL_ERROR';
    $text ||= 'No description provided';

    return $self->sendSoapResponse(
        $req, "<cas:serviceResponse xmlns:cas='http://www.yale.edu/tp/cas'>
\t<cas:authenticationFailure code=\"$code\">
\t\t$text
\t</cas:authenticationFailure>
</cas:serviceResponse>\n"
    );
}

# Return success for CAS SERVICE VALIDATE request
sub returnCasServiceValidateSuccess {
    my ( $self, $req, $username, $pgtIou, $proxies, $attributes ) = @_;

    my $s = "<cas:serviceResponse xmlns:cas='http://www.yale.edu/tp/cas'>
\t<cas:authenticationSuccess>
\t\t<cas:user>$username</cas:user>\n";
    if ( defined $attributes ) {
        $s .= "\t\t<cas:attributes>\n";
        foreach my $attribute ( keys %$attributes ) {
            foreach my $value (
                split(
                    $self->conf->{multiValuesSeparator},
                    $attributes->{$attribute}
                )
              )
            {
                $s .= "\t\t\t<cas:$attribute>$value</cas:$attribute>\n";
            }
        }
        $s .= "\t\t</cas:attributes>\n";
    }
    if ( defined $pgtIou ) {
        $self->logger->debug("Add proxy granting ticket $pgtIou in response");
        $s .=
          "\t\t<cas:proxyGrantingTicket>$pgtIou</cas:proxyGrantingTicket>\n";
    }
    if ($proxies) {
        $self->logger->debug("Add proxies $proxies in response");
        $s .= "\t\t<cas:proxies>\n";
        $s .= "\t\t\t<cas:proxy>$_</cas:proxy>\n"
          foreach (
            reverse( split( $self->conf->{multiValuesSeparator}, $proxies ) ) );
        $s .= "\t\t</cas:proxies>\n";
    }
    $s .= "\t</cas:authenticationSuccess>\n</cas:serviceResponse>\n";

    return $self->sendSoapResponse( $req, $s );
}

# Return an error for CAS PROXY request
sub returnCasProxyError {
    my ( $self, $req, $code, $text ) = @_;

    $code ||= 'INTERNAL_ERROR';
    $text ||= 'No description provided';

    $self->logger->debug("Return CAS proxy error $code ($text)");

    return $self->sendSoapResponse(
        $req, "<cas:serviceResponse xmlns:cas='http://www.yale.edu/tp/cas'>
\t<cas:proxyFailure code=\"$code\">
\t\t$text
\t</cas:proxyFailure>
</cas:serviceResponse>\n"
    );
}

# Return success for CAS PROXY request
sub returnCasProxySuccess {
    my ( $self, $req, $ticket ) = @_;

    $self->logger->debug("Return CAS proxy success with ticket $ticket");

    return $self->sendSoapResponse(
        $req, "<cas:serviceResponse xmlns:cas='http://www.yale.edu/tp/cas'>
\t<cas:proxySuccess>
\t\t<cas:proxyTicket>$ticket</cas:proxyTicket>
\t</cas:proxySuccess>
</cas:serviceResponse>\n"
    );
}

# Change the ID of secondary sessions (during upgrade)
sub updateCasSecondarySessions {
    my ( $self, $req, $old_session_id, $new_session_id ) = @_;

    # Find CAS sessions
    my $moduleOptions;
    if ( $self->conf->{casStorage} ) {
        $moduleOptions = $self->conf->{casStorageOptions} || {};
        $moduleOptions->{backend} = $self->conf->{casStorage};
    }
    else {
        $moduleOptions = $self->conf->{globalStorageOptions} || {};
        $moduleOptions->{backend} = $self->conf->{globalStorage};
    }
    my $module = "Lemonldap::NG::Common::Apache::Session";

    my $cas_sessions =
      $module->searchOn( $moduleOptions, "_cas_id", $old_session_id );

    if (
        my @cas_sessions_keys =
        grep { $cas_sessions->{$_}->{_session_kind} eq $self->sessionKind }
        keys %$cas_sessions
      )
    {

        foreach my $cas_session (@cas_sessions_keys) {

            # Get session
            $self->logger->debug("Retrieve CAS session $cas_session");

            my $casSession = $self->getCasSession($cas_session, undef, 0);

            # Delete session
            if ($casSession) {
                $casSession->update( { _cas_id => $new_session_id } );
            }
        }
    }

    return;
}

# Find and delete CAS sessions bounded to a primary session
sub deleteCasSecondarySessions {
    my ( $self, $session_id ) = @_;
    my $result = 1;

    # Find CAS sessions
    my $moduleOptions;
    if ( $self->conf->{casStorage} ) {
        $moduleOptions = $self->conf->{casStorageOptions} || {};
        $moduleOptions->{backend} = $self->conf->{casStorage};
    }
    else {
        $moduleOptions = $self->conf->{globalStorageOptions} || {};
        $moduleOptions->{backend} = $self->conf->{globalStorage};
    }
    my $module = "Lemonldap::NG::Common::Apache::Session";

    my $cas_sessions =
      $module->searchOn( $moduleOptions, "_cas_id", $session_id );

    if (
        my @cas_sessions_keys =
        grep { $cas_sessions->{$_}->{_session_kind} eq $self->sessionKind }
        keys %$cas_sessions
      )
    {

        foreach my $cas_session (@cas_sessions_keys) {

            # Get session
            $self->logger->debug("Retrieve CAS session $cas_session");

            my $casSession = $self->getCasSession($cas_session, undef, 0);

            # Delete session
            $result = $self->deleteCasSession($casSession);
        }
    }
    else {
        $self->logger->debug("No CAS session found for session $session_id ");
    }

    return $result;

}

# Delete an opened CAS session
sub deleteCasSession {
    my ( $self, $session ) = @_;

    # Check session object
    unless ( $session && $session->data ) {
        $self->logger->error("No session to delete");
        return 0;
    }

    # Get session_id
    my $session_id = $session->id;

    # Delete session
    unless ( $session->remove ) {
        $self->logger->error( $session->error );
        return 0;
    }

    $self->logger->debug("CAS session $session_id deleted");

    return 1;
}

# Call proxy granting URL on CAS client
sub callPgtUrl {
    my ( $self, $pgtUrl, $pgtIou, $pgtId ) = @_;

    # Build URL
    my $url =
        $pgtUrl
      . ( $pgtUrl =~ /\?/ ? '&' : '?' )
      . build_urlencoded( pgtIou => $pgtIou, pgtId => $pgtId );

    $self->logger->debug("Call URL $url");

    # GET URL
    my $response = $self->ua->get($url);

    # Return result
    return $response->is_success();
}

# Get Server Login URL
sub getServerLoginURL {
    my ( $self, $service, $srvConf ) = @_;

    return "$srvConf->{casSrvMetaDataOptionsUrl}/login?"
      . build_urlencoded( service => $service );
}

# Get Server Logout URL
sub getServerLogoutURL {
    my ( $self, $service, $srvUrl ) = @_;

    return "$srvUrl/logout?" . build_urlencoded( service => $service );
}

# Validate ST
sub validateST {
    my ( $self, $req, $service, $ticket, $srvConf, $proxied ) = @_;

    my %prm = ( service => $service, ticket => $ticket );

    my $samlValidate = $srvConf->{casSrvMetaDataOptionsSamlValidate};

    my $proxy_url;
    if (%$proxied) {
        $proxy_url = $self->p->fullUrl($req);

        # TODO: @coudot: why die here without any message ?
        die if ( $proxy_url =~ /casProxy=1/ );
        $proxy_url .= ( $proxy_url =~ /\?/ ? '&' : '?' ) . 'casProxy=1';

        $self->logger->debug("CAS Proxy URL: $proxy_url");

        $req->data->{casProxyUrl} = $proxy_url;

        $prm{pgtUrl} = $proxy_url;
    }

    my $request = do {
        if ($samlValidate) {
            $self->_buildRequestForSamlValidate(
                $srvConf->{casSrvMetaDataOptionsUrl}, %prm );
        }
        else {
            $self->_buildRequestForServiceValidate(
                $srvConf->{casSrvMetaDataOptionsUrl}, %prm );
        }
    };

    my $response = $self->ua->request($request);

    $self->logger->debug(
        "Get CAS serviceValidate response: " . $response->as_string );

    return 0 if $response->is_error;

    my $xml = $response->decoded_content( default_charset => 'UTF-8' );

    my $extract_result = do {
        if ($samlValidate) {
            $self->getAttributesFromSamlValidateResponse($xml);
        }
        else {
            $self->getAttributesFromServiceValidateResponse($xml);
        }
    };

    if ( $extract_result->{success} ) {
        my $user       = $extract_result->{user};
        my $attributes = $extract_result->{attributes};

        # Flatten each list of attribute values
        my $result = {};
        while ( my ( $attribute, $values ) = each %$attributes ) {
            $result->{$attribute} =
              join( $self->conf->{multiValuesSeparator}, @$values );
        }

        if ( $proxy_url and $extract_result->{pgtId} ) {
            $self->logger->debug("Storing PGT id");
            $req->data->{pgtId} = $extract_result->{pgtId};
        }

        return ( $user, $result );
    }
    else {
        my $error = $extract_result->{message};
        $self->logger->error(
            "Failed to validate Service Ticket $ticket: $error");
        return 0;
    }
}

sub _buildRequestForServiceValidate {
    my ( $self, $url, %prm ) = @_;

    my $serviceValidateUrl = "$url/serviceValidate?" . build_urlencoded(%prm);
    $self->logger->debug("Validate ST on CAS URL $serviceValidateUrl");

    return HTTP::Request->new( GET => $serviceValidateUrl );
}

sub _buildRequestForSamlValidate {
    my ( $self, $url, %prm ) = @_;

    my $serviceValidateUrl =
      "$url/samlValidate?" . build_urlencoded( TARGET => $prm{service} );

    $self->logger->debug("Validate ST on CAS URL $serviceValidateUrl");

    return HTTP::Request->new(
        POST => $serviceValidateUrl,
        [ 'Content-Type' => 'text/xml; charset=UTF-8' ],
        $self->buildSamlValidateRequest( $prm{ticket} )
    );
}

# Store PGT IOU and PGT ID
sub storePGT {
    my ( $self, $pgtIou, $pgtId ) = @_;

    my $infos = {
        type   => 'casPgtId',
        _utime => time,
        pgtIou => $pgtIou,
        pgtId  => $pgtId
    };

    my $pgtSession = $self->getCasSession( undef, $infos );

    return $pgtSession->id;
}

# Retrieve Proxy Ticket
sub retrievePT {
    my ( $self, $service, $pgtId, $srvConf ) = @_;

    my $proxyUrl = "$srvConf->{casSrvMetaDataOptionsUrl}/proxy?"
      . build_urlencoded( targetService => $service, pgt => $pgtId );

    my $response = $self->ua->get($proxyUrl);

    $self->logger->debug( "Get CAS proxy response: " . $response->as_string );

    return 0 if $response->is_error;

    my $casResponse = $self->parser->parse_string( $response->decoded_content )
      ->documentElement;

    if ( my $failure = $casResponse->getElementsByTagName('cas:proxyFailure') )
    {
        $self->logger->error(
            "Failed to get PT: " . $failure->string_value =~ s/\R//r );
        return 0;
    }

    my $pt =
      $casResponse->find('//cas:proxySuccess/cas:proxyTicket')->string_value;

    return $pt;
}

# Get CAS App from service URL
sub getCasApp {
    my ( $self, $uri_param ) = @_;

    my $uri      = URI->new($uri_param);
    my $hostname = $uri->authority;
    my $uriCanon = $uri->canonical;
    return undef unless $hostname;

    my $prefixConfKey;
    my $longestCandidate = "";
    my $hostnameConfKey;

    for my $app ( keys %{ $self->casAppList } ) {

        for my $appservice (
            split(
                /\s+/, $self->casAppList->{$app}->{casAppMetaDataOptionsService}
            )
          )
        {
            my $candidateUri   = URI->new($appservice);
            my $candidateHost  = $candidateUri->authority;
            my $candidateCanon = $candidateUri->canonical;

            # Try to match prefix, remembering the longest match found
            if ( index( $uriCanon, $candidateCanon ) == 0 ) {
                if ( length($longestCandidate) < length($candidateCanon) ) {
                    $longestCandidate = $candidateCanon;
                    $prefixConfKey    = $app;
                }
            }

            # Try to match host, only if strict matching is disabled
            unless ( $self->conf->{casStrictMatching} ) {
                $hostnameConfKey = $app if ( $hostname eq $candidateHost );
            }
        }
    }

    # Application found by prefix has priority
    return $prefixConfKey if $prefixConfKey;
    $self->logger->warn(
            "Matched CAS service $hostnameConfKey based on hostname only. "
          . "This will be deprecated in a future version" )
      if $hostnameConfKey;
    return $hostnameConfKey;
}

# This method returns the host part of the given URL
# If the URL has no scheme, return it completely
# http://example.com/uri => example.com
# foo.bar => foo.bar
sub _getHostForService {
    my ( $self, $service ) = @_;
    return undef unless $service;

    my $uri = URI->new($service);
    return $uri->scheme ? $uri->host : $uri->as_string;
}

# Build the XML Logout request that gets sent to CAS applications
sub buildLogoutRequest {
    my ( $self, $ticket ) = @_;

    my $now = strftime( "%Y-%m-%dT%TZ", gmtime() );

    my $doc = XML::LibXML::Document->new( '1.0', 'UTF-8' );
    my $LogoutRequest =
      $doc->createElementNS( "urn:oasis:names:tc:SAML:2.0:protocol",
        "samlp:LogoutRequest" );

    # NB: $ticket is a good enough random ID :-)
    # NB: although it looks alike SAML, the CAS SLO protocol is specific
    $LogoutRequest->setAttribute( "ID",           $ticket );
    $LogoutRequest->setAttribute( "Version",      "2.0" );
    $LogoutRequest->setAttribute( "IssueInstant", $now );
    my $NameID = $doc->createElementNS( "urn:oasis:names:tc:SAML:2.0:assertion",
        "saml:NameID" );
    $NameID->appendText('@NOT_USED@');
    $LogoutRequest->appendChild($NameID);
    my $SessionIndex =
      $doc->createElementNS( "urn:oasis:names:tc:SAML:2.0:protocol",
        "samlp:SessionIndex" );
    $SessionIndex->appendText($ticket);
    $LogoutRequest->appendChild($SessionIndex);
    my $logout_request_text = $LogoutRequest->toString;

    $self->logger->debug("Generated CAS logout request: $logout_request_text");
    return $logout_request_text;
}

sub buildSamlValidateRequest {
    my ( $self, $ticket ) = @_;

    my $now = strftime( "%Y-%m-%dT%TZ", gmtime() );

    my $document = XML::LibXML->createDocument( "1.0", "UTF-8" );

    my $envelope =
      $document->createElementNS( "http://schemas.xmlsoap.org/soap/envelope/",
        "SOAP-ENV:Envelope" );
    $document->setDocumentElement($envelope);

    my $body =
      $document->createElementNS( "http://schemas.xmlsoap.org/soap/envelope/",
        "SOAP-ENV:Body" );
    $envelope->appendChild($body);

    my $request =
      $document->createElementNS( "urn:oasis:names:tc:SAML:1.0:protocol",
        "samlp:Request" );
    $request->setAttribute( "MajorVersion", 1 );
    $request->setAttribute( "MinorVersion", 1 );
    $request->setAttribute( "RequestID",
        "_" . unpack( "H*", Crypt::URandom::urandom(16) ) );
    $request->setAttribute( "IssueInstant", $now );
    $body->appendChild($request);

    my $assert_art =
      $document->createElementNS( "urn:oasis:names:tc:SAML:1.0:protocol",
        "samlp:AssertionArtifact" );
    $assert_art->appendText($ticket);
    $request->appendChild($assert_art);

    my $request_text = $envelope->toString;
    $self->logger->debug("Generated CAS samlValidate request: $request_text");
    return $request_text;
}

sub getServiceTicketFromSamlRequest {
    my ( $self, $soap_message ) = @_;
    my $artifact = eval {
        my $dom = $self->parser->parse_string($soap_message);
        my $xpc = XML::LibXML::XPathContext->new($dom);
        $xpc->registerNs( 'samlp', 'urn:oasis:names:tc:SAML:1.0:protocol' );
        $xpc->registerNs( 'saml',  'urn:oasis:names:tc:SAML:1.0:assertion' );
        $xpc->registerNs( 'SOAP-ENV',
            'http://schemas.xmlsoap.org/soap/envelope/' );
        $xpc->find('//samlp:AssertionArtifact/text()')->string_value();

    };
    if ($@) {
        $self->logger->error("Could not process SamlValidate request: $@");
        return;
    }
    return $artifact;
}

sub getAttributesFromServiceValidateResponse {
    my ( $self, $xml ) = @_;

    my $casResponse = $self->parser->parse_string($xml)->documentElement;

    unless ( $casResponse->nodeName eq "cas:serviceResponse" ) {
        return {
            success => 0,
            message => (
                "unexpected top-level XML element: " . $casResponse->nodeName
            ),
        };
    }

    if ( my $failure =
        $casResponse->getElementsByTagName('cas:authenticationFailure') )
    {
        return {
            success => 0,
            message => ( $failure->string_value =~ s/\R//r ),
        };
    }

    my $pgtId;

    # Get proxy data and store pgtId
    my $pgtIou =
      $casResponse->find('//cas:authenticationSuccess/cas:proxyGrantingTicket')
      ->string_value;

    if ($pgtIou) {
        my $moduleOptions;
        if ( $self->conf->{casStorage} ) {
            $moduleOptions = $self->conf->{casStorageOptions} || {};
            $moduleOptions->{backend} = $self->conf->{casStorage};
        }
        else {
            $moduleOptions = $self->conf->{globalStorageOptions} || {};
            $moduleOptions->{backend} = $self->conf->{globalStorage};
        }
        my $module = "Lemonldap::NG::Common::Apache::Session";

        my $pgtIdSessions =
          $module->searchOn( $moduleOptions, "pgtIou", $pgtIou );

        foreach my $id (
            grep { $pgtIdSessions->{$_}->{_session_kind} eq $self->sessionKind }
            keys %$pgtIdSessions
          )
        {

            # There should be only on session
            my $pgtIdSession = $self->getCasSession($id, undef, 0) or next;
            $pgtId = $pgtIdSession->data->{pgtId};
            $pgtIdSession->remove;
        }
    }

    my $user =
      $casResponse->find('//cas:authenticationSuccess/cas:user')->string_value;
    unless ($user) {
        return {
            success => 0,
            message => "Could not extract cas:user field from XML response",
        };
    }

    my $attrs = Hash::MultiValue->new;
    if ( my $casAttr =
        $casResponse->find('//cas:authenticationSuccess/cas:attributes/cas:*') )
    {
        $casAttr->foreach(
            sub {
                my $k = $_[0]->localname;
                my $v = $_[0]->textContent;
                utf8::encode($v);
                $attrs->add( $k => $v );
            }
        );
    }
    return {
        success    => 1,
        user       => $user,
        attributes => $attrs->multi,
        pgtId      => $pgtId,
    };
}

sub getAttributesFromSamlValidateResponse {
    my ( $self, $soap_message ) = @_;
    my $result = eval {
        my $dom = $self->parser->parse_string($soap_message);
        my $xpc = XML::LibXML::XPathContext->new($dom);
        $xpc->registerNs( 'samlp', 'urn:oasis:names:tc:SAML:1.0:protocol' );
        $xpc->registerNs( 'saml',  'urn:oasis:names:tc:SAML:1.0:assertion' );
        $xpc->registerNs( 'SOAP-ENV',
            'http://schemas.xmlsoap.org/soap/envelope/' );
        my $response =
          $xpc->find('/SOAP-ENV:Envelope/SOAP-ENV:Body/samlp:Response')->pop;
        if ($response) {
            return $self->_saml_validate_response($response);
        }
        else {
            return {
                success => 0,
                message =>
                  "samlValidate response did not contain a Response element",
            };
        }
    };
    if ($@) {
        return {
            success => 0,
            message => "Could not process samlValidate response: $@",
        };
    }
    return $result;
}

sub _saml_validate_response {
    my ( $self, $response ) = @_;
    my $status =
      $response->find('./samlp:Status/samlp:StatusCode/@Value')->string_value();
    if ( $status and $status eq "samlp:Success" ) {
        my $user =
          $response->find( './saml:Assertion'
              . '/*[self::saml:AttributeStatement or self::saml:AuthenticationStatement]'
              . '/saml:Subject/saml:NameIdentifier/text()' )->string_value();

        if ($user) {
            my $attributes = $self->_saml_validate_get_attributes($response);
            return {
                success    => 1,
                user       => $user,
                attributes => $attributes,
            };
        }
        else {
            return {
                success => 0,
                message => "No subject found in samlValidate response",
            };
        }
    }
    else {
        my $display_status = $status // '<not found>';
        return {
            success => 0,
            message => "samlValidate response status is $display_status",
        };
    }
}

sub _saml_validate_get_attributes {
    my ( $self, $response ) = @_;
    my $attributes     = {};
    my @attribute_list = $response->find(
        './saml:Assertion' . '/saml:AttributeStatement/saml:Attribute' )
      ->get_nodelist;
    for my $attribute (@attribute_list) {
        my $attribute_name = $attribute->getAttribute("AttributeName");
        if ($attribute_name) {
            my @attribute_values =
              $attribute->find("./saml:AttributeValue")->get_nodelist;
            if (@attribute_values) {
                $attributes->{$attribute_name} = [
                    map {
                        my $text = $_->textContent;
                        utf8::encode($text);
                        $text =~ s/^\s+//;
                        $text =~ s/\s+$//;
                        $text;
                    } @attribute_values
                ];
            }
        }
    }

    return $attributes;
}

sub returnSamlValidateSuccess {
    my ( $self, $req, $username, $pgtIou, $proxies, $attributes ) = @_;

    my $document = XML::LibXML->createDocument( "1.0", "UTF-8" );

    my $envelope =
      $document->createElementNS( "http://schemas.xmlsoap.org/soap/envelope/",
        "SOAP-ENV:Envelope" );
    $document->setDocumentElement($envelope);

    my $body =
      $document->createElementNS( "http://schemas.xmlsoap.org/soap/envelope/",
        "SOAP-ENV:Body" );
    $envelope->appendChild($body);

    my $issueInstant = strftime( "%Y-%m-%dT%TZ", gmtime() );
    my $notAfter     = strftime( "%Y-%m-%dT%TZ", gmtime( time + 300 ) );
    my $authInstant  = strftime( "%Y-%m-%dT%TZ",
        gmtime( $req->sessionInfo->{_lastAuthnUTime} ) );
    my $response =
      $document->createElementNS( "urn:oasis:names:tc:SAML:1.0:protocol",
        "Response" );
    $response->setNamespace( "urn:oasis:names:tc:SAML:1.0:assertion",
        "saml", 0 );
    $response->setNamespace( "urn:oasis:names:tc:SAML:1.0:protocol",
        "samlp", 0 );

    $response->setAttribute( "IssueInstant", $issueInstant );
    $response->setAttribute( "MajorVersion", "1" );
    $response->setAttribute( "MinorVersion", "1" );
    $body->appendChild($response);

    my $status =
      $document->createElementNS( "urn:oasis:names:tc:SAML:1.0:protocol",
        "Status" );
    $response->appendChild($status);

    my $status_code =
      $document->createElementNS( "urn:oasis:names:tc:SAML:1.0:protocol",
        "StatusCode" );
    $status_code->setAttribute( "Value", "samlp:Success" );
    $status->appendChild($status_code);

    my $assertion =
      $document->createElementNS( "urn:oasis:names:tc:SAML:1.0:assertion",
        "Assertion" );
    $assertion->setAttribute( "AssertionID",
        "_" . unpack( "H*", Crypt::URandom::urandom(16) ) );
    $assertion->setAttribute( "IssueInstant", $issueInstant );
    $assertion->setAttribute( "MajorVersion", "1" );
    $assertion->setAttribute( "MinorVersion", "1" );

    $response->appendChild($assertion);

    my $assertion_conditions =
      $document->createElementNS( "urn:oasis:names:tc:SAML:1.0:assertion",
        "Conditions" );
    $assertion_conditions->setAttribute( "NotBefore",    $issueInstant );
    $assertion_conditions->setAttribute( "NotOnOrAfter", $notAfter );
    $assertion->appendChild($assertion_conditions);

    my $authentication_statement =
      $document->createElementNS( "urn:oasis:names:tc:SAML:1.0:assertion",
        "AuthenticationStatement" );
    $authentication_statement->setAttribute( "AuthenticationInstant",
        $authInstant );
    $authentication_statement->setAttribute( "AuthenticationMethod",
        "urn:oasis:names:tc:SAML:1.0:am:unspecified" );
    $assertion->appendChild($authentication_statement);

    my $subject =
      $document->createElementNS( "urn:oasis:names:tc:SAML:1.0:assertion",
        "Subject" );
    $authentication_statement->appendChild($subject);
    my $name_identifier =
      $document->createElementNS( "urn:oasis:names:tc:SAML:1.0:assertion",
        "NameIdentifier" );
    $name_identifier->appendText($username);
    $subject->appendChild($name_identifier);

    my $attribute_statement =
      $document->createElementNS( "urn:oasis:names:tc:SAML:1.0:assertion",
        "AttributeStatement" );
    $attribute_statement->appendChild( $subject->cloneNode(1) );
    $assertion->appendChild($attribute_statement);

    if ( defined $attributes ) {
        foreach my $attribute ( keys %$attributes ) {
            my $saml_attribute = $document->createElementNS(
                "urn:oasis:names:tc:SAML:1.0:assertion", "Attribute" );
            $saml_attribute->setAttribute( "AttributeName", $attribute );
            $saml_attribute->setAttribute( "AttributeNamespace",
                "http://www.ja-sig.org/products/cas/" );
            my $has_value;

            foreach my $value (
                split(
                    $self->conf->{multiValuesSeparator},
                    $attributes->{$attribute}
                )
              )
            {
                my $attribute_value = $document->createElementNS(
                    "urn:oasis:names:tc:SAML:1.0:assertion",
                    "AttributeValue" );
                utf8::downgrade($value);
                $attribute_value->appendText($value);
                $saml_attribute->appendChild($attribute_value);
                $has_value = 1;
            }

            $attribute_statement->appendChild($saml_attribute) if $has_value;
        }
    }

    my $soap_response = $envelope->toString;
    utf8::encode($soap_response);
    return $self->sendSoapResponse( $req, $soap_response );
}

sub returnSamlValidateError {
    my ( $self, $req, $code, $reason ) = @_;

    my $saml_code =
      { INVALID_REQUEST => "Requester", INVALID_TICKET => "Requester" }->{$code}
      // "Responder";

    my $document = XML::LibXML->createDocument( "1.0", "UTF-8" );

    my $envelope =
      $document->createElementNS( "http://schemas.xmlsoap.org/soap/envelope/",
        "SOAP-ENV:Envelope" );
    $document->setDocumentElement($envelope);

    my $body =
      $document->createElementNS( "http://schemas.xmlsoap.org/soap/envelope/",
        "SOAP-ENV:Body" );
    $envelope->appendChild($body);

    my $response =
      $document->createElementNS( "urn:oasis:names:tc:SAML:1.0:protocol",
        "Response" );
    $response->setNamespace( "urn:oasis:names:tc:SAML:1.0:assertion",
        "saml", 0 );
    $response->setNamespace( "urn:oasis:names:tc:SAML:1.0:protocol",
        "samlp", 0 );

    $response->setAttribute( "IssueInstant",
        strftime( "%Y-%m-%dT%TZ", gmtime() ) );
    $response->setAttribute( "MajorVersion", "1" );
    $response->setAttribute( "MinorVersion", "1" );
    $body->appendChild($response);

    my $status =
      $document->createElementNS( "urn:oasis:names:tc:SAML:1.0:protocol",
        "Status" );
    $response->appendChild($status);

    my $status_code =
      $document->createElementNS( "urn:oasis:names:tc:SAML:1.0:protocol",
        "StatusCode" );
    $status_code->setAttribute( "Value", "samlp:$saml_code" );
    $status->appendChild($status_code);

    my $status_message =
      $document->createElementNS( "urn:oasis:names:tc:SAML:1.0:protocol",
        "StatusMessage" );
    $status_message->appendText($reason);
    $status->appendChild($status_message);

    my $soap_response = $envelope->toString;
    utf8::encode($soap_response);
    return $self->sendSoapResponse( $req, $soap_response );
}

1;
__END__

=head1 NAME

=encoding utf8

Lemonldap::NG::Portal::Lib::CAS - Common CAS functions

=head1 SYNOPSIS

use Lemonldap::NG::Portal::Lib::CAS;

=head1 DESCRIPTION

This module contains common methods for CAS

=head1 METHODS

=head2 getCasSession

Try to recover the CAS session corresponding to id and return session data
If id is set to undef, return a new session

=head2 returnCasValidateError

Return an error for CAS VALIDATE request

=head2 returnCasValidateSuccess

Return success for CAS VALIDATE request

=head2 deleteCasSecondarySessions

Find and delete CAS sessions bounded to a primary session

=head2 returnCasServiceValidateError

Return an error for CAS SERVICE VALIDATE request

=head2 returnCasServiceValidateSuccess

Return success for CAS SERVICE VALIDATE request

=head2 returnCasProxyError

Return an error for CAS PROXY request

=head2 returnCasProxySuccess

Return success for CAS PROXY request

=head2 deleteCasSession

Delete an opened CAS session

=head2 callPgtUrl

Call proxy granting URL on CAS client

=head1 SEE ALSO

L<Lemonldap::NG::Portal::IssuerDBCAS>

=head1 AUTHORS

=over

=item LemonLDAP::NG team L<http://lemonldap-ng.org/team>

=back

=head1 BUG REPORT

Use OW2 system to report bug or ask for features:
L<https://gitlab.ow2.org/lemonldap-ng/lemonldap-ng/issues>

=head1 DOWNLOAD

Lemonldap::NG is available at
L<https://lemonldap-ng.org/download>

=head1 COPYRIGHT AND LICENSE

See COPYING file for details.

This library is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2, or (at your option)
any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see L<http://www.gnu.org/licenses/>.

=cut
