##@file
# Secure Token

##@class
# Secure Token
#
# Create a secure token used to resolve user identity by a protected application

# This specific handler is intended to be called directly by Apache

package Lemonldap::NG::Handler::Lib::SecureToken;

use strict;
use Cache::Memcached;
use Apache::Session::Generate::MD5;

our $VERSION = '2.0.7';

# Shared variables
our $secureTokenMemcachedConnection;

BEGIN {
    eval {
        require threads::shared;
        threads::share($secureTokenMemcachedConnection);
    };
}

## @rmethod Apache2::Const run(Apache2::RequestRec r)
# Overload main run method
# @param r Current request
# @return Apache2::Const value ($class->OK, $class->FORBIDDEN, $class->REDIRECT or $class->SERVER_ERROR)
sub run {
    my $class = shift;
    my $r     = shift;
    my ( $ret, $session ) = $class->Lemonldap::NG::Handler::Main::run($r);

    # Continue only if user is authorized
    return $ret unless ( $ret == $class->OK );

    # Get current URI
    my $uri = $r->{env}->{REQUEST_URI};

    # Catch Secure Token parameters
    my $localConfig = $class->localConfig;
    our $secureTokenMemcachedServers =
      $localConfig->{secureTokenMemcachedServers} || ['127.0.0.1:11211'];
    my $secureTokenExpiration = $localConfig->{secureTokenExpiration} || 60;
    my $secureTokenAttribute  = $localConfig->{secureTokenAttribute}  || 'uid';
    our $secureTokenUrls = $localConfig->{'secureTokenUrls'} || ['.*'];
    my $secureTokenHeader = $localConfig->{secureTokenHeader} || 'Auth-Token';
    my $secureTokenAllowOnError = $localConfig->{'secureTokenAllowOnError'}
      // 1;

    # Force some parameters to be array references
    foreach (qw/secureTokenMemcachedServers secureTokenUrls/) {
        no strict 'refs';
        unless ( ref ${$_} eq "ARRAY" ) {
            $class->logger->debug("Transform $_ value into an array reference");
            my @array = split( /\s+/, ${$_} );
            ${$_} = \@array;
        }
    }

    # Display found values in debug mode
    $class->logger->debug(
        "secureTokenMemcachedServers: @$secureTokenMemcachedServers");
    $class->logger->debug("secureTokenExpiration: $secureTokenExpiration");
    $class->logger->debug("secureTokenAttribute: $secureTokenAttribute");
    $class->logger->debug("secureTokenUrls: @$secureTokenUrls");
    $class->logger->debug("secureTokenHeader: $secureTokenHeader");
    $class->logger->debug("secureTokenAllowOnError: $secureTokenAllowOnError");

    # Return if we are not on a secure token URL
    my $checkurl = 0;
    foreach (@$secureTokenUrls) {
        if ( $uri =~ m#$_# ) {
            $checkurl = 1;
            $class->logger->debug(
                "URL $uri detected as an Secure Token URL (rule $_)");
            last;
        }
    }
    return $class->OK unless ($checkurl);

    # Test Memcached connection
    unless ( $class->_isAlive() ) {
        $secureTokenMemcachedConnection =
          $class->_createMemcachedConnection($secureTokenMemcachedServers);
    }

    # Exit if no connection
    return $class->_returnError( $r, $secureTokenAllowOnError )
      unless $class->_isAlive();

    # Value to store
    my $value = $class->data->{$secureTokenAttribute};

    # Set token
    my $key = $class->_setToken( $value, $secureTokenExpiration );
    return $class->_returnError( $r, $secureTokenAllowOnError ) unless $key;

    # Header location
    $class->set_header_in( $r, $secureTokenHeader => $key );

    # Remove token
    eval 'use Apache2::Filter' unless ( $INC{"Apache2/Filter.pm"} );

    if ( $INC{"Apache2/Filter.pm"} and defined $r->{env}->{'psgi.r'} ) {
        $r->{env}->{'psgi.r'}->add_output_filter(
            sub {
                my $f = shift;
                while ( $f->read( my $buffer, 1024 ) ) {
                    $f->print($buffer);
                }
                if ( $f->seen_eos ) {
                    $class->_deleteToken($key);
                }
                return $class->OK;
            }
        );
    }

    return $class->OK;
}

## @method private Cache::Memcached _createMemcachedConnection(ArrayRef secureTokenMemcachedServers)
# Create Memcached connexion
# @param $secureTokenMemcachedServers Memcached servers
# @return Cache::Memcached object
sub _createMemcachedConnection {
    my ( $class, $secureTokenMemcachedServers ) = @_;

    # Open memcached connexion
    my $memd = new Cache::Memcached {
        'servers' => $secureTokenMemcachedServers,
        'debug'   => 0,
    };

    $class->logger->debug("Memcached connection created");

    return $memd;
}

## @method private string _setToken(string value, int secureTokenExpiration)
# Set token value
# @param value Value
# @param secureTokenExpiration expiration
# @return Token key
sub _setToken {
    my ( $class, $value, $secureTokenExpiration ) = @_;
    my $key = Apache::Session::Generate::MD5::generate();
    my $res =
      $secureTokenMemcachedConnection->set( $key, $value,
        $secureTokenExpiration );

    unless ($res) {
        $class->logger->error("Unable to store secure token $key");
        return;
    }

    $class->logger->info("Set $value in token $key");

    return $key;
}

## @method private boolean _deleteToken(string key)
# Delete token
# @param key Key
# @return result
sub _deleteToken {
    my ( $class, $key ) = @_;
    my $res = $secureTokenMemcachedConnection->delete($key);

    unless ($res) {
        $class->logger->error("Unable to delete secure token $key");
    }
    else {
        $class->logger->info("Token $key deleted");
    }

    return $res;
}

## @method private boolean _isAlive()
# Run a STATS command to see if Memcached connection is alive
# @param connection Cache::Memcached object
# @return result
sub _isAlive {
    my ($class) = @_;
    return 0 unless defined $secureTokenMemcachedConnection;
    my $stats = $secureTokenMemcachedConnection->stats();

    if ( $stats and defined $stats->{'total'} ) {
        my $total_c = $stats->{'total'}->{'connection_structures'};
        my $total_i = $stats->{'total'}->{'total_items'};
        $class->logger->debug(
"Memcached connection is alive ($total_c connections / $total_i items)"
        );

        return 1;
    }

    $class->logger->error("Memcached connection is not alive");

    return 0;
}

## @method private int _returnError(boolean secureTokenAllowOnError)
# Give hand back to Apache
# @param secureTokenAllowOnError
# @return Apache2::Const value
sub _returnError {
    my ( $class, $r, $secureTokenAllowOnError ) = @_;

    if ($secureTokenAllowOnError) {
        $class->logger->debug("Allow request without secure token");
        return $class->OK;
    }

    # Redirect or Forbidden?
    if ( $class->tsv->{useRedirectOnError} ) {
        $class->logger->debug("Use redirect for error");
        return $class->goToError( '/', 500 );
    }

    else {
        $class->logger->debug("Return error");
        return $class->SERVER_ERROR;
    }
}

1;
