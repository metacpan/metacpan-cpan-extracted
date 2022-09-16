# Base package for simple issuers plugins
#
# Issuer should just implement a run() method that will be called only for
# authenticated users when PATH_INFO starts with issuerDBXXPath
#
# run() should just return a Lemonldap::NG::Portal::Main::Constants value. It
# is called using process() method (Lemonldap::NG::Portal::Main::Process)
package Lemonldap::NG::Portal::Main::Issuer;

use strict;
use Mouse;
use MIME::Base64;
use IO::String;
use URI::Escape;
use URI;
use Lemonldap::NG::Common::FormEncode;
use Lemonldap::NG::Portal::Main::Constants qw(
  PE_OK
  PE_RENEWSESSION
  PE_UPGRADESESSION
);

extends 'Lemonldap::NG::Portal::Main::Plugin';

our $VERSION = '2.0.12';

# PROPERTIES

has type  => ( is => 'rw' );
has path  => ( is => 'rw' );
has ipath => ( is => 'rw' );
has _ott => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        my $ott     = $_[0]->{p}->loadModule('::Lib::OneTimeToken');
        my $timeout = $_[0]->{conf}->{issuersTimeout}
          // $_[0]->{conf}->{formTimeout};
        $ott->timeout($timeout);
        return $ott;
    }
);

# INTERFACE

# Only logout is called in normal use. Issuer that inherits from this
# package are called only by their path
sub beforeLogout { 'logout' }

# INITIALIZATION

sub init {
    my ($self) = @_;
    if ( $self->conf->{forceGlobalStorageIssuerOTT} ) {
        $self->logger->debug(
            "-> Issuer tokens will be stored into global storage");
        $self->_ott->cache(undef);
    }

    my $type = ref( $_[0] );
    $type =~ s/.*:://;
    $self->type($type);
    if ( my $path = $self->conf->{"issuerDB${type}Path"} ) {
        $path =~ s/^.*?(\w+).*?$/$1/;
        $self->path($path);
        $self->addUnauthRoute(
            $path => { '*' => '_redirect' },
            [ 'GET', 'POST' ]
        );
        $self->addAuthRoute(
            $path => { '*' => "_forAuthUser" },
            [ 'GET', 'POST' ]
        );
    }
    else {
        $self->logger->debug("No path declared for issuer $type. Skipping");
    }
    $self->ipath( 'issuerRequest' . $self->path );
}

# RUNNING METHODS

# Case 1: Unauthentified users are redirected to the main portal

sub _redirect {
    my ( $self, $req, @path ) = @_;
    if (    $req->pdata->{issuerTs}
        and $req->pdata->{issuerTs} + $self->conf->{issuersTimeout} < time )
    {
        $self->cleanAllPdata($req);
    }
    my $restore;
    my $ir;
    unless ( $self->can('ssoMatch') and not $self->ssoMatch($req) ) {
        $self->logger->debug("Unauth request to $self->{path} issuer");
        $restore = 1;
        $self->logger->debug('Processing _redirect');
        $ir = $req->pdata->{ $self->ipath } ||= $self->storeRequest($req);
        $req->pdata->{ $self->ipath . 'Path' } = \@path;
        $self->logger->debug(
            'Add ' . $self->ipath . ', ' . $self->ipath . 'Path in keepPdata' );
        push @{ $req->pdata->{keepPdata} }, $self->ipath, $self->ipath . 'Path';
        $req->{urldc}           = $self->p->buildUrl( $self->path );
        $req->pdata->{_url}     = encode_base64( $req->urldc, '' );
        $req->pdata->{issuerTs} = time;
    }
    else {
        $self->logger->debug('Not seen as Issuer request, skipping');
    }

    # TODO: launch normal process with 'run' at the end
    return $self->p->do(
        $req,
        [
            'controlUrl',
            @{ $self->p->beforeAuth },
            $self->p->authProcess,
            @{ $self->p->betweenAuthAndData },
            $self->p->sessionData,
            @{ $self->p->afterData },
            $self->p->validSession,
            @{ $self->p->endAuth },
            (
                $restore
                ? sub {

                    # Restore urldc if auth doesn't need to dial with browser
                    $self->restoreRequest( $_[0], $ir );
                    $self->cleanPdata( $_[0] );
                    return $self->run( @_, @path );
                  }
                : ()
            )
        ]
    );
}

