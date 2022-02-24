package Lemonldap::NG::Handler::PSGI::Try;

use strict;
use Mouse;

our $VERSION = '2.0.14';

extends 'Lemonldap::NG::Handler::PSGI::Router';

has 'authRoutes' => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub {
        {
            GET     => {},
            POST    => {},
            PUT     => {},
            PATCH   => {},
            DELETE  => {},
            OPTIONS => {}
        }
    }
);

has 'unAuthRoutes' => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub {
        {
            GET     => {},
            POST    => {},
            PUT     => {},
            PATCH   => {},
            DELETE  => {},
            OPTIONS => {}
        }
    }
);

sub addRoute {
    die;
}

sub addAuthRoute {
    my $self = shift;
    $self->routes( $self->authRoutes );
    $self->logger->debug('Declaring auth route');
    return $self->SUPER::addRoute(@_);
}

sub addUnauthRoute {
    my $self = shift;
    $self->routes( $self->unAuthRoutes );
    $self->logger->debug('Declaring unauth route');
    return $self->SUPER::addRoute(@_);
}

sub addAuthRouteWithRedirect {
    my $self = shift;
    $self->logger->debug("Route with redirect to $_[0]");
    $self->addAuthRoute(@_);
    $self->addUnauthRoute( $_[0] => '_auth_and_redirect', [ 'GET', 'POST' ] );
}

sub _auth_and_redirect {
    my ( $self, $req ) = @_;
    $self->api->goToPortal( $req, $req->{env}->{REQUEST_URI} );
    return [ 302, [ $req->spliceHdrs ], [] ];
}

sub defaultAuthRoute {
    my $self = shift;
    $self->routes( $self->authRoutes );
    return $self->SUPER::defaultRoute(@_);
}

sub defaultUnauthRoute {
    my $self = shift;
    $self->routes( $self->unAuthRoutes );
    return $self->SUPER::defaultRoute(@_);
}

sub _run {
    my $self = shift;

    return sub {
        my $req = Lemonldap::NG::Common::PSGI::Request->new( $_[0] );
        my $res = $self->_logAuthTrace( $req, 1 );
        if ( $res->[0] < 300 ) {
            $self->routes( $self->authRoutes );
            $req->userData( $self->api->data );
            $req->respHeaders( $res->[1] );
        }
        elsif ( $res->[0] != 403 and not $req->data->{noTry} ) {

            # Unset headers (handler adds a Location header)
            $self->logger->debug(
                "User not authenticated, Try in use, cancel redirection");
            $req->userData( {} );
            $req->respHeaders( [] );
            $self->routes( $self->unAuthRoutes );
        }
        else {
            return $res;
        }
        $res = $self->_logAndHandle($req);
        push @{ $res->[1] }, $req->spliceHdrs;
        return $res;
    };

}

1;
__END__

=head1 NAME

=encoding utf8

Lemonldap::NG::Handler::PSGI::Try - Special handler for Lemonldap::NG Portal

=head1 SYNOPSIS

  package My::PSGI;
  
  use base Lemonldap::NG::Handler::PSGI::Try;
  
  sub init {
    my ($self,$args) = @_;
    
    # Declare REST routes for authenticated users (could be HTML templates or
    # methods)
    $self->addAuthRoute ( 'index.html', undef, ['GET'] )
         ->addAuthRoute ( books => { ':book' => 'booksMethod' }, ['GET', 'POST'] );
  
    # Default route (ie: PATH_INFO == '/')
    $self->defaultAuthRoute('index.html');
  
    # Same for unauthenticated users
    $self->addUnauthRoute ( 'login.html', undef, ['GET'] )
         ->addUnauthRoute ( 'login', undef, ['POST'] );
    $self->defaultUnauthRoute('login.html');
   
    # Return a boolean. If false, then error message has to be stored in
    # $self->error
    return 1;
  }
  
  sub booksMethod {
    my ( $self, $req, @otherPathInfo ) = @_;

    # Will be called only if authorized
    my $userId = $self->userId;
    my $book = $req->params('book');
    my $method = $req->method;
    ...
    $self->sendJSONresponse(...);
  }

=head1 DESCRIPTION

Lemonldap::NG::Handler::PSGI::Try is a L<Lemonldap::NG::Handler::PSGI::Router>
package that provides 2 REST routers: one for authenticated users and one for
unauthenticated users.

=head1 METHODS

Same as L<Lemonldap::NG::Handler::PSGI::Router> (inherits from
L<Lemonldap::NG::Common::PSGI::Router>) except that:

=over

=item addRoute() must be replaced by addAuthRoute() or addUnauthRoute()

=item defaultRoute() must be replaced by defaultAuthRoute() or defaultUnauthRoute()

=back

Note also that user session datas are available in $req parameter (first argument
received by REST methods):

=over

=item $req->userData() returns a hash reference containing user session data

=back

=head1 SEE ALSO

See L<Lemonldap::NG::Common::PSGI::Router> for more.

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
