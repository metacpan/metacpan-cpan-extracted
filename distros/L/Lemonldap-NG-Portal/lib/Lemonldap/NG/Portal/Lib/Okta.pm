package Lemonldap::NG::Portal::Lib::Okta;

use strict;
use HTTP::Request;
use Mouse::Role;
use URI;

has ua => (
    is      => 'rw',
    lazy    => 1,
    builder => sub {
        my $ua = Lemonldap::NG::Common::UserAgent->new( $_[0]->{conf} );
        $ua->env_proxy();
        $ua->default_headers->header( 'Accept'       => 'application/json' );
        $ua->default_headers->header( 'Content-Type' => 'application/json' );
        $ua->default_headers->header(
            'Authorization' => 'SSWS ' . $_[0]->{conf}->{okta2fApiKey} );

        return $ua;
    }
);

sub searchProfile {
    my ( $self, $okta_login ) = @_;

    my $u = URI->new( $self->conf->{okta2fAdminURL} . '/api/v1/users/' );
    $u->query_form( 'search' => 'profile.login eq "' . $okta_login . '"' );
    my $user_response = $self->ua->get( $u->as_string );
    if ( $user_response->is_error ) {
        $self->logger->error( "Unable to get user "
              . $okta_login
              . " in Okta:"
              . $user_response->content );
        return;
    }

    return $user_response->decoded_content;
}

sub searchFactors {
    my ( $self, $okta_userid ) = @_;

    my $factor_response =
      $self->ua->get( $self->conf->{okta2fAdminURL}
          . '/api/v1/users/'
          . $okta_userid
          . '/factors' );

    if ( $factor_response->is_error ) {
        $self->logger->error( "Unable to get factors for $okta_userid in Okta:"
              . $factor_response->content );
        return;
    }

    return $factor_response->decoded_content;
}

sub issueFactor {
    my ( $self, $okta_userid, $okta_factorid ) = @_;

    my $issue_request = HTTP::Request->new(
        'POST',
        $self->conf->{okta2fAdminURL}
          . '/api/v1/users/'
          . $okta_userid
          . '/factors/'
          . $okta_factorid
          . '/verify',
        []
    );
    my $issue_response = $self->ua->request($issue_request);

    if ( $issue_response->is_error ) {
        $self->logger->error(
            "Unable to issue factor challenge for $okta_userid in Okta:"
              . $issue_response->content );
        return;
    }

    return $issue_response->decoded_content;
}

sub pollFactor {
    my ( $self, $okta_poll_url ) = @_;

    my $poll_response = $self->ua->get($okta_poll_url);

    if ( $poll_response->is_error ) {
        $self->logger->error(
            "Unable to get poll response on $okta_poll_url in Okta:"
              . $poll_response->content );
        return;
    }

    return $poll_response->decoded_content;
}

sub verifyFactor {
    my ( $self, $okta_userid, $okta_factorid, $code ) = @_;

    my $verify_content = '{"passCode":"' . $code . '"}';

    my $verify_request = HTTP::Request->new(
        'POST',
        $self->conf->{okta2fAdminURL}
          . '/api/v1/users/'
          . $okta_userid
          . '/factors/'
          . $okta_factorid
          . '/verify',
        [],
        $verify_content
    );
    my $verify_response = $self->ua->request($verify_request);

    if ( $verify_response->is_error ) {
        $self->logger->error(
            "Unable to verify code $code for $okta_userid in Okta:"
              . $verify_response->content );
        return;
    }

    return $verify_response->decoded_content;
}

1;