# Case 3: authentified user, launch
sub _forAuthUser {
    my ( $self, $req, @path ) = @_;

    if (    $req->pdata->{issuerTs}
        and $req->pdata->{issuerTs} + $self->conf->{issuersTimeout} < time )
    {
        $self->cleanAllPdata($req);
    }
    $self->logger->debug('Processing _forAuthUser');
    if ( my $r = $req->pdata->{ $self->ipath } ) {
        $self->logger->debug("Restoring request to $self->{path} issuer");
        $self->restoreRequest( $req, $r );
        @path = @{ $req->pdata->{ $self->ipath . 'Path' } }
          if ( $req->pdata->{ $self->ipath . 'Path' } );

        # In case a confirm form is shown, we need it to POST on the
        # current Path
        $req->data->{confirmFormAction} = URI->new( $req->uri )->path;
    }

    # Clean pdata: keepPdata has been set, so pdata must be cleaned here
    $self->logger->debug('Cleaning pdata');
    $self->cleanPdata($req);

    $req->maybeNotBase64(1) if ( ref($self) =~ /::CAS$/ );
    $req->mustRedirect(1);
    return $self->p->do(
        $req,
        [
            'importHandlerData',
            'controlUrl',
            @{ $self->p->forAuthUser },
            sub {
                return $self->run( @_, @path );
            },
        ]
    );
}

sub cleanAllPdata {
    my ( $self, $req ) = @_;
    foreach my $k ( keys %{ $req->pdata } ) {
        if ( exists $req->pdata->{ $k . 'Path' } ) {
            $self->cleanPdata( $req, $k );
        }
    }
}

sub cleanPdata {
    my ( $self, $req, $path ) = @_;
    $path ||= $self->ipath;
    for my $s ( $path, $path . 'Path' ) {
        if ( $req->pdata->{$s} ) {
            $self->logger->debug("Removing $s key from pdata");
            delete $req->pdata->{$s};
        }
    }
    if ( $req->pdata->{keepPdata} and ref $req->pdata->{keepPdata} ) {
        @{ $req->pdata->{keepPdata} } =
          grep {
                  $_ ne $path
              and $_ ne $path . 'Path'
              ? 1
              : ( $self->logger->debug("Removing $_ from keepPdata") and 0 )
          } @{ $req->pdata->{keepPdata} };
        delete $req->pdata->{keepPdata}
          unless ( @{ $req->pdata->{keepPdata} } );
    }
}

sub storeRequest {
    my ( $self, $req ) = @_;
    $self->logger->debug('Store issuer request');
    my $info = {};
    $info->{content} = $req->content;
    foreach ( keys %{ $req->env } ) {
        next if $_ eq "psgi.errors";
        next if $_ eq "psgi.input";
        $info->{$_} = $req->env->{$_} unless ( ref $req->env->{$_} );
    }
    return $self->_ott->createToken($info);
}

sub restoreRequest {
    my ( $self, $req, $token ) = @_;
    my $env = $self->_ott->getToken($token);
    if ($env) {
        $self->logger->debug("Restoring request from $token");
        if ( my $c = delete $env->{content} ) {
            $env->{'psgix.input.buffered'} = 0;
            $env->{'psgi.input'}           = IO::String->new($c);
        }
        $req->{env} = {};
        foreach ( keys %$env ) {
            $self->logger->debug(
                "Restore $_" . ( ref $env->{$_} ? '' : "\t" . $env->{$_} ) );
            $req->env->{$_} = $env->{$_} unless /^plack/;
        }
    }
    $req->{uri} = uri_unescape( $req->env->{REQUEST_URI} );
    $req->{uri} =~ s|^//+|/|g;
    return $req;
}

