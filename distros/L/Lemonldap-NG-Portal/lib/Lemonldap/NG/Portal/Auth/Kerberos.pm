package Lemonldap::NG::Portal::Auth::Kerberos;

use strict;
use Mouse;
use GSSAPI;
use MIME::Base64;
use Lemonldap::NG::Portal::Main::Constants qw(
  PE_BADCREDENTIALS
  PE_ERROR
  PE_FIRSTACCESS
  PE_OK
  PE_SENDRESPONSE
);

our $VERSION = '2.0.12';

extends 'Lemonldap::NG::Portal::Main::Auth';

has allowedDomains => ( is => 'rw', isa => 'ArrayRef' );
has keytab         => ( is => 'rw' );
has AjaxInitScript => ( is => 'rw', default => '' );
has Name           => ( is => 'ro', default => 'Kerberos' );

# Override _Ajax InitCmd
has InitCmd => (
    is      => 'ro',
    default =>
q@$self->p->setHiddenFormValue( $req, kerberos => 0, '', 0 );$self->p->setHiddenFormValue( $req, ajax_auth_token => 0, '', 0 )@
);

has auth_id => ( is => 'ro', default => 'krb' );

with 'Lemonldap::NG::Portal::Auth::_Ajax';

# INITIALIZATION

sub init {
    my $self = shift;
    my $file;
    my $domains;
    unless ( $file = $self->conf->{krbKeytab} ) {
        $self->logger->error('Keytab not defined');
        return 0;
    }

    if ( $domains = $self->conf->{krbAllowedDomains} ) {
        $self->allowedDomains( [ split /[\s,]+/, $domains ] );
    }

    $self->keytab("FILE:$file");
    $self->AjaxInitScript( '<script type="text/javascript" src="'
          . $self->p->staticPrefix
          . '/common/js/kerberosChoice.js"></script>' )
      if $self->conf->{krbByJs};
    return 1;
}

sub auth_route {
    my ( $self, $req ) = @_;

    my $auth = $req->env->{HTTP_AUTHORIZATION};
    if ($auth) {
        return $self->_handle_ajax_response( $req, $auth );
    }
    else {
        return $self->_request_ajax_credential($req);
    }
}

sub extractFormInfo {
    my ( $self, $req ) = @_;

    # This is used when a Combination stack defined different UserDB
    # for different Kerberos domains
    if ( $req->data->{_krbUser} ) {
        $self->logger->debug(
            'Kerberos ticket already validated for ' . $req->data->{_krbUser} );
        return $self->_checkDomains($req);
    }

    my $token_id = $req->param('ajax_auth_token');
    if ($token_id) {
        my $token = $self->get_auth_token( $req, $token_id );
        if ( $token->{user} ) {
            return $self->_krbAuthFinish( $req, $token->{user} );
        }
        else {
            return PE_ERROR;
        }
    }

    # Non-AJAX auth
    my $auth = $req->env->{HTTP_AUTHORIZATION};
    if ($auth) {
        return $self->_handle_response( $req, $auth );
    }
    else {
        return $self->_request_credential($req);
    }
}

sub _request_credential {
    my ( $self, $req ) = @_;

    # Case 1: simple usage or first Kerberos Ajax request
    #         => return 401 to initiate Kerberos
    if ( !$self->{conf}->{krbByJs} or $req->param('kerberos') ) {
        $self->logger->debug('Initialize Kerberos dialog');

        # Case 1.1: Ajax request
        if ( $req->wantJSON ) {
            $req->response( [
                    401,
                    [
                        'WWW-Authenticate' => 'Negotiate',
                        'Content-Type'     => 'application/json',
                        'Content-Length'   => 35
                    ],
                    ['{"error":"Authentication required"}']
                ]
            );
        }

        # Case 1.2: HTML request: display error and initiate Kerberos
        #           dialog
        else {
            $req->error(PE_BADCREDENTIALS);
            push @{ $req->respHeaders }, 'WWW-Authenticate' => 'Negotiate';
            my ( $tpl, $prms ) = $self->p->display($req);
            $req->response(
                $self->p->sendHtml(
                    $req, $tpl,
                    params => $prms,
                    code   => 401
                )
            );
        }
        return PE_SENDRESPONSE;
    }

    # Case 2: Ajax Kerberos request has failed, and javascript has reloaded
    # page with "kerberos=0". Return an error to be able to switch to
    # another backend (Combination)
    elsif ( defined $req->param('kerberos') ) {
        $self->userLogger->warn(
            'Kerberos authentication has failed, back to portal');
        $self->p->setHiddenFormValue( $req, kerberos => 0, '', 0 );
        return PE_BADCREDENTIALS;
    }

    # Case 3: Display kerberos auth page (with javascript)
    else {
        $self->logger->debug( 'Append ' . $self->Name . ' init/script' );

        # Call kerberos.js if Kerberos is the only Auth module
        # kerberosChoice.js is used by Choice
        $self->{AjaxInitScript} =~ s/kerberosChoice/kerberos/;

        # In some Combination scenarios, Kerberos may be called multiple
        # times but we only want to add the JS once
        unless ( $req->data->{_krbJsAlreadySent} ) {

            $req->data->{customScript} .= $self->{AjaxInitScript};
            $self->logger->debug(
                "Send init/script -> " . $req->data->{customScript} );
            $req->data->{_krbJsAlreadySent} = 1;
        }

        #$self->p->setHiddenFormValue( $req, kerberos => 0, '', 0 );
        eval( $self->InitCmd );
        die 'Unable to launch init commmand ' . $self->{InitCmd} if ($@);
        $req->data->{waitingMessage} = 1;
        return PE_FIRSTACCESS;
    }
}

