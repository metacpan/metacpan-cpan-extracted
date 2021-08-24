## @file
# Client side of the SOAP proxy mechanism for Apache::Session modules

## @class
# Client side of the SOAP proxy mechanism for Apache::Session modules
package Lemonldap::NG::Common::Apache::Session::SOAP;

use strict;
use SOAP::Lite;

our $VERSION = '2.0.0';

#parameter proxy Url of SOAP service
#parameter proxyOptions SOAP::Lite options
#parameter User Username
#parameter Password Password
#parameter localStorage Cache module
#parameter localStorageOptions Cache module options

# Variables shared with SOAP::Transport::HTTP::Client
our ( $user, $password ) = ( '', '' );

BEGIN {

    sub SOAP::Transport::HTTP::Client::get_basic_credentials {
        return $Lemonldap::NG::Common::Apache::Session::SOAP::user =>
          $Lemonldap::NG::Common::Apache::Session::SOAP::password;
    }
}

# PUBLIC INTERFACE

## @cmethod Lemonldap::NG::Common::Apache::Session::SOAP TIEHASH(string session_id, hashRef args)
# Constructor for Perl TIE mechanism. See perltie(3) for more.
# @return Lemonldap::NG::Common::Apache::Session::SOAP object
sub TIEHASH {
    my $class = shift;

    my $session_id = shift;
    my $args       = shift;
    my ( $proxy, $proxyOptions );
    die "proxy argument is required"
      unless ( $args and $args->{proxy} );
    my $self = {
        data     => { _session_id => $session_id },
        modified => 0,
    };
    foreach (qw(proxy proxyOptions ns localStorage localStorageOptions)) {
        $self->{$_} = $args->{$_};
    }
    ( $user, $password ) = ( $args->{User}, $args->{Password} );
    bless $self, $class;

    if ( defined $session_id && $session_id ) {
        die "unexistant session $session_id"
          unless ( $self->get($session_id) );
    }
    else {
        die "unable to create session"
          unless ( $self->newSession() );
    }
    return $self;
}

sub FETCH {
    my $self = shift;
    my $key  = shift;
    return $self->{data}->{$key};
}

sub STORE {
    my $self  = shift;
    my $key   = shift;
    my $value = shift;

    $self->{data}->{$key} = $value;
    $self->{modified} = 1;
    return $value;
}

sub DELETE {
    my $self = shift;
    my $key  = shift;

    $self->{modified} = 1;

    delete $self->{data}->{$key};
}

sub CLEAR {
    my $self = shift;

    $self->{modified} = 1;

    $self->{data} = {};
}

sub EXISTS {
    my $self = shift;
    my $key  = shift;
    return exists $self->{data}->{$key};
}

sub FIRSTKEY {
    my $self  = shift;
    my $reset = keys %{ $self->{data} };
    return each %{ $self->{data} };
}

sub NEXTKEY {
    my $self = shift;
    return each %{ $self->{data} };
}

sub DESTROY {
    my $self = shift;
    $self->save;
}

## @method private SOAP::Lite _connect()
# @return The SOAP::Lite object. Build it at the first call.
sub _connect {
    my $self = shift;
    return $self->{service} if ( $self->{service} );
    my @args = ( $self->{proxy} );
    if ( $self->{proxyOptions} ) {
        push @args, %{ $self->{proxyOptions} };
    }
    $self->{ns} ||= 'urn:Lemonldap/NG/Common/PSGI/SOAPService';
    return $self->{service} = SOAP::Lite->ns( $self->{ns} )->proxy(@args);
}

## @method private $ _soapCall(string func, @args)
# @param $func remote function to call
# @param @args Functions parameters
# @return Result
sub _soapCall {
    my $self = shift;
    my $func = shift;
    my $r    = $self->_connect->$func(@_);
    if ( $r->fault ) {
        print STDERR "SOAP Error: " . $r->fault->{faultstring};
        return ();
    }
    return $r->result;
}

## @method hashRef get(string id)
# @param $id Apache::Session session ID.
# @return User data
sub get {
    my $self = shift;
    my $id   = shift;

    # Check cache
    if ( $self->{localStorage} && $self->cache->get("soap$id") ) {
        return $self->{data} = $self->cache->get("soap$id");
    }

    # No cache, use SOAP and set cache
    my $r = $self->_soapCall( "getAttributes", $id );
    return 0 unless ( $r or $r->{error} );
    $self->{data} = $r->{attributes};

    $self->cache->set( "soap$id", $self->{data} ) if $self->{localStorage};

    return $self->{data};
}

## @method hashRef newSession()
# Build a new Apache::Session session.
# @return User data (just the session ID)
sub newSession {
    my $self = shift;
    $self->{data} = $self->_soapCall("newSession");

    # Set cache
    if ( $self->{localStorage} ) {
        my $id = "soap" . $self->{data}->{_session_id};
        if ( $self->cache->get($id) ) {
            $self->cache->remove($id);
        }
        $self->cache->set( $id, $self->{data} );
    }

    return $self->{data};
}

## @method boolean save()
# Save user data if modified.
sub save {
    my $self = shift;
    return unless ( $self->{modified} );

    # Update session in cache
    if ( $self->{localStorage} ) {
        my $id = "soap" . $self->{data}->{_session_id};
        if ( $self->cache->get($id) ) {
            $self->cache->remove($id);
        }
        $self->cache->set( $id, $self->{data} );
    }

    # SOAP
    return $self->_soapCall( "setAttributes", $self->{data}->{_session_id},
        $self->{data} );
}

## @method boolean delete()
# Deletes the current session.
sub delete {
    my $self = shift;

    # Remove session from cache
    if ( $self->{localStorage} ) {
        my $id = "soap" . $self->{data}->{_session_id};
        if ( $self->cache->get($id) ) {
            $self->cache->remove($id);
        }
    }

    # SOAP
    return $self->_soapCall( "deleteSession", $self->{data}->{_session_id} );
}

