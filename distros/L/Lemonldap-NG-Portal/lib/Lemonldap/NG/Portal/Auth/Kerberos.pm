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

our $VERSION = '2.0.2';

extends 'Lemonldap::NG::Portal::Main::Auth';

has keytab         => ( is => 'rw' );
has AjaxInitScript => ( is => 'rw', default => '' );
has Name           => ( is => 'ro', default => 'Kerberos' );
has InitCmd => (
    is      => 'ro',
    default => q@$self->p->setHiddenFormValue( $req, kerberos => 0, '', 0 )@
);

# INITIALIZATION

sub init {
    my ($self) = @_;
    my $file;
    unless ( $file = $self->conf->{krbKeytab} ) {
        $self->error('Keytab not defined');
        return 0;
    }
    $self->keytab("FILE:$file");
    $self->AjaxInitScript( '<script type="text/javascript" src="'
          . $self->p->staticPrefix
          . '/common/js/kerberosChoice.js"></script>' )
      if $self->conf->{krbByJs};
    return 1;
}

sub extractFormInfo {
    my ( $self, $req ) = @_;

    if ( $req->data->{_krbUser} ) {
        $self->logger->debug(
            'Kerberos ticket already validated for ' . $req->data->{_krbUser} );
        return PE_OK;
    }

    my $auth = $req->env->{HTTP_AUTHORIZATION};
    unless ($auth) {

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
        # switch to another backend
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
            $req->data->{customScript} .= $self->{AjaxInitScript};
            $self->logger->debug(
                "Send init/script -> " . $req->data->{customScript} );

            #$self->p->setHiddenFormValue( $req, kerberos => 0, '', 0 );
            eval( $self->InitCmd );
            die 'Unable to launch init commmand ' . $self->{InitCmd} if ($@);
            return PE_FIRSTACCESS;
        }
    }

    # Case 4: an "Authorization header" has been sent
    if ( $auth !~ /^Negotiate (.*)$/ ) {
        $self->userLogger->error('Bad authorization header');
        return PE_BADCREDENTIALS;
    }

    # Case 5: Kerberos ticket received
    $self->logger->debug("Kerberos ticket received: $1");
    my $data;
    eval { $data = MIME::Base64::decode($1) };
    if ($@) {
        $self->userLogger->error( 'Bad authorization header: ' . $@ );
        return PE_BADCREDENTIALS;
    }
    $ENV{KRB5_KTNAME} = $self->keytab;
    $self->logger->debug( "Set KRB5_KTNAME env to " . $ENV{KRB5_KTNAME} );
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
        return PE_ERROR;
    }
    my $client_name;
    $status = $gss_client_name->display($client_name);
    unless ($status) {
        $self->logger->error('Unable to display KRB client name');
        foreach ( $status->generic_message(), $status->specific_message() ) {
            $self->logger->error($_);
        }
        return PE_ERROR;
    }
    $self->userLogger->notice("$client_name authentified by Kerberos");
    $req->data->{_krbUser} = $client_name;
    if ( $self->conf->{krbRemoveDomain} ) {
        $client_name =~ s/^(.*)@.*$/$1/;
    }
    $req->user($client_name);
    return PE_OK;
}

sub authenticate {
    PE_OK;
}

sub authLogout {
    PE_OK;
}

sub setAuthSessionInfo {
    my ( $self, $req ) = @_;
    $req->{sessionInfo}->{authenticationLevel} = $self->conf->{krbAuthnLevel};
    $req->{sessionInfo}->{_krbUser}            = $req->data->{_krbUser};
    PE_OK;
}

sub getDisplayType {
    return "logo";
}

1;