sub _handle_response {
    my ( $self, $req, $auth ) = @_;

    my $client_name = $self->_krb_get_user($auth);
    if ($client_name) {
        return $self->_krbAuthFinish( $req, $client_name );
    }
    else {
        return PE_BADCREDENTIALS;
    }
}

sub _krbAuthFinish {
    my ( $self, $req, $client_name ) = @_;

    $self->userLogger->notice("$client_name authentified by Kerberos");
    $req->data->{_krbUser} = $client_name;
    if ( $self->conf->{krbRemoveDomain} ) {
        $client_name =~ s/^(.*)@.*$/$1/;
    }
    $req->user($client_name);
    return $self->_checkDomains($req);
}

sub _request_ajax_credential {
    my ( $self, $req ) = @_;

    $self->logger->debug('Initialize Kerberos dialog');

    return [
        401,
        [
            'WWW-Authenticate' => 'Negotiate',
            'Content-Type'     => 'application/json',
            'Content-Length'   => 35
        ],
        ['{"error":"Authentication required"}']
    ];
}

sub _handle_ajax_response {
    my ( $self, $req, $auth ) = @_;

    my $client_name = $self->_krb_get_user($auth);
    if ($client_name) {
        return $self->ajax_success( $req, $client_name );
    }
    else {
        $req->wantErrorRender(1);
        return $self->p->do( $req, [ sub { PE_BADCREDENTIALS } ] );
    }
}

sub _krb_get_user {
    my ( $self, $auth ) = @_;

    # Case 4: an "Authorization header" has been sent
    if ( $auth !~ /^Negotiate (.*)$/ ) {
        $self->userLogger->error('Bad authorization header');
        return;
    }

    # Case 5: Kerberos ticket received
    $self->logger->debug("Kerberos ticket received: $1");
    my $data;
    eval { $data = MIME::Base64::decode($1) };
    if ($@) {
        $self->userLogger->error( 'Bad authorization header: ' . $@ );
        return;
    }
    $ENV{KRB5_KTNAME} = $self->keytab;
    $self->logger->debug( "Set KRB5_KTNAME env to " . $ENV{KRB5_KTNAME} );

    # NTML tickets are not part of GSSAPI and not recognized by MIT KRB5
    # since they are a proprietary SSPI mechanism
    if ( substr( $data, 0, 8 ) eq "NTLMSSP\0" ) {
        $self->logger->error(
            'Received ticket is actually a NTLM ticket instead of a Kerberos '
              . 'ticket, make sure the workstation is correctly configured: '
              . 'portal in trusted internet zone, clock synchronization, '
              . 'correct reverse DNS configuration...' );
        return;
    }

    my $status = GSSAPI::Context::accept(
        my $server_context,
        GSS_C_NO_CREDENTIAL,
        $data,
        GSS_C_NO_CHANNEL_BINDINGS,
        my $gss_client_name,
        undef,
        my $gss_output_token,
        my $out_flags,
        my $out_time,
        my $gss_delegated_cred
    );
    unless ($status) {
        $self->logger->error('Unable to accept security context');
        foreach ( $status->generic_message(), $status->specific_message() ) {
            $self->logger->error($_);
        }
        return;
    }
    my $client_name;
    $status = $gss_client_name->display($client_name);
    if ($status) {
        return $client_name;
    }
    $self->logger->error('Unable to display KRB client name');
    foreach ( $status->generic_message(), $status->specific_message() ) {
        $self->logger->error($_);
    }
    return;
}

sub _checkDomains {
    my ( $self, $req ) = @_;

    # If krbAllowedDomains is not defined, allow every domain
    return PE_OK unless ( $self->allowedDomains );

    my ($domain) = $req->data->{_krbUser} =~ m/^.*@(.*)$/;
    if ( grep { lc($_) eq lc($domain) } @{ $self->allowedDomains } ) {
        return PE_OK;
    }
    else {
        $self->userLogger->warn(
            "Received kerberos domain $domain is not allowed");
        return PE_BADCREDENTIALS;
    }
}

sub authenticate {
    return PE_OK;
}

sub authLogout {
    return PE_OK;
}

sub setAuthSessionInfo {
    my ( $self, $req ) = @_;
    $req->{sessionInfo}->{authenticationLevel} = $self->conf->{krbAuthnLevel};
    $req->{sessionInfo}->{_krbUser}            = $req->data->{_krbUser};
    return PE_OK;
}

sub getDisplayType {
    return "logo";
}

1;
