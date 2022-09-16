package Lemonldap::NG::Handler::Lib::AuthBasic;

use strict;
use Exporter;
use Digest::SHA qw(sha256_hex);
use MIME::Base64;
use HTTP::Headers;

#use SOAP::Lite;    # link protected portalRequest
use Lemonldap::NG::Common::UserAgent;
use Lemonldap::NG::Common::FormEncode;
use Lemonldap::NG::Common::Session;

our $VERSION = '2.0.15';
our @ISA     = ('Exporter');
our @EXPORT  = qw(fetchId retrieveSession createSession hideCookie goToPortal);
our @EXPORT_OK = @EXPORT;
our $_ua;

sub ua {
    my ($class) = @_;
    return $_ua if $_ua;
    $_ua = Lemonldap::NG::Common::UserAgent->new( {
            lwpOpts    => $class->tsv->{lwpOpts},
            lwpSslOpts => $class->tsv->{lwpSslOpts}
        }
    );
    return $_ua;
}

## @rmethod protected fetchId
# Get user session id from Authorization header
# Unlike usual processing, session id is computed from user creds,
# so that it remains secret but handler can easily get it.
# It is still changed from time to time - once a day - to prevent from
# using indefinitely a session id disclosed accidentally or maliciously.
# @return session id
sub fetchId {
    my ( $class, $req ) = @_;
    if ( my $creds = $req->env->{'HTTP_AUTHORIZATION'} ) {
        $creds =~ s/^Basic\s+//;
        my @date = localtime;
        my $day  = $date[5] * 366 + $date[7];
        return Digest::SHA::sha256_hex( $creds . $day );
    }
    else {
        return 0;
    }
}

## @rmethod protected boolean retrieveSession(id)
# Tries to retrieve the session whose index is id,
# and if needed, ask portal to create it through a SOAP request
# @return true if the session was found, false else
sub retrieveSession {
    my ( $class, $req, $id ) = @_;

    # First check if session already exists
    if ( my $res =
        $class->Lemonldap::NG::Handler::Main::retrieveSession( $req, $id ) )
    {
        return $res;
    }

    # Then ask portal to create it
    if ( $class->createSession( $req, $id ) ) {
        return $class->Lemonldap::NG::Handler::Main::retrieveSession( $req,
            $id );
    }
    else {
        return 0;
    }
}

## @rmethod protected boolean createSession(id)
# Send a create session request to the Portal
# @return true if the session is created, else false
sub createSession {
    my ( $class, $req, $id ) = @_;

    # Add client IP as X-Forwarded-For IP in request
    my $xheader = $req->env->{'HTTP_X_FORWARDED_FOR'};
    $xheader .= ", " if ($xheader);
    $xheader .= $req->{env}->{REMOTE_ADDR};

    #my $soapHeaders = HTTP::Headers->new( "X-Forwarded-For" => $xheader );
    ## TODO: use adminSession or sessions
    #my $soapClient = SOAP::Lite->proxy(
    #    $class->tsv->{portal}->() . '/sessions',
    #    default_headers => $soapHeaders
    #)->uri('urn:Lemonldap/NG/Common/PSGI/SOAPService');

    my $creds = $req->env->{'HTTP_AUTHORIZATION'};
    $creds =~ s/^Basic\s+//;
    my ( $user, $pwd ) = ( decode_base64($creds) =~ /^(.*?):(.*)$/ );
    $class->logger->debug("AuthBasic authentication for user: $user");

    #my $soapRequest = $soapClient->getCookies( $user, $pwd, $id );
    my $url = $class->tsv->{portal}->() . "/sessions/global/$id?auth";
    $url =~ s#//sessions/#/sessions/#g;
    my $get = HTTP::Request->new( POST => $url );
    $get->header( 'X-Forwarded-For' => $xheader );
    $get->header( 'Content-Type'    => 'application/x-www-form-urlencoded' );
    $get->header( Accept            => 'application/json' );
    $get->content(
        build_urlencoded(
            user     => $user,
            password => $pwd,
            secret   => $class->tsv->{cipher}->encrypt(time),
            (
                $class->tsv->{authChoiceAuthBasic}
                ? ( $class->tsv->{authChoiceParam} =>
                      $class->tsv->{authChoiceAuthBasic} )
                : ()
            )
        )
    );
    my $resp = $class->ua->request($get);

    if ( $resp->is_success ) {
        $class->userLogger->notice("Good REST authentication for $user");
        return 1;
    }
    else {
        $class->userLogger->warn(
            "Authentication failed for $user: " . $resp->status_line );
        return 0;
    }

    ## Catch SOAP errors
    #if ( $soapRequest->fault ) {
    #    $class->abort( "SOAP request to the portal failed: "
    #          . $soapRequest->fault->{faultstring} );
    #}
    #else {
    #    my $res = $soapRequest->result();

    #    # If authentication failed, display error
    #    if ( $res->{errorCode} ) {
    #        $class->userLogger->notice( "Authentication failed for $user: "
    #              . $soapClient->error( $res->{errorCode}, 'en' )->result() );
    #        return 0;
    #    }
    #    else {
    #        return 1;
    #    }
    #}
}

## @rmethod protected void hideCookie()
# Hide user credentials to the protected application
sub hideCookie {
    my ( $class, $req ) = @_;
    $class->logger->debug("removing Authorization header");
    $class->unset_header_in( $req, 'Authorization' );
}

## @rmethod protected int goToPortal(string url, string arg)
# If user is asked to authenticate, return $class->AUTH_REQUIRED,
# else redirect him to the portal to display some message defined by $arg
# @param $url Url requested
# @param $arg optionnal GET parameters
# @return AUTH_REDIRECT or AUTH_REQUIRED constant
sub goToPortal {
    my ( $class, $req, $url, $arg ) = @_;
    if ($arg) {
        return $class->Lemonldap::NG::Handler::Main::goToPortal( $req, $url,
            $arg );
    }
    else {
        $class->set_header_out( $req,
            'WWW-Authenticate' => 'Basic realm="LemonLDAP::NG"' );
        return $class->AUTH_REQUIRED;
    }
}

1;
