## @file
# CAS Issuer file

## @class
# CAS Issuer class
package Lemonldap::NG::Portal::IssuerDBCAS;

use strict;
use Lemonldap::NG::Portal::Simple;
use Lemonldap::NG::Portal::_CAS;
use base qw(Lemonldap::NG::Portal::_CAS Lemonldap::NG::Portal::_LibAccess);
use URI;

our $VERSION = '1.4.9';

## @method void issuerDBInit()
# Nothing to do
# @return Lemonldap::NG::Portal error code
sub issuerDBInit {
    my $self = shift;

    return PE_OK;
}

## @apmethod int issuerForUnAuthUser()
# Manage CAS request for unauthenticated user
# @return Lemonldap::NG::Portal error code
sub issuerForUnAuthUser {
    my $self = shift;

    # CAS URLs
    my $issuerDBCASPath     = $self->{issuerDBCASPath};
    my $cas_login           = 'login';
    my $cas_logout          = 'logout';
    my $cas_validate        = 'validate';
    my $cas_serviceValidate = 'serviceValidate';
    my $cas_proxyValidate   = 'proxyValidate';
    my $cas_proxy           = 'proxy';

    # Called URL
    my $url = $self->url();
    my $url_path = $self->url( -absolute => 1 );
    $url_path =~ s#^//#/#;

    # 1. LOGIN
    if ( $url_path =~ m#${issuerDBCASPath}${cas_login}# ) {

        $self->lmLog( "URL $url detected as an CAS LOGIN URL", 'debug' );

        # GET parameters
        my $service = $self->getHiddenFormValue('service')
          || $self->param('service');
        my $renew = $self->getHiddenFormValue('renew') || $self->param('renew');
        my $gateway = $self->getHiddenFormValue('gateway')
          || $self->param('gateway');

        # Keep values in hidden fields
        $self->setHiddenFormValue( 'service', $service );
        $self->setHiddenFormValue( 'renew',   $renew );
        $self->setHiddenFormValue( 'gateway', $gateway );

        # Gateway
        if ( $gateway eq 'true' ) {

            # User should already be authenticated
            $self->lmLog(
                "Gateway authentication requested, but user is not logged in",
                'error' );

            # Redirect user to the service
            $self->lmLog( "Redirect user to $service", 'debug' );

            $self->{urldc} = $service;

            return $self->_subProcess(qw(autoRedirect));

        }

    }

    # 2. LOGOUT
    if ( $url_path =~ m#${issuerDBCASPath}${cas_logout}# ) {

        $self->lmLog( "URL $url detected as an CAS LOGOUT URL", 'debug' );

        # GET parameters
        my $logout_url = $self->param('url');

        if ($logout_url) {

            # Display a link to the provided URL
            $self->lmLog( "Logout URL $logout_url will be displayed", 'debug' );

            $self->info( "<h3>" . $self->msg(PM_BACKTOCASURL) . "</h3>" );
            $self->info("<p><a href=\"$logout_url\">$logout_url</a></p>");
            $self->{activeTimer} = 0;

            return PE_CONFIRM;
        }

        return PE_LOGOUT_OK;

    }

    # 3. VALIDATE [CAS 1.0]
    if ( $url_path =~ m#${issuerDBCASPath}${cas_validate}# ) {

        $self->lmLog( "URL $url detected as an CAS VALIDATE URL", 'debug' );

        # GET parameters
        my $service = $self->param('service');
        my $ticket  = $self->param('ticket');
        my $renew   = $self->param('renew');

        # Required parameters: service and ticket
        unless ( $service and $ticket ) {
            $self->lmLog( "Service and Ticket parameters required", 'error' );
            $self->returnCasValidateError();
        }

        $self->lmLog(
            "Get validate request with ticket $ticket for service $service",
            'debug' );

        unless ( $ticket =~ s/^ST-// ) {
            $self->lmLog( "Provided ticket is not a service ticket (ST)",
                'error' );
            $self->returnCasValidateError();
        }

        my $casServiceSession = $self->getCasSession($ticket);

        unless ($casServiceSession) {
            $self->lmLog( "Service ticket session $ticket not found", 'error' );
            $self->returnCasValidateError();
        }

        $self->lmLog( "Service ticket session $ticket found", 'debug' );

        my $service1_uri = URI->new($service);
        my $service2_uri = URI->new( $casServiceSession->data->{service} );

        # Check service
        unless ( $service1_uri->eq($service2_uri) ) {

            # Tolerate that relative URI are the same
            if (   $service1_uri->rel($service2_uri) eq "./"
                or $service2_uri->rel($service1_uri) eq "./" )
            {
                $self->lmLog(
"Submitted service $service1_uri does not exactly match initial service "
                      . $service2_uri
                      . ' but difference is tolerated.',
                    'warn'
                );
            }
            else {
                $self->lmLog(
                    "Submitted service $service does not match initial service "
                      . $casServiceSession->data->{service},
                    'error'
                );
                $self->deleteCasSession($casServiceSession);
                $self->returnCasValidateError();
            }
        }
        else {
            $self->lmLog( "Submitted service $service math initial servce",
                'debug' );
        }

        # Check renew
        if ( $renew eq 'true' ) {

            # We should check the ST was delivered with primary credentials
            $self->lmLog( "Renew flag detected ", 'debug' );

            unless ( $casServiceSession->data->{renew} ) {
                $self->lmLog(
"Authentication renew requested, but not done in former authentication process",
                    'error'
                );
                $self->deleteCasSession($casServiceSession);
                $self->returnCasValidateError();
            }
        }

        # Open local session
        my $localSession =
          $self->getApacheSession( $casServiceSession->data->{_cas_id}, 1 );

        unless ($localSession) {
            $self->lmLog(
                "Local session "
                  . $casServiceSession->data->{_cas_id}
                  . " notfound",
                'error'
            );
            $self->deleteCasSession($casServiceSession);
            $self->returnCasValidateError();
        }

        # Get username
        my $username =
          $localSession->data->{ $self->{casAttr} || $self->{whatToTrace} };

        $self->lmLog( "Get username $username", 'debug' );

        # Return success message
        $self->deleteCasSession($casServiceSession);
        $self->returnCasValidateSuccess($username);

        # We should not be there
        return PE_ERROR;
    }

    # 4. SERVICE VALIDATE [CAS 2.0]
    # 5. PROXY VALIDATE [CAS 2.0]
    if (   ( $url_path =~ m#${issuerDBCASPath}${cas_serviceValidate}# )
        || ( $url_path =~ m#${issuerDBCASPath}${cas_proxyValidate}# ) )
    {

        my $urlType = (
            $url_path =~ m#${issuerDBCASPath}${cas_serviceValidate}#
            ? 'SERVICE'
            : 'PROXY'
        );

        $self->lmLog( "URL $url detected as an CAS $urlType VALIDATE URL",
            'debug' );

        # GET parameters
        my $service = $self->param('service');
        my $ticket  = $self->param('ticket');
        my $pgtUrl  = $self->param('pgtUrl');
        my $renew   = $self->param('renew');

        # PGTIOU
        my $casProxyGrantingTicketIOU;

        # Required parameters: service and ticket
        unless ( $service and $ticket ) {
            $self->lmLog( "Service and Ticket parameters required", 'error' );
            $self->returnCasServiceValidateError( 'INVALID_REQUEST',
                'Missing mandatory parameters (service, ticket)' );
        }

        $self->lmLog(
            "Get "
              . lc($urlType)
              . " validate request with ticket $ticket for service $service",
            'debug'
        );

        # Get CAS session corresponding to ticket
        if ( $urlType eq 'SERVICE' and !( $ticket =~ s/^ST-// ) ) {
            $self->lmLog( "Provided ticket is not a service ticket (ST)",
                'error' );
            $self->returnCasServiceValidateError( 'INVALID_TICKET',
                'Provided ticket is not a service ticket' );
        }
        elsif ( $urlType eq 'PROXY' and !( $ticket =~ s/^(P|S)T-// ) ) {
            $self->lmLog(
                "Provided ticket is not a service or proxy ticket ($1T)",
                'error' );
            $self->returnCasServiceValidateError( 'INVALID_TICKET',
                'Provided ticket is not a service or proxy ticket' );
        }

        my $casServiceSession = $self->getCasSession($ticket);

        unless ($casServiceSession) {
            $self->lmLog( "$urlType ticket session $ticket not found",
                'error' );
            $self->returnCasServiceValidateError( 'INVALID_TICKET',
                'Ticket not found' );
        }

        $self->lmLog( "$urlType ticket session $ticket found", 'debug' );

        my $service1_uri = URI->new($service);
        my $service2_uri = URI->new( $casServiceSession->data->{service} );

        # Check service
        unless ( $service1_uri->eq($service2_uri) ) {

            # Tolerate that relative URI are the same
            if (   $service1_uri->rel($service2_uri) eq "./"
                or $service2_uri->rel($service1_uri) eq "./" )
            {
                $self->lmLog(
"Submitted service $service1_uri does not exactly match initial service "
                      . $service2_uri
                      . ' but difference is tolerated.',
                    'warn'
                );
            }
            else {
                $self->lmLog(
                    "Submitted service $service does not match initial service "
                      . $casServiceSession->data->{service},
                    'error'
                );

                $self->deleteCasSession($casServiceSession);
                $self->returnCasServiceValidateError( 'INVALID_SERVICE',
                    'Submitted service does not match initial service' );
            }
        }
        else {
            $self->lmLog( "Submitted service $service match initial service",
                'debug' );
        }

        # Check renew
        if ( $renew eq 'true' ) {

            # We should check the ST was delivered with primary credentials
            $self->lmLog( "Renew flag detected ", 'debug' );

            unless ( $casServiceSession->data->{renew} ) {
                $self->lmLog(
"Authentication renew requested, but not done in former authentication process",
                    'error'
                );
                $self->deleteCasSession($casServiceSession);
                $self->returnCasValidateError();
            }

        }

        # Proxies (for PROXY VALIDATE only)
        my $proxies = $casServiceSession->data->{proxies};

        # Proxy granting ticket
        if ($pgtUrl) {

            # Create a proxy granting ticket
            $self->lmLog(
                "Create a CAS proxy granting ticket for service $service",
                'debug' );

            my $casProxyGrantingSession = $self->getCasSession();

            if ($casProxyGrantingSession) {

                my $PGinfos;

                # PGT session
                $PGinfos->{type}    = 'casProxyGranting';
                $PGinfos->{service} = $service;
                $PGinfos->{_cas_id} = $casServiceSession->data->{_cas_id};
                $PGinfos->{_utime}  = $casServiceSession->data->{_utime};

                # Trace proxies
                $PGinfos->{proxies} = (
                      $proxies
                    ? $proxies . $self->{multiValuesSeparator} . $pgtUrl
                    : $pgtUrl
                );

                my $casProxyGrantingSessionID = $casProxyGrantingSession->id;
                my $casProxyGrantingTicket =
                  "PGT-" . $casProxyGrantingSessionID;

                $casProxyGrantingSession->update($PGinfos);

                $self->lmLog(
"CAS proxy granting session $casProxyGrantingSessionID created",
                    'debug'
                );

                # Generate the proxy granting ticket IOU
                my $tmpCasSession = $self->getCasSession();

                if ($tmpCasSession) {

                    $casProxyGrantingTicketIOU = "PGTIOU-" . $tmpCasSession->id;
                    $self->deleteCasSession($tmpCasSession);
                    $self->lmLog(
"Generate proxy granting ticket IOU $casProxyGrantingTicketIOU",
                        'debug'
                    );

                    # Request pgtUrl
                    if (
                        $self->callPgtUrl(
                            $pgtUrl,
                            $casProxyGrantingTicketIOU,
                            $casProxyGrantingTicket
                        )
                      )
                    {
                        $self->lmLog(
                            "Proxy granting URL $pgtUrl called with success",
                            'debug' );
                    }
                    else {
                        $self->lmLog(
                            "Error calling proxy granting URL $pgtUrl",
                            'warn' );
                        $casProxyGrantingTicketIOU = undef;
                    }
                }

            }
            else {
                $self->lmLog(
                    "Error in proxy granting ticket management, bypass it",
                    'warn' );
            }
        }

        # Open local session
        my $localSession =
          $self->getApacheSession( $casServiceSession->data->{_cas_id}, 1 );

        unless ($localSession) {
            $self->lmLog(
                "Local session "
                  . $casServiceSession->data->{_cas_id}
                  . " notfound",
                'error'
            );
            $self->deleteCasSession($casServiceSession);
            $self->returnCasServiceValidateError( 'INTERNAL_ERROR',
                'No session associated to ticket' );
        }

        # Get username
        my $username =
          $localSession->data->{ $self->{casAttr} || $self->{whatToTrace} };

        $self->lmLog( "Get username $username", 'debug' );

        # Return success message
        $self->deleteCasSession($casServiceSession);
        $self->returnCasServiceValidateSuccess( $username,
            $casProxyGrantingTicketIOU, $proxies );

        # We should not be there
        return PE_ERROR;
    }

    # 6. PROXY [CAS 2.0]
    if ( $url_path =~ m#${issuerDBCASPath}${cas_proxy}# ) {

        $self->lmLog( "URL $url detected as an CAS PROXY URL", 'debug' );

        # GET parameters
        my $pgt           = $self->param('pgt');
        my $targetService = $self->param('targetService');

        # Required parameters: pgt and targetService
        unless ( $pgt and $targetService ) {
            $self->lmLog( "Pgt and TargetService parameters required",
                'error' );
            $self->returnCasProxyError( 'INVALID_REQUEST',
                'Missing mandatory parameters (pgt, targetService)' );
        }

        $self->lmLog(
            "Get proxy request with ticket $pgt for service $targetService",
            'debug' );

        # Get CAS session corresponding to ticket
        unless ( $pgt =~ s/^PGT-// ) {
            $self->lmLog(
                "Provided ticket is not a proxy granting ticket (PGT)",
                'error' );
            $self->returnCasProxyError( 'BAD_PGT',
                'Provided ticket is not a proxy granting ticket' );
        }

        my $casProxyGrantingSession = $self->getCasSession($pgt);

        unless ($casProxyGrantingSession) {
            $self->lmLog( "Proxy granting ticket session $pgt not found",
                'error' );
            $self->returnCasProxyError( 'BAD_PGT', 'Ticket not found' );
        }

        $self->lmLog( "Proxy granting session $pgt found", 'debug' );

        # Create a proxy ticket
        $self->lmLog( "Create a CAS proxy ticket for service $targetService",
            'debug' );

        my $casProxySession = $self->getCasSession();

        unless ($casProxySession) {
            $self->lmLog( "Unable to create CAS proxy session", 'error' );
            $self->returnCasProxyError( 'INTERNAL_ERROR',
                'Error in proxy session management' );
        }

        my $Pinfos;
        $Pinfos->{type}    = 'casProxy';
        $Pinfos->{service} = $targetService;
        $Pinfos->{_cas_id} = $casProxyGrantingSession->data->{_cas_id};
        $Pinfos->{_utime}  = $casProxyGrantingSession->data->{_utime};
        $Pinfos->{proxies} = $casProxyGrantingSession->data->{proxies};

        $casProxySession->update($Pinfos);

        my $casProxySessionID = $casProxySession->id;
        my $casProxyTicket    = "PT-" . $casProxySessionID;

        $self->lmLog( "CAS proxy session $casProxySessionID created", 'debug' );

        # Return success message
        $self->returnCasProxySuccess($casProxyTicket);

        # We should not be there
        return PE_ERROR;
    }

    return PE_OK;
}

## @apmethod int issuerForAuthUser()
# Manage CAS request for unauthenticated user
# @return Lemonldap::NG::Portal error code
sub issuerForAuthUser {
    my $self = shift;

    # CAS URLs
    my $issuerDBCASPath     = $self->{issuerDBCASPath};
    my $cas_login           = 'login';
    my $cas_logout          = 'logout';
    my $cas_validate        = 'validate';
    my $cas_serviceValidate = 'serviceValidate';
    my $cas_proxyValidate   = 'proxyValidate';
    my $cas_proxy           = 'proxy';

    # Called URL
    my $url = $self->url();
    my $url_path = $self->url( -absolute => 1 );
    $url_path =~ s#^//#/#;

    # Session ID
    my $session_id = $self->{sessionInfo}->{_session_id} || $self->{id};

    # Session creation timestamp
    my $time = $self->{sessionInfo}->{_utime} || time();

    # 1. LOGIN
    if ( $url_path =~ m#${issuerDBCASPath}${cas_login}# ) {

        $self->lmLog( "URL $url detected as an CAS LOGIN URL", 'debug' );

        # GET parameters
        my $service = $self->getHiddenFormValue('service')
          || $self->param('service');
        my $renew = $self->getHiddenFormValue('renew') || $self->param('renew');
        my $gateway = $self->getHiddenFormValue('gateway')
          || $self->param('gateway');
        my $casServiceTicket;

        # Renew
        if ( $renew eq 'true' ) {

            # Authentication must be replayed
            $self->lmLog( "Authentication renew requested", 'debug' );
            $self->{updateSession} = 1;
            $self->{error}         = $self->_subProcess(
                qw(issuerDBInit authInit issuerForUnAuthUser extractFormInfo
                  userDBInit getUser setAuthSessionInfo setSessionInfo
                  setMacros setGroups setPersistentSessionInfo
                  setLocalGroups authenticate store authFinish)
            );

            # Return error if any
            if ( $self->{error} > 0 ) {
                $self->lmLog( "Error in authentication renew process",
                    'error' );
                return $self->{error};
            }
        }

        # If no service defined, exit
        unless ( defined $service ) {
            $self->lmLog( "No service defined in CAS URL", 'debug' );
            return PE_OK;
        }

        # Check access on the service
        my $casAccessControlPolicy = $self->{casAccessControlPolicy};

        if ( $casAccessControlPolicy =~ /^(error|faketicket)$/i ) {
            $self->lmLog( "CAS access control requested on service $service",
                'debug' );

            if ( $self->_grant($service) ) {
                $self->lmLog( "CAS service $service access allowed", 'debug' );
            }

            else {
                $self->lmLog( "CAS service $service access not allowed",
                    'error' );

                if ( $casAccessControlPolicy =~ /^(error)$/i ) {
                    $self->lmLog(
"Return error instead of redirecting user on CAS service",
                        'debug'
                    );
                    return PE_CAS_SERVICE_NOT_ALLOWED;
                }

                else {
                    $self->lmLog(
                        "Redirect user on CAS service with a fake ticket",
                        'debug' );
                    $casServiceTicket = "ST-F4K3T1CK3T";
                }
            }
        }

        unless ($casServiceTicket) {

            # Check last authentication time to decide if
            # the authentication is recent or not
            my $casRenewFlag = 0;
            my $last_authn_utime = $self->{sessionInfo}->{_lastAuthnUTime} || 0;
            if (
                time() - $last_authn_utime < $self->{portalForceAuthnInterval} )
            {
                $self->lmLog(
                    "Authentication is recent, will set CAS renew flag to true",
                    'debug'
                );
                $casRenewFlag = 1;
            }

            # Create a service ticket
            $self->lmLog( "Create a CAS service ticket for service $service",
                'debug' );

            my $casServiceSession = $self->getCasSession();

            unless ($casServiceSession) {
                $self->lmLog( "Unable to create CAS session", 'error' );
                return PE_ERROR;
            }

            my $Sinfos;
            $Sinfos->{type}    = 'casService';
            $Sinfos->{service} = $service;
            $Sinfos->{renew}   = $casRenewFlag;
            $Sinfos->{_cas_id} = $session_id;
            $Sinfos->{_utime}  = $time;

            $casServiceSession->update($Sinfos);

            my $casServiceSessionID = $casServiceSession->id;
            $casServiceTicket = "ST-" . $casServiceSessionID;

            $self->lmLog( "CAS service session $casServiceSessionID created",
                'debug' );
        }

        # Redirect to service
        my $service_url = $service;
        $service_url .= (
            $service =~ /\?/
            ? '&ticket=' . $casServiceTicket
            : '?ticket=' . $casServiceTicket
        );

        $self->lmLog( "Redirect user to $service_url", 'debug' );

        $self->{urldc} = $service_url;

        return $self->_subProcess(qw(autoRedirect));
    }

    # 2. LOGOUT
    if ( $url_path =~ m#${issuerDBCASPath}${cas_logout}# ) {

        $self->lmLog( "URL $url detected as an CAS LOGOUT URL", 'debug' );

        # GET parameters
        my $logout_url = $self->param('url');

        # Delete linked CAS sessions
        $self->deleteCasSecondarySessions($session_id);

        # Delete local session
        unless (
            $self->_deleteSession( $self->getApacheSession( $session_id, 1 ) ) )
        {
            $self->lmLog( "Fail to delete session $session_id ", 'error' );
        }

        if ($logout_url) {

            # Display a link to the provided URL
            $self->lmLog( "Logout URL $logout_url will be displayed", 'debug' );

            $self->info( "<h3>" . $self->msg(PM_BACKTOCASURL) . "</h3>" );
            $self->info("<p><a href=\"$logout_url\">$logout_url</a></p>");
            $self->{activeTimer} = 0;

            return PE_CONFIRM;
        }

        return PE_LOGOUT_OK;

    }

    # 3. VALIDATE [CAS 1.0]
    if ( $url_path =~ m#${issuerDBCASPath}${cas_validate}# ) {

        $self->lmLog( "URL $url detected as an CAS VALIDATE URL", 'debug' );

        # This URL must not be called by authenticated users
        $self->lmLog(
            "CAS VALIDATE URL called by authenticated user, ignore it",
            'info' );

        return PE_OK;
    }

    # 4. SERVICE VALIDATE [CAS 2.0]
    if ( $url_path =~ m#${issuerDBCASPath}${cas_serviceValidate}# ) {

        $self->lmLog( "URL $url detected as an CAS SERVICE VALIDATE URL",
            'debug' );

        # This URL must not be called by authenticated users
        $self->lmLog(
            "CAS SERVICE VALIDATE URL called by authenticated user, ignore it",
            'info'
        );

        return PE_OK;
    }

    # 5. PROXY VALIDATE [CAS 2.0]
    if ( $url_path =~ m#${issuerDBCASPath}${cas_proxyValidate}# ) {

        $self->lmLog( "URL $url detected as an CAS PROXY VALIDATE URL",
            'debug' );

        # This URL must not be called by authenticated users
        $self->lmLog(
            "CAS PROXY VALIDATE URL called by authenticated user, ignore it",
            'info' );

        return PE_OK;
    }

    # 6. PROXY [CAS 2.0]
    if ( $url_path =~ m#${issuerDBCASPath}${cas_proxy}# ) {

        $self->lmLog( "URL $url detected as an CAS PROXY URL", 'debug' );

        # This URL must not be called by authenticated users
        $self->lmLog( "CAS PROXY URL called by authenticated user, ignore it",
            'info' );

        return PE_OK;
    }

    return PE_OK;
}

## @apmethod int issuerLogout()
# Destroy linked CAS sessions
# @return Lemonldap::NG::Portal error code
sub issuerLogout {
    my $self = shift;

    # Session ID
    my $session_id = $self->{sessionInfo}->{_session_id} || $self->{id};

    # Delete linked CAS sessions
    $self->deleteCasSecondarySessions($session_id);

    return PE_OK;
}

1;

__END__

=head1 NAME

=encoding utf8

Lemonldap::NG::Portal::IssuerDBCAS - CAS IssuerDB for LemonLDAP::NG

=head1 DESCRIPTION

CAS Issuer implementation in LemonLDAP::NG

=head1 SEE ALSO

L<Lemonldap::NG::Portal>,
L<http://www.jasig.org/cas/protocol>

=head1 AUTHOR

=over

=item Clement Oudot, E<lt>clem.oudot@gmail.comE<gt>

=item François-Xavier Deltombe, E<lt>fxdeltombe@gmail.com.E<gt>

=item Xavier Guimard, E<lt>x.guimard@free.frE<gt>

=back

=head1 BUG REPORT

Use OW2 system to report bug or ask for features:
L<http://jira.ow2.org>

=head1 DOWNLOAD

Lemonldap::NG is available at
L<http://forge.objectweb.org/project/showfiles.php?group_id=274>

=head1 COPYRIGHT AND LICENSE

=over

=item Copyright (C) 2010 by Xavier Guimard, E<lt>x.guimard@free.frE<gt>

=item Copyright (C) 2012 by François-Xavier Deltombe, E<lt>fxdeltombe@gmail.com.E<gt>

=item Copyright (C) 2010, 2011, 2012 by Clement Oudot, E<lt>clem.oudot@gmail.comE<gt>

=back

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
