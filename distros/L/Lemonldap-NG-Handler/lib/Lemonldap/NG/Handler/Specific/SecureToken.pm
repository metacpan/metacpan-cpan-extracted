##@file
# Secure Token

##@class
# Secure Token
#
# Create a secure token used to resolve user identity by a protected application

# This specific handler is intended to be called directly by Apache

package Lemonldap::NG::Handler::Specific::SecureToken;

use strict;
use Lemonldap::NG::Handler::SharedConf qw(:all);
use Lemonldap::NG::Handler::API qw(:httpCodes);
use base qw(Lemonldap::NG::Handler::SharedConf);
use Cache::Memcached;
use Apache::Session::Generate::MD5;
use Lemonldap::NG::Handler::Main::Logger;

our $VERSION = '1.9.1';

# Shared variables
our $secureTokenMemcachedConnection;

BEGIN {
    eval {
        require threads::shared;
        threads::share($secureTokenMemcachedConnection);
    };
}

sub handler {
    my ( $class, $request ) = ( __PACKAGE__, shift );
    Lemonldap::NG::Handler::API->newRequest($request);
    $class->run($request);
}

## @rmethod Apache2::Const run(Apache2::RequestRec r)
# Overload main run method
# @param r Current request
# @return Apache2::Const value (OK, FORBIDDEN, REDIRECT or SERVER_ERROR)
sub run {
    my $class = shift;
    my $r     = $_[0];
    my $ret   = $class->SUPER::run();

    # Continue only if user is authorized
    return $ret unless ( $ret == OK );

    # Get current URI
    my $uri = Lemonldap::NG::Handler::API->uri_with_args($r);

    # Catch Secure Token parameters
    my $localConfig = $Lemonldap::NG::Handler::SharedConf::localConfig;
    my $secureTokenMemcachedServers =
      $localConfig->{secureTokenMemcachedServers} || ['127.0.0.1:11211'];
    my $secureTokenExpiration = $localConfig->{secureTokenExpiration} || 60;
    my $secureTokenAttribute  = $localConfig->{secureTokenAttribute}  || 'uid';
    my $secureTokenUrls       = $localConfig->{'secureTokenUrls'}     || ['.*'];
    my $secureTokenHeader = $localConfig->{secureTokenHeader} || 'Auth-Token';
    my $secureTokenAllowOnError = 1
      unless defined $localConfig->{'secureTokenAllowOnError'};

    # Force some parameters to be array references
    foreach (qw/secureTokenMemcachedServers secureTokenUrls/) {
        no strict 'refs';
        unless ( ref ${$_} eq "ARRAY" ) {
            Lemonldap::NG::Handler::Main::Logger->lmLog(
                "Transform $_ value into an array reference", 'debug' );
            my @array = split( /\s+/, ${$_} );
            ${$_} = \@array;
        }
    }

    # Display found values in debug mode
    Lemonldap::NG::Handler::Main::Logger->lmLog(
        "secureTokenMemcachedServers: @$secureTokenMemcachedServers", 'debug' );
    Lemonldap::NG::Handler::Main::Logger->lmLog(
        "secureTokenExpiration: $secureTokenExpiration", 'debug' );
    Lemonldap::NG::Handler::Main::Logger->lmLog(
        "secureTokenAttribute: $secureTokenAttribute", 'debug' );
    Lemonldap::NG::Handler::Main::Logger->lmLog(
        "secureTokenUrls: @$secureTokenUrls", 'debug' );
    Lemonldap::NG::Handler::Main::Logger->lmLog(
        "secureTokenHeader: $secureTokenHeader", 'debug' );
    Lemonldap::NG::Handler::Main::Logger->lmLog(
        "secureTokenAllowOnError: $secureTokenAllowOnError", 'debug' );

    # Return if we are not on a secure token URL
    my $checkurl = 0;
    foreach (@$secureTokenUrls) {
        if ( $uri =~ m#$_# ) {
            $checkurl = 1;
            Lemonldap::NG::Handler::Main::Logger->lmLog(
                "URL $uri detected as an Secure Token URL (rule $_)", 'debug' );
            last;
        }
    }
    return OK unless ($checkurl);

    # Test Memcached connection
    unless ( $class->_isAlive() ) {
        $secureTokenMemcachedConnection =
          $class->_createMemcachedConnection($secureTokenMemcachedServers);
    }

    # Exit if no connection
    return $class->_returnError( $r, $secureTokenAllowOnError )
      unless $class->_isAlive();

    # Value to store
    my $value = $datas->{$secureTokenAttribute};

    # Set token
    my $key = $class->_setToken( $value, $secureTokenExpiration );
    return $class->_returnError( $r, $secureTokenAllowOnError ) unless $key;

    # Header location
    Lemonldap::NG::Handler::API->set_header_in( $secureTokenHeader => $key );

    # Remove token
    eval 'use Apache2::Filter' unless ( $INC{"Apache2/Filter.pm"} );

    $r->add_output_filter(
        sub {
            my $f = shift;
            while ( $f->read( my $buffer, 1024 ) ) {
                $f->print($buffer);
            }
            if ( $f->seen_eos ) {
                $class->_deleteToken($key);
            }
            return OK;
        }
    );

    # Return OK
    return OK;
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

    Lemonldap::NG::Handler::Main::Logger->lmLog( "Memcached connection created",
        'debug' );

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
        Lemonldap::NG::Handler::Main::Logger->lmLog(
            "Unable to store secure token $key", 'error' );
        return;
    }

    Lemonldap::NG::Handler::Main::Logger->lmLog( "Set $value in token $key",
        'info' );

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
        Lemonldap::NG::Handler::Main::Logger->lmLog(
            "Unable to delete secure token $key", 'error' );
    }
    else {
        Lemonldap::NG::Handler::Main::Logger->lmLog( "Token $key deleted",
            'info' );
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

        Lemonldap::NG::Handler::Main::Logger->lmLog(
"Memcached connection is alive ($total_c connections / $total_i items)",
            'debug'
        );

        return 1;
    }

    Lemonldap::NG::Handler::Main::Logger->lmLog(
        "Memcached connection is not alive", 'error' );

    return 0;
}

