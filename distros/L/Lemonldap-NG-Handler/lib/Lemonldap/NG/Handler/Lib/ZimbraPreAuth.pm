##@file
# Zimbra preauthentication

##@class
# Zimbra preauthentication
#
# It will build Zimbra preauth URL

package Lemonldap::NG::Handler::Lib::ZimbraPreAuth;

use strict;
use URI::Escape;
use Digest::HMAC_SHA1 qw(hmac_sha1_hex);

our $VERSION = '2.0.7';

# Overload main run method
sub run {
    my ( $class, $req )     = @_;
    my ( $ret,   $session ) = $class->Lemonldap::NG::Handler::Main::run($req);

    # Continue only if user is authorized
    return $ret unless ( $ret == $class->OK );

    # Get current URI
    my $uri = $req->{env}->{REQUEST_URI};

    # Get Zimbra parameters
    my $localConfig      = $class->localConfig;
    my $zimbraPreAuthKey = $localConfig->{zimbraPreAuthKey};
    my $zimbraAccountKey = $localConfig->{zimbraAccountKey} || 'uid';
    my $zimbraBy         = $localConfig->{zimbraBy}         || 'id';
    my $zimbraUrl        = $localConfig->{zimbraUrl}    || '/service/preauth';
    my $zimbraSsoUrl     = $localConfig->{zimbraSsoUrl} || '^/zimbrasso$';
    my $timeout          = $localConfig->{'timeout'}    || '0';

    # Remove trailing white-spaces
    $zimbraAccountKey =~ s/\s+$//;
    $zimbraBy         =~ s/\s+$//;
    $zimbraUrl        =~ s/\s+$//;
    $zimbraSsoUrl     =~ s/\s+$//;

    # Display found values in debug mode
    $class->logger->debug("zimbraPreAuthKey: $zimbraPreAuthKey");
    $class->logger->debug("zimbraAccountKey: $zimbraAccountKey");
    $class->logger->debug("zimbraBy: $zimbraBy");
    $class->logger->debug("zimbraUrl: $zimbraUrl");
    $class->logger->debug("zimbraSsoUrl: $zimbraSsoUrl");
    $class->logger->debug("timeout: $timeout");

    # Return if we are not on a Zimbra SSO URI
    return $class->OK unless ( $uri =~ $zimbraSsoUrl );

    # Check mandatory parameters
    unless ($zimbraPreAuthKey) {
        $class->logger->error("No Zimbra preauth key configured");
        return $class->SERVER_ERROR;
    }

    # Build URL
    my $zimbra_url =
      $class->_buildZimbraPreAuthUrl( $req, $zimbraPreAuthKey, $zimbraUrl,
        $class->data->{$zimbraAccountKey},
        $zimbraBy, $timeout );

    # Header location
    $class->set_header_out( $req, 'Location' => $zimbra_url );

    return $class->REDIRECT;
}

## @method private string _buildZimbraPreAuthUrl(string key, string url, string account, string by, int timeout)
# Build Zimbra PreAuth URL
# @param key PreAuthKey
# @param url URL
# @param account User account
# @param by Account type
# @param timeout Timout
# @return Zimbra PreAuth URL
sub _buildZimbraPreAuthUrl {
    my ( $class, $req, $key, $url, $account, $by, $timeout ) = @_;

    # Expiration time is calculated with _utime and timeout
    my $expires =
      $timeout ? ( $class->data->{_utime} + $timeout ) * 1000 : $timeout;

    # Timestamp
    my $timestamp = time() * 1000;

    # Compute preauth value
    my $computed_value =
      hmac_sha1_hex( "$account|$by|$expires|$timestamp", $key );

    $class->logger->debug(
        "Compute value $account|$by|$expires|$timestamp into $computed_value");

    # Build PreAuth URL
    my $zimbra_url =
"$url?account=$account&by=$by&timestamp=$timestamp&expires=$expires&preauth=$computed_value";

    $class->logger->debug("Build Zimbra URL: $zimbra_url");

    return $zimbra_url;
}

1;
