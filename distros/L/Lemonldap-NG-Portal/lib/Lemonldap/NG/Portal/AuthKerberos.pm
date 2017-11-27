package Lemonldap::NG::Portal::AuthKerberos;

use strict;
use GSSAPI;
use MIME::Base64;
use Lemonldap::NG::Portal::Simple;

our $VERSION = '1.9.14';

# INITIALIZATION

sub authInit {
    my ($self) = @_;
    my $file;
    unless ( $file = $self->{krbKeytab} ) {
        $self->lmLog( 'Keytab not defined', 'error' );
        return PE_ERROR;
    }
    $self->{_keytab} = "FILE:$file";
    return PE_OK;
}

sub extractFormInfo {
    my ($self) = @_;

    if ( $self->{krbUseModKrb} and $self->{_krbUser} = $ENV{REMOTE_USER} ) {
        $self->userNotice(
            "$self->{_krbUuser} authentified by Web Server Kerberos module");
        $self->{user} = $self->{_krbUser};
        if ( $self->{krbRemoveDomain} ) { $self->{user} =~ s/^(.*)@.*$/$1/; }
        return PE_OK;
    }

    my $auth = $ENV{HTTP_AUTHORIZATION};
    unless ($auth) {

        # Case 1: simple usage or first Kerberos Ajax request
        #         => return 401 to initiate Kerberos
        if ( !$self->{krbByJs} or $self->param('kerberos') ) {
            $self->lmLog( 'Initialize Kerberos dialog', 'debug' );

            # HTML request: display error and initiate Kerberos
            # dialog
            print $self->header(
                -status             => '401 Unauthorizated',
                '-WWW-Authenticate' => 'Negotiate'
            );
            $self->quit;
        }

        # Case 2: Ajax Kerberos request has failed, and javascript has reloaded
        # page with "kerberos=0". Return an error to be able to switch to
        # another backend (Multi)
        # switch to another backend
        elsif ( defined $self->param('kerberos') ) {
            $self->userNotice(
                'Kerberos authentication has failed, back to portal');
            $self->setHiddenFormValue( 'kerberos', 0, '', 0 );
            return PE_BADCREDENTIALS;
        }

        # Case 3: Display kerberos auth page (with javascript)
        else {
            $self->lmLog( 'Send Kerberos javascript', 'debug' );
            return PE_FIRSTACCESS;
        }
    }

    # Case 4: an "Authorization header" has been sent
    if ( $auth !~ /^Negotiate (.*)$/ ) {
        $self->userError('Bad authorization header');
        return PE_BADCREDENTIALS;
    }

    # Case 5: Kerberos ticket received
    $self->lmLog( "Kerberos ticket received: $1", 'debug' );
    my $data;
    eval { $data = MIME::Base64::decode($1) };
    if ($@) {
        $self->userError( 'Bad authorization header: ' . $@ );
        return PE_BADCREDENTIALS;
    }
    $ENV{KRB5_KTNAME} = $self->{_keytab};
    $self->lmLog( "Set KRB5_KTNAME env to " . $ENV{KRB5_KTNAME}, 'debug' );
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
        $self->lmLog( 'Unable to accept security context', 'error' );
        return PE_ERROR;
    }
    my $client_name;
    $status = $gss_client_name->display($client_name);
    unless ($status) {
        $self->lmLog( 'Unable to display KRB client name', 'error' );
        foreach ( $status->generic_message(), $status->specific_message() ) {
            $self->lmLog( $_, 'error' );
        }
        return PE_ERROR;
    }
    $self->userNotice("$client_name authentified by Kerberos");
    $self->{_krbUser} = $client_name;
    $self->{user}     = $self->{_krbUser};
    if ( $self->{krbRemoveDomain} ) { $self->{user} =~ s/^(.*)@.*$/$1/; }
    return PE_OK;
}

sub authenticate {
    PE_OK;
}

sub authLogout {
    PE_OK;
}

sub setAuthSessionInfo {
    my ($self) = @_;
    $self->{sessionInfo}->{authenticationLevel} = $self->{krbAuthnLevel};
    $self->{sessionInfo}->{_krbUser}            = $self->{_krbUser};
    PE_OK;
}

sub getDisplayType {
    return "kerberos";
}

1;