## @method private int _returnError(boolean secureTokenAllowOnError)
# Give hand back to Apache
# @param secureTokenAllowOnError
# @return Apache2::Const value
sub _returnError {
    my ( $class, $r, $secureTokenAllowOnError ) = @_;

    if ($secureTokenAllowOnError) {
        Lemonldap::NG::Handler::Main::Logger->lmLog(
            "Allow request without secure token", 'debug' );
        return OK;
    }

    # Redirect or Forbidden?
    if ( $tsv->{useRedirectOnError} ) {
        Lemonldap::NG::Handler::Main::Logger->lmLog( "Use redirect for error",
            'debug' );
        return $class->goToPortal( '/', 'lmError=500' );
    }

    else {
        Lemonldap::NG::Handler::Main::Logger->lmLog( "Return error", 'debug' );
        return SERVER_ERROR;
    }
}

__PACKAGE__->init( {} );

1;

__END__

=head1 NAME

=encoding utf8

Lemonldap::NG::Handler::SecureToken - Perl extension to generate a secure token

=head1 SYNOPSIS

package My::SecureToken;
use Lemonldap::NG::Handler::SecureToken;
@ISA = qw(Lemonldap::NG::Handler::SecureToken);

__PACKAGE__->init ( {

# See Lemonldap::NG::Handler for more

		} );
1;

=head1 DESCRIPTION

Edit your vhost configuration like this:

<VirtualHost *>
ServerName secure.example.com

# Load Secure Token Handler
PerlRequire __HANDLERDIR__/MyHandlerSecureToken.pm
PerlHeaderParserHandler My::SecureToken

</VirtualHost>

=head2 EXPORT

See L<Lemonldap::NG::Handler>

=head1 SEE ALSO

L<Lemonldap::NG::Handler>

=head1 AUTHOR

=over

=item Clement Oudot, E<lt>clem.oudot@gmail.comE<gt>

=back

=head1 BUG REPORT

Use OW2 system to report bug or ask for features:
L<http://jira.ow2.org>

=head1 DOWNLOAD

Lemonldap::NG is available at
L<http://forge.objectweb.org/project/showfiles.php?group_id=274>

=head1 COPYRIGHT AND LICENSE

=over

=item Copyright (C) 2011, 2012 by Clement Oudot, E<lt>clem.oudot@gmail.comE<gt>

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

