package Lemonldap::NG::Portal::Lib::CAS;

use strict;
use Mouse;
use Lemonldap::NG::Common::FormEncode;
use XML::Simple;
use Lemonldap::NG::Common::UserAgent;
use URI;

our $VERSION = '2.0.15';

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

has casSrvList => ( is => 'rw', default => sub { {} }, );
has casAppList => ( is => 'rw', default => sub { {} }, );
has srvRules   => ( is => 'rw', default => sub { {} }, );
has spRules    => ( is => 'rw', default => sub { {} }, );
has spMacros   => ( is => 'rw', default => sub { {} }, );

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
            $rule = $self->p->HANDLER->substitute($rule);
            unless ( $rule = $self->p->HANDLER->buildSub($rule) ) {
                $self->logger->error(
                    "Unable to build access rule for CAS Application $_: "
                      . $self->p->HANDLER->tsv->{jail}->error );
                $valid = 0;
            }
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
            $self->spRules->{$_}  = $rule;
            $self->spMacros->{$_} = $compiledMacros;
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
    my ( $self, $id, $info ) = @_;

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

    $self->logger->debug("Return CAS validate error");

    return [ 200, [ 'Content-Length' => 4 ], ["no\n\n"] ];
}

# Return success for CAS VALIDATE request
sub returnCasValidateSuccess {
    my ( $self, $req, $username ) = @_;

    $self->logger->debug("Return CAS validate success with username $username");

    return $self->sendSoapResponse( $req, "yes\n$username\n" );
}

# Return an error for CAS SERVICE VALIDATE request
sub returnCasServiceValidateError {
    my ( $self, $req, $code, $text ) = @_;

    $code ||= 'INTERNAL_ERROR';
    $text ||= 'No description provided';

    $self->logger->debug("Return CAS service validate error $code ($text)");

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

    $self->logger->debug(
        "Return CAS service validate success with username $username");

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

            my $casSession = $self->getCasSession($cas_session);

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

    my $serviceValidateUrl =
      "$srvConf->{casSrvMetaDataOptionsUrl}/serviceValidate?"
      . build_urlencoded(%prm);

    $self->logger->debug("Validate ST on CAS URL $serviceValidateUrl");

    my $response = $self->ua->get($serviceValidateUrl);

    $self->logger->debug(
        "Get CAS serviceValidate response: " . $response->as_string );

    return 0 if $response->is_error;

    my $xml = $response->decoded_content( default_charset => 'UTF-8' );
    utf8::encode($xml);
    $xml = XMLin($xml);

    if ( defined $xml->{'cas:authenticationFailure'} ) {
        $self->logger->error( "Failed to validate Service Ticket $ticket: "
              . $xml->{'cas:authenticationFailure'}->{content} );
        return 0;
    }

    # Get proxy data and store pgtId
    if ($proxy_url) {
        my $pgtIou =
          $xml->{'cas:authenticationSuccess'}->{'cas:proxyGrantingTicket'};

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
                grep {
                    $pgtIdSessions->{$_}->{_session_kind} eq $self->sessionKind
                }
                keys %$pgtIdSessions
              )
            {

                # There should be only on session
                my $pgtIdSession = $self->getCasSession($id) or next;
                $req->data->{pgtId} = $pgtIdSession->data->{pgtId};
                $pgtIdSession->remove;
            }
        }
    }

    my $user  = $xml->{'cas:authenticationSuccess'}->{'cas:user'};
    my $attrs = {};
    if ( my $casAttr = $xml->{'cas:authenticationSuccess'}->{'cas:attributes'} )
    {
        foreach my $k ( keys %$casAttr ) {
            my $v = $casAttr->{$k};
            if ( ref($v) eq "ARRAY" ) {
                $v = join( $self->conf->{multiValuesSeparator}, @$v );
            }
            utf8::encode($v);
            $k =~ s/^cas://;
            $attrs->{$k} = $v;
        }
    }

    # TODO store attributes for UserDBCAS

    return ( $user, $attrs );
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

    my $xml = XMLin( $response->decoded_content );

    if ( defined $xml->{'cas:proxyFailure'} ) {
        $self->logger->error(
            "Failed to get PT: " . $xml->{'cas:proxyFailure'} );
        return 0;
    }

    my $pt = $xml->{'cas:proxySuccess'}->{'cas:proxyTicket'};

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