## @method get_key_from_all_sessions()
# Not documented.
sub get_key_from_all_sessions() {
    my $class = shift;
    my $args  = shift;
    my $data  = shift;
    my $self  = bless {}, $class;
    foreach (qw(proxy proxyOptions ns)) {
        $self->{$_} = $args->{$_};
    }
    die('proxy is required') unless ( $self->{proxy} );
    ( $user, $password ) = ( $args->{User}, $args->{Password} );

    # Get token before query
    my $token = Lemonldap::NG::Handler::Main->tsv->{cipher}
      ->decrypt( $self->_soapCall('getCipheredToken') );
    if ( ref($data) eq 'CODE' ) {
        my $r = $self->_soapCall( "get_key_from_all_sessions", $token );
        my $res;
        if ($r) {
            foreach my $k ( keys %$r ) {
                my $tmp = &$data( $r->{$k}, $k );
                $res->{$k} = $tmp if ( defined($tmp) );
            }
        }
    }
    else {
        return $self->_soapCall( "get_key_from_all_sessions", $token, $data );
    }
}

sub cache {
    my $self = shift;

    return $self->{cache} if $self->{cache};

    my $module = $self->{localStorage};
    eval "use $module;";
    $self->{cache} = $module->new( $self->{localStorageOptions} );

    return $self->{cache};
}

1;
__END__

=head1 NAME

=encoding utf8

Lemonldap::NG::Common::Apache::Session::SOAP - Perl extension written to
access to Lemonldap::NG Web-SSO sessions via SOAP.

=head1 SYNOPSIS

=over

=item * With Lemonldap::NG::Handler

  package My::Package;
  use Lemonldap::NG::Handler::SharedConf;

  our @ISA = qw(Lemonldap::NG::Handler::Simple);

  __PACKAGE__->init ({
         globalStorage => 'Lemonldap::NG::Common::Apache::Session::SOAP',
         globalStorageOptions => {
                 proxy => 'http://auth.example.com/sessions',
                 proxyOptions => {
                     timeout => 5,
                 },
                 # If soapserver is protected by HTTP Basic:
                 User     => 'http-user',
                 Password => 'pass',
                 # To have a local session cache
                 localStorage        => "Cache::FileCache",
                 localStorageOptions => {
                     'namespace'          => 'lemonldap-ng',
                     'default_expires_in' => 600,
                 },
         },
         configStorage       => {
             ... # See Lemonldap::NG::Handler

=item * With Lemonldap::NG::Portal

  use Lemonldap::NG::Portal::SharedConf;
  my $portal = new Lemonldap::NG::Portal::SharedConf (
         globalStorage => 'Lemonldap::NG::Common::Apache::Session::SOAP',
         globalStorageOptions => {
                 proxy => 'http://auth.example.com/sessions',
                 proxyOptions => {
                     timeout => 5,
                 },
                 # If soapserver is protected by HTTP Basic:
                 User     => 'http-user',
                 Password => 'pass',
                 # To have a local session cache
                 localStorage        => "Cache::FileCache",
                 localStorageOptions => {
                     'namespace'          => 'lemonldap-ng',
                     'default_expires_in' => 600,
                 },
         },
         configStorage => {
             ... # See Lemonldap::NG::Portal

You can also set parameters corresponding to "Apache::Session module" in the
manager.

=back

=head1 DESCRIPTION

Lemonldap::NG::Common::Conf provides a simple interface to access to
Lemonldap::NG Web-SSO configuration. It is used by L<Lemonldap::NG::Handler>,
L<Lemonldap::NG::Portal> and L<Lemonldap::NG::Manager>.

Lemonldap::NG::Common::Apache::Session::SOAP used with
L<Lemonldap::NG::Portal> provides the ability to access to
Lemonldap::NG sessions via SOAP: the portal act as a proxy to access to the
real Apache::Session module (see HTML documentation for more)

=head2 SECURITY

As Lemonldap::NG::Common::Conf::SOAP use SOAP::Lite, you have to see
L<SOAP::Transport> to know arguments that can be passed to C<proxyOptions>.
Lemonldap::NG provides a system for HTTP basic authentication.

Examples :

=over

=item * HTTP Basic authentication

SOAP::transport can use basic authentication by rewriting
C<>SOAP::Transport::HTTP::Client::get_basic_credentials>:

  package My::Package;
  
  use base Lemonldap::NG::Handler::SharedConf;
  
  __PACKAGE__->init ( {
      globalStorage => 'Lemonldap::NG::Common::Apache::Session::SOAP',
      globalStorageOptions => {
                proxy => 'http://auth.example.com/sessions',
                User     => 'http-user',
                Password => 'pass',
      },
  } );

=item * SSL Authentication

SOAP::transport provides a simple way to use SSL certificate: you've just to
set environment variables.

  package My::Package;
  
  use base Lemonldap::NG::Handler::SharedConf;
  
  # AUTHENTICATION
  $ENV{HTTPS_CERT_FILE} = 'client-cert.pem';
  $ENV{HTTPS_KEY_FILE}  = 'client-key.pem';
  
  __PACKAGE__->init ( {
      globalStorage => 'Lemonldap::NG::Common::Apache::Session::SOAP',
      globalStorageOptions => {
                proxy => 'https://auth.example.com/sessions',
      },
  } );

=back

=head1 SEE ALSO

L<Lemonldap::NG::Manager>, L<Lemonldap::NG::Common::Conf::SOAP>,
L<Lemonldap::NG::Handler>, L<Lemonldap::NG::Portal>,
L<http://lemonldap-ng.org/>

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
