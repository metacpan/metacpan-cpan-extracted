package Lemonldap::NG::Portal::Main::SecondFactor;

use strict;
use Mouse;
use Lemonldap::NG::Portal::Main::Constants qw(
  PE_OK
  PE_ERROR
  PE_NOTOKEN
  PE_SENDRESPONSE
  PE_TOKENEXPIRED
  PE_BADCREDENTIALS
);

our $VERSION = '2.0.16';

extends qw(
  Lemonldap::NG::Portal::Main::Plugin
  Lemonldap::NG::Portal::Auth::_WebForm
);

# INITIALIZATION

has ott => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        my $ott =
          $_[0]->{p}->loadModule('Lemonldap::NG::Portal::Lib::OneTimeToken');
        $ott->timeout( $_[0]->{conf}->{sfLoginTimeout}
              || $_[0]->{conf}->{formTimeout} );
        return $ott;
    }
);

has prefix  => ( is => 'rw' );
has logo    => ( is => 'rw', default => '2f.png' );
has label   => ( is => 'rw' );
has noRoute => ( is => 'ro' );
has authnLevel => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        return $_[0]->conf->{ $_[0]->prefix . '2fAuthnLevel' };
    }
);

# 'type' field of stored _2fDevices
# Defaults to the last component of the package name
# But can be overriden by sfExtra
has type => (
    is      => 'rw',
    default => sub {
        ( split( '::', ref( $_[0] ) ) )[-1];
    }
);

sub init {
    my ($self) = @_;

    # Set logo if overridden
    $self->logo( $self->conf->{ $self->prefix . '2fLogo' } )
      if $self->conf->{ $self->prefix . '2fLogo' };

    # Set label if provided, translation files will be used otherwise
    $self->label( $self->conf->{ $self->prefix . '2fLabel' } )
      if $self->conf->{ $self->prefix . '2fLabel' };

    unless ( $self->noRoute ) {
        $self->logger->debug( 'Adding ' . $self->prefix . '2fcheck routes' );
        $self->addAuthRoute(
            $self->prefix . '2fcheck' => '_verify',
            ['POST']
        );
        $self->addAuthRoute(
            $self->prefix . '2fcheck' => '_redirect',
            ['GET']
        );
        $self->addUnauthRoute(
            $self->prefix . '2fcheck' => '_verify',
            ['POST']
        );
        $self->addUnauthRoute(
            $self->prefix . '2fcheck' => '_redirect',
            ['GET']
        );
    }
    return 1;
}

sub _redirect {
    my ( $self, $req ) = @_;
    my $arg = $req->env->{QUERY_STRING};
    return [
        302, [ Location => $self->conf->{portal} . ( $arg ? "?$arg" : '' ) ], []
    ];
}

sub _verify {
    my ( $self, $req ) = @_;

    # Check token
    my $token;
    unless ( $token = $req->param('token') ) {
        $self->userLogger->error( $self->prefix . ' 2F access without token' );
        eval { $self->setSecurity($req) };
        $req->mustRedirect(1);
        return $self->p->do( $req, [ sub { PE_NOTOKEN } ] );
    }

    my $session;
    unless ( $session = $self->ott->getToken($token) ) {
        $self->userLogger->info('Token expired');
        $req->noLoginDisplay(1);
        return $self->p->do( $req, [ sub { PE_TOKENEXPIRED } ] );
    }
    unless ( $session->{_2fRealSession} ) {
        $self->logger->error("Invalid 2FA session token");
        $req->noLoginDisplay(1);
        return $self->p->do( $req, [ sub { PE_ERROR } ] );
    }

    # Launch second factor verification
    my $res = $self->verify( $req, $session );

    # Update sessionInfo
    delete $session->{$_}
      foreach (qw(tokenSessionStartTimestamp tokenTimeoutTimestamp _type));
    $req->sessionInfo($session);
    $req->id( delete $req->sessionInfo->{_2fRealSession} );
    $req->urldc( delete $req->sessionInfo->{_2fUrldc} );
    $req->{sessionInfo}->{_utime} = delete $req->{sessionInfo}->{_2fUtime};
    $req->{sessionInfo}->{_2f}    = $self->prefix;

    # Case error
    if ($res) {
        $req->noLoginDisplay(1);
        $req->authResult(PE_BADCREDENTIALS);
        return $self->p->do( $req, [ 'storeHistory', sub { $res } ] );
    }

    # Else restore session
    $req->mustRedirect(1);
    $self->userLogger->notice( $self->prefix
          . '2f verification for '
          . $req->sessionInfo->{ $self->conf->{whatToTrace} } );

    if ( my $l = $self->authnLevel ) {
        $self->logger->debug(
            "Update sessionInfo with new authenticationLevel: $l");
        $req->sessionInfo->{authenticationLevel} = $l;

        # Compute macros & local groups again with new authenticationLevel
        $self->logger->debug("Compute macros and local groups...");
        $req->steps( [ 'setMacros', 'setLocalGroups' ] );
        if ( my $error = $self->p->process($req) ) {
            $self->logger->debug("SFA: Process returned error: $error");
            $req->error($error);
            return $self->p->do( $req, [ sub { $error } ] );
        }
        $self->logger->debug("De-duplicate groups...");
        $req->sessionInfo->{groups} = join $self->conf->{multiValuesSeparator},
          keys %{ {
                map { $_ => 1 } split $self->conf->{multiValuesSeparator},
                $req->sessionInfo->{groups}
            }
          };

        $self->logger->debug("Filter macros...");
        my %macros = (
            map { $_ => $req->sessionInfo->{$_} }
              keys %{ $self->{conf}->{macros} }
        );

        $self->logger->debug(
"Update session with new authenticationLevel, groups, hGroups and macros"
        );
        $self->p->updateSession(
            $req,
            {
                authenticationLevel => $l,
                groups              => $req->sessionInfo->{groups},
                hGroups             => $req->sessionInfo->{hGroups},
                _2f                 => $self->prefix,
                %macros
            }
        );
    }
    else {
        # Only update _2f session key
        $self->p->updateSession(
            $req,
            {
                _2f => $self->prefix,
            }
        );
    }

    $req->authResult(PE_SENDRESPONSE);
    return $self->p->do(
        $req,
        [
            @{ $self->p->afterData },
            $self->p->validSession,
            'rebuildCookies',
            @{ $self->p->endAuth },
            sub { PE_OK }
        ]
    );
}