sub reAuth {
    my ( $self, $req ) = @_;
    $req->data->{customScript} =
qq'<script type="text/javascript" src="$self->{p}->{staticPrefix}/common/js/autoRenew.min.js"></script>'
      if ( $self->conf->{skipRenewConfirmation} );
    $req->data->{_url} =
      encode_base64( $self->conf->{portal} . $req->path_info, '' );
    $req->pdata->{ $self->ipath } = $self->storeRequest($req);
    push @{ $req->pdata->{keepPdata} }, $self->ipath, $self->ipath . 'Path';
    $req->pdata->{issuerTs} = time;
    return PE_RENEWSESSION;
}

sub upgradeAuth {
    my ( $self, $req ) = @_;
    $req->data->{customScript} =
qq'<script type="text/javascript" src="$self->{p}->{staticPrefix}/common/js/autoRenew.min.js"></script>'
      if ( $self->conf->{skipUpgradeConfirmation} );
    $req->data->{_url} =
      encode_base64( $self->conf->{portal} . $req->path_info, '' );
    $req->pdata->{ $self->ipath } = $self->storeRequest($req);
    push @{ $req->pdata->{keepPdata} }, $self->ipath, $self->ipath . 'Path';
    $req->pdata->{issuerTs} = time;
    return PE_UPGRADESESSION;
}

1;
__END__

=pod

=encoding utf8

=head1 NAME

Lemonldap::NG::Portal::Main::Issuer - Base class for identity providers.

=head1 SYNOPSIS

  package Lemonldap::NG::Portal::Issuer::My;
  use strict;
  use Mouse;
  extends 'Lemonldap::NG::Portal::Main::Issuer';
  use Lemonldap::NG::Portal::Main::Constants qw(PE_OK);

  # Required: URL root path
  use constant path => 'saml';
  
  # Optional initialization method
  sub init {
      my ($self) = @_;
      ...
      # Must return 1 (succeed) or 0 (failure)
  }
  
  # Required methods are run() and logout(), they are launched only for
  # authenticated users
  # $req is a Lemonldap::NG::Portal::Main::Request object
  # They must return a Lemonldap::NG::Portal::Main::Constants constant
  sub run {
      my ( $self, $req ) = @_
      ...
      return PE_OK
  }
  
  sub logout {
      my ( $self, $req ) = @_
      ...
      return PE_OK
  }
  1;

=head1 DESCRIPTION

Lemonldap::NG::Portal::Main::Issuer is a base class to write identity providers
for Lemonldap::NG web-SSO system. It provide several methods to write easily
an IdP and manage authentication if the identity request comes before
authentication.

=head1 WRITING AN IDENTITY PROVIDER

To write a classic identity provider, you just have to inherit this class and
write run() and logout() methods. These methods must return a
Lemonldap::NG::Portal::Main::Constants constant.

A classic identity provider needs a "issuerDBE<gt>XXXE<lt>Path" parameter in
LLNG configuration to declare its base URI path (see
L<Lemonldap::NG::Manager::Build>). Example: /saml/. All requests that starts
with /saml/ will call run() after authentication if needed, and no one else.

The logout() function is called when user asks for logout on this server. If
you want to write an identity provider, you must implement a single logout
system.

=head2 managing other URI path

Lemonldap::NG::Portal::Main::Issuer provides methods to bind a method to an
URI path:

=over

=item addAuthRoute() for authenticated users

=item addUnauthRoute() for unauthenticated users

=back

They must be called during initialization process (so you must write the
optional init() sub).

Be careful with C<add*authRoute()>: you can't catch here your root path (=
path declared in C<$self-E<gt>path>) because it is caught by this module,
but you can catch sub-routes (ie C</path/something>).

Example:

  sub init {
      my ($self) = @_;
      ...
      $self->addUnauthRoute( saml => { soap => 'soapServer' }, [ 'POST' ] );
      return 1;
  }
  sub soapServer {
      my ( $self, $req ) = @_;
      ...
      # You must return a valid PSGI response
      return [ 200, [ 'Content-Type' => 'application/xml' ], [] ];
  }

=head2 avoid conflicts in path

If you share base URI path with another plugin (a C<Auth::*> module for
example), it is recommended to write a C<ssoMatch> function that returns true
if C<$req-E<gt>uri> has to be handled by Issuer module. See C<Issuer::SAML>
or C<Issuer::OpenIDConnect> to have some examples.

=head1 SEE ALSO

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