1;
__END__

=pod

=encoding utf8

=head1 NAME

Lemonldap::NG::Portal::Main::SecondFactor - Base class for
L<Lemonldap::NG::Portal> second factor plugins.

=head1 SYNOPSIS

  package Lemonldap::NG::Portal::2F::MySecondFactor;
  use Mouse;
  # Import used constants
  use Lemonldap::NG::Portal::Main::Constants qw(
    PE_OK
    PE_BADCREDENTIALS
    PE_SENDRESPONSE
  );
  extends 'Lemonldap::NG::Portal::Main::SecondFactor';
  
  # INITIALIZATION
  
  # Prefix that will be used in parameter names. The form used to enter the
  # second factor must post its result to "/my2fcheck" (if "my" is the prefix).
  has prefix => ( is => 'ro', default => 'my' );
  # Optional logo
  has logo => ( is => 'rw', default => 'mylogo.png' );
  
  # Required init method
  sub init {
      my ($self) = @_;
      # Insert here initialization process
      #
      # If self registration is enabled and "activation" is set to "enabled",
      # replace the rule to detect if user has registered a device key.
      # The rule must be like this :
      # By example :
      $self->conf->{u2fActivation} = '$_2fDevices =~ /"type":\s*"U2F"/s'
      # Optionally, the rule can be : '$_2fDevices and $_2fDevices =~ /"type":\s*"U2F"/s'
      # to avoid warning due to undef variable
      #
      # Required call:
      return $self->SUPER::init();
  }

  # RUNNING METHODS
  
  # Required 2nd factor send method
  sub run {
      my ( $self, $req, $token ) = @_;
      # $token must be inserted in a hidden input in your form with the name
      # "token"
      ...
      # A LLNG constant must be returned. Example:
      $req->response($my_psgi_response)
      return PE_SENDRESPONSE;
  }
  # Required 2nd factor verify method
  sub verify {
      my ( $self, $req, $session ) = @_;
      # Use $req->param('field') to get POST responses
      ...
      if ($result eq $goodResult) {
        return PE_OK;
      }
      else {
        return PE_BADCREDENTIALS
      }
  }

Enable your plugin in lemonldap-ng.ini, section [portal]:

=over

=item <prefix>2fActivation (required): 1, 0 or a rule

=item <prefix>2fAuthnLevel (optional): change authentication level for users
authenticated by this plugin

=back

Example:

  [portal]
  customPlugins = Lemonldap::NG::Portal::2F::MyPlugin
  my2fActivation = 1
  my2fAuthnLevel = 4

=head1 DESCRIPTION

Lemonldap::NG::Portal::Main::SecondFactor provides a simple framework to build
Lemonldap::NG second authentication factor plugin.

See Lemonldap::NG::Portal::Plugins::2F::* packages for examples.

=head1 SEE ALSO

L<http://lemonldap-ng.org>

=head2 OTHER POD FILES

=over

=item Writing an authentication module: L<Lemonldap::NG::Portal::Auth>

=item Writing a UserDB module: L<Lemonldap::NG::Portal::UserDB>

=item Writing a second factor module: L<Lemonldap::NG::Portal::Main::SecondFactor>

=item Writing an issuer module: L<Lemonldap::NG::Portal::Main::Issuer>

=item Writing another plugin: L<Lemonldap::NG::Portal::Main::Plugin>

=item Request object: L<Lemonldap::NG::Portal::Main::Request>

=item Adding parameters in the manager: L<Lemonldap::NG::Manager::Build>

=back

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
